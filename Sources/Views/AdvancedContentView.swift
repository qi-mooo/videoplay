import SwiftUI
import AVFoundation

struct AdvancedContentView: View {
    @State private var selectedVideoURL: URL?
    @ObservedObject private var settings = PlayerSettings.shared
    @StateObject private var beautySettings = BeautySettings()
    @State private var showDocumentPicker = false
    @State private var isControlsHidden = false
    @State private var isSeeking = false
    @State private var seekTime: Double = 0
    @State private var isPlaying = true
    @State private var errorMessage: String?
    @State private var showLogViewer = false
    @State private var showWebDAVBrowser = false
    @State private var showSettings = false
    
    // 监听设备方向
    @State private var orientation: UIDeviceOrientation = UIDevice.current.orientation
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                Color.black.ignoresSafeArea()
                
                if let videoURL = selectedVideoURL {
                    // 1. 视频播放器层 (底层)
                    AdvancedVideoPlayerView(
                        videoURL: videoURL,
                        beautySettings: beautySettings,
                        isControlsHidden: $isControlsHidden,
                        isPlaying: $isPlaying,
                        errorMessage: $errorMessage
                    )
                    .id(videoURL) // 强制在 URL 变化时重建播放器视图
                    .ignoresSafeArea()
                    .onTapGesture(count: 2) {
                        // 双击播放/暂停
                        isPlaying.toggle()
                    }
                    .onTapGesture(count: 1) {
                        // 单击显示/隐藏控制栏
                        withAnimation {
                            isControlsHidden.toggle()
                        }
                    }
                    
                    // 错误提示层
                    if let error = errorMessage {
                        VStack {
                            Spacer()
                            HStack {
                                Spacer()
                                VStack(spacing: 12) {
                                    Image(systemName: "exclamationmark.triangle.fill")
                                        .font(.system(size: 40))
                                        .foregroundColor(.red)
                                    Text("播放错误")
                                        .font(.headline)
                                        .foregroundColor(.white)
                                    Text(error)
                                        .font(.caption)
                                        .foregroundColor(.white.opacity(0.8))
                                        .multilineTextAlignment(.center)
                                        .padding(.horizontal)
                                    Button(action: {
                                        errorMessage = nil
                                    }) {
                                        Text("关闭")
                                            .foregroundColor(.white)
                                            .padding(.horizontal, 20)
                                            .padding(.vertical, 8)
                                            .background(Color.red.opacity(0.8))
                                            .cornerRadius(8)
                                    }
                                }
                                .padding(24)
                                .background(
                                    RoundedRectangle(cornerRadius: 16)
                                        .fill(Color.black.opacity(0.85))
                                )
                                Spacer()
                            }
                            Spacer()
                        }
                        .transition(.opacity)
                    }
                    
                    // 2. 控制层 (悬浮层)
                    if !isControlsHidden {
                        // 顶部栏
                        VStack {
                            HStack {
                                Button(action: {
                                    selectedVideoURL = nil
                                    rotate(to: .portrait)
                                }) {
                                    Image(systemName: "xmark.circle.fill")
                                        .font(.system(size: 30))
                                        .foregroundColor(.white)
                                        .shadow(radius: 2)
                                }
                                .padding()
                                
                                Spacer()
                                
                                Button(action: {
                                    toggleRotation()
                                }) {
                                    Image(systemName: "arrow.triangle.2.circlepath.circle.fill")
                                        .font(.system(size: 30))
                                        .foregroundColor(.white)
                                        .shadow(radius: 2)
                                }
                                .padding()
                            }
                            .background(
                                LinearGradient(colors: [.black.opacity(0.6), .clear], startPoint: .top, endPoint: .bottom)
                            )
                            
                            Spacer()
                        }
                        
                        // 底部/侧边功能区
                        // 使用 GeometryReader 判断布局
                        VStack {
                            Spacer()
                            HStack(alignment: .bottom) {
                                Spacer()
                                
                                // 美颜面板
                                BeautyControlPanel(settings: beautySettings, isLandscape: geometry.size.width > geometry.size.height)
                                    .frame(width: 280)
                            }
                            // 横屏时水平间距设为 0，紧贴 Safe Area；竖屏保持 20
                            .padding(.horizontal, geometry.size.width > geometry.size.height ? 0 : 20)
                            // 底部避开进度条 (进度条占据底部约 60pt 区域)，横屏设为 75 确保不重叠
                            .padding(.bottom, geometry.size.width > geometry.size.height ? 75 : 80) 
                        }
                    }
                    
                    // 3. 寻找指示器
                    if isSeeking {
                        Text(formatTime(seekTime))
                            .font(.system(size: 40, weight: .bold))
                            .foregroundColor(.white)
                            .padding(20)
                            .background(Color.black.opacity(0.5))
                            .cornerRadius(10)
                    }
                    
                    // 4. 暂停指示图标 (双击暂停时显示一下)
                    if !isPlaying {
                        Image(systemName: "pause.circle.fill")
                            .font(.system(size: 60))
                            .foregroundColor(.white.opacity(0.8))
                            .shadow(radius: 4)
                            .transition(.scale)
                    }
                } else {
                    // 选择界面
                    VStack(spacing: 30) {
                        Image(systemName: "video.badge.plus")
                            .font(.system(size: 80))
                            .foregroundColor(.white.opacity(0.6))
                        
                        Text("选择视频开始播放")
                            .font(.title2)
                            .foregroundColor(.white)
                        
                        Button(action: {
                            showDocumentPicker = true
                        }) {
                            HStack {
                                Image(systemName: "folder.fill")
                                Text("选择本地文件")
                            }
                            .font(.headline)
                            .foregroundColor(.white)
                            .padding(.horizontal, 40)
                            .padding(.vertical, 15)
                            .background(Color.blue)
                            .cornerRadius(25)
                        }
                        
                        Button(action: {
                            showWebDAVBrowser = true
                        }) {
                            HStack {
                                Image(systemName: "globe")
                                Text("WebDAV 连接")
                            }
                            .font(.headline)
                            .foregroundColor(.white)
                            .padding(.horizontal, 40)
                            .padding(.vertical, 15)
                            .background(Color.green)
                            .cornerRadius(25)
                        }
                        
                        HStack(spacing: 15) {
                            Button(action: {
                                showSettings = true
                            }) {
                                HStack {
                                    Image(systemName: "gearshape.fill")
                                    Text("设置")
                                }
                                .font(.subheadline)
                                .foregroundColor(.white.opacity(0.8))
                                .padding(.horizontal, 20)
                                .padding(.vertical, 10)
                                .background(Color.blue.opacity(0.3))
                                .cornerRadius(15)
                            }
                            
                            Button(action: {
                                showLogViewer = true
                            }) {
                                HStack {
                                    Image(systemName: "doc.text.magnifyingglass")
                                    Text("日志")
                                }
                                .font(.subheadline)
                                .foregroundColor(.white.opacity(0.8))
                                .padding(.horizontal, 20)
                                .padding(.vertical, 10)
                                .background(Color.gray.opacity(0.3))
                                .cornerRadius(15)
                            }
                        }
                        .padding(.top, 10)
                    }
                }
            }
        }
        .sheet(isPresented: $showDocumentPicker) {
            DocumentPicker(selectedURL: $selectedVideoURL)
        }
        .sheet(isPresented: $showWebDAVBrowser) {
            WebDAVBrowserView(selectedURL: $selectedVideoURL)
        }
        .sheet(isPresented: $showLogViewer) {
            LogViewerView()
        }
        .sheet(isPresented: $showSettings) {
            SettingsView()
        }
        .statusBar(hidden: selectedVideoURL != nil && isControlsHidden)
        .onReceive(NotificationCenter.default.publisher(for: UIDevice.orientationDidChangeNotification)) { _ in
            self.orientation = UIDevice.current.orientation
        }
        .onAppear {
            UIApplication.shared.isIdleTimerDisabled = true
        }
        .onDisappear {
            UIApplication.shared.isIdleTimerDisabled = false
        }
    }
    
    func toggleRotation() {
        // 获取当前界面方向
        let currentOrientation = UIApplication.shared.windows.first?.windowScene?.interfaceOrientation ?? .portrait
        
        if currentOrientation.isPortrait {
            rotate(to: .landscapeRight)
        } else {
            rotate(to: .portrait)
        }
    }
    
    func formatTime(_ seconds: Double) -> String {
        let mins = Int(seconds) / 60
        let secs = Int(seconds) % 60
        return String(format: "%02d:%02d", mins, secs)
    }
    
    func rotate(to orientation: UIInterfaceOrientationMask) {
        AppDelegate.orientationLock = orientation
        
        DispatchQueue.main.async {
            if #available(iOS 16.0, *) {
                if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene {
                    windowScene.requestGeometryUpdate(.iOS(interfaceOrientations: orientation)) { error in
                        print("Rotation error: \(error)")
                        // Fallback
                        UIViewController.attemptRotationToDeviceOrientation()
                    }
                }
            } else {
                UIDevice.current.setValue(orientation.toUIInterfaceOrientation.rawValue, forKey: "orientation")
                UIViewController.attemptRotationToDeviceOrientation()
            }
        }
    }
}

extension UIInterfaceOrientationMask {
    var toUIInterfaceOrientation: UIInterfaceOrientation {
        switch self {
        case .landscape: return .landscapeRight
        case .landscapeLeft: return .landscapeLeft
        case .landscapeRight: return .landscapeRight
        case .portrait: return .portrait
        case .portraitUpsideDown: return .portraitUpsideDown
        default: return .unknown
        }
    }
}

// 高级视频播放器
struct AdvancedVideoPlayerView: UIViewRepresentable {
    let videoURL: URL
    @ObservedObject var beautySettings: BeautySettings
    @Binding var isControlsHidden: Bool
    @Binding var isPlaying: Bool
    @Binding var errorMessage: String?
    
    // 销毁时清理资源
    static func dismantleUIView(_ uiView: UIView, coordinator: Coordinator) {
        coordinator.cleanup()
    }
    
    func makeUIView(context: Context) -> UIView {
        let containerView = UIView()
        containerView.backgroundColor = .black
        
        // 视频渲染视图
        let videoView = UIView()
        videoView.backgroundColor = .black
        videoView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        containerView.addSubview(videoView)
        
        // 播放控制视图 (原生 UIControl)
        let controlsView = PlayerControlsView()
        controlsView.translatesAutoresizingMaskIntoConstraints = false
        
        // 绑定播放状态回调
        controlsView.onPlayPauseTapped = {
            isPlaying.toggle()
        }
        
        controlsView.onSeek = { percentage in
            context.coordinator.seek(to: percentage)
        }
        
        containerView.addSubview(controlsView)
        
        // 手势识别视图
        let gestureView = UIView()
        gestureView.backgroundColor = .clear
        gestureView.translatesAutoresizingMaskIntoConstraints = false
        containerView.addSubview(gestureView)
        
        // 添加约束
        NSLayoutConstraint.activate([
            controlsView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
            controlsView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),
            controlsView.bottomAnchor.constraint(equalTo: containerView.safeAreaLayoutGuide.bottomAnchor, constant: -20),
            controlsView.heightAnchor.constraint(equalToConstant: 40),
            
            gestureView.topAnchor.constraint(equalTo: containerView.topAnchor),
            gestureView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
            gestureView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),
            gestureView.bottomAnchor.constraint(equalTo: controlsView.topAnchor)
        ])
        
        context.coordinator.videoView = videoView
        context.coordinator.controlsView = controlsView
        context.coordinator.gestureView = gestureView
        context.coordinator.setupPlayer(url: videoURL)
        context.coordinator.setupGestures()
        
        return containerView
    }
    
    func updateUIView(_ uiView: UIView, context: Context) {
        context.coordinator.updateBeauty(beautySettings)
        
        // 更新播放状态
        if isPlaying {
            context.coordinator.player?.play()
        } else {
            context.coordinator.player?.pause()
        }
        context.coordinator.controlsView?.updatePlayButton(isPlaying: isPlaying)
        
        // 更新控制栏可见性
        UIView.animate(withDuration: 0.3) {
            context.coordinator.controlsView?.alpha = isControlsHidden ? 0 : 1
        }
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(beautySettings, errorMessage: $errorMessage)
    }
    
    class Coordinator: NSObject {
        var videoView: UIView?
        var controlsView: PlayerControlsView?
        var gestureView: UIView?
        var player: AVPlayer?
        var settings = PlayerSettings.shared
        var videoOutput: AVPlayerItemVideoOutput?
        var displayLink: CADisplayLink?
        var gpuPixelWrapper: GPUPixelWrapper?
        var timeObserver: Any?
        var downloadTask: URLSessionDownloadTask?
        var progressObserver: NSKeyValueObservation?
        var beautySettings: BeautySettings
        var errorMessage: Binding<String?>
        var statusObserver: NSKeyValueObservation?
        
        // 安全资源管理
        var currentSecurityScopedURL: URL?
        // 流式资源加载器（用于 file:// URL 的流式播放）
        var resourceLoader: StreamingResourceLoader?
        var webDAVResourceLoader: WebDAVResourceLoader?
        var cachedFileURL: URL?
        
        // 手势状态
        var isLongPressing = false
        var startTouchPoint: CGPoint = .zero
        var startSeekTime: Double = 0
        
        init(_ settings: BeautySettings, errorMessage: Binding<String?>) {
            self.beautySettings = settings
            self.errorMessage = errorMessage
        }
        
        deinit {
            cleanup()
        }
        
        func cleanup() {
            downloadTask?.cancel()
            downloadTask = nil
            progressObserver?.invalidate()
            progressObserver = nil
            
            displayLink?.invalidate()
            displayLink = nil
            
            if let observer = timeObserver {
                player?.removeTimeObserver(observer)
                timeObserver = nil
            }
            
            statusObserver?.invalidate()
            statusObserver = nil
            
            player?.pause()
            player = nil
            
            if let url = currentSecurityScopedURL {
                url.stopAccessingSecurityScopedResource()
                currentSecurityScopedURL = nil
                Logger.shared.info("🔒 Stopped accessing security scoped resource")
            }
            
            // 清理缓存文件
            if let cacheURL = cachedFileURL {
                do {
                    try FileManager.default.removeItem(at: cacheURL)
                    Logger.shared.info("🗑️ Cleared cached file: \(cacheURL.lastPathComponent)")
                } catch {
                    Logger.shared.error("❌ Failed to clear cache: \(error.localizedDescription)")
                }
                cachedFileURL = nil
            }
            
            Logger.shared.info("🧹 Coordinator cleaned up")
        }
        
        private func downloadAndPlay(url: URL) {
            let filename = url.lastPathComponent
            let tempDir = FileManager.default.temporaryDirectory
            let destinationURL = tempDir.appendingPathComponent(filename)
            
            // 保存引用以便清理
            cachedFileURL = destinationURL
            
            if FileManager.default.fileExists(atPath: destinationURL.path) {
                Logger.shared.info("📂 Playing from cache: \(filename)")
                setupAVPlayer(url: destinationURL)
                return
            }
            
            Logger.shared.info("⬇️ Downloading to: \(destinationURL.path)")
            self.errorMessage.wrappedValue = "准备下载..."
            
            var request = URLRequest(url: url)
            if let host = url.host {
                let protectionSpace = URLProtectionSpace(
                    host: host,
                    port: url.port ?? (url.scheme == "https" ? 443 : 80),
                    protocol: url.scheme,
                    realm: nil,
                    authenticationMethod: NSURLAuthenticationMethodHTTPBasic
                )
                if let cred = URLCredentialStorage.shared.defaultCredential(for: protectionSpace),
                   let user = cred.user, let password = cred.password {
                    let authStr = "\(user):\(password)"
                    if let authData = authStr.data(using: .utf8) {
                        let authValue = "Basic \(authData.base64EncodedString())"
                        request.setValue(authValue, forHTTPHeaderField: "Authorization")
                    }
                }
            }
            
            let task = URLSession.shared.downloadTask(with: request) { [weak self] localURL, response, error in
                guard let self = self else { return }
                self.downloadTask = nil
                self.progressObserver?.invalidate()
                self.progressObserver = nil
                
                if let error = error {
                    DispatchQueue.main.async {
                        Logger.shared.error("❌ Download failed: \(error.localizedDescription)")
                        self.errorMessage.wrappedValue = "下载失败，尝试在线播放..."
                        self.setupAVPlayer(url: url)
                    }
                    return
                }
                
                guard let localURL = localURL else { return }
                
                do {
                    if FileManager.default.fileExists(atPath: destinationURL.path) {
                        try FileManager.default.removeItem(at: destinationURL)
                    }
                    try FileManager.default.moveItem(at: localURL, to: destinationURL)
                    DispatchQueue.main.async {
                        Logger.shared.info("✅ Download complete")
                        self.errorMessage.wrappedValue = nil
                        self.setupAVPlayer(url: destinationURL)
                    }
                } catch {
                    DispatchQueue.main.async {
                        Logger.shared.error("❌ Move file failed: \(error.localizedDescription)")
                        self.setupAVPlayer(url: url)
                    }
                }
            }
            
            progressObserver = task.progress.observe(\.fractionCompleted) { [weak self] progress, _ in
                DispatchQueue.main.async {
                    let percent = Int(progress.fractionCompleted * 100)
                    self?.errorMessage.wrappedValue = "正在下载: \(percent)%"
                }
            }
            
            self.downloadTask = task
            task.resume()
        }
        
        private func getAuthenticatedURL(for url: URL) -> URL {
            guard !url.isFileURL, let host = url.host else { return url }
            
            let protectionSpace = URLProtectionSpace(
                host: host,
                port: url.port ?? (url.scheme == "https" ? 443 : 80),
                protocol: url.scheme,
                realm: nil,
                authenticationMethod: NSURLAuthenticationMethodHTTPBasic
            )
            
            return url
        }
        
        func setupPlayer(url: URL) {
            guard let videoView = videoView else { return }
            
            Logger.shared.info("🎬 setupPlayer: \(url.lastPathComponent)")
            
            if let oldUrl = currentSecurityScopedURL {
                oldUrl.stopAccessingSecurityScopedResource()
                currentSecurityScopedURL = nil
            }
            
            if url.isFileURL {
                if url.startAccessingSecurityScopedResource() {
                    currentSecurityScopedURL = url
                    Logger.shared.info("✅ Security scoped resource accessed")
                }
            }
            
            gpuPixelWrapper = nil
            statusObserver?.invalidate()
            statusObserver = nil
            
            setupAVPlayer(url: url)
        }
        
        private func setupAVPlayer(url: URL) {
            guard let videoView = videoView else { return }
            
            gpuPixelWrapper = GPUPixelWrapper(view: videoView)
            
            Logger.shared.info("📹 Creating AVPlayer for: \(url.isFileURL ? "file://" : url.scheme ?? "unknown")")
            
            var assetURL = url
            webDAVResourceLoader = nil
            
            // 如果是 WebDAV URL，配置 ResourceLoader
            if !url.isFileURL, let host = url.host, let scheme = url.scheme {
                Logger.shared.info("   URL: \(host):\(url.port ?? 0)\(url.path)")
                
                let protectionSpace = URLProtectionSpace(
                    host: host,
                    port: url.port ?? (scheme == "https" ? 443 : 80),
                    protocol: scheme,
                    realm: nil,
                    authenticationMethod: NSURLAuthenticationMethodHTTPBasic
                )
                
                if let cred = URLCredentialStorage.shared.defaultCredential(for: protectionSpace),
                   let user = cred.user, let password = cred.password {
                    
                    // 构造 streaming URL
                    var components = URLComponents(url: url, resolvingAgainstBaseURL: false)
                    components?.scheme = "streaming-\(scheme)"
                    if let streamingURL = components?.url {
                        assetURL = streamingURL
                        webDAVResourceLoader = WebDAVResourceLoader(username: user, password: password)
                        Logger.shared.info("🌐 Using WebDAVResourceLoader for streaming")
                    }
                }
            }
            
            let asset = AVURLAsset(url: assetURL)
            if let loader = webDAVResourceLoader {
                asset.resourceLoader.setDelegate(loader, queue: DispatchQueue(label: "com.videoplay.loader"))
            }
            
            let tracks = asset.tracks(withMediaType: .video)
            if let track = tracks.first {
                let size = track.naturalSize
                let transform = track.preferredTransform
                let sizeWithTransform = size.applying(transform)
                let width = abs(sizeWithTransform.width)
                let height = abs(sizeWithTransform.height)
                
                DispatchQueue.main.async {
                    if width > height {
                        self.rotate(to: .landscapeRight)
                    } else {
                        self.rotate(to: .portrait)
                    }
                }
            }
            
            let playerItem = AVPlayerItem(asset: asset)
            
            // 初始化 VideoOutput (修复黑屏问题)
            let settings: [String: Any] = [
                kCVPixelBufferPixelFormatTypeKey as String: Int(kCVPixelFormatType_32BGRA)
            ]
            videoOutput = AVPlayerItemVideoOutput(pixelBufferAttributes: settings)
            playerItem.add(videoOutput!)
            
            statusObserver = playerItem.observe(\.status, options: [.new]) { [weak self] item, _ in
                DispatchQueue.main.async {
                    guard let self = self else { return }
                    switch item.status {
                    case .failed:
                        if let error = item.error {
                            let errorDesc = error.localizedDescription
                            let nsError = error as NSError
                            Logger.shared.error("❌ Player failed: \(errorDesc)")
                            Logger.shared.error("   Domain: \(nsError.domain), Code: \(nsError.code)")
                            
                            self.errorMessage.wrappedValue = errorDesc
                        }
                    case .readyToPlay:
                        Logger.shared.info("✅ Player ready to play")
                        self.errorMessage.wrappedValue = nil
                    default:
                        break
                    }
                }
            }
            
            player = AVPlayer(playerItem: playerItem)
            // GPUPixelWrapper 不需要 setPlayer，它通过 displayLink 接收数据
            
            let interval = CMTime(seconds: 0.5, preferredTimescale: CMTimeScale(NSEC_PER_SEC))
            timeObserver = player?.addPeriodicTimeObserver(forInterval: interval, queue: .main) { [weak self] time in
                guard let self = self, let player = self.player else { return }
                let currentTime = CMTimeGetSeconds(time)
                let duration = CMTimeGetSeconds(player.currentItem?.duration ?? .zero)
                if !self.isLongPressing { 
                    self.controlsView?.updateProgress(current: currentTime, duration: duration)
                }
            }
            
            NotificationCenter.default.addObserver(
                forName: .AVPlayerItemDidPlayToEndTime,
                object: playerItem,
                queue: .main
            ) { [weak self] _ in
                self?.player?.seek(to: .zero)
                self?.player?.play()
            }
            
            player?.play()
            setupDisplayLink()
            updateBeauty(beautySettings)
        }
        
        func rotate(to orientation: UIInterfaceOrientationMask) {
            AppDelegate.orientationLock = orientation
            if #available(iOS 16.0, *) {
                if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene {
                    windowScene.requestGeometryUpdate(.iOS(interfaceOrientations: orientation))
                }
            } else {
                UIDevice.current.setValue(orientation.toUIInterfaceOrientation.rawValue, forKey: "orientation")
                UIViewController.attemptRotationToDeviceOrientation()
            }
        }

        func setupDisplayLink() {
            displayLink = CADisplayLink(target: self, selector: #selector(displayLinkCallback))
            displayLink?.add(to: .main, forMode: .common)
        }
        
        @objc func displayLinkCallback() {
            guard let output = videoOutput, let item = player?.currentItem else { return }
            let currentTime = item.currentTime()
            
            if output.hasNewPixelBuffer(forItemTime: currentTime) {
                var presentationItemTime: CMTime = .zero
                if let buffer = output.copyPixelBuffer(forItemTime: currentTime, itemTimeForDisplay: &presentationItemTime) {
                    gpuPixelWrapper?.processPixelBuffer(buffer)
                }
            }
        }
        
        func setupGestures() {
            guard let view = gestureView else { return }
            
            // 长按手势 (加速)
            let longPress = UILongPressGestureRecognizer(target: self, action: #selector(handleLongPress(_:)))
            longPress.minimumPressDuration = 0.5
            view.addGestureRecognizer(longPress)
            
            // 拖拽手势 (快进/快退)
            let pan = UIPanGestureRecognizer(target: self, action: #selector(handlePan(_:)))
            view.addGestureRecognizer(pan)
            
            // 单击手势 (在 SwiftUI 层处理了，这里主要是为了不阻断)
        }
        
        @objc func handleLongPress(_ gesture: UILongPressGestureRecognizer) {
            switch gesture.state {
            case .began:
                isLongPressing = true
                player?.rate = 2.0
                UIImpactFeedbackGenerator(style: .medium).impactOccurred()
            case .ended, .cancelled, .failed:
                isLongPressing = false
                player?.rate = 1.0
            default:
                break
            }
        }
        
        @objc func handlePan(_ gesture: UIPanGestureRecognizer) {
            guard let player = player, let item = player.currentItem else { return }
            let translation = gesture.translation(in: gestureView)
            
            switch gesture.state {
            case .began:
                startSeekTime = CMTimeGetSeconds(player.currentTime())
                player.pause()
            case .changed:
                // 简单的算法：每 10 像素对应 1 秒
                let deltaSeconds = Double(translation.x) / 10.0
                let targetTime = startSeekTime + deltaSeconds
                let duration = CMTimeGetSeconds(item.duration)
                let clampedTime = max(0, min(targetTime, duration))
                
                let time = CMTime(seconds: clampedTime, preferredTimescale: 600)
                player.seek(to: time, toleranceBefore: .zero, toleranceAfter: .zero)
                controlsView?.updateProgress(current: clampedTime, duration: duration)
                
            case .ended, .cancelled:
                player.play()
            default:
                break
            }
        }
        
        func updateBeauty(_ settings: BeautySettings) {
            guard let wrapper = gpuPixelWrapper else { return }
            
            if settings.enabled {
                wrapper.setBeautyParameters(
                    settings.smoothingFloat,
                    whitening: settings.whiteningFloat,
                    sharpening: settings.sharpeningFloat,
                    faceSlim: settings.faceSlimFloat,
                    eyeEnlarge: settings.eyeEnlargeFloat
                )
            } else {
                wrapper.setBeautyEnabled(false)
            }
        }
        
        func seek(to percentage: Double) {
            if let player = player, let duration = player.currentItem?.duration {
                let seconds = percentage * CMTimeGetSeconds(duration)
                player.seek(to: CMTime(seconds: seconds, preferredTimescale: 600))
            }
        }
    }
}

// 播放器控制视图
class PlayerControlsView: UIView {
    // 移除直接的 player 引用，改用回调
    var onPlayPauseTapped: (() -> Void)?
    var onSeek: ((Double) -> Void)?
    
    private let playPauseButton = UIButton(type: .system)
    private let progressSlider = UISlider()
    private let currentTimeLabel = UILabel()
    private let durationLabel = UILabel()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupUI() {
        backgroundColor = UIColor.black.withAlphaComponent(0.4)
        layer.cornerRadius = 20
        
        // 播放/暂停按钮
        playPauseButton.setImage(UIImage(systemName: "pause.fill"), for: .normal)
        playPauseButton.tintColor = .white
        playPauseButton.addTarget(self, action: #selector(togglePlayPause), for: .touchUpInside)
        
        // 进度条
        progressSlider.minimumValue = 0
        progressSlider.maximumValue = 1
        progressSlider.tintColor = .white
        progressSlider.maximumTrackTintColor = .white.withAlphaComponent(0.3)
        progressSlider.thumbTintColor = .white
        progressSlider.addTarget(self, action: #selector(sliderValueChanged), for: .valueChanged)
        
        // 时间标签
        currentTimeLabel.textColor = .white
        currentTimeLabel.font = .monospacedDigitSystemFont(ofSize: 12, weight: .medium)
        currentTimeLabel.text = "0:00"
        
        durationLabel.textColor = .white
        durationLabel.font = .monospacedDigitSystemFont(ofSize: 12, weight: .medium)
        durationLabel.text = "0:00"
        
        addSubview(playPauseButton)
        addSubview(progressSlider)
        addSubview(currentTimeLabel)
        addSubview(durationLabel)
        
        playPauseButton.translatesAutoresizingMaskIntoConstraints = false
        progressSlider.translatesAutoresizingMaskIntoConstraints = false
        currentTimeLabel.translatesAutoresizingMaskIntoConstraints = false
        durationLabel.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            playPauseButton.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 15),
            playPauseButton.centerYAnchor.constraint(equalTo: centerYAnchor),
            playPauseButton.widthAnchor.constraint(equalToConstant: 30),
            playPauseButton.heightAnchor.constraint(equalToConstant: 30),
            
            currentTimeLabel.leadingAnchor.constraint(equalTo: playPauseButton.trailingAnchor, constant: 10),
            currentTimeLabel.centerYAnchor.constraint(equalTo: centerYAnchor),
            currentTimeLabel.widthAnchor.constraint(equalToConstant: 45),
            
            progressSlider.leadingAnchor.constraint(equalTo: currentTimeLabel.trailingAnchor, constant: 10),
            progressSlider.trailingAnchor.constraint(equalTo: durationLabel.leadingAnchor, constant: -10),
            progressSlider.centerYAnchor.constraint(equalTo: centerYAnchor),
            
            durationLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -15),
            durationLabel.centerYAnchor.constraint(equalTo: centerYAnchor),
            durationLabel.widthAnchor.constraint(equalToConstant: 45)
        ])
    }
    
    @objc private func togglePlayPause() {
        onPlayPauseTapped?()
    }
    
    func updatePlayButton(isPlaying: Bool) {
        let imageName = isPlaying ? "pause.fill" : "play.fill"
        playPauseButton.setImage(UIImage(systemName: imageName), for: .normal)
    }
    
    @objc private func sliderValueChanged() {
        // 传递进度百分比 (0.0 - 1.0)
        onSeek?(Double(progressSlider.value))
    }
    
    func updateProgress(current: Double, duration: Double) {
        guard duration > 0 else { return }
        progressSlider.value = Float(current / duration)
        currentTimeLabel.text = formatTime(current)
        durationLabel.text = formatTime(duration)
    }
    
    private func formatTime(_ seconds: Double) -> String {
        guard !seconds.isNaN && !seconds.isInfinite else { return "0:00" }
        let mins = Int(seconds) / 60
        let secs = Int(seconds) % 60
        return String(format: "%d:%02d", mins, secs)
    }
}
