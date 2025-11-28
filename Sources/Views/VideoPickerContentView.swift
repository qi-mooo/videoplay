import SwiftUI
import AVFoundation

struct VideoPickerContentView: View {
    @State private var isBeautyOn = false
    @State private var selectedVideoURL: URL?
    @State private var showVideoPicker = false
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            if let videoURL = selectedVideoURL {
                // 显示已选择的视频
                VideoPlayerWithFilterView(
                    videoURL: videoURL,
                    isBeautyOn: isBeautyOn
                )
                .ignoresSafeArea()
            } else {
                // 显示选择视频提示
                VStack(spacing: 30) {
                    Image(systemName: "video.badge.plus")
                        .font(.system(size: 80))
                        .foregroundColor(.white.opacity(0.6))
                    
                    Text("选择视频开始播放")
                        .font(.title2)
                        .foregroundColor(.white)
                    
                    Button(action: {
                        showVideoPicker = true
                    }) {
                        HStack {
                            Image(systemName: "folder.fill")
                            Text("选择视频")
                        }
                        .font(.headline)
                        .foregroundColor(.white)
                        .padding(.horizontal, 30)
                        .padding(.vertical, 15)
                        .background(Color.blue)
                        .cornerRadius(25)
                    }
                }
            }
            
            // 控制按钮
            if selectedVideoURL != nil {
                VStack {
                    Spacer()
                    
                    HStack(spacing: 20) {
                        // 重新选择视频
                        Button(action: {
                            showVideoPicker = true
                        }) {
                            Image(systemName: "folder.fill")
                                .font(.system(size: 20))
                                .foregroundColor(.white)
                                .frame(width: 50, height: 50)
                                .background(Color.gray.opacity(0.8))
                                .clipShape(Circle())
                        }
                        
                        Spacer()
                        
                        // 美颜开关
                        Button(action: {
                            isBeautyOn.toggle()
                        }) {
                            HStack {
                                Image(systemName: isBeautyOn ? "sparkles" : "sparkles.rectangle.stack")
                                Text(isBeautyOn ? "Beauty: ON" : "Beauty: OFF")
                            }
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.white)
                            .padding(.horizontal, 20)
                            .padding(.vertical, 10)
                            .background(isBeautyOn ? Color.pink.opacity(0.8) : Color.black.opacity(0.6))
                            .cornerRadius(20)
                        }
                    }
                    .padding(.horizontal, 30)
                    .padding(.bottom, 50)
                }
            }
        }
        .sheet(isPresented: $showVideoPicker) {
            VideoPickerViewController(selectedVideoURL: $selectedVideoURL)
        }
    }
}

// UIKit 视频选择器桥接到 SwiftUI
struct VideoPickerViewController: UIViewControllerRepresentable {
    @Binding var selectedVideoURL: URL?
    @Environment(\.presentationMode) var presentationMode
    
    func makeUIViewController(context: Context) -> UIViewController {
        let viewController = UIViewController()
        
        DispatchQueue.main.async {
            let picker = VideoPicker(
                presentationController: viewController,
                delegate: context.coordinator
            )
            context.coordinator.picker = picker
            
            // 创建一个临时按钮作为源视图
            let sourceView = UIView(frame: viewController.view.bounds)
            viewController.view.addSubview(sourceView)
            picker.present(from: sourceView)
        }
        
        return viewController
    }
    
    func updateUIViewController(_ uiViewController: UIViewController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, VideoPickerDelegate {
        let parent: VideoPickerViewController
        var picker: VideoPicker?
        
        init(_ parent: VideoPickerViewController) {
            self.parent = parent
        }
        
        func didSelectVideo(url: URL?) {
            parent.selectedVideoURL = url
            parent.presentationMode.wrappedValue.dismiss()
        }
    }
}

// 带滤镜的视频播放器视图
struct VideoPlayerWithFilterView: UIViewRepresentable {
    let videoURL: URL
    var isBeautyOn: Bool
    
    func makeUIView(context: Context) -> UIView {
        return context.coordinator.view
    }
    
    func updateUIView(_ uiView: UIView, context: Context) {
        context.coordinator.updateBeauty(isBeautyOn)
    }
    
    func makeCoordinator() -> Coordinator {
        return Coordinator(videoURL: videoURL)
    }
    
    class Coordinator: NSObject {
        var view: UIView
        var player: AVPlayer?
        var videoOutput: AVPlayerItemVideoOutput?
        var displayLink: CADisplayLink?
        var gpuPixelWrapper: GPUPixelWrapper?
        
        init(videoURL: URL) {
            self.view = UIView(frame: .zero)
            self.view.backgroundColor = .black
            super.init()
            
            setupGPUPixel()
            setupPlayer(url: videoURL)
            setupDisplayLink()
        }
        
        deinit {
            displayLink?.invalidate()
            player?.pause()
        }
        
        func setupGPUPixel() {
            do {
                gpuPixelWrapper = GPUPixelWrapper(view: view)
                print("✅ GPUPixel initialized")
            } catch {
                print("❌ GPUPixel error: \(error)")
            }
        }
        
        func setupPlayer(url: URL) {
            print("📹 Loading video: \(url.lastPathComponent)")
            
            let item = AVPlayerItem(url: url)
            
            let settings: [String: Any] = [
                kCVPixelBufferPixelFormatTypeKey as String: Int(kCVPixelFormatType_32BGRA)
            ]
            
            videoOutput = AVPlayerItemVideoOutput(pixelBufferAttributes: settings)
            item.add(videoOutput!)
            
            player = AVPlayer(playerItem: item)
            player?.play()
            
            // Loop video
            NotificationCenter.default.addObserver(
                forName: .AVPlayerItemDidPlayToEndTime,
                object: item,
                queue: .main
            ) { [weak self] _ in
                self?.player?.seek(to: .zero)
                self?.player?.play()
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
        
        func updateBeauty(_ isBeautyOn: Bool) {
            gpuPixelWrapper?.setBeautyEnabled(isBeautyOn)
            print(isBeautyOn ? "✨ Beauty ON" : "▶️ Beauty OFF")
        }
    }
}
