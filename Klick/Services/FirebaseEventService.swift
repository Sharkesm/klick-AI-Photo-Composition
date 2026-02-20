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
    
    var debugModeEnabled: Bool {
        #if DEBUG || DEVELOPMENT
            return true
        #else
            return false
        #endif
    }
    
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
        guard !debugModeEnabled else { return }
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
    
    /// Log a GA4-compliant purchase event so Firebase revenue dashboards populate correctly.
    ///
    /// Firebase/Google Analytics revenue metrics (Total Revenue, Purchase Revenue,
    /// Avg Purchase per Active User) are ONLY populated by the reserved `purchase`
    /// event with exactly these parameters:
    ///   - `value`          – purchase price as a Double (NOT a String)
    ///   - `currency`       – ISO 4217 3-letter code, e.g. "USD"
    ///   - `transaction_id` – unique identifier to prevent duplicate counting
    ///   - `items`          – array of item dictionaries
    ///
    /// Custom event names (e.g. "paywall_purchase_completed") are never counted
    /// toward revenue regardless of the parameters they carry.
    ///
    /// - Parameters:
    ///   - value: Purchase price as a Double
    ///   - currency: ISO 4217 currency code (e.g. "USD", "EUR", "MYR")
    ///   - transactionId: Unique transaction identifier from RevenueCat/StoreKit
    ///   - productId: The App Store product identifier
    ///   - productName: Human-readable product name for the `items` array
    func logPurchaseEvent(
        value: Double,
        currency: String,
        transactionId: String,
        productId: String,
        productName: String
    ) async {
        guard !debugModeEnabled else { return }
        await MainActor.run {
            Analytics.logEvent(
                AnalyticsEventPurchase,
                parameters: [
                    AnalyticsParameterValue: value,
                    AnalyticsParameterCurrency: currency,
                    AnalyticsParameterTransactionID: transactionId,
                    AnalyticsParameterItems: [
                        [
                            AnalyticsParameterItemID: productId,
                            AnalyticsParameterItemName: productName,
                            AnalyticsParameterPrice: value,
                            AnalyticsParameterQuantity: 1
                        ]
                    ]
                ]
            )
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
