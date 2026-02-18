//
//  PostHogEventService.swift
//  Klick
//
//  Created on 14/02/2026.
//

import Foundation
import PostHog

class PostHogEventService: EventTrackingService {
    let name = "PostHog"
    
    /// Initialize PostHog service
    /// Note: PostHog must be configured separately before using this service
    /// Use PostHogSDK.shared.setup(PostHogConfig(apiKey:host:)) in your app initialization
    init() {
        // PostHog should be configured separately via PostHogSDK.shared.setup()
        // This allows API keys to be managed securely (e.g., from Info.plist or environment)
    }
    
    func setup() {
        // Get API key and host from Info.plist or use defaults
        let apiKey = Bundle.main.object(forInfoDictionaryKey: "PostHogAPIKey") as? String ?? ""
        let host = Bundle.main.object(forInfoDictionaryKey: "PostHogHost") as? String ?? "https://us.i.posthog.com"

        // Configure PostHog SDK
        let config = PostHogConfig(apiKey: apiKey, host: host)
        PostHogSDK.shared.setup(config)
    }
    
    func trackEvent(name eventName: String, parameters: [String: Any]? = nil) async {
        await MainActor.run {
            PostHogSDK.shared.capture(eventName, properties: parameters)
        }
    }
    
    func setUserProperty(_ key: String, value: Any?) async {
        await MainActor.run {
            PostHogSDK.shared.setValue(value, forKey: key)
        }
    }
    
    func identify(userId: String?) async {
        await MainActor.run {
            if let userId = userId {
                PostHogSDK.shared.identify(userId)
            } else {
                // Reset to anonymous
                PostHogSDK.shared.reset()
            }
        }
    }
    
    func reset() async {
        await MainActor.run {
            PostHogSDK.shared.reset()
        }
    }
}
