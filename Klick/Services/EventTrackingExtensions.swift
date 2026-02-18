//
//  EventTrackingExtensions.swift
//  Klick
//
//  Created on 14/02/2026.
//

import Foundation
import RevenueCat

// MARK: - EventTrackingManager Convenience Extensions

/// Type-safe convenience methods for tracking events
/// Provides autocomplete and compile-time safety for event tracking
extension EventTrackingManager {
    
    // MARK: - Onboarding Events
    
    /// Track onboarding flow started
    func trackOnboardingFlowStarted(source: String) async {
        await track(
            eventName: OnboardingEvent.flowStarted.eventName,
            parameters: ["source": source]
        )
    }
    
    /// Track onboarding screen viewed
    func trackOnboardingScreenViewed(screen: OnboardingScreen) async {
        await track(
            eventName: OnboardingEvent.screenViewed.eventName,
            parameters: ["screen": screen.rawValue]
        )
    }
    
    /// Track onboarding screen completed
    func trackOnboardingScreenCompleted(screen: OnboardingScreen) async {
        await track(
            eventName: OnboardingEvent.screenCompleted.eventName,
            parameters: ["screen": screen.rawValue]
        )
    }
    
    /// Track onboarding screen back navigation
    func trackOnboardingScreenBack(fromScreen: OnboardingScreen) async {
        await track(
            eventName: OnboardingEvent.screenBack.eventName,
            parameters: ["from_screen": fromScreen.rawValue]
        )
    }
    
    /// Track onboarding screen skipped
    func trackOnboardingScreenSkipped(screen: OnboardingScreen) async {
        await track(
            eventName: OnboardingEvent.screenSkipped.eventName,
            parameters: ["screen": screen.rawValue]
        )
    }
    
    /// Track onboarding Pro upsell viewed
    func trackOnboardingProUpsellViewed() async {
        await track(eventName: OnboardingEvent.proUpsellViewed.eventName)
    }
    
    /// Track onboarding Pro upsell upgrade tapped
    func trackOnboardingProUpsellUpgradeTapped() async {
        await track(eventName: OnboardingEvent.proUpsellUpgradeTapped.eventName)
    }
    
    /// Track onboarding Pro upsell skipped
    func trackOnboardingProUpsellSkipped() async {
        await track(eventName: OnboardingEvent.proUpsellSkipped.eventName)
    }
    
    /// Track onboarding goal selected
    func trackOnboardingGoalSelected(goal: UserCreativeGoal) async {
        await track(
            eventName: OnboardingEvent.goalSelected.eventName,
            parameters: ["goal": goal.rawValue]
        )
    }
    
    /// Track onboarding goal confirmed
    func trackOnboardingGoalConfirmed(goal: UserCreativeGoal) async {
        await track(
            eventName: OnboardingEvent.goalConfirmed.eventName,
            parameters: ["goal": goal.rawValue]
        )
    }
    
    /// Track onboarding flow completed
    func trackOnboardingFlowCompleted(completedScreens: Int, timeSpent: TimeInterval) async {
        await track(
            eventName: OnboardingEvent.flowCompleted.eventName,
            parameters: [
                "completed_screens": completedScreens,
                "time_spent_seconds": Int(timeSpent)
            ]
        )
    }
    
    /// Track onboarding permission viewed
    func trackOnboardingPermissionViewed(permissionType: OnboardingPermissionType) async {
        await track(
            eventName: OnboardingEvent.permissionViewed.eventName,
            parameters: ["permission_type": permissionType.rawValue]
        )
    }
    
    /// Track onboarding permission requested
    func trackOnboardingPermissionRequested(permissionType: OnboardingPermissionType) async {
        await track(
            eventName: OnboardingEvent.permissionRequested.eventName,
            parameters: ["permission_type": permissionType.rawValue]
        )
    }
    
    /// Track onboarding permission granted
    func trackOnboardingPermissionGranted(permissionType: OnboardingPermissionType) async {
        await track(
            eventName: OnboardingEvent.permissionGranted.eventName,
            parameters: ["permission_type": permissionType.rawValue]
        )
    }
    
    /// Track onboarding permission denied
    func trackOnboardingPermissionDenied(permissionType: OnboardingPermissionType) async {
        await track(
            eventName: OnboardingEvent.permissionDenied.eventName,
            parameters: ["permission_type": permissionType.rawValue]
        )
    }
    
    /// Track onboarding permission settings opened
    func trackOnboardingPermissionSettingsOpened(permissionType: OnboardingPermissionType) async {
        await track(
            eventName: OnboardingEvent.permissionSettingsOpened.eventName,
            parameters: ["permission_type": permissionType.rawValue]
        )
    }
    
    /// Track onboarding guide viewed
    func trackOnboardingGuideViewed(guideType: OnboardingGuideType) async {
        await track(
            eventName: OnboardingEvent.guideViewed.eventName,
            parameters: ["guide_type": guideType.rawValue]
        )
    }
    
    /// Track onboarding guide dismissed
    func trackOnboardingGuideDismissed(guideType: OnboardingGuideType, timeSpent: TimeInterval) async {
        await track(
            eventName: OnboardingEvent.guideDismissed.eventName,
            parameters: [
                "guide_type": guideType.rawValue,
                "time_spent_seconds": Int(timeSpent)
            ]
        )
    }
    
    // MARK: - Monetization Events
    
    /// Track paywall viewed
    func trackPaywallViewed(source: PaywallSource, offeringsCount: Int, defaultPackage: String?) async {
        var parameters: [String: Any] = [
            "source": source.rawValue,
            "offerings_count": offeringsCount
        ]
        if let defaultPackage = defaultPackage {
            parameters["default_package"] = defaultPackage
        }
        await track(eventName: PaywallEvent.viewed.eventName, parameters: parameters)
    }
    
    /// Track paywall dismissed
    func trackPaywallDismissed(source: PaywallSource, timeSpent: TimeInterval, packageSelected: Bool) async {
        await track(
            eventName: PaywallEvent.dismissed.eventName,
            parameters: [
                "source": source.rawValue,
                "time_spent_seconds": Int(timeSpent),
                "package_selected": packageSelected
            ]
        )
    }
    
    /// Track paywall package selected
    func trackPaywallPackageSelected(package: Package) async {
        let packageType = PackageType(from: package.packageType)
        await track(
            eventName: PaywallEvent.packageSelected.eventName,
            parameters: [
                "package_id": package.identifier,
                "package_type": packageType.rawValue,
                "price": package.storeProduct.price,
                "currency": package.storeProduct.currencyCode ?? "USD"
            ]
        )
    }
    
    /// Track paywall subscribe tapped
    func trackPaywallSubscribeTapped(package: Package) async {
        let packageType = PackageType(from: package.packageType)
        await track(
            eventName: PaywallEvent.subscribeTapped.eventName,
            parameters: [
                "package_id": package.identifier,
                "package_type": packageType.rawValue,
                "price": package.storeProduct.price,
                "currency": package.storeProduct.currencyCode ?? "USD"
            ]
        )
    }
    
    /// Track paywall purchase completed
    func trackPaywallPurchaseCompleted(package: Package, timeToComplete: TimeInterval) async {
        let packageType = PackageType(from: package.packageType)
        await track(
            eventName: PaywallEvent.purchaseCompleted.eventName,
            parameters: [
                "product_id": package.storeProduct.productIdentifier,
                "package_type": packageType.rawValue,
                "price": package.storeProduct.price,
                "currency": package.storeProduct.currencyCode ?? "USD",
                "time_to_purchase_seconds": Int(timeToComplete)
            ]
        )
    }
    
    /// Track paywall purchase failed
    func trackPaywallPurchaseFailed(error: Error, packageId: String?) async {
        var parameters: [String: Any] = [
            "error_message": error.localizedDescription
        ]
        if let packageId = packageId {
            parameters["package_id"] = packageId
        }
        await track(eventName: PaywallEvent.purchaseFailed.eventName, parameters: parameters)
    }
    
    /// Track paywall purchase interrupted
    func trackPaywallPurchaseInterrupted(package: Package) async {
        let packageType = PackageType(from: package.packageType)
        await track(
            eventName: PaywallEvent.purchaseInterrupted.eventName,
            parameters: [
                "package_id": package.identifier,
                "package_type": packageType.rawValue
            ]
        )
    }
    
    /// Track paywall restore tapped
    func trackPaywallRestoreTapped() async {
        await track(eventName: PaywallEvent.restoreTapped.eventName)
    }
    
    /// Track paywall restore completed
    func trackPaywallRestoreCompleted(entitlements: [String]) async {
        await track(
            eventName: PaywallEvent.restoreCompleted.eventName,
            parameters: ["entitlements_restored": entitlements.joined(separator: ", ")]
        )
    }
    
    /// Track paywall restore failed
    func trackPaywallRestoreFailed(error: Error) async {
        await track(
            eventName: PaywallEvent.restoreFailed.eventName,
            parameters: ["error_message": error.localizedDescription]
        )
    }
    
    /// Track paywall success viewed
    func trackPaywallSuccessViewed(packageType: PackageType, source: PaywallSource) async {
        await track(
            eventName: PaywallEvent.successViewed.eventName,
            parameters: [
                "package_type": packageType.rawValue,
                "source": source.rawValue
            ]
        )
    }
    
    /// Track paywall success continue tapped
    func trackPaywallSuccessContinueTapped(packageType: PackageType) async {
        await track(
            eventName: PaywallEvent.successContinueTapped.eventName,
            parameters: ["package_type": packageType.rawValue]
        )
    }
    
    /// Track upgrade prompt viewed
    func trackUpgradePromptViewed(context: UpgradePromptContext) async {
        await track(
            eventName: UpgradePromptEvent.viewed.eventName,
            parameters: ["context": context.rawValue]
        )
    }
    
    /// Track upgrade prompt upgrade tapped
    func trackUpgradePromptUpgradeTapped(context: UpgradePromptContext, timeOnScreen: TimeInterval) async {
        await track(
            eventName: UpgradePromptEvent.upgradeTapped.eventName,
            parameters: [
                "context": context.rawValue,
                "time_on_screen_seconds": Int(timeOnScreen)
            ]
        )
    }
    
    /// Track upgrade prompt dismissed
    func trackUpgradePromptDismissed(context: UpgradePromptContext, timeOnScreen: TimeInterval) async {
        await track(
            eventName: UpgradePromptEvent.dismissed.eventName,
            parameters: [
                "context": context.rawValue,
                "time_on_screen_seconds": Int(timeOnScreen)
            ]
        )
    }
    
    // MARK: - Camera Events
    
    /// Track photo captured
    func trackPhotoCaptured(
        compositionType: CompositionType,
        cameraQuality: CameraQuality,
        flashMode: TrackingFlashMode,
        zoomLevel: TrackingZoomLevel,
        facesDetected: Int,
        compositionScore: Double?
    ) async {
        var parameters: [String: Any] = [
            "composition_type": compositionType.rawValue,
            "camera_quality": cameraQuality.rawValue,
            "flash_mode": flashMode.rawValue,
            "zoom_level": zoomLevel.rawValue,
            "faces_detected": facesDetected
        ]
        if let score = compositionScore {
            parameters["composition_score"] = score
        }
        await track(eventName: CameraEvent.photoCaptured.eventName, parameters: parameters)
    }
    
    /// Track composition selected
    func trackCompositionSelected(compositionType: CompositionType, selectionMethod: SelectionMethod) async {
        await track(
            eventName: CameraEvent.compositionSelected.eventName,
            parameters: [
                "composition_type": compositionType.rawValue,
                "selection_method": selectionMethod.rawValue
            ]
        )
    }
    
    /// Track composition swiped
    func trackCompositionSwiped(
        fromComposition: CompositionType,
        toComposition: CompositionType,
        swipeDirection: String
    ) async {
        await track(
            eventName: CameraEvent.compositionSwiped.eventName,
            parameters: [
                "from_composition": fromComposition.rawValue,
                "to_composition": toComposition.rawValue,
                "swipe_direction": swipeDirection
            ]
        )
    }
    
    /// Track flash changed
    func trackFlashChanged(mode: TrackingFlashMode) async {
        await track(
            eventName: CameraEvent.flashChanged.eventName,
            parameters: ["mode": mode.rawValue]
        )
    }
    
    /// Track zoom changed
    func trackZoomChanged(level: TrackingZoomLevel) async {
        await track(
            eventName: CameraEvent.zoomChanged.eventName,
            parameters: ["zoom_level": level.rawValue]
        )
    }
    
    /// Track camera quality selected
    func trackCameraQualitySelected(quality: CameraQuality, wasGated: Bool) async {
        await track(
            eventName: CameraEvent.qualitySelected.eventName,
            parameters: [
                "quality": quality.rawValue,
                "was_gated": wasGated
            ]
        )
    }
    
    /// Track camera flipped
    func trackCameraFlipped(toCamera: CameraPosition) async {
        await track(
            eventName: CameraEvent.cameraFlipped.eventName,
            parameters: ["to_camera": toCamera.rawValue]
        )
    }
    
    /// Track focus tapped
    func trackFocusTapped(x: Double, y: Double) async {
        await track(
            eventName: CameraEvent.focusTapped.eventName,
            parameters: [
                "x": x,
                "y": y
            ]
        )
    }
    
    /// Track camera screen viewed
    func trackCameraScreenViewed(sessionId: String) async {
        await track(
            eventName: CameraEvent.screenViewed.eventName,
            parameters: ["session_id": sessionId]
        )
    }
    
    /// Track camera settings opened
    func trackCameraSettingsOpened() async {
        await track(eventName: CameraEvent.settingsOpened.eventName)
    }
    
    /// Track photo album opened from camera
    func trackCameraPhotoAlbumOpened(photoCount: Int) async {
        await track(
            eventName: CameraEvent.photoAlbumOpened.eventName,
            parameters: ["photo_count": photoCount]
        )
    }
    
    /// Track composition practice opened
    func trackCameraPracticeOpened(compositionType: CompositionType) async {
        await track(
            eventName: CameraEvent.practiceOpened.eventName,
            parameters: ["composition_type": compositionType.rawValue]
        )
    }
    
    // MARK: - Gallery Events
    
    /// Track gallery viewed
    func trackGalleryViewed(photoCount: Int, source: GallerySource) async {
        await track(
            eventName: ScreenEvent.galleryViewed.eventName,
            parameters: [
                "photo_count": photoCount,
                "source": source.rawValue
            ]
        )
    }
    
    /// Track gallery dismissed
    func trackGalleryDismissed(timeSpent: TimeInterval, photosViewed: Int) async {
        await track(
            eventName: GalleryEvent.dismissed.eventName,
            parameters: [
                "time_spent_seconds": Int(timeSpent),
                "photos_viewed": photosViewed
            ]
        )
    }
    
    /// Track gallery photo selected
    func trackGalleryPhotoSelected(photoId: String, positionInGrid: Int) async {
        await track(
            eventName: GalleryEvent.photoSelected.eventName,
            parameters: [
                "photo_id": photoId,
                "position_in_grid": positionInGrid
            ]
        )
    }
    
    /// Track gallery selection mode toggled
    func trackGallerySelectionModeToggled(enabled: Bool) async {
        await track(
            eventName: GalleryEvent.selectionModeToggled.eventName,
            parameters: ["enabled": enabled]
        )
    }
    
    /// Track photos deleted from gallery
    func trackPhotosDeleted(count: Int, selectionMethod: PhotoSelectionMethod) async {
        await track(
            eventName: GalleryEvent.photosDeleted.eventName,
            parameters: [
                "count": count,
                "selection_method": selectionMethod.rawValue
            ]
        )
    }
    
    /// Track photo detail viewed
    func trackPhotoDetailViewed(photoId: String, compositionType: String?, framingScore: Double?) async {
        var parameters: [String: Any] = ["photo_id": photoId]
        if let compositionType = compositionType {
            parameters["composition_type"] = compositionType
        }
        if let framingScore = framingScore {
            parameters["framing_score"] = framingScore
        }
        await track(eventName: ScreenEvent.photoDetailViewed.eventName, parameters: parameters)
    }
    
    /// Track photo detail dismissed
    func trackPhotoDetailDismissed(timeSpent: TimeInterval) async {
        await track(
            eventName: PhotoEvent.detailDismissed.eventName,
            parameters: ["time_spent_seconds": Int(timeSpent)]
        )
    }
    
    /// Track photo saved to library
    func trackPhotoSavedToLibrary(photoId: String, format: String, fileSize: Int) async {
        await track(
            eventName: PhotoEvent.savedToLibrary.eventName,
            parameters: [
                "photo_id": photoId,
                "format": format,
                "file_size_bytes": fileSize
            ]
        )
    }
    
    // MARK: - Image Preview Events
    
    /// Track image preview viewed
    func trackImagePreviewViewed(compositionType: String?, cameraQuality: CameraQuality) async {
        var parameters: [String: Any] = ["camera_quality": cameraQuality.rawValue]
        if let compositionType = compositionType {
            parameters["composition_type"] = compositionType
        }
        await track(eventName: ScreenEvent.imagePreviewViewed.eventName, parameters: parameters)
    }
    
    /// Track photo saved from preview
    func trackPhotoSaved(
        filterApplied: String?,
        blurApplied: Bool,
        adjustmentsMade: Bool,
        timeToSave: TimeInterval
    ) async {
        var parameters: [String: Any] = [
            "blur_applied": blurApplied,
            "adjustments_made": adjustmentsMade,
            "time_to_save_seconds": Int(timeToSave)
        ]
        if let filter = filterApplied {
            parameters["filter_applied"] = filter
        }
        await track(eventName: ImagePreviewEvent.photoSaved.eventName, parameters: parameters)
    }
    
    /// Track photo discarded from preview
    func trackPhotoDiscarded(timeSpent: TimeInterval, filterApplied: String?, blurApplied: Bool) async {
        var parameters: [String: Any] = [
            "time_spent_seconds": Int(timeSpent),
            "blur_applied": blurApplied
        ]
        if let filter = filterApplied {
            parameters["filter_applied"] = filter
        }
        await track(eventName: ImagePreviewEvent.photoDiscarded.eventName, parameters: parameters)
    }
    
    /// Track effects panel opened
    func trackEffectsPanelOpened() async {
        await track(eventName: ImagePreviewEvent.effectsPanelOpened.eventName)
    }
    
    /// Track effects panel closed
    func trackEffectsPanelClosed(filterApplied: String?, timeSpent: TimeInterval) async {
        var parameters: [String: Any] = ["time_spent_seconds": Int(timeSpent)]
        if let filter = filterApplied {
            parameters["filter_applied"] = filter
        }
        await track(eventName: ImagePreviewEvent.effectsPanelClosed.eventName, parameters: parameters)
    }
    
    /// Track filter pack selected
    func trackFilterPackSelected(packName: FilterPack) async {
        await track(
            eventName: FilterEvent.packSelected.eventName,
            parameters: ["pack_name": packName.rawValue]
        )
    }
    
    /// Track filter applied
    func trackFilterApplied(filterName: String, filterPack: FilterPack, isPremium: Bool, wasGated: Bool) async {
        await track(
            eventName: FilterEvent.applied.eventName,
            parameters: [
                "filter_name": filterName,
                "filter_pack": filterPack.rawValue,
                "is_premium": isPremium,
                "was_gated": wasGated
            ]
        )
    }
    
    /// Track filter removed
    func trackFilterRemoved(previousFilter: String) async {
        await track(
            eventName: FilterEvent.removed.eventName,
            parameters: ["previous_filter": previousFilter]
        )
    }
    
    /// Track filter adjusted
    func trackFilterAdjusted(adjustmentType: AdjustmentType, value: Double) async {
        await track(
            eventName: FilterEvent.adjusted.eventName,
            parameters: [
                "adjustment_type": adjustmentType.rawValue,
                "value": value
            ]
        )
    }
    
    /// Track background blur toggled
    func trackBlurToggled(enabled: Bool, wasGated: Bool) async {
        await track(
            eventName: ImagePreviewEvent.blurToggled.eventName,
            parameters: [
                "enabled": enabled,
                "was_gated": wasGated
            ]
        )
    }
    
    /// Track background blur adjusted
    func trackBlurAdjusted(intensity: Double) async {
        await track(
            eventName: ImagePreviewEvent.blurAdjusted.eventName,
            parameters: ["intensity": intensity]
        )
    }
    
    /// Track ProRAW toggle
    func trackProRawToggled(toMode: ImageProcessingMode) async {
        await track(
            eventName: ImagePreviewEvent.proRawToggled.eventName,
            parameters: ["to_mode": toMode.rawValue]
        )
    }
    
    /// Track share screen viewed
    func trackShareScreenViewed(compositionType: String?, filterApplied: String?) async {
        var parameters: [String: Any] = [:]
        if let compositionType = compositionType {
            parameters["composition_type"] = compositionType
        }
        if let filter = filterApplied {
            parameters["filter_applied"] = filter
        }
        await track(eventName: ScreenEvent.shareViewed.eventName, parameters: parameters)
    }
    
    /// Track photo shared
    func trackPhotoShared(shareDestination: String?) async {
        var parameters: [String: Any] = [:]
        if let destination = shareDestination {
            parameters["share_destination"] = destination
        }
        await track(eventName: PhotoEvent.shared.eventName, parameters: parameters)
    }
    
    /// Track share screen dismissed
    func trackShareScreenDismissed(timeSpent: TimeInterval, shared: Bool) async {
        await track(
            eventName: "share_screen_dismissed",
            parameters: [
                "time_spent_seconds": Int(timeSpent),
                "shared": shared
            ]
        )
    }
    
    // MARK: - Settings Events
    
    /// Track settings frame viewed
    func trackSettingsFrameViewed() async {
        await track(eventName: SettingsEvent.frameViewed.eventName)
    }
    
    /// Track settings frame dismissed
    func trackSettingsFrameDismissed(timeSpent: TimeInterval) async {
        await track(
            eventName: SettingsEvent.frameDismissed.eventName,
            parameters: ["time_spent_seconds": Int(timeSpent)]
        )
    }
    
    /// Track facial recognition toggled
    func trackSettingsFacialRecognitionToggled(enabled: Bool) async {
        await track(
            eventName: SettingsEvent.facialRecognitionToggled.eventName,
            parameters: ["enabled": enabled]
        )
    }
    
    /// Track live analysis toggled
    func trackSettingsLiveAnalysisToggled(enabled: Bool) async {
        await track(
            eventName: SettingsEvent.liveAnalysisToggled.eventName,
            parameters: ["enabled": enabled]
        )
    }
    
    /// Track live feedback toggled
    func trackSettingsLiveFeedbackToggled(enabled: Bool, wasGated: Bool) async {
        await track(
            eventName: SettingsEvent.liveFeedbackToggled.eventName,
            parameters: [
                "enabled": enabled,
                "was_gated": wasGated
            ]
        )
    }
    
    /// Track hide overlays toggled
    func trackSettingsHideOverlaysToggled(enabled: Bool, wasGated: Bool) async {
        await track(
            eventName: SettingsEvent.hideOverlaysToggled.eventName,
            parameters: [
                "enabled": enabled,
                "was_gated": wasGated
            ]
        )
    }
    
    /// Track how Klick works tapped
    func trackSettingsHowKlickWorksTapped() async {
        await track(eventName: SettingsEvent.howKlickWorksTapped.eventName)
    }
    
    /// Track legal terms tapped
    func trackLegalTermsTapped(source: String) async {
        await track(
            eventName: LegalEvent.termsTapped.eventName,
            parameters: ["source": source]
        )
    }
    
    /// Track legal privacy tapped
    func trackLegalPrivacyTapped(source: String) async {
        await track(
            eventName: LegalEvent.privacyTapped.eventName,
            parameters: ["source": source]
        )
    }
    
    // MARK: - Practice Events
    
    /// Track practice mode viewed
    func trackPracticeViewed(compositionType: String) async {
        await track(
            eventName: PracticeEvent.viewed.eventName,
            parameters: ["composition_type": compositionType]
        )
    }
    
    /// Track practice mode dismissed
    func trackPracticeDismissed(compositionType: String, timeSpent: TimeInterval) async {
        await track(
            eventName: PracticeEvent.dismissed.eventName,
            parameters: [
                "composition_type": compositionType,
                "time_spent_seconds": Int(timeSpent)
            ]
        )
    }
    
    /// Track practice example selected
    func trackPracticeExampleSelected(compositionType: String, exampleType: String) async {
        await track(
            eventName: PracticeEvent.exampleSelected.eventName,
            parameters: [
                "composition_type": compositionType,
                "example_type": exampleType
            ]
        )
    }
    
    // MARK: - Camera Quality Intro Events
    
    /// Track camera quality intro viewed
    func trackCameraQualityIntroViewed() async {
        await track(eventName: CameraQualityIntroEvent.viewed.eventName)
    }
    
    /// Track camera quality intro dismissed
    func trackCameraQualityIntroDismissed(timeSpent: TimeInterval) async {
        await track(
            eventName: CameraQualityIntroEvent.dismissed.eventName,
            parameters: ["time_spent_seconds": Int(timeSpent)]
        )
    }
    
    // MARK: - Error/Alert Events
    
    /// Track storage full alert shown
    func trackStorageFullAlertShown(currentPhotoCount: Int, limit: Int) async {
        await track(
            eventName: AlertEvent.storageFullShown.eventName,
            parameters: [
                "current_photo_count": currentPhotoCount,
                "limit": limit
            ]
        )
    }
    
    /// Track camera permission denied
    func trackCameraPermissionDenied(source: String) async {
        await track(
            eventName: AlertEvent.cameraPermissionDenied.eventName,
            parameters: ["source": source]
        )
    }
}
