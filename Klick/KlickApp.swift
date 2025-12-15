//
//  KlickApp.swift
//  Klick
//
//  Created by Manase on 12/07/2025.
//

import SwiftUI
import RevenueCat

@main
struct KlickApp: App {
    // Register the AppDelegate for SwiftUI App
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    init() {
        PurchaseService.configure()
        
        Task {
            await PurchaseService.main.refreshSubscriptionStatus()
        }
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
            // LandingPageView()
        }
    }
}
