import SwiftUI

struct WebDAVBrowserView: View {
    @Binding var selectedURL: URL?
    @Environment(\.presentationMode) var presentationMode
    
    @State private var currentView: ViewType = .list
    @State private var savedConnections: [SavedConnection] = []
    
    // 文件浏览状态
    @State private var browsingConnection: SavedConnection?
    @State private var currentPath: String = "/"
    @State private var files: [FileItem] = []
    @State private var isLoadingFiles: Bool = false
    @State private var browseError: String?
    
    // 编辑/新建连接的字段
    @State private var editingConnection: SavedConnection?
    @State private var name: String = ""
    @State private var host: String = ""
    @State private var port: String = "80"
    @State private var username: String = ""
    @State private var password: String = ""
    @State private var path: String = "/"
    
    enum ViewType {
        case list
        case edit
        case browse
    }
    
    struct FileItem: Identifiable {
        let id = UUID()
        let name: String
        let path: String
        let isDirectory: Bool
        let size: Int64?
    }
    
    struct SavedConnection: Identifiable, Codable {
        let id: UUID
        var name: String
        var host: String
        var port: Int
        var username: String
        var password: String
        var path: String
        
        init(id: UUID = UUID(), name: String, host: String, port: Int, username: String, password: String, path: String) {
            self.id = id
            self.name = name
            self.host = host
            self.port = port
            self.username = username
            self.password = password
            self.path = path
        }
    }
    
    var body: some View {
        NavigationView {
            Group {
                if currentView == .list {
                    listView
                } else if currentView == .edit {
                    editView
                } else {
                    browseView
                }
            }
            .navigationTitle(navigationTitle)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(leadingButtonTitle) {
                        handleLeadingButton()
                    }
                }
                
                if currentView == .list {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button(action: {
                            editingConnection = nil
                            clearEditFields()
                            currentView = .edit
                        }) {
                            Image(systemName: "plus")
                        }
                    }
                }
            }
        }
        .onAppear {
            loadConnections()
        }
    }
    
    private var navigationTitle: String {
        switch currentView {
        case .list:
            return "WebDAV"
        case .edit:
            return editingConnection == nil ? "新建连接" : "编辑连接"
        case .browse:
            return browsingConnection?.name ?? "浏览文件"
        }
    }
    
    private var leadingButtonTitle: String {
        switch currentView {
        case .list:
            return "关闭"
        case .edit:
            return "取消"
        case .browse:
            return "断开"
        }
    }
    
    private func handleLeadingButton() {
        switch currentView {
        case .list:
            presentationMode.wrappedValue.dismiss()
        case .edit:
            currentView = .list
            clearEditFields()
        case .browse:
            currentView = .list
            browsingConnection = nil
            files = []
            currentPath = "/"
        }
    }
    
    private var listView: some View {
        Group {
            if savedConnections.isEmpty {
                VStack(spacing: 20) {
                    Image(systemName: "network.slash")
                        .font(.system(size: 60))
                        .foregroundColor(.gray)
                    
                    Text("暂无保存的连接")
                        .font(.headline)
                        .foregroundColor(.gray)
                    
                    Text("点击右上角 + 添加新连接")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                List {
                    ForEach(savedConnections) { connection in
                        Button(action: {
                            browseConnection(connection)
                        }) {
                            HStack {
                                Image(systemName: "globe")
                                    .foregroundColor(.blue)
                                    .font(.title2)
                                
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(connection.name)
                                        .font(.headline)
                                        .foregroundColor(.primary)
                                    
                                    Text("WebDAV • \(connection.host):\(connection.port)")
                                        .font(.caption)
                                        .foregroundColor(.gray)
                                    
                                    if !connection.path.isEmpty && connection.path != "/" {
                                        Text(connection.path)
                                            .font(.caption2)
                                            .foregroundColor(.gray)
                                    }
                                }
                                
                                Spacer()
                                
                                Image(systemName: "chevron.right")
                                    .foregroundColor(.gray)
                                    .font(.caption)
                            }
                            .padding(.vertical, 8)
                        }
                        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                            Button(role: .destructive) {
                                deleteConnection(connection)
                            } label: {
                                Label("删除", systemImage: "trash")
                            }
                            
                            Button {
                                editConnection(connection)
                            } label: {
                                Label("编辑", systemImage: "pencil")
                            }
                            .tint(.blue)
                        }
                    }
                }
            }
        }
    }
    
    private var editView: some View {
        Form {
            Section(header: Text("连接名称")) {
                TextField("例如: 家庭NAS", text: $name)
            }
            
            Section(header: Text("服务器信息")) {
                TextField("主机地址", text: $host)
                    .autocapitalization(.none)
                    .disableAutocorrection(true)
                
                TextField("端口", text: $port)
                    .keyboardType(.numberPad)
                
                TextField("文件路径（可选）", text: $path)
                    .autocapitalization(.none)
                    .disableAutocorrection(true)
            }
            
            Section(header: Text("认证信息（可选）")) {
                TextField("用户名", text: $username)
                    .autocapitalization(.none)
                    .disableAutocorrection(true)
                
                SecureField("密码", text: $password)
            }
            
            Section {
                Button(action: saveConnection) {
                    HStack {
                        Spacer()
                        Text(editingConnection == nil ? "保存连接" : "更新连接")
                            .fontWeight(.semibold)
                        Spacer()
                    }
                }
                .disabled(name.isEmpty || host.isEmpty)
            }
        }
    }
    
    private func loadConnections() {
        if let data = UserDefaults.standard.data(forKey: "saved_webdav_connections") {
            do {
                let connections = try JSONDecoder().decode([SavedConnection].self, from: data)
                savedConnections = connections
                Logger.shared.info("📂 Loaded \(connections.count) saved connections")
            } catch {
                Logger.shared.warning("⚠️ Failed to decode connections, clearing old data: \(error.localizedDescription)")
                UserDefaults.standard.removeObject(forKey: "saved_webdav_connections")
                savedConnections = []
            }
        }
    }
    
    private func saveConnections() {
        if let data = try? JSONEncoder().encode(savedConnections) {
            UserDefaults.standard.set(data, forKey: "saved_webdav_connections")
            Logger.shared.info("💾 Saved \(savedConnections.count) connections")
        }
    }
    
    private func saveConnection() {
        let portNum = Int(port) ?? 80
        
        if let editing = editingConnection {
            if let index = savedConnections.firstIndex(where: { $0.id == editing.id }) {
                savedConnections[index] = SavedConnection(
                    id: editing.id,
                    name: name,
                    host: host,
                    port: portNum,
                    username: username,
                    password: password,
                    path: path
                )
            }
        } else {
            let connection = SavedConnection(
                name: name,
                host: host,
                port: portNum,
                username: username,
                password: password,
                path: path
            )
            savedConnections.append(connection)
        }
        
        saveConnections()
        currentView = .list
        clearEditFields()
    }
    
    private func editConnection(_ connection: SavedConnection) {
        editingConnection = connection
        name = connection.name
        host = connection.host
        port = String(connection.port)
        username = connection.username
        password = connection.password
        path = connection.path
        currentView = .edit
    }
    
    private func deleteConnection(_ connection: SavedConnection) {
        savedConnections.removeAll { $0.id == connection.id }
        saveConnections()
    }
    
    private func clearEditFields() {
        editingConnection = nil
        name = ""
        host = ""
        port = "80"
        username = ""
        password = ""
        path = "/"
    }
    
    // MARK: - File Browsing
    
    private var browseView: some View {
        VStack(spacing: 0) {
            // 当前路径
            HStack {
                Image(systemName: "folder")
                    .foregroundColor(.blue)
                Text(currentPath)
                    .font(.caption)
                    .foregroundColor(.gray)
                Spacer()
            }
            .padding(.horizontal)
            .padding(.vertical, 8)
            .background(Color(UIColor.systemGroupedBackground))
            
            if isLoadingFiles {
                Spacer()
                ProgressView("加载中...")
                Spacer()
            } else if let error = browseError {
                Spacer()
                VStack(spacing: 16) {
                    Image(systemName: "exclamationmark.triangle")
                        .font(.system(size: 60))
                        .foregroundColor(.red)
                    Text(error)
                        .foregroundColor(.red)
                        .multilineTextAlignment(.center)
                        .padding()
                }
                Spacer()
            } else if files.isEmpty {
                Spacer()
                VStack(spacing: 16) {
                    Image(systemName: "folder.badge.questionmark")
                        .font(.system(size: 60))
                        .foregroundColor(.gray)
                    Text("文件夹为空")
                        .foregroundColor(.gray)
                }
                Spacer()
            } else {
                List {
                    // 返回上级
                    if currentPath != "/" {
                        Button(action: goBack) {
                            HStack {
                                Image(systemName: "arrow.turn.up.left")
                                    .foregroundColor(.blue)
                                Text("..")
                                    .foregroundColor(.blue)
                                Spacer()
                            }
                        }
                    }
                    
                    // 文件列表
                    ForEach(files) { file in
                        Button(action: {
                            selectFile(file)
                        }) {
                            HStack {
                                Image(systemName: file.isDirectory ? "folder.fill" : "film.fill")
                                    .foregroundColor(file.isDirectory ? .blue : .orange)
                                
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(file.name)
                                        .foregroundColor(.primary)
                                    
                                    if let size = file.size, !file.isDirectory {
                                        Text(formatFileSize(size))
                                            .font(.caption)
                                            .foregroundColor(.gray)
                                    }
                                }
                                
                                Spacer()
                                
                                if file.isDirectory {
                                    Image(systemName: "chevron.right")
                                        .font(.caption)
                                        .foregroundColor(.gray)
                                }
                            }
                        }
                    }
                }
                .listStyle(PlainListStyle())
            }
        }
    }
    
    private func browseConnection(_ connection: SavedConnection) {
        browsingConnection = connection
        currentPath = connection.path.isEmpty ? "/" : connection.path
        currentView = .browse
        loadFiles(at: currentPath)
    }
    
    private func loadFiles(at path: String) {
        guard let connection = browsingConnection else { return }
        
        isLoadingFiles = true
        browseError = nil
        currentPath = path
        
        // 构建 WebDAV URL
        let baseURL = URL(string: "http://\(connection.host):\(connection.port)")!
        let provider = WebDAVFileProvider(
            baseURL: baseURL,
            username: connection.username.isEmpty ? nil : connection.username,
            password: connection.password.isEmpty ? nil : connection.password
        )
        
        provider.listFiles(at: path) { result in
            DispatchQueue.main.async {
                self.isLoadingFiles = false
                
                switch result {
                case .success(let items):
                    self.files = items.map { item in
                        FileItem(
                            name: item.name,
                            path: item.path,
                            isDirectory: item.isDirectory,
                            size: item.size
                        )
                    }
                case .failure(let error):
                    self.browseError = error.localizedDescription
                    Logger.shared.error("❌ Failed to load files: \(error.localizedDescription)")
                }
            }
        }
    }
    
    private func goBack() {
        // 简单的路径处理，实际 WebDAV 可能需要更复杂的逻辑
        if currentPath == "/" { return }
        
        let components = currentPath.split(separator: "/")
        if components.isEmpty {
            loadFiles(at: "/")
        } else {
            let newPath = "/" + components.dropLast().joined(separator: "/") + "/"
            // 确保路径以 / 结尾（如果是根目录则不需要两个 /）
            let finalPath = newPath == "//" ? "/" : newPath
            loadFiles(at: finalPath)
        }
    }
    
    private func selectFile(_ file: FileItem) {
        if file.isDirectory {
            // 进入目录
            var newPath = file.path
            if !newPath.hasSuffix("/") {
                newPath += "/"
            }
            loadFiles(at: newPath)
        } else {
            // 选择文件并播放
            guard let connection = browsingConnection else { return }
            
            let scheme = "http" // WebDAV 通常使用 HTTP/HTTPS
            let encodedPath = file.path.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? file.path
            
            // 构建干净的 URL（不包含认证信息）
            let urlString = "\(scheme)://\(connection.host):\(connection.port)\(encodedPath)"
            
            guard let url = URL(string: urlString) else {
                Logger.shared.error("❌ Failed to construct URL")
                return
            }
            
            // 如果有认证信息，存储到 URLCredentialStorage
            if !connection.username.isEmpty {
                let credential = URLCredential(
                    user: connection.username,
                    password: connection.password,
                    persistence: .forSession
                )
                
                // 尝试多种 protection space 配置以确保兼容性
                let protectionSpaces = [
                    // 标准配置：指定 realm 为 nil
                    URLProtectionSpace(
                        host: connection.host,
                        port: connection.port,
                        protocol: scheme,
                        realm: nil,
                        authenticationMethod: NSURLAuthenticationMethodHTTPBasic
                    ),
                    // 备用配置：不指定 realm（某些服务器需要）
                    URLProtectionSpace(
                        host: connection.host,
                        port: connection.port,
                        protocol: scheme,
                        realm: "",
                        authenticationMethod: NSURLAuthenticationMethodHTTPBasic
                    )
                ]
                
                for protectionSpace in protectionSpaces {
                    URLCredentialStorage.shared.setDefaultCredential(credential, for: protectionSpace)
                }
                
                // 同时设置为所有凭据（不仅是默认）
                if let protectionSpace = protectionSpaces.first {
                    URLCredentialStorage.shared.set(credential, for: protectionSpace)
                }
                
                Logger.shared.info("🔐 Credential stored for \(connection.host):\(connection.port) (user: \(connection.username))")
            }
            
            Logger.shared.info("✅ Selected: \(file.name) from \(connection.host)")
            selectedURL = url
            presentationMode.wrappedValue.dismiss()
        }
    }
    
    private func formatFileSize(_ bytes: Int64) -> String {
        let formatter = ByteCountFormatter()
        formatter.countStyle = .file
        return formatter.string(fromByteCount: bytes)
    }
}
