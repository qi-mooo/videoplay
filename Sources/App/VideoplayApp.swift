import SwiftUI

// 用于控制屏幕旋转的 AppDelegate
class AppDelegate: NSObject, UIApplicationDelegate {
    static var orientationLock = UIInterfaceOrientationMask.portrait
    
    func application(_ application: UIApplication, supportedInterfaceOrientationsFor window: UIWindow?) -> UIInterfaceOrientationMask {
        return AppDelegate.orientationLock
    }
}

@main
struct VideoplayApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    var body: some Scene {
        WindowGroup {
            AdvancedContentView()
        }
    }
}
