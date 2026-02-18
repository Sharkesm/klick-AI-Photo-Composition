//
//  PhotoEvents.swift
//  Klick
//
//  Created on 18/02/2026.
//

import Foundation

// MARK: - Gallery Event Names

/// Feature-level event names for photo gallery
enum GalleryEvent: String {
    case viewed = "viewed"
    case dismissed = "dismissed"
    case photoSelected = "photo_selected"
    case addPhotoTapped = "add_photo_tapped"
    case selectionModeToggled = "selection_mode_toggled"
    case photosDeleted = "photos_deleted"
    
    /// Generate full event name with gallery prefix
    var eventName: String {
        return "gallery_\(rawValue)"
    }
}

// MARK: - Photo Event Names

/// Feature-level event names for photo actions
enum PhotoEvent: String {
    case detailViewed = "detail_viewed"
    case detailDismissed = "detail_dismissed"
    case savedToLibrary = "saved_to_library"
    case saved = "saved"
    case discarded = "discarded"
    case shared = "shared"
    
    /// Generate full event name with photo prefix
    var eventName: String {
        return "\(EventGroup.photo)_\(rawValue)"
    }
}

// MARK: - Screen Event Names

/// Screen-level event names
enum ScreenEvent: String {
    case galleryViewed = "gallery_viewed"
    case photoDetailViewed = "photo_detail_viewed"
    case imagePreviewViewed = "image_preview_viewed"
    case shareViewed = "share_viewed"
    case settingsFrameViewed = "settings_frame_viewed"
    case practiceViewed = "practice_viewed"
    
    /// Generate full event name with screen prefix
    var eventName: String {
        return "\(EventGroup.screen)_\(rawValue)"
    }
}

// MARK: - Selection Method Enum

/// Method used for photo deletion
enum PhotoSelectionMethod: String {
    case single = "single"
    case bulk = "bulk"
}

// MARK: - Settings Event Names

/// Feature-level event names for settings
enum SettingsEvent: String {
    case frameViewed = "frame_viewed"
    case frameDismissed = "frame_dismissed"
    case facialRecognitionToggled = "facial_recognition_toggled"
    case liveAnalysisToggled = "live_analysis_toggled"
    case liveFeedbackToggled = "live_feedback_toggled"
    case hideOverlaysToggled = "hide_overlays_toggled"
    case howKlickWorksTapped = "how_klick_works_tapped"
    
    /// Generate full event name with settings prefix
    var eventName: String {
        return "settings_\(rawValue)"
    }
}

// MARK: - Legal Event Names

/// Feature-level event names for legal links
enum LegalEvent: String {
    case termsTapped = "terms_tapped"
    case privacyTapped = "privacy_tapped"
    
    /// Generate full event name with legal prefix
    var eventName: String {
        return "legal_\(rawValue)"
    }
}

// MARK: - Practice Event Names

/// Feature-level event names for composition practice mode
enum PracticeEvent: String {
    case viewed = "viewed"
    case dismissed = "dismissed"
    case exampleSelected = "example_selected"
    
    /// Generate full event name with practice prefix
    var eventName: String {
        return "practice_\(rawValue)"
    }
}

// MARK: - Camera Quality Intro Event Names

/// Feature-level event names for camera quality intro
enum CameraQualityIntroEvent: String {
    case viewed = "viewed"
    case dismissed = "dismissed"
    
    /// Generate full event name with camera_quality_intro prefix
    var eventName: String {
        return "camera_quality_intro_\(rawValue)"
    }
}

// MARK: - Error/Alert Event Names

/// Feature-level event names for errors and alerts
enum AlertEvent: String {
    case storageFullShown = "storage_full_alert_shown"
    case cameraPermissionDenied = "camera_permission_denied"
    
    /// Generate full event name (already complete)
    var eventName: String {
        return rawValue
    }
}
