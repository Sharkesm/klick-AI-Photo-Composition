//
//  CameraEvents.swift
//  Klick
//
//  Created on 18/02/2026.
//

import Foundation

// MARK: - Camera Event Names

/// Feature-level event names for camera functionality
/// Provides type safety and autocomplete for camera events
enum CameraEvent: String {
    // Core actions
    case photoCaptured = "photo_captured"
    case compositionSelected = "composition_selected"
    case compositionSwiped = "composition_swiped"
    case screenViewed = "screen_viewed"
    
    // Camera controls
    case flashChanged = "flash_changed"
    case zoomChanged = "zoom_changed"
    case qualitySelected = "quality_selected"
    case cameraFlipped = "flipped"
    case focusTapped = "focus_tapped"
    
    // Navigation
    case settingsOpened = "settings_opened"
    case photoAlbumOpened = "photo_album_opened"
    case practiceOpened = "practice_opened"
    
    /// Generate full event name with camera prefix
    var eventName: String {
        return "\(EventGroup.camera)_\(rawValue)"
    }
}

// MARK: - Tracking Flash Mode Enum

/// Flash modes for event tracking
enum TrackingFlashMode: String {
    case off = "off"
    case auto = "auto"
    case on = "on"
}

// MARK: - Tracking Zoom Level Enum

/// Zoom level options for event tracking
enum TrackingZoomLevel: String {
    case ultraWide = "0.5x"
    case wide = "1x"
    case telephoto2x = "2x"
    case telephoto5x = "5x"
    
    /// Initialize from zoom factor
    init(fromFactor factor: CGFloat) {
        switch factor {
        case 0.5:
            self = .ultraWide
        case 1.0:
            self = .wide
        case 2.0:
            self = .telephoto2x
        case 5.0:
            self = .telephoto5x
        default:
            // Default to closest match
            if factor < 0.75 {
                self = .ultraWide
            } else if factor < 1.5 {
                self = .wide
            } else if factor < 3.5 {
                self = .telephoto2x
            } else {
                self = .telephoto5x
            }
        }
    }
}

// MARK: - Camera Position Enum

/// Camera position (front/back)
enum CameraPosition: String {
    case front = "front"
    case back = "back"
}

// MARK: - Selection Method Enum

/// Method used to select composition
enum SelectionMethod: String {
    case tap = "tap"
    case swipe = "swipe"
}

// MARK: - Gallery Source Enum

/// Source that opened the gallery
enum GallerySource: String {
    case photoStrip = "photo_strip"
    case button = "button"
}
