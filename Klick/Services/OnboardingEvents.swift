//
//  OnboardingEvents.swift
//  Klick
//
//  Created on 14/02/2026.
//

import Foundation

// MARK: - Onboarding Event Names

/// Feature-level event names for onboarding flow
/// Provides type safety and autocomplete for onboarding events
enum OnboardingEvent: String {
    // Flow lifecycle
    case flowStarted = "flow_started"
    case flowCompleted = "flow_completed"
    case flowAbandoned = "flow_abandoned"
    
    // Screen tracking
    case screenViewed = "screen_viewed"
    case screenCompleted = "screen_completed"
    
    // Navigation
    case screenSkipped = "screen_skipped"
    case screenBack = "screen_back"
    
    // Monetization
    case proUpsellViewed = "proupsell_viewed"
    case proUpsellUpgradeTapped = "proupsell_upgrade_tapped"
    case proUpsellSkipped = "proupsell_skipped"
    case proUpsellDeclined = "proupsell_declined"
    
    // Goal selection
    case goalSelected = "goal_selected"
    case goalConfirmed = "goal_confirmed"
    
    // Permissions
    case permissionViewed = "permission_viewed"
    case permissionRequested = "permission_requested"
    case permissionGranted = "permission_granted"
    case permissionDenied = "permission_denied"
    case permissionSettingsOpened = "permission_settings_opened"
    
    // Post-onboarding education
    case guideViewed = "guide_viewed"
    case guideDismissed = "guide_dismissed"
    case cameraQualityIntroViewed = "cameraquality_intro_viewed"
    case imagePreviewIntroViewed = "imagepreview_intro_viewed"
    
    /// Generate full event name with onboarding prefix
    var eventName: String {
        return "\(EventGroup.onboarding)_\(rawValue)"
    }
}

// MARK: - Screen Names Enum

/// Onboarding screen identifiers
enum OnboardingScreen: String {
    case welcome = "welcome"
    case composition = "composition"
    case posing = "posing"
    case editing = "editing"
    case achievement = "achievement"
    case proUpsell = "pro_upsell"
    case personalization = "personalization"
    case permission = "permission"
}

// MARK: - Permission Types Enum

/// Permission types tracked during onboarding
enum OnboardingPermissionType: String {
    case camera = "camera"
    case photoLibrary = "photo_library"
}

// MARK: - Guide Types Enum

/// Post-onboarding guide types
enum OnboardingGuideType: String {
    case introduction = "introduction"
    case cameraQuality = "camera_quality"
    case imagePreview = "image_preview"
}

// MARK: - User Goals Enum

/// User creative goals from personalization screen
enum UserCreativeGoal: String {
    case selfPortraits = "self-portraits"
    case proShots = "pro-shots"
    case aestheticFeed = "aesthetic-feed"
    case learnComposition = "learn-composition"
    
    /// Initialize from AppStorage string value
    init?(rawValue: String) {
        switch rawValue {
        case "self-portraits":
            self = .selfPortraits
        case "pro-shots":
            self = .proShots
        case "aesthetic-feed":
            self = .aestheticFeed
        case "learn-composition":
            self = .learnComposition
        default:
            return nil
        }
    }
}
