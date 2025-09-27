//
//  HapticFeedback.swift
//  Klick
//
//  Created by Manase on 27/09/2025.
//

import Foundation
import UIKit

enum HapticFeedback {
    case light
    case medium
    case heavy
    case selection
    case success
    case error
    case warning
    
    func generate() {
        switch self {
        case .light:
            generateImpact(style: .light)
        case .medium:
            generateImpact(style: .medium)
        case .heavy:
            generateImpact(style: .heavy)
        case .selection:
            generateSelection()
        case .success:
            generateNotification(type: .success)
        case .error:
            generateNotification(type: .error)
        case .warning:
            generateNotification(type: .warning)
        }
    }
    
    // MARK: - Generic calls
    
    func generateImpact(style: UIImpactFeedbackGenerator.FeedbackStyle) {
        guard #available(iOS 10.0, *) else {
            return
        }
        
        let lightImpactFeedbackGenerator = UIImpactFeedbackGenerator(style: style)
        lightImpactFeedbackGenerator.impactOccurred()
    }
    
    func generateSelection() {
        guard #available(iOS 10.0, *) else {
            return
        }
        
        let selectionFeedbackGenerator = UISelectionFeedbackGenerator()
        selectionFeedbackGenerator.selectionChanged()
    }
    
    func generateNotification(type: UINotificationFeedbackGenerator.FeedbackType) {
        guard #available(iOS 10.0, *) else {
            return
        }
        
        let successNotificationFeedbackGenerator = UINotificationFeedbackGenerator()
        successNotificationFeedbackGenerator.notificationOccurred(type)
    }
    
}
