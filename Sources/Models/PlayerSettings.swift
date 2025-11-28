import Foundation

class PlayerSettings: ObservableObject {
    static let shared = PlayerSettings()
    
    @Published var useLocalCache: Bool {
        didSet {
            UserDefaults.standard.set(useLocalCache, forKey: "use_local_cache")
        }
    }
    
    @Published var rememberPlaybackProgress: Bool {
        didSet {
            UserDefaults.standard.set(rememberPlaybackProgress, forKey: "remember_playback_progress")
            if !rememberPlaybackProgress {
                // 如果关闭记忆功能，清除所有已保存的进度
                PlaybackProgressManager.shared.clearAllProgress()
            }
        }
    }
    
    private init() {
        self.useLocalCache = UserDefaults.standard.bool(forKey: "use_local_cache")
        // 默认启用播放进度记忆功能
        self.rememberPlaybackProgress = UserDefaults.standard.object(forKey: "remember_playback_progress") as? Bool ?? true
    }
}
