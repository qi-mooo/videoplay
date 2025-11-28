import Foundation
import AVFoundation

/// WebDAV 资源加载器，主要用于添加认证头部
class WebDAVResourceLoader: NSObject, AVAssetResourceLoaderDelegate, URLSessionDataDelegate, URLSessionTaskDelegate {
    
    private var session: URLSession!
    private let credential: URLCredential?
    private var requestMap: [URLSessionTask: AVAssetResourceLoadingRequest] = [:]
    private let queue = DispatchQueue(label: "com.videoplay.webdav", qos: .userInitiated)
    
    init(username: String? = nil, password: String? = nil) {
        if let username = username, let password = password {
            self.credential = URLCredential(user: username, password: password, persistence: .forSession)
        } else {
            self.credential = nil
        }
        super.init()
        
        let config = URLSessionConfiguration.default
        self.session = URLSession(configuration: config, delegate: self, delegateQueue: nil)
    }
    
    // MARK: - URLSessionTaskDelegate (Authentication)
    
    func urlSession(_ session: URLSession, task: URLSessionTask, didReceive challenge: URLAuthenticationChallenge, completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {
        Logger.shared.info("🔐 Auth Challenge: \(challenge.protectionSpace.authenticationMethod)")
        
        if let credential = credential, challenge.previousFailureCount == 0 {
            Logger.shared.info("🔐 Using credential")
            completionHandler(.useCredential, credential)
        } else {
            Logger.shared.error("❌ Auth failed or no credential")
            completionHandler(.performDefaultHandling, nil)
        }
    }
    
    func resourceLoader(_ resourceLoader: AVAssetResourceLoader,
                       shouldWaitForLoadingOfRequestedResource loadingRequest: AVAssetResourceLoadingRequest) -> Bool {
        
        queue.async { [weak self] in
            guard let self = self else {
                loadingRequest.finishLoading(with: NSError(domain: "WebDAVResourceLoader", code: -1))
                return
            }
            
            self.handleLoadingRequest(loadingRequest)
        }
        
        return true
    }
    
    func resourceLoader(_ resourceLoader: AVAssetResourceLoader,
                       didCancel loadingRequest: AVAssetResourceLoadingRequest) {
        queue.async { [weak self] in
            guard let self = self else { return }
            for (task, req) in self.requestMap {
                if req == loadingRequest {
                    task.cancel()
                    self.requestMap.removeValue(forKey: task)
                    break
                }
            }
        }
    }
    
    private func handleLoadingRequest(_ loadingRequest: AVAssetResourceLoadingRequest) {
        guard let url = loadingRequest.request.url else {
            Logger.shared.error("❌ WebDAV: Invalid URL in loading request")
            loadingRequest.finishLoading(with: NSError(domain: "WebDAV", code: -2))
            return
        }
        
        // 将自定义 scheme 还原为 http/https
        var components = URLComponents(url: url, resolvingAgainstBaseURL: false)
        if let scheme = components?.scheme {
            components?.scheme = scheme.replacingOccurrences(of: "streaming-", with: "")
        }
        
        guard let realURL = components?.url else {
            Logger.shared.error("❌ WebDAV: Failed to construct real URL from: \(url.absoluteString)")
            loadingRequest.finishLoading(with: NSError(domain: "WebDAV", code: -3))
            return
        }
        
        var request = URLRequest(url: realURL)
        request.httpMethod = "GET"
        
        // 手动添加 Basic Auth Header
        if let credential = credential, let user = credential.user, let password = credential.password {
            let authStr = "\(user):\(password)"
            if let authData = authStr.data(using: .utf8) {
                let authValue = "Basic \(authData.base64EncodedString())"
                request.setValue(authValue, forHTTPHeaderField: "Authorization")
                Logger.shared.debug("🔐 Added Authorization header")
            }
        }
        
        // 添加 Range 头部
        if let dataRequest = loadingRequest.dataRequest {
            let offset = dataRequest.requestedOffset
            let length = dataRequest.requestedLength
            let rangeEnd = offset + Int64(length) - 1
            request.setValue("bytes=\(offset)-\(rangeEnd)", forHTTPHeaderField: "Range")
            Logger.shared.debug("📥 WebDAV Request: \(offset)-\(rangeEnd)")
        }
        
        // 使用不带 completion handler 的 dataTask，这样 URLSessionDelegate 才会被调用
        let task = session.dataTask(with: request)
        requestMap[task] = loadingRequest
        task.resume()
    }
    
    // MARK: - URLSessionDataDelegate
    
    func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive response: URLResponse, completionHandler: @escaping (URLSession.ResponseDisposition) -> Void) {
        guard let loadingRequest = requestMap[dataTask],
              let httpResponse = response as? HTTPURLResponse else {
            completionHandler(.cancel)
            return
        }
        
        if httpResponse.statusCode >= 400 {
            Logger.shared.error("❌ HTTP Error: \(httpResponse.statusCode)")
            completionHandler(.allow)
            return
        }
        
        // 填充 Content Information
        if let contentRequest = loadingRequest.contentInformationRequest {
            var contentLength: Int64 = 0
            if let rangeHeader = httpResponse.allHeaderFields["Content-Range"] as? String {
                if let totalLengthStr = rangeHeader.components(separatedBy: "/").last,
                   let length = Int64(totalLengthStr) {
                    contentLength = length
                }
            }
            
            if contentLength == 0, let length = httpResponse.expectedContentLength as Int64?, length > 0 {
                if httpResponse.statusCode == 200 {
                    contentLength = length
                }
            }
            
            contentRequest.contentLength = contentLength
            let mimeType = httpResponse.mimeType ?? "video/mp4"
            contentRequest.contentType = mimeType == "application/octet-stream" ? "video/mp4" : mimeType
            contentRequest.isByteRangeAccessSupported = true
            
            Logger.shared.info("📊 Content: len=\(contentLength), type=\(contentRequest.contentType ?? "?")")
        }
        
        completionHandler(.allow)
    }
    
    func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive data: Data) {
        guard let loadingRequest = requestMap[dataTask],
              let dataRequest = loadingRequest.dataRequest else { return }
        
        dataRequest.respond(with: data)
    }
    
    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        guard let loadingRequest = requestMap[task] else { return }
        requestMap.removeValue(forKey: task)
        
        if let error = error {
            Logger.shared.error("❌ Task failed: \(error.localizedDescription)")
            loadingRequest.finishLoading(with: error)
        } else {
            if let httpResponse = task.response as? HTTPURLResponse, httpResponse.statusCode >= 400 {
                loadingRequest.finishLoading(with: NSError(domain: "HTTP", code: httpResponse.statusCode))
            } else {
                loadingRequest.finishLoading()
                Logger.shared.debug("✅ Task completed")
            }
        }
    }
}
