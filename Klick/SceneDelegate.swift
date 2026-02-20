import UIKit
import SwiftUI

class SceneDelegate: NSObject, UIWindowSceneDelegate {
    var window: UIWindow?
    
    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        // This method is called when the scene is first created
        // Use this method to set up the scene if needed
    }
    
    func scene(_ scene: UIScene, openURLContexts URLContexts: Set<UIOpenURLContext>) {
        // Handle URL opening for Facebook SDK in iOS 13+
        // This will be handled by the Facebook SDK if FacebookCore is added
        guard let url = URLContexts.first?.url else {
            return
        }
        
        // For now, just log the URL - full handling requires FacebookCore
        SVLogger.main.log(message: "Received URL", info: url.absoluteString, logLevel: .info)
    }
}
