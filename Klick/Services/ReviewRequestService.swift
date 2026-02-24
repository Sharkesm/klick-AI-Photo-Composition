//
//  ReviewRequestService.swift
//  Klick
//
//  Created by Manase on 24/02/2026.
//

import Foundation
import Combine
import UIKit
import StoreKit

class ReviewRequestService: ObservableObject {
    
    // Routes
    // Auto-tracking
    //
    // - Hive cycle completion
    // - Active tabs apart from the Expense Add-tab
    // - Logging expenses
    // -
    
    // Manual-tracking
    // - Send feedback (On settings)
    
    private let userDefaults = UserDefaults.standard
    
    private let reviewRequestLimit: Int = 40
    private let reviewRequestKey = "reviewRequestCountKey"
    private let lastReviewedVersionKey = "lastReviewedVersionKey"
    
    private(set) var reviewURL: URL? = URL(string: "https://apps.apple.com/app/id6749798728")
    
    @Published private(set) var count: Int
    
    init() {
        count = userDefaults.integer(forKey: reviewRequestKey)
    }
    
    func shouldAskForReview() -> Bool {
        let recentReviewedVersion = userDefaults.string(forKey: lastReviewedVersionKey)
        
        guard let currentVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String else {
            fatalError("Expected to find CFBundleShortVersionString in Info.plist")
        }
        
        let currentCount = userDefaults.integer(forKey: reviewRequestKey)
        let hasReachedLimit = currentCount > 0 && currentCount.isMultiple(of: reviewRequestLimit)
        let isAppNewVersion = currentVersion != recentReviewedVersion
        
        guard hasReachedLimit && isAppNewVersion else {
            return false
        }
        
        userDefaults.set(currentVersion, forKey: lastReviewedVersionKey)
        SVLogger.main.log(message: "Set review request", logLevel: .success)
        return true
    }
    
    func requestReviewIfAppropriate() {
        guard shouldAskForReview() else { return }
        guard let scene = UIApplication.shared.connectedScenes
            .first(where: { $0.activationState == .foregroundActive }) as? UIWindowScene else { return }
        SKStoreReviewController.requestReview(in: scene)
        SVLogger.main.log(message: "Requested in-app review via StoreKit", logLevel: .success)
    }
    
    func requestReviewManually() {
        guard let reviewURL = reviewURL else {
            fatalError(#function + ": Failed to construct URL for review request")
        }
        
        UIApplication.shared.open(reviewURL)
        SVLogger.main.log(message: "Requested review manually", logLevel: .info)
    }
    
    func increment() {
        count += 1
        userDefaults.set(count, forKey: reviewRequestKey)
        SVLogger.main.log(message: "Incremented review request", info: "Count to \(count)", logLevel: .info)
    }
    
    func reset() {
        count = 0
        userDefaults.set(0, forKey: reviewRequestKey)
        SVLogger.main.log(message: "Resetted review request", info: "Count to \(count)", logLevel: .info)
    }
}
