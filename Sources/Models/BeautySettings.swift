import SwiftUI
import Combine

// 美颜参数设置 - 支持持久化
class BeautySettings: ObservableObject {
    @AppStorage("beauty_enabled") var enabled: Bool = false
    @AppStorage("beauty_smoothing") var smoothing: Double = 0.5
    @AppStorage("beauty_whitening") var whitening: Double = 0.2
    @AppStorage("beauty_sharpening") var sharpening: Double = 0.2
    @AppStorage("beauty_faceSlim") var faceSlim: Double = 0.0
    @AppStorage("beauty_eyeEnlarge") var eyeEnlarge: Double = 0.0
    
    // 为了兼容 Float 接口的计算属性
    var smoothingFloat: Float { Float(smoothing) }
    var whiteningFloat: Float { Float(whitening) }
    var sharpeningFloat: Float { Float(sharpening) }
    var faceSlimFloat: Float { Float(faceSlim) }
    var eyeEnlargeFloat: Float { Float(eyeEnlarge) }
    
    func reset() {
        smoothing = 0.5
        whitening = 0.2
        sharpening = 0.2
        faceSlim = 0.0
        eyeEnlarge = 0.0
    }
}

// 美颜参数调节面板
struct BeautyControlPanel: View {
    @ObservedObject var settings: BeautySettings
    @State private var isExpanded = false
    var isLandscape: Bool = false
    
    var body: some View {
        VStack(spacing: 0) {
            // 顶部栏：左侧开关，右侧展开
            HStack(spacing: 0) {
                // 左侧：开关美颜
                Button(action: {
                    let generator = UIImpactFeedbackGenerator(style: .medium)
                    generator.impactOccurred()
                    settings.enabled.toggle()
                }) {
                    HStack {
                        Image(systemName: settings.enabled ? "sparkles" : "sparkles.rectangle.stack")
                        Text(settings.enabled ? "Beauty: ON" : "Beauty: OFF")
                            .font(.system(size: 16, weight: .bold))
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.leading, 15)
                    .padding(.vertical, 12)
                    .contentShape(Rectangle())
                }
                
                Divider()
                    .frame(height: 20)
                    .background(Color.white.opacity(0.3))
                
                // 右侧：展开/收起设置
                Button(action: {
                    withAnimation(.spring()) {
                        isExpanded.toggle()
                    }
                }) {
                    Image(systemName: isExpanded ? "chevron.down" : "chevron.up")
                        .frame(width: 50, height: 44)
                        .contentShape(Rectangle())
                }
            }
            .foregroundColor(.white)
            .background(settings.enabled ? Color.pink.opacity(0.8) : Color.black.opacity(0.6))
            
            // 参数调节面板
            if isExpanded {
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 15) {
                        // 磨皮
                        BeautySlider(title: "磨皮", value: $settings.smoothing)
                        
                        // 美白
                        BeautySlider(title: "美白", value: $settings.whitening)
                        
                        // 锐化
                        BeautySlider(title: "锐化", value: $settings.sharpening)
                        
                        Divider().background(Color.white.opacity(0.3))
                        
                        // 瘦脸
                        BeautySlider(title: "瘦脸", value: $settings.faceSlim)
                        
                        // 大眼
                        BeautySlider(title: "大眼", value: $settings.eyeEnlarge)
                        
                        // 重置按钮
                        Button(action: {
                            settings.reset()
                        }) {
                            Text("重置默认值")
                                .font(.caption)
                                .foregroundColor(.white.opacity(0.7))
                                .padding(.top, 5)
                        }
                    }
                    .padding(15)
                }
                // 限制最大高度，防止横屏溢出
                .frame(maxHeight: isLandscape ? 200 : 300)
                .background(Color.black.opacity(0.8))
                .disabled(!settings.enabled)
                .opacity(settings.enabled ? 1 : 0.5)
            }
        }
        .cornerRadius(20)
        // 移除底部 padding，由父视图控制
    }
}

struct BeautySlider: View {
    let title: String
    @Binding var value: Double
    
    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            HStack {
                Text(title)
                    .foregroundColor(.white)
                Spacer()
                Text("\(Int(value * 100))%")
                    .foregroundColor(.white.opacity(0.7))
                    .font(.caption)
            }
            Slider(value: $value, in: 0...1)
                .accentColor(.pink)
        }
    }
}
