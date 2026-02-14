//
//  ConsoleEventService.swift
//  Klick
//
//  Created on 14/02/2026.
//

import Foundation

/// Console/debug implementation of EventTrackingService
/// Useful for development and debugging
class ConsoleEventService: EventTrackingService {
    let name = "Console"
    
    /// Whether to print events to console (useful for debugging)
    var isEnabled: Bool = true
    
    func trackEvent(name eventName: String, parameters: [String: Any]? = nil) async {
        guard isEnabled else { return }
        
        var logMessage = "📊 [Event] \(eventName)"
        
        if let parameters = parameters, !parameters.isEmpty {
            let paramsString = parameters.map { "\($0.key): \($0.value)" }.joined(separator: ", ")
            logMessage += " | Parameters: \(paramsString)"
        }
        
        print(logMessage)
    }
    
    func setUserProperty(_ key: String, value: Any?) async {
        guard isEnabled else { return }
        
        if let value = value {
            print("📊 [User Property] \(key): \(value)")
        } else {
            print("📊 [User Property] \(key): nil (cleared)")
        }
    }
    
    func identify(userId: String?) async {
        guard isEnabled else { return }
        
        if let userId = userId {
            print("📊 [Identify] User ID: \(userId)")
        } else {
            print("📊 [Identify] User ID: nil (anonymous)")
        }
    }
    
    func reset() async {
        guard isEnabled else { return }
        
        print("📊 [Reset] User data cleared")
    }
}
