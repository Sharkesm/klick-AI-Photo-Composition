//
//  EventTrackingService.swift
//  Klick
//
//  Created on 14/02/2026.
//

import Foundation

// MARK: - Event Tracking Service Protocol

/// Protocol for event tracking platform implementations
/// Each platform (Firebase, PostHog, etc.) implements this protocol
protocol EventTrackingService {
    /// The name of the tracking service (e.g., "Firebase", "PostHog")
    var name: String { get }
    
    /// Determines whether it SHOULD log event in debug mode
    var debugModeEnabled: Bool { get }
    
    /// Configures the services with the API credentials
    func setup()
    
    /// Track an event with optional parameters
    /// - Parameters:
    ///   - eventName: Event name following Braze conventions (group_noun_action, lowercase, snake_case)
    ///   - parameters: Optional event parameters/properties
    func trackEvent(name eventName: String, parameters: [String: Any]?) async
    
    /// Set a user property/attribute
    /// - Parameters:
    ///   - key: Property key
    ///   - value: Property value (String, Int, Double, Bool, or Date)
    func setUserProperty(_ key: String, value: Any?) async
    
    /// Identify a user with a unique identifier
    /// - Parameter userId: Unique user identifier
    func identify(userId: String?) async
    
    /// Reset/clear user data (e.g., on logout)
    func reset() async
}

// MARK: - Event Model

/// Represents a tracking event following Braze naming conventions
/// Structure: group_noun_action (lowercase, snake_case)
/// Use properties for variations instead of creating multiple events
struct Event {
    let name: String
    let parameters: [String: Any]?
    
    /// Initialize an event with Braze-compliant naming
    /// - Parameters:
    ///   - group: Event group (e.g., "user", "camera", "onboarding")
    ///   - noun: Noun describing what (e.g., "photo", "composition", "screen")
    ///   - action: Action verb (e.g., "captured", "viewed", "selected")
    ///   - parameters: Optional event properties
    init(group: String, noun: String, action: String, parameters: [String: Any]? = nil) {
        self.name = "\(group)_\(noun)_\(action)".lowercased()
        self.parameters = parameters
    }
    
    /// Direct initialization with full event name (for flexibility)
    /// - Parameters:
    ///   - name: Full event name (should follow group_noun_action format)
    ///   - parameters: Optional event properties
    init(name: String, parameters: [String: Any]? = nil) {
        self.name = name.lowercased()
        self.parameters = parameters
    }
}

// MARK: - Common Event Groups

/// Predefined event groups following Braze conventions
enum EventGroup {
    static let user = "user"
    static let camera = "camera"
    static let onboarding = "onboarding"
    static let composition = "composition"
    static let photo = "photo"
    static let filter = "filter"
    static let purchase = "purchase"
    static let screen = "screen"
    static let paywall = "paywall"
    static let upgrade = "upgrade"
}

// MARK: - Common Event Actions

/// Predefined event actions following Braze conventions
enum EventAction {
    static let viewed = "viewed"
    static let tapped = "tapped"
    static let selected = "selected"
    static let captured = "captured"
    static let saved = "saved"
    static let deleted = "deleted"
    static let shared = "shared"
    static let started = "started"
    static let completed = "completed"
    static let skipped = "skipped"
    static let abandoned = "abandoned"
    static let signedUp = "signed_up"
    static let subscribed = "subscribed"
    static let restored = "restored"
}
