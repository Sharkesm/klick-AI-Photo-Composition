import UIKit

class AppDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // Initialize Facebook SDK for sharing
        // Note: If you need full Facebook SDK functionality, add FacebookCore package
        return true
    }
    
    func application(_ app: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey : Any] = [:]) -> Bool {
        // Handle URL opening for Facebook SDK
        // This will be handled by the Facebook SDK if FacebookCore is added
        return false
    }
}
