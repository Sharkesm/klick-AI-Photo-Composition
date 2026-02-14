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

// MARK: - Onboarding Event Tracking Extensions

extension EventTrackingManager {
    
    // MARK: Flow Lifecycle
    
    /// Track onboarding flow started
    /// - Parameter source: Source that triggered onboarding (default: "landing_page")
    func trackOnboardingFlowStarted(source: String = "landing_page") async {
        await track(
            eventName: OnboardingEvent.flowStarted.eventName,
            parameters: ["source": source]
        )
    }
    
    /// Track onboarding flow completed
    /// - Parameters:
    ///   - timeSpent: Total time spent in onboarding
    ///   - screensViewed: Number of screens viewed
    ///   - skippedCount: Number of screens skipped
    func trackOnboardingFlowCompleted(
        timeSpent: TimeInterval,
        screensViewed: Int,
        skippedCount: Int
    ) async {
        await track(
            eventName: OnboardingEvent.flowCompleted.eventName,
            parameters: [
                "time_spent_seconds": Int(timeSpent),
                "screens_viewed": screensViewed,
                "skipped_count": skippedCount
            ]
        )
        
        // Set user property
        await setUserProperty("onboarding_completed_at", value: Date())
    }
    
    /// Track onboarding flow abandoned
    /// - Parameters:
    ///   - lastScreen: Last screen viewed before abandonment
    ///   - timeSpent: Time spent before abandonment
    func trackOnboardingFlowAbandoned(
        lastScreen: OnboardingScreen,
        timeSpent: TimeInterval
    ) async {
        await track(
            eventName: OnboardingEvent.flowAbandoned.eventName,
            parameters: [
                "last_screen": lastScreen.rawValue,
                "time_spent_seconds": Int(timeSpent)
            ]
        )
    }
    
    // MARK: Screen Tracking
    
    /// Track onboarding screen viewed
    /// - Parameters:
    ///   - screen: Screen identifier
    ///   - screenNumber: Screen number (1-7)
    func trackOnboardingScreenViewed(
        screen: OnboardingScreen,
        screenNumber: Int
    ) async {
        await track(
            eventName: OnboardingEvent.screenViewed.eventName,
            parameters: [
                "screen_name": screen.rawValue,
                "screen_number": screenNumber
            ]
        )
    }
    
    /// Track onboarding screen completed
    /// - Parameters:
    ///   - screen: Screen identifier
    ///   - screenNumber: Screen number (1-7)
    ///   - timeOnScreen: Time spent on screen
    func trackOnboardingScreenCompleted(
        screen: OnboardingScreen,
        screenNumber: Int,
        timeOnScreen: TimeInterval
    ) async {
        await track(
            eventName: OnboardingEvent.screenCompleted.eventName,
            parameters: [
                "screen_name": screen.rawValue,
                "screen_number": screenNumber,
                "time_on_screen_seconds": Int(timeOnScreen)
            ]
        )
    }
    
    // MARK: Navigation
    
    /// Track onboarding screen skipped
    /// - Parameters:
    ///   - fromScreen: Screen being skipped from
    ///   - fromScreenNumber: Screen number being skipped from
    func trackOnboardingScreenSkipped(
        fromScreen: OnboardingScreen,
        fromScreenNumber: Int
    ) async {
        await track(
            eventName: OnboardingEvent.screenSkipped.eventName,
            parameters: [
                "from_screen_name": fromScreen.rawValue,
                "from_screen_number": fromScreenNumber
            ]
        )
    }
    
    /// Track onboarding screen back navigation
    /// - Parameters:
    ///   - fromScreen: Screen navigating back from
    ///   - toScreen: Screen navigating back to
    func trackOnboardingScreenBack(
        fromScreen: Int,
        toScreen: Int
    ) async {
        await track(
            eventName: OnboardingEvent.screenBack.eventName,
            parameters: [
                "from_screen_number": fromScreen,
                "to_screen_number": toScreen
            ]
        )
    }
    
    // MARK: Monetization
    
    /// Track Pro upsell screen viewed
    /// - Parameter cameFromSkip: Whether user arrived via skip button
    func trackOnboardingProUpsellViewed(cameFromSkip: Bool) async {
        await track(
            eventName: OnboardingEvent.proUpsellViewed.eventName,
            parameters: ["came_from_skip": cameFromSkip]
        )
    }
    
    /// Track Pro upsell upgrade button tapped
    /// - Parameter timeOnScreen: Time spent on upsell screen
    func trackOnboardingProUpsellUpgradeTapped(timeOnScreen: TimeInterval) async {
        await track(
            eventName: OnboardingEvent.proUpsellUpgradeTapped.eventName,
            parameters: ["time_on_screen_seconds": Int(timeOnScreen)]
        )
    }
    
    /// Track Pro upsell skipped
    /// - Parameter timeOnScreen: Time spent on upsell screen
    func trackOnboardingProUpsellSkipped(timeOnScreen: TimeInterval) async {
        await track(
            eventName: OnboardingEvent.proUpsellSkipped.eventName,
            parameters: ["time_on_screen_seconds": Int(timeOnScreen)]
        )
    }
    
    // MARK: Goal Selection
    
    /// Track onboarding goal selected
    /// - Parameters:
    ///   - goal: Selected creative goal
    ///   - changedSelection: Whether user changed from previous selection
    func trackOnboardingGoalSelected(
        goal: UserCreativeGoal,
        changedSelection: Bool
    ) async {
        await track(
            eventName: OnboardingEvent.goalSelected.eventName,
            parameters: [
                "goal": goal.rawValue,
                "changed_selection": changedSelection
            ]
        )
    }
    
    /// Track onboarding goal confirmed
    /// - Parameters:
    ///   - goal: Confirmed creative goal
    ///   - timeSpent: Time spent selecting goal
    func trackOnboardingGoalConfirmed(
        goal: UserCreativeGoal,
        timeSpent: TimeInterval
    ) async {
        await track(
            eventName: OnboardingEvent.goalConfirmed.eventName,
            parameters: [
                "goal": goal.rawValue,
                "time_spent_selecting_seconds": Int(timeSpent)
            ]
        )
        
        // Set user property for segmentation
        await setUserProperty("user_creative_goal", value: goal.rawValue)
    }
    
    // MARK: Permissions
    
    /// Track permission screen viewed
    /// - Parameter permissionType: Type of permission being requested
    func trackOnboardingPermissionViewed(
        permissionType: OnboardingPermissionType
    ) async {
        await track(
            eventName: OnboardingEvent.permissionViewed.eventName,
            parameters: ["permission_type": permissionType.rawValue]
        )
    }
    
    /// Track permission requested
    /// - Parameter permissionType: Type of permission being requested
    func trackOnboardingPermissionRequested(
        permissionType: OnboardingPermissionType
    ) async {
        await track(
            eventName: OnboardingEvent.permissionRequested.eventName,
            parameters: ["permission_type": permissionType.rawValue]
        )
    }
    
    /// Track permission granted
    /// - Parameters:
    ///   - permissionType: Type of permission granted
    ///   - timeToGrant: Time taken to grant permission
    func trackOnboardingPermissionGranted(
        permissionType: OnboardingPermissionType,
        timeToGrant: TimeInterval
    ) async {
        await track(
            eventName: OnboardingEvent.permissionGranted.eventName,
            parameters: [
                "permission_type": permissionType.rawValue,
                "time_to_grant_seconds": Int(timeToGrant)
            ]
        )
    }
    
    /// Track permission denied
    /// - Parameter permissionType: Type of permission denied
    func trackOnboardingPermissionDenied(
        permissionType: OnboardingPermissionType
    ) async {
        await track(
            eventName: OnboardingEvent.permissionDenied.eventName,
            parameters: ["permission_type": permissionType.rawValue]
        )
    }
    
    /// Track settings opened for permission
    /// - Parameter permissionType: Type of permission needing settings access
    func trackOnboardingPermissionSettingsOpened(
        permissionType: OnboardingPermissionType
    ) async {
        await track(
            eventName: OnboardingEvent.permissionSettingsOpened.eventName,
            parameters: ["permission_type": permissionType.rawValue]
        )
    }
    
    // MARK: Post-Onboarding Education
    
    /// Track onboarding guide viewed
    /// - Parameters:
    ///   - guideType: Type of guide being viewed
    ///   - trigger: How the guide was triggered (e.g., "auto", "manual")
    func trackOnboardingGuideViewed(
        guideType: OnboardingGuideType,
        trigger: String
    ) async {
        await track(
            eventName: OnboardingEvent.guideViewed.eventName,
            parameters: [
                "guide_type": guideType.rawValue,
                "trigger": trigger
            ]
        )
    }
    
    /// Track onboarding guide dismissed
    /// - Parameters:
    ///   - guideType: Type of guide being dismissed
    ///   - timeSpent: Time spent viewing guide
    func trackOnboardingGuideDismissed(
        guideType: OnboardingGuideType,
        timeSpent: TimeInterval
    ) async {
        await track(
            eventName: OnboardingEvent.guideDismissed.eventName,
            parameters: [
                "guide_type": guideType.rawValue,
                "time_spent_seconds": Int(timeSpent)
            ]
        )
    }
}
