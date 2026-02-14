//
//  PostHogEventService.swift
//  Klick
//
//  Created on 14/02/2026.
//

import Foundation

#if canImport(PostHog)
import PostHog

/// PostHog implementation of EventTrackingService
class PostHogEventService: EventTrackingService {
    let name = "PostHog"
    
    func trackEvent(name eventName: String, parameters: [String: Any]? = nil) async {
        await MainActor.run {
            PostHog.shared.capture(eventName, properties: parameters)
        }
    }
    
    func setUserProperty(_ key: String, value: Any?) async {
        await MainActor.run {
            if let value = value {
                PostHog.shared.identify(distinctId: nil, properties: [key: value])
            } else {
                // PostHog doesn't have direct unset, but we can set to nil
                PostHog.shared.identify(distinctId: nil, properties: [key: NSNull()])
            }
        }
    }
    
    func identify(userId: String?) async {
        await MainActor.run {
            if let userId = userId {
                PostHog.shared.identify(distinctId: userId)
            } else {
                // Reset to anonymous
                PostHog.shared.reset()
            }
        }
    }
    
    func reset() async {
        await MainActor.run {
            PostHog.shared.reset()
        }
    }
}

#else

/// Placeholder implementation when PostHog is not available
class PostHogEventService: EventTrackingService {
    let name = "PostHog"
    
    func trackEvent(name eventName: String, parameters: [String: Any]? = nil) async {
        print("⚠️ PostHogEventService: PostHog SDK not available. Event: \(eventName)")
    }
    
    func setUserProperty(_ key: String, value: Any?) async {
        print("⚠️ PostHogEventService: PostHog SDK not available. Property: \(key)")
    }
    
    func identify(userId: String?) async {
        print("⚠️ PostHogEventService: PostHog SDK not available. UserId: \(userId ?? "nil")")
    }
    
    func reset() async {
        print("⚠️ PostHogEventService: PostHog SDK not available. Reset called.")
    }
}

#endif
