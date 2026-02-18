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
