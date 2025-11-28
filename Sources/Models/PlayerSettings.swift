import Foundation

class PlayerSettings: ObservableObject {
    static let shared = PlayerSettings()
    
    @Published var useLocalCache: Bool {
        didSet {
            UserDefaults.standard.set(useLocalCache, forKey: "use_local_cache")
        }
    }
    
    private init() {
        self.useLocalCache = UserDefaults.standard.bool(forKey: "use_local_cache")
    }
}
