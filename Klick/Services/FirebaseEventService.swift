//
//  FirebaseEventService.swift
//  Klick
//
//  Created on 20/02/2026.
//

import Foundation
import FirebaseCore
import FirebaseAnalytics

/// Firebase Analytics implementation of EventTrackingService
/// Handles Firebase initialization and event tracking in a self-contained service
class FirebaseEventService: EventTrackingService {
    let name = "Firebase"
    
    /// Initialize Firebase service
    init() {
        // Firebase configuration happens in setup()
    }
    
    /// Configure Firebase Analytics
    /// This method initializes Firebase if not already configured
    /// Called automatically by EventTrackingManager when service is registered
    func setup() {
        // Check if Firebase is already configured
        if FirebaseApp.app() == nil {
            FirebaseApp.configure()
        }
    }
    
    /// Track an event with Firebase Analytics
    /// - Parameters:
    ///   - eventName: Event name (Firebase allows up to 40 characters)
    ///   - parameters: Optional event parameters (keys up to 40 chars, values up to 100 chars)
    func trackEvent(name eventName: String, parameters: [String: Any]? = nil) async {
        await MainActor.run {
            Analytics.logEvent(eventName, parameters: parameters)
        }
    }
    
    /// Set a user property in Firebase Analytics
    /// - Parameters:
    ///   - key: Property name (up to 24 characters, alphanumeric and underscores)
    ///   - value: Property value (String recommended, up to 36 characters)
    func setUserProperty(_ key: String, value: Any?) async {
        await MainActor.run {
            if let value = value {
                // Convert various types to String for Firebase
                let stringValue: String
                if let strValue = value as? String {
                    stringValue = strValue
                } else if let intValue = value as? Int {
                    stringValue = String(intValue)
                } else if let doubleValue = value as? Double {
                    stringValue = String(doubleValue)
                } else if let boolValue = value as? Bool {
                    stringValue = String(boolValue)
                } else {
                    stringValue = String(describing: value)
                }
                Analytics.setUserProperty(stringValue, forName: key)
            } else {
                // Clear the user property
                Analytics.setUserProperty(nil, forName: key)
            }
        }
    }
    
    /// Identify a user with Firebase Analytics
    /// - Parameter userId: Unique user identifier
    func identify(userId: String?) async {
        await MainActor.run {
            if let userId = userId {
                Analytics.setUserID(userId)
            } else {
                // Clear user ID
                Analytics.setUserID(nil)
            }
        }
    }
    
    /// Reset Firebase Analytics user data
    /// Note: Firebase doesn't have a full reset like PostHog
    /// This clears the user ID, but session data persists
    func reset() async {
        await MainActor.run {
            Analytics.setUserID(nil)
            // Firebase doesn't provide a full reset API
            // Consider clearing important user properties individually if needed
        }
    }
}
