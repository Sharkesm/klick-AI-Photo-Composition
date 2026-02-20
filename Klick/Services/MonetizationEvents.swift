//
//  MonetizationEvents.swift
//  Klick
//
//  Created on 14/02/2026.
//

import Foundation
import RevenueCat

// MARK: - Paywall Events

/// Feature-level event names for paywall/sales page
/// Provides type safety and autocomplete for monetization events
enum PaywallEvent: String {
    case viewed = "viewed"
    case dismissed = "dismissed"
    case packageSelected = "package_selected"
    case subscribeTapped = "subscribe_tapped"
    case purchaseCompleted = "purchase_completed"
    case purchaseFailed = "purchase_failed"
    case purchaseInterrupted = "purchase_interrupted"
    case restoreTapped = "restore_tapped"
    case restoreCompleted = "restore_completed"
    case restoreFailed = "restore_failed"
    case successViewed = "success_viewed"
    case successContinueTapped = "success_continue_tapped"
    
    /// Generate full event name with paywall prefix
    var eventName: String {
        return "\(EventGroup.paywall)_\(rawValue)"
    }
}

// MARK: - Upgrade Prompt Events

/// Feature-level event names for upgrade prompts
enum UpgradePromptEvent: String {
    case viewed = "viewed"
    case upgradeTapped = "upgrade_tapped"
    case dismissed = "dismissed"
    
    /// Generate full event name with upgrade_prompt prefix
    var eventName: String {
        return "\(EventGroup.upgrade)_prompt_\(rawValue)"
    }
}

// MARK: - Paywall Source Enum

/// Entry points that lead to the paywall/sales page
enum PaywallSource: String {
    case topBarUpgrade = "top_bar_upgrade"
    case photoCounterBadge = "photo_counter_badge"
    case frameSettingsLiveFeedback = "frame_settings_live_feedback"
    case frameSettingsHideOverlays = "frame_settings_hide_overlays"
    case compositionPractice = "composition_practice"
    case cameraQualityPro = "camera_quality_pro"
    case imagePreviewPremiumFilter = "image_preview_premium_filter"
    case imagePreviewBackgroundBlur = "image_preview_background_blur"
    case photoLimit = "photo_limit"
    case advancedComposition = "advanced_composition"
    case upgradePrompt = "upgrade_prompt"
}

// MARK: - Upgrade Prompt Context Enum

/// Context/reason for showing upgrade prompt
enum UpgradePromptContext: String {
    case photoLimit = "photo_limit"
    case lastFreePhoto = "last_free_photo"
    case advancedComposition = "advanced_composition"
    case premiumFilter = "premium_filter"
    case backgroundBlur = "background_blur"
    case portraitPractices = "portrait_practices"
    case liveFeedback = "live_feedback"
    case hideOverlays = "hide_overlays"
    case proCameraQuality = "pro_camera_quality"
    case batchDelete = "batch_delete"
    case filterAdjustments = "filter_adjustments"
    
    /// Initialize from FeatureManager.UpgradeContext
    init(from featureContext: FeatureManager.UpgradeContext) {
        switch featureContext {
        case .photoLimit:
            self = .photoLimit
        case .lastFreePhoto:
            self = .lastFreePhoto
        case .advancedComposition:
            self = .advancedComposition
        case .premiumFilter:
            self = .premiumFilter
        case .backgroundBlur:
            self = .backgroundBlur
        case .portraitPractices:
            self = .portraitPractices
        case .liveFeedback:
            self = .liveFeedback
        case .hideOverlays:
            self = .hideOverlays
        case .proCameraQuality:
            self = .proCameraQuality
        case .batchDelete:
            self = .batchDelete
        case .filterAdjustments:
            self = .filterAdjustments
        }
    }
}

// MARK: - Package Type Enum

/// Subscription package types
enum PackageType: String {
    case weekly = "weekly"
    case monthly = "monthly"
    case annual = "annual"
    case yearly = "yearly"
    case lifetime = "lifetime"
    case unknown = "unknown"
    
    /// Initialize from RevenueCat PackageType
    init(from rcPackageType: RevenueCat.PackageType) {
        switch rcPackageType {
        case .weekly:
            self = .weekly
        case .monthly:
            self = .monthly
        case .annual:
            self = .annual
        case .lifetime:
            self = .lifetime
        default:
            self = .unknown
        }
    }
}
