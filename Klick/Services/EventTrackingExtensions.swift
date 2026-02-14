//
//  EventTrackingExtensions.swift
//  Klick
//
//  Created on 14/02/2026.
//

import Foundation

// MARK: - Convenience Extensions

extension EventTrackingManager {
    
    // MARK: - Common Event Helpers
    
    /// Track a screen view event
    /// - Parameters:
    ///   - screenName: Name of the screen (e.g., "camera", "gallery", "settings")
    ///   - parameters: Optional additional parameters
    func trackScreenView(_ screenName: String, parameters: [String: Any]? = nil) async {
        var params = parameters ?? [:]
        params["screen_name"] = screenName
        await track(eventName: "\(EventGroup.screen)_\(screenName)_\(EventAction.viewed)", parameters: params)
    }
    
    /// Track a user signup event
    /// - Parameter method: Signup method (e.g., "email", "apple", "google")
    func trackUserSignup(method: String? = nil) async {
        var parameters: [String: Any]? = nil
        if let method = method {
            parameters = ["method": method]
        }
        await track(eventName: "\(EventGroup.user)_\(EventAction.signedUp)", parameters: parameters)
    }
    
    /// Track onboarding completion
    /// - Parameters:
    ///   - goal: User's selected creative goal
    ///   - timeSpent: Time spent in onboarding (seconds)
    func trackOnboardingCompleted(goal: String? = nil, timeSpent: TimeInterval? = nil) async {
        var parameters: [String: Any] = [:]
        if let goal = goal {
            parameters["goal"] = goal
        }
        if let timeSpent = timeSpent {
            parameters["time_spent"] = Int(timeSpent)
        }
        await track(eventName: "\(EventGroup.onboarding)_completed", parameters: parameters.isEmpty ? nil : parameters)
    }
    
    /// Track photo capture event
    /// - Parameters:
    ///   - compositionType: Composition type used (if any)
    ///   - filterApplied: Filter applied (if any)
    func trackPhotoCaptured(compositionType: String? = nil, filterApplied: String? = nil) async {
        var parameters: [String: Any] = [:]
        if let compositionType = compositionType {
            parameters["composition_type"] = compositionType
        }
        if let filterApplied = filterApplied {
            parameters["filter"] = filterApplied
        }
        await track(eventName: "\(EventGroup.photo)_captured", parameters: parameters.isEmpty ? nil : parameters)
    }
    
    /// Track composition type selection
    /// - Parameter compositionType: Selected composition type
    func trackCompositionSelected(_ compositionType: String) async {
        await track(eventName: "\(EventGroup.composition)_selected", parameters: ["composition_type": compositionType])
    }
    
    /// Track filter application
    /// - Parameter filterName: Name of the filter applied
    func trackFilterApplied(_ filterName: String) async {
        await track(eventName: "\(EventGroup.filter)_applied", parameters: ["filter_name": filterName])
    }
    
    /// Track purchase/subscription event
    /// - Parameters:
    ///   - productId: Product identifier
    ///   - price: Price of the product
    ///   - currency: Currency code
    func trackPurchase(productId: String, price: Double? = nil, currency: String? = nil) async {
        var parameters: [String: Any] = ["product_id": productId]
        if let price = price {
            parameters["price"] = price
        }
        if let currency = currency {
            parameters["currency"] = currency
        }
        await track(eventName: "\(EventGroup.purchase)_completed", parameters: parameters)
    }
}
