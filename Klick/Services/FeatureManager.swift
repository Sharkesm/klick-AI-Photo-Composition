//
//  FeatureManager.swift
//  Klick
//
//  Feature gating and subscription management
//

import Foundation
import SwiftUI
import Combine

/// Central manager for freemium feature gating
class FeatureManager: ObservableObject {
    static let shared = FeatureManager()
    
    // MARK: - Constants
    
    /// Maximum number of photos allowed in free tier
    private(set) var maxFreePhotos = 2
    
    // MARK: - Published State
    
    /// Whether user has Pro subscription
    @Published var isPro: Bool = false
    
    /// Number of photos captured (used for trial period)
    @Published var capturedPhotoCount: Int = 0
    
    // MARK: - Private State
    
    private var cancellables = Set<AnyCancellable>()
    private let userDefaults = UserDefaults.standard
    private let photoCountKey = "com.klick.photoCount"
    
    // MARK: - Computed Properties
    
    /// Whether user is in trial period (first 10 photos)
    var isInTrialPeriod: Bool {
        capturedPhotoCount < maxFreePhotos
    }
    
    /// Whether user can capture more photos
    var canCapture: Bool {
        isPro || capturedPhotoCount < maxFreePhotos
    }
    
    /// Whether user can use advanced composition types (Center Framing, Symmetry)
    var canUseAdvancedComposition: Bool {
        isPro || isInTrialPeriod
    }
    
    /// Whether user can use premium filters (26 filters beyond the 3 free ones)
    var canUsePremiumFilters: Bool {
        isPro || isInTrialPeriod
    }
    
    /// Whether user can use filter adjustments (intensity, brightness, warmth)
    var canUseFilterAdjustments: Bool {
        isPro || isInTrialPeriod
    }
    
    /// Whether user can batch delete photos
    var canBatchDelete: Bool {
        isPro
    }
    
    /// Whether user can hide overlays
    var canHideOverlays: Bool {
        isPro || isInTrialPeriod
    }
    
    // REMOVED: Watermark feature temporarily disabled due to memory consumption
    // /// Whether photos should have watermark
    // var shouldShowWatermark: Bool {
    //     !isPro
    // }
    
    /// Whether user can save to photo library
    var canSaveToPhotoLibrary: Bool {
        isPro || capturedPhotoCount < maxFreePhotos
    }
    
    /// Whether user can use Pro camera quality (RAW+Processed)
    var canUseProCameraQuality: Bool {
        isPro
    }
    
    /// Remaining photos in trial
    var remainingTrialPhotos: Int {
        max(0, maxFreePhotos - capturedPhotoCount)
    }
    
    /// Progress through trial (0.0 to 1.0)
    var trialProgress: Double {
        min(1.0, Double(capturedPhotoCount) / Double(maxFreePhotos))
    }
    
    // MARK: - Free Filters (Always Available)
    
    /// Number of free filters per pack
    private let freeFiltersPerPack = 2
    
    /// Check if a specific filter is available
    /// - Parameters:
    ///   - id: Filter ID
    ///   - pack: Filter pack the filter belongs to
    /// - Returns: True if filter is available (first 3 of pack, or Pro/trial period)
    func canUseFilter(id: String, pack: FilterPack) -> Bool {
        // Pro users or users in trial period can use all filters
        if isPro || isInTrialPeriod {
            return true
        }
        
        // For free users, check if filter is in first 3 of its pack
        let packFilters = FilterManager.shared.filters(for: pack)
        let filterIndex = packFilters.firstIndex { $0.id == id }
        
        // If filter not found, deny access
        guard let index = filterIndex else {
            return false
        }
        
        // First 3 filters (indices 0, 1, 2) are free
        return index < freeFiltersPerPack
    }
    
    /// Legacy method for backward compatibility (checks all packs)
    /// - Note: This method is less efficient. Use canUseFilter(id:pack:) when pack is known.
    func canUseFilter(id: String) -> Bool {
        // Pro users or users in trial period can use all filters
        if isPro || isInTrialPeriod {
            return true
        }
        
        // Check all packs to find the filter
        for pack in FilterPack.allCases {
            let packFilters = FilterManager.shared.filters(for: pack)
            if let index = packFilters.firstIndex(where: { $0.id == id }) {
                // First 3 filters (indices 0, 1, 2) are free
                return index < freeFiltersPerPack
            }
        }
        
        // Filter not found in any pack
        return false
    }
    
    // MARK: - Initialization
    
    private init() {
        // Load persisted photo count
        capturedPhotoCount = userDefaults.integer(forKey: photoCountKey)
        
        // Subscribe to PurchaseService for Pro status
        PurchaseService.main.$isSubscribed
            .sink { [weak self] isSubscribed in
                self?.isPro = isSubscribed
                print("📊 FeatureManager: Pro status updated to \(isSubscribed)")
            }
            .store(in: &cancellables)
        
        print("📊 FeatureManager initialized - Photo count: \(capturedPhotoCount), Pro: \(isPro)")
    }
    
    // MARK: - Photo Count Management
    
    /// Update photo count (called by PhotoManager)
    func updatePhotoCount(_ count: Int) {
        guard count != capturedPhotoCount else { return }
        
        capturedPhotoCount = count
        userDefaults.set(count, forKey: photoCountKey)
        
        print("📊 FeatureManager: Photo count updated to \(count)")
        
        // Post notification for UI updates
        NotificationCenter.default.post(
            name: .photoCountDidChange,
            object: nil,
            userInfo: ["count": count]
        )
        
        // Check if user just hit the limit
        if count == maxFreePhotos && !isPro {
            NotificationCenter.default.post(
                name: .trialLimitReached,
                object: nil
            )
        }
    }
    
    /// Increment photo count
    func incrementPhotoCount() {
        updatePhotoCount(capturedPhotoCount + 1)
    }
    
    /// Decrement photo count (when photo is deleted)
    func decrementPhotoCount() {
        updatePhotoCount(max(0, capturedPhotoCount - 1))
    }
    
    // MARK: - Upgrade Prompts
    
    enum UpgradeContext: String {
        case photoLimit = "photo_limit"
        case advancedComposition = "advanced_composition"
        case premiumFilter = "premium_filter"
        case filterAdjustments = "filter_adjustments"
        case batchDelete = "batch_delete"
        case hideOverlays = "hide_overlays"
        // REMOVED: Watermark feature temporarily disabled due to memory consumption
        // case watermarkRemoval = "watermark_removal"
        case proCameraQuality = "pro_camera_quality"
    }
    
    /// Show upgrade prompt for specific context
    func showUpgradePrompt(context: UpgradeContext) {
        print("💎 FeatureManager: Showing upgrade prompt for \(context.rawValue)")
        
        NotificationCenter.default.post(
            name: .showUpgradePrompt,
            object: nil,
            userInfo: ["context": context.rawValue]
        )
    }
    
    // MARK: - Debug Helpers
    
    /// Reset photo count (for testing)
    func resetPhotoCount() {
        updatePhotoCount(0)
        print("🔄 FeatureManager: Photo count reset to 0")
    }
    
    /// Print current feature status
    func printFeatureStatus() {
        print("""
        📊 FeatureManager Status:
        - Pro: \(isPro)
        - Photo Count: \(capturedPhotoCount)/\(maxFreePhotos)
        - In Trial: \(isInTrialPeriod)
        - Can Capture: \(canCapture)
        - Can Use Advanced Composition: \(canUseAdvancedComposition)
        - Can Use Premium Filters: \(canUsePremiumFilters)
        """)
    }
}

// MARK: - Notification Names

extension Notification.Name {
    static let photoCountDidChange = Notification.Name("com.klick.photoCountDidChange")
    static let trialLimitReached = Notification.Name("com.klick.trialLimitReached")
    static let showUpgradePrompt = Notification.Name("com.klick.showUpgradePrompt")
}

