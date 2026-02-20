//
//  EventTrackingManager.swift
//  Klick
//
//  Created on 14/02/2026.
//

import Foundation
import PostHog

// MARK: - Event Tracking Manager

/// Orchestrator for multiple event tracking services
/// Manages multiple platform implementations (Firebase, PostHog, etc.)
/// Provides unified API while delegating to individual services
class EventTrackingManager {
    
    /// Singleton instance
    static let shared = EventTrackingManager()
    
    /// Registered tracking services
    private var services: [EventTrackingService] = []
    
    /// Whether tracking is enabled (can be disabled for privacy/debugging)
    var isEnabled: Bool = true
    
    private init() {}
    
    // MARK: - Service Registration
    
    /// Register a tracking service
    /// - Parameter service: The tracking service to register
    func register(_ service: EventTrackingService) {
        services.append(service)
        service.setup()
    }
    
    /// Register multiple tracking services
    /// - Parameter services: Array of tracking services to register
    func register(_ services: [EventTrackingService]) {
        services.forEach { register($0) }
    }
    
    /// Remove a tracking service
    /// - Parameter serviceName: Name of the service to remove
    func unregister(serviceName: String) {
        services.removeAll { $0.name == serviceName }
    }
    
    /// Get list of registered service names
    var registeredServices: [String] {
        services.map { $0.name }
    }
    
    // MARK: - Event Tracking
    
    /// Track an event across all registered services
    /// - Parameters:
    ///   - eventName: Event name following Braze conventions (group_noun_action)
    ///   - parameters: Optional event parameters/properties
    /// 
    /// Example usage:
    /// ```swift
    /// // Simple event
    /// await EventTrackingManager.shared.track(eventName: "user_signup")
    /// 
    /// // Event with parameters
    /// await EventTrackingManager.shared.track(
    ///     eventName: "photo_captured",
    ///     parameters: ["composition_type": "rule_of_thirds", "filter": "vintage"]
    /// )
    /// 
    /// // Using Event model
    /// let event = Event(group: "camera", noun: "photo", action: "captured", parameters: ["filter": "vintage"])
    /// await EventTrackingManager.shared.track(event)
    /// ```
    func track(eventName: String, parameters: [String: Any]? = nil) async {
        guard isEnabled else { return }
        
        await withTaskGroup(of: Void.self) { group in
            for service in services {
                group.addTask {
                    await service.trackEvent(name: eventName, parameters: parameters)
                }
            }
        }
    }
    
    /// Track an event using the Event model
    /// - Parameter event: Event to track
    func track(_ event: Event) async {
        await track(eventName: event.name, parameters: event.parameters)
    }
    
    // MARK: - User Identification
    
    /// Identify a user across all registered services
    /// - Parameter userId: Unique user identifier
    func identify(userId: String?) async {
        guard isEnabled else { return }
        
        await withTaskGroup(of: Void.self) { group in
            for service in services {
                group.addTask {
                    await service.identify(userId: userId)
                }
            }
        }
    }
    
    // MARK: - User Properties
    
    /// Set a user property across all registered services
    /// - Parameters:
    ///   - key: Property key
    ///   - value: Property value (String, Int, Double, Bool, or Date)
    func setUserProperty(_ key: String, value: Any?) async {
        guard isEnabled else { return }
        
        await withTaskGroup(of: Void.self) { group in
            for service in services {
                group.addTask {
                    await service.setUserProperty(key, value: value)
                }
            }
        }
    }
    
    // MARK: - Reset
    
    /// Reset/clear user data across all registered services
    func reset() async {
        await withTaskGroup(of: Void.self) { group in
            for service in services {
                group.addTask {
                    await service.reset()
                }
            }
        }
    }
    
    // MARK: - Firebase Revenue Tracking

    /// Log a GA4-compliant `purchase` event directly to Firebase so revenue dashboards populate.
    ///
    /// This must be called in addition to (not instead of) your custom `paywall_purchase_completed`
    /// event. Firebase revenue metrics only count events whose name is exactly `purchase`
    /// (the GA4 reserved event), carrying `value` as a Double, `currency`, `transaction_id`, and `items`.
    ///
    /// - Parameters:
    ///   - value: Purchase price as a Double
    ///   - currency: ISO 4217 currency code (e.g. "USD", "MYR")
    ///   - transactionId: Unique transaction ID from StoreKit/RevenueCat (prevents double-counting)
    ///   - productId: App Store product identifier
    ///   - productName: Human-readable product name
    func logFirebasePurchase(
        value: Double,
        currency: String,
        transactionId: String,
        productId: String,
        productName: String
    ) async {
        guard isEnabled else { return }
        for service in services {
            if let firebaseService = service as? FirebaseEventService {
                await firebaseService.logPurchaseEvent(
                    value: value,
                    currency: currency,
                    transactionId: transactionId,
                    productId: productId,
                    productName: productName
                )
            }
        }
    }

    // MARK: - Configuration
    
    /// Configure all available event tracking services
    /// This method iterates through all available services and pre-configures them
    /// Call this during app initialization (e.g., in KlickApp.swift init())
    /// 
    /// Example initialization in KlickApp.swift:
    /// ```swift
    /// init() {
    ///     // Configure all event tracking services
    ///     EventTrackingManager.configure()
    /// }
    /// ```
    /// 
    /// **Security Note**: Store API keys in Info.plist (not in code) or use environment variables.
    /// Add Info.plist keys to .gitignore if they contain sensitive data.
    /// 
    /// Reference: https://posthog.com/docs/libraries/ios
    static func configure() {
        shared.register([
            PostHogEventService(),
            ConsoleEventService(),
            FirebaseEventService()
        ])
    }
}
