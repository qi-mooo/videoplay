import SwiftUI

struct SettingsView: View {
    @ObservedObject var settings = PlayerSettings.shared
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("播放设置")) {
                    Toggle("启用本地缓存 (WebDAV)", isOn: $settings.useLocalCache)
                    Text("先下载后播放。支持美颜，但需要等待下载完成。")
                        .font(.caption)
                        .foregroundColor(.gray)
                    
                    Toggle("记忆播放进度", isOn: $settings.rememberPlaybackProgress)
                    Text("自动保存视频播放位置，下次打开时从上次位置继续播放。")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
                
                Section(header: Text("关于")) {
                    HStack {
                        Text("播放器引擎")
                        Spacer()
                        Text("AVPlayer")
                            .foregroundColor(.gray)
                    }
                }
            }
            .navigationTitle("设置")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("完成") {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
            }
        }
    }
}
