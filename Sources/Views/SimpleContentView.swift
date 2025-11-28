import SwiftUI
import AVFoundation
import AVKit

// 简化版本 - 仅播放视频，不使用滤镜
struct SimpleContentView: View {
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            if let url = Bundle.main.url(forResource: "sample", withExtension: "mp4") {
                VideoPlayer(player: AVPlayer(url: url))
                    .ignoresSafeArea()
                    .onAppear {
                        print("✅ Video loaded successfully")
                    }
            } else {
                VStack {
                    Text("Video not found")
                        .foregroundColor(.white)
                        .font(.title)
                    Text("sample.mp4")
                        .foregroundColor(.gray)
                        .font(.caption)
                }
            }
        }
    }
}
