import Foundation

/// 播放进度管理器 - 负责保存和恢复视频播放进度
class PlaybackProgressManager {
    static let shared = PlaybackProgressManager()
    
    private let userDefaults = UserDefaults.standard
    private let progressKey = "playback_progress"
    
    /// 播放进度数据结构
    struct PlaybackProgress: Codable {
        let videoIdentifier: String  // 视频唯一标识（URL 的 hash 或路径）
        let currentTime: Double      // 当前播放时间（秒）
        let duration: Double         // 视频总时长（秒）
        let lastPlayed: Date         // 最后播放时间
        
        var progressPercentage: Double {
            guard duration > 0 else { return 0 }
            return currentTime / duration
        }
    }
    
    private init() {}
    
    // MARK: - Public Methods
    
    /// 保存播放进度
    /// - Parameters:
    ///   - url: 视频 URL
    ///   - currentTime: 当前播放时间
    ///   - duration: 视频总时长
    func saveProgress(for url: URL, currentTime: Double, duration: Double) {
        // 只有播放进度超过 5 秒且未播放完成时才保存
        guard currentTime > 5.0, currentTime < duration - 5.0 else {
            // 如果播放到接近结尾，删除已保存的进度
            if currentTime >= duration - 5.0 {
                removeProgress(for: url)
            }
            return
        }
        
        let identifier = generateIdentifier(for: url)
        let progress = PlaybackProgress(
            videoIdentifier: identifier,
            currentTime: currentTime,
            duration: duration,
            lastPlayed: Date()
        )
        
        var progressDict = loadAllProgress()
        progressDict[identifier] = progress
        
        // 限制保存的进度数量，只保留最近 100 个
        if progressDict.count > 100 {
            let sortedProgress = progressDict.values.sorted { $0.lastPlayed > $1.lastPlayed }
            progressDict = Dictionary(uniqueKeysWithValues: sortedProgress.prefix(100).map { ($0.videoIdentifier, $0) })
        }
        
        saveAllProgress(progressDict)
        Logger.shared.info("💾 Saved progress for \(url.lastPathComponent): \(formatTime(currentTime))/\(formatTime(duration))")
    }
    
    /// 获取播放进度
    /// - Parameter url: 视频 URL
    /// - Returns: 保存的播放进度，如果没有则返回 nil
    func getProgress(for url: URL) -> PlaybackProgress? {
        let identifier = generateIdentifier(for: url)
        let progressDict = loadAllProgress()
        
        if let progress = progressDict[identifier] {
            Logger.shared.info("📖 Found saved progress for \(url.lastPathComponent): \(formatTime(progress.currentTime))/\(formatTime(progress.duration))")
            return progress
        }
        
        return nil
    }
    
    /// 删除播放进度
    /// - Parameter url: 视频 URL
    func removeProgress(for url: URL) {
        let identifier = generateIdentifier(for: url)
        var progressDict = loadAllProgress()
        progressDict.removeValue(forKey: identifier)
        saveAllProgress(progressDict)
        Logger.shared.info("🗑️ Removed progress for \(url.lastPathComponent)")
    }
    
    /// 清除所有播放进度
    func clearAllProgress() {
        userDefaults.removeObject(forKey: progressKey)
        Logger.shared.info("🗑️ Cleared all playback progress")
    }
    
    /// 获取所有保存的播放进度
    /// - Returns: 所有播放进度的数组，按最后播放时间排序
    func getAllProgress() -> [PlaybackProgress] {
        let progressDict = loadAllProgress()
        return progressDict.values.sorted { $0.lastPlayed > $1.lastPlayed }
    }
    
    // MARK: - Private Methods
    
    /// 生成视频的唯一标识符
    private func generateIdentifier(for url: URL) -> String {
        // 使用 URL 的绝对字符串生成 hash
        // 对于本地文件，使用文件名和大小（如果可用）
        // 对于网络文件，使用完整 URL
        if url.isFileURL {
            // 本地文件：使用路径的最后部分和文件大小
            let fileName = url.lastPathComponent
            if let attributes = try? FileManager.default.attributesOfItem(atPath: url.path),
               let fileSize = attributes[.size] as? Int64 {
                return "\(fileName)_\(fileSize)"
            }
            return fileName
        } else {
            // 网络文件：使用完整 URL 的 hash
            return url.absoluteString.hashValue.description
        }
    }
    
    /// 加载所有播放进度
    private func loadAllProgress() -> [String: PlaybackProgress] {
        guard let data = userDefaults.data(forKey: progressKey) else {
            return [:]
        }
        
        do {
            let decoder = JSONDecoder()
            return try decoder.decode([String: PlaybackProgress].self, from: data)
        } catch {
            Logger.shared.error("❌ Failed to decode progress: \(error.localizedDescription)")
            return [:]
        }
    }
    
    /// 保存所有播放进度
    private func saveAllProgress(_ progress: [String: PlaybackProgress]) {
        do {
            let encoder = JSONEncoder()
            let data = try encoder.encode(progress)
            userDefaults.set(data, forKey: progressKey)
        } catch {
            Logger.shared.error("❌ Failed to encode progress: \(error.localizedDescription)")
        }
    }
    
    /// 格式化时间
    private func formatTime(_ seconds: Double) -> String {
        guard !seconds.isNaN && !seconds.isInfinite else { return "0:00" }
        let mins = Int(seconds) / 60
        let secs = Int(seconds) % 60
        return String(format: "%d:%02d", mins, secs)
    }
}
