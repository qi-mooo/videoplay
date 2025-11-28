import Foundation
import UIKit

/// 应用日志管理器
class Logger: ObservableObject {
    static let shared = Logger()
    
    @Published var logs: [LogEntry] = []
    private let maxLogs = 500  // 最多保留 500 条日志
    private let queue = DispatchQueue(label: "com.videoplay.logger", qos: .utility)
    
    struct LogEntry: Identifiable {
        let id = UUID()
        let timestamp: Date
        let level: LogLevel
        let message: String
        
        var formattedString: String {
            let formatter = DateFormatter()
            formatter.dateFormat = "HH:mm:ss.SSS"
            let timeString = formatter.string(from: timestamp)
            return "[\(timeString)] [\(level.emoji)] \(message)"
        }
    }
    
    enum LogLevel: String {
        case debug = "DEBUG"
        case info = "INFO"
        case warning = "WARNING"
        case error = "ERROR"
        
        var emoji: String {
            switch self {
            case .debug: return "🔍"
            case .info: return "ℹ️"
            case .warning: return "⚠️"
            case .error: return "❌"
            }
        }
    }
    
    private init() {}
    
    func log(_ message: String, level: LogLevel = .info) {
        queue.async { [weak self] in
            guard let self = self else { return }
            
            let entry = LogEntry(timestamp: Date(), level: level, message: message)
            
            DispatchQueue.main.async {
                self.logs.append(entry)
                
                // 限制日志数量
                if self.logs.count > self.maxLogs {
                    self.logs.removeFirst(self.logs.count - self.maxLogs)
                }
            }
            
            // 同时输出到控制台
            print(entry.formattedString)
        }
    }
    
    func debug(_ message: String) {
        log(message, level: .debug)
    }
    
    func info(_ message: String) {
        log(message, level: .info)
    }
    
    func warning(_ message: String) {
        log(message, level: .warning)
    }
    
    func error(_ message: String) {
        log(message, level: .error)
    }
    
    func clear() {
        DispatchQueue.main.async {
            self.logs.removeAll()
        }
    }
    
    func exportLogs() -> URL? {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd_HH-mm-ss"
        let timestamp = formatter.string(from: Date())
        let filename = "Videoplay_Log_\(timestamp).txt"
        
        let tempDir = FileManager.default.temporaryDirectory
        let fileURL = tempDir.appendingPathComponent(filename)
        
        let logText = logs.map { $0.formattedString }.joined(separator: "\n")
        
        do {
            try logText.write(to: fileURL, atomically: true, encoding: .utf8)
            return fileURL
        } catch {
            print("Failed to export logs: \(error)")
            return nil
        }
    }
}
