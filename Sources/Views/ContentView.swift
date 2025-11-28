import SwiftUI
import AVFoundation

struct ContentView: View {
    @State private var isBeautyOn = false
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            // Video Player View with Filter
            GPUPixelPlayerView(isBeautyOn: isBeautyOn, videoFileName: "sample")
                .ignoresSafeArea()
            
            // Controls Overlay
            VStack {
                Spacer()
                
                Button(action: {
                    isBeautyOn.toggle()
                }) {
                    Text(isBeautyOn ? "Beauty: ON" : "Beauty: OFF")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.white)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 10)
                        .background(Color.black.opacity(0.6))
                        .cornerRadius(20)
                }
                .padding(.bottom, 50)
            }
        }
    }
}

struct GPUPixelPlayerView: UIViewRepresentable {
    var isBeautyOn: Bool
    var videoFileName: String
    
    func makeUIView(context: Context) -> UIView {
        return context.coordinator.view
    }
    
    func updateUIView(_ uiView: UIView, context: Context) {
        context.coordinator.updateBeauty(isBeautyOn)
    }
    
    func makeCoordinator() -> Coordinator {
        return Coordinator(videoFileName: videoFileName)
    }
    
    class Coordinator: NSObject {
        var view: UIView
        var player: AVPlayer?
        var videoOutput: AVPlayerItemVideoOutput?
        var displayLink: CADisplayLink?
        var gpuPixelWrapper: GPUPixelWrapper?
        
        init(videoFileName: String) {
            self.view = UIView(frame: .zero)
            self.view.backgroundColor = .black
            super.init()
            
            setupGPUPixel()
            setupPlayer(fileName: videoFileName)
            setupDisplayLink()
        }
        
        deinit {
            displayLink?.invalidate()
            player?.pause()
        }
        
        func setupGPUPixel() {
            // Initialize the wrapper with the target view
            do {
                gpuPixelWrapper = GPUPixelWrapper(view: view)
                print("✅ GPUPixel initialized successfully")
            } catch {
                print("❌ GPUPixel initialization failed: \(error)")
                // Continue without filter - video will still play
            }
        }
        
        func setupPlayer(fileName: String) {
            guard let url = Bundle.main.url(forResource: fileName, withExtension: "mp4") else {
                print("Video file not found: \(fileName).mp4")
                return
            }
            
            let item = AVPlayerItem(url: url)
            
            // Configure Video Output
            // kCVPixelFormatType_32BGRA is required for GPUPixel as per our wrapper implementation
            let settings: [String: Any] = [
                kCVPixelBufferPixelFormatTypeKey as String: Int(kCVPixelFormatType_32BGRA)
            ]
            
            videoOutput = AVPlayerItemVideoOutput(pixelBufferAttributes: settings)
            item.add(videoOutput!)
            
            player = AVPlayer(playerItem: item)
            player?.play()
            
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
            
            // Get the current time of the player item
            let currentTime = item.currentTime()
            
            // Check if a new pixel buffer is available
            if output.hasNewPixelBuffer(forItemTime: currentTime) {
                var presentationItemTime: CMTime = .zero
                if let buffer = output.copyPixelBuffer(forItemTime: currentTime, itemTimeForDisplay: &presentationItemTime) {
                    // Send the pixel buffer to GPUPixel for processing and rendering
                    if let wrapper = gpuPixelWrapper {
                        wrapper.processPixelBuffer(buffer)
                    }
                }
            }
        }
        
        func updateBeauty(_ isBeautyOn: Bool) {
            gpuPixelWrapper?.setBeautyEnabled(isBeautyOn)
        }
    }
}
