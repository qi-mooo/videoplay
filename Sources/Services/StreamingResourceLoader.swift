import AVFoundation
import Foundation

/// 流式资源加载器，用于实现从 file:// URL 的流式播放
/// 通过 AVAssetResourceLoaderDelegate 拦截数据请求，使用 FileHandle 按需读取
class StreamingResourceLoader: NSObject, AVAssetResourceLoaderDelegate {
    
    private let fileURL: URL
    private var fileHandle: FileHandle?
    private let queue = DispatchQueue(label: "com.videoplay.resourceloader")
    
    init(fileURL: URL) {
        self.fileURL = fileURL
        super.init()
    }
    
    deinit {
        try? fileHandle?.close()
    }
    
    // MARK: - AVAssetResourceLoaderDelegate
    
    func resourceLoader(_ resourceLoader: AVAssetResourceLoader, 
                       shouldWaitForLoadingOfRequestedResource loadingRequest: AVAssetResourceLoadingRequest) -> Bool {
        
        queue.async { [weak self] in
            guard let self = self else {
                loadingRequest.finishLoading(with: NSError(domain: "StreamingResourceLoader", code: -1))
                return
            }
            
            // 处理内容信息请求
            if let contentRequest = loadingRequest.contentInformationRequest {
                self.handleContentInfoRequest(contentRequest)
            }
            
            // 处理数据请求
            if let dataRequest = loadingRequest.dataRequest {
                self.handleDataRequest(dataRequest, loadingRequest: loadingRequest)
            } else {
                loadingRequest.finishLoading()
            }
        }
        
        return true
    }
    
    func resourceLoader(_ resourceLoader: AVAssetResourceLoader, 
                       didCancel loadingRequest: AVAssetResourceLoadingRequest) {
        print("⚠️ Resource loading request cancelled")
    }
    
    // MARK: - Private Methods
    
    private func handleContentInfoRequest(_ request: AVAssetResourceLoadingContentInformationRequest) {
        do {
            // 获取文件属性
            let attributes = try FileManager.default.attributesOfItem(atPath: fileURL.path)
            
            if let fileSize = attributes[.size] as? NSNumber {
                request.contentLength = fileSize.int64Value
                request.isByteRangeAccessSupported = true
                
                // 根据文件扩展名设置 MIME 类型
                let ext = fileURL.pathExtension.lowercased()
                request.contentType = mimeType(for: ext)
                
                print("📊 Content info: size=\(fileSize), type=\(request.contentType ?? "unknown")")
            }
        } catch {
            print("❌ Failed to get file attributes: \(error)")
        }
    }
    
    private func handleDataRequest(_ dataRequest: AVAssetResourceLoadingDataRequest, 
                                   loadingRequest: AVAssetResourceLoadingRequest) {
        do {
            // 打开文件句柄（如果还没打开）
            if fileHandle == nil {
                fileHandle = try FileHandle(forReadingFrom: fileURL)
            }
            
            guard let handle = fileHandle else {
                loadingRequest.finishLoading(with: NSError(domain: "StreamingResourceLoader", code: -2))
                return
            }
            
            // 计算读取范围
            let offset = dataRequest.requestedOffset
            let length = dataRequest.requestedLength
            
            print("📥 Data request: offset=\(offset), length=\(length)")
            
            // Seek 到请求的位置
            if #available(iOS 13.0, *) {
                try handle.seek(toOffset: UInt64(offset))
            } else {
                handle.seek(toFileOffset: UInt64(offset))
            }
            
            // 读取数据
            let data: Data
            if #available(iOS 13.4, *) {
                data = try handle.read(upToCount: length) ?? Data()
            } else {
                data = handle.readData(ofLength: length)
            }
            
            // 响应数据请求
            dataRequest.respond(with: data)
            loadingRequest.finishLoading()
            
            print("✅ Responded with \(data.count) bytes")
            
        } catch {
            print("❌ Failed to read file: \(error)")
            loadingRequest.finishLoading(with: error as NSError)
        }
    }
    
    private func mimeType(for ext: String) -> String {
        switch ext {
        case "mp4", "m4v":
            return "video/mp4"
        case "mov":
            return "video/quicktime"
        case "mkv":
            return "video/x-matroska"
        case "avi":
            return "video/x-msvideo"
        case "webm":
            return "video/webm"
        case "flv":
            return "video/x-flv"
        case "wmv":
            return "video/x-ms-wmv"
        case "3gp":
            return "video/3gpp"
        case "ts":
            return "video/mp2t"
        default:
            return "video/mp4"
        }
    }
}
