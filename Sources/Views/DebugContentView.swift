import SwiftUI
import AVFoundation

// 调试版本 - 显示详细状态信息
struct DebugContentView: View {
    @State private var statusMessage = "Initializing..."
    @State private var isBeautyOn = false
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            // Video Player
            DebugPlayerView(statusMessage: $statusMessage, isBeautyOn: isBeautyOn)
                .ignoresSafeArea()
            
            // Debug overlay
            VStack {
                Text(statusMessage)
                    .foregroundColor(.white)
                    .padding()
                    .background(Color.black.opacity(0.7))
                    .cornerRadius(10)
                    .padding(.top, 50)
                
                Spacer()
                
                Button(action: {
                    isBeautyOn.toggle()
                }) {
                    Text(isBeautyOn ? "Beauty: ON" : "Beauty: OFF")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.white)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 10)
                        .background(Color.blue.opacity(0.8))
                        .cornerRadius(20)
                }
                .padding(.bottom, 50)
            }
        }
    }
}

struct DebugPlayerView: UIViewRepresentable {
    @Binding var statusMessage: String
    var isBeautyOn: Bool
    
    func makeUIView(context: Context) -> UIView {
        return context.coordinator.view
    }
    
    func updateUIView(_ uiView: UIView, context: Context) {
        context.coordinator.updateBeauty(isBeautyOn)
    }
    
    func makeCoordinator() -> Coordinator {
        return Coordinator(statusMessage: $statusMessage)
    }
    
    class Coordinator: NSObject {
        var view: UIView
        var player: AVPlayer?
        var videoOutput: AVPlayerItemVideoOutput?
        var displayLink: CADisplayLink?
        var gpuPixelWrapper: GPUPixelWrapper?
        @Binding var statusMessage: String
        
        init(statusMessage: Binding<String>) {
            self._statusMessage = statusMessage
            self.view = UIView(frame: .zero)
            self.view.backgroundColor = .black
            super.init()
            
            DispatchQueue.main.async {
                self.statusMessage = "Setting up GPUPixel..."
            }
            
            setupGPUPixel()
            setupPlayer(fileName: "sample")
            setupDisplayLink()
        }
        
        deinit {
            displayLink?.invalidate()
            player?.pause()
        }
        
        func setupGPUPixel() {
            do {
                gpuPixelWrapper = GPUPixelWrapper(view: view)
                DispatchQueue.main.async {
                    self.statusMessage = "✅ GPUPixel Ready"
                }
                print("✅ GPUPixel initialized")
            } catch {
                DispatchQueue.main.async {
                    self.statusMessage = "⚠️ GPUPixel failed: \(error.localizedDescription)"
                }
                print("❌ GPUPixel error: \(error)")
            }
        }
        
        func setupPlayer(fileName: String) {
            guard let url = Bundle.main.url(forResource: fileName, withExtension: "mp4") else {
                DispatchQueue.main.async {
                    self.statusMessage = "❌ Video file not found"
                }
                print("❌ Video not found: \(fileName).mp4")
                return
            }
            
            print("✅ Video found: \(url.path)")
            
            let item = AVPlayerItem(url: url)
            
            let settings: [String: Any] = [
                kCVPixelBufferPixelFormatTypeKey as String: Int(kCVPixelFormatType_32BGRA)
            ]
            
            videoOutput = AVPlayerItemVideoOutput(pixelBufferAttributes: settings)
            item.add(videoOutput!)
            
            player = AVPlayer(playerItem: item)
            player?.play()
            
            DispatchQueue.main.async {
                self.statusMessage = "▶️ Playing video"
            }
            
            // Loop video
            NotificationCenter.default.addObserver(forName: .AVPlayerItemDidPlayToEndTime, object: item, queue: .main) { [weak self] _ in
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
                    if let wrapper = gpuPixelWrapper {
                        wrapper.processPixelBuffer(buffer)
                    }
                }
            }
        }
        
        func updateBeauty(_ isBeautyOn: Bool) {
            gpuPixelWrapper?.setBeautyEnabled(isBeautyOn)
            DispatchQueue.main.async {
                self.statusMessage = isBeautyOn ? "✨ Beauty ON" : "▶️ Beauty OFF"
            }
        }
    }
}
