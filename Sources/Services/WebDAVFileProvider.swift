import Foundation

/// WebDAV 文件提供器，用于浏览和访问 WebDAV 服务器上的文件
class WebDAVFileProvider {
    
    let baseURL: URL
    let credential: URLCredential?
    
    struct FileItem {
        let name: String
        let path: String
        let isDirectory: Bool
        let size: Int64?
        let modificationDate: Date?
    }
    
    init(baseURL: URL, username: String? = nil, password: String? = nil) {
        self.baseURL = baseURL
        
        if let username = username, let password = password {
            self.credential = URLCredential(user: username, password: password, persistence: .forSession)
        } else {
            self.credential = nil
        }
    }
    
    /// 列出指定路径下的文件和文件夹
    func listFiles(at path: String, completion: @escaping (Result<[FileItem], Error>) -> Void) {
        let url = baseURL.appendingPathComponent(path)
        
        var request = URLRequest(url: url)
        request.httpMethod = "PROPFIND"
        request.setValue("1", forHTTPHeaderField: "Depth")
        request.setValue("application/xml", forHTTPHeaderField: "Content-Type")
        
        // WebDAV PROPFIND 请求体
        let propfindBody = """
        <?xml version="1.0" encoding="utf-8" ?>
        <D:propfind xmlns:D="DAV:">
            <D:prop>
                <D:displayname/>
                <D:getcontentlength/>
                <D:getlastmodified/>
                <D:resourcetype/>
            </D:prop>
        </D:propfind>
        """
        request.httpBody = propfindBody.data(using: .utf8)
        
        // 添加认证
        if let credential = credential {
            let credentialData = "\(credential.user!):\(credential.password!)".data(using: .utf8)!
            let base64Credentials = credentialData.base64EncodedString()
            request.setValue("Basic \(base64Credentials)", forHTTPHeaderField: "Authorization")
        }
        
        Logger.shared.info("📡 PROPFIND request to: \(url.absoluteString)")
        
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                Logger.shared.error("❌ PROPFIND failed: \(error.localizedDescription)")
                completion(.failure(error))
                return
            }
            
            guard let data = data,
                  let httpResponse = response as? HTTPURLResponse else {
                completion(.failure(NSError(domain: "WebDAV", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid response"])))
                return
            }
            
            Logger.shared.info("📡 PROPFIND response: \(httpResponse.statusCode)")
            
            if httpResponse.statusCode == 207 { // Multi-Status
                do {
                    let files = try self.parseMultiStatus(data: data, basePath: path)
                    Logger.shared.info("✅ Found \(files.count) items")
                    completion(.success(files))
                } catch {
                    Logger.shared.error("❌ Parse failed: \(error.localizedDescription)")
                    completion(.failure(error))
                }
            } else {
                let errorMsg = "HTTP \(httpResponse.statusCode)"
                completion(.failure(NSError(domain: "WebDAV", code: httpResponse.statusCode, userInfo: [NSLocalizedDescriptionKey: errorMsg])))
            }
        }
        
        task.resume()
    }
    
    /// 解析 WebDAV Multi-Status 响应
    private func parseMultiStatus(data: Data, basePath: String) throws -> [FileItem] {
        var files: [FileItem] = []
        
        let parser = XMLParser(data: data)
        let delegate = PropfindXMLDelegate()
        parser.delegate = delegate
        
        if parser.parse() {
            // 过滤掉当前目录本身
            let currentPath = basePath.hasSuffix("/") ? basePath : basePath + "/"
            
            for response in delegate.responses {
                // 解码 URL 路径
                guard let decodedHref = response.href.removingPercentEncoding else { continue }
                
                // 跳过当前目录
                if decodedHref == currentPath || decodedHref == basePath {
                    continue
                }
                
                // 提取文件名
                let name = decodedHref.split(separator: "/").last.map(String.init) ?? ""
                if name.isEmpty { continue }
                
                let file = FileItem(
                    name: name,
                    path: decodedHref,
                    isDirectory: response.isCollection,
                    size: response.contentLength,
                    modificationDate: response.lastModified
                )
                
                files.append(file)
            }
        }
        
        return files.sorted { file1, file2 in
            // 文件夹排在前面
            if file1.isDirectory != file2.isDirectory {
                return file1.isDirectory
            }
            return file1.name.localizedCaseInsensitiveCompare(file2.name) == .orderedAscending
        }
    }
}

/// WebDAV PROPFIND XML 解析器
class PropfindXMLDelegate: NSObject, XMLParserDelegate {
    
    struct Response {
        var href: String = ""
        var isCollection: Bool = false
        var contentLength: Int64?
        var lastModified: Date?
    }
    
    var responses: [Response] = []
    private var currentResponse: Response?
    private var currentElement: String = ""
    private var currentValue: String = ""
    
    func parser(_ parser: XMLParser, didStartElement elementName: String, namespaceURI: String?, qualifiedName qName: String?, attributes attributeDict: [String : String] = [:]) {
        currentElement = elementName.lowercased()
        currentValue = ""
        
        // 忽略命名空间前缀（例如 D:response -> response）
        if let colonIndex = currentElement.firstIndex(of: ":") {
            currentElement = String(currentElement[currentElement.index(after: colonIndex)...])
        }
        
        if currentElement == "response" {
            currentResponse = Response()
        }
    }
    
    func parser(_ parser: XMLParser, foundCharacters string: String) {
        currentValue += string.trimmingCharacters(in: .whitespacesAndNewlines)
    }
    
    func parser(_ parser: XMLParser, didEndElement elementName: String, namespaceURI: String?, qualifiedName qName: String?) {
        guard var response = currentResponse else { return }
        
        var cleanName = elementName.lowercased()
        if let colonIndex = cleanName.firstIndex(of: ":") {
            cleanName = String(cleanName[cleanName.index(after: colonIndex)...])
        }
        
        switch cleanName {
        case "href":
            response.href = currentValue
        case "collection":
            response.isCollection = true
        case "getcontentlength":
            response.contentLength = Int64(currentValue)
        case "getlastmodified":
            // 解析日期 (RFC 1123 格式)
            let formatter = DateFormatter()
            formatter.dateFormat = "EEE, dd MMM yyyy HH:mm:ss zzz"
            formatter.locale = Locale(identifier: "en_US_POSIX")
            response.lastModified = formatter.date(from: currentValue)
        case "response":
            responses.append(response)
            currentResponse = nil
            return
        default:
            break
        }
        
        currentResponse = response
    }
}
