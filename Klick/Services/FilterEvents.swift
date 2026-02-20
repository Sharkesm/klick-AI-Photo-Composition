//
//  FilterEvents.swift
//  Klick
//
//  Created on 18/02/2026.
//

import Foundation

// MARK: - Image Preview Event Names

/// Feature-level event names for image preview screen
enum ImagePreviewEvent: String {
    case photoSaved = "photo_saved"
    case photoDiscarded = "photo_discarded"
    case effectsPanelOpened = "effects_opened"
    case effectsPanelClosed = "effects_closed"
    case blurToggled = "blur_toggled"
    case blurAdjusted = "blur_adjusted"
    case proRawToggled = "proraw_toggled"
    case comparisonToggled = "comparison_toggled"
    
    /// Generate full event name with image_preview prefix
    var eventName: String {
        return "image_preview_\(rawValue)"
    }
}

// MARK: - Filter Event Names

/// Feature-level event names for filter actions
enum FilterEvent: String {
    case packSelected = "pack_selected"
    case applied = "applied"
    case removed = "removed"
    case adjusted = "adjusted"
    
    /// Generate full event name with filter prefix
    var eventName: String {
        return "\(EventGroup.filter)_\(rawValue)"
    }
}

// MARK: - Adjustment Type Enum

/// Filter adjustment types
enum AdjustmentType: String {
    case intensity = "intensity"
    case brightness = "brightness"
    case warmth = "warmth"
}

// MARK: - Comparison Action Enum

/// Before/after comparison action
enum ComparisonAction: String {
    case shown = "shown"
    case hidden = "hidden"
}
