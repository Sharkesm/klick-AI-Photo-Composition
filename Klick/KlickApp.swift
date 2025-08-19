//
//  KlickApp.swift
//  Klick
//
//  Created by Manase on 12/07/2025.
//

import SwiftUI

@main
struct KlickApp: App {
    // Register the AppDelegate for SwiftUI App
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    var body: some Scene {
        WindowGroup {
            LandingPageView()
        }
    }
}
