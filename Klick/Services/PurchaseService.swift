//
//  PurchaseService.swift
//  Klick
//
//  Created by Manase on 18/04/2025.
//
import RevenueCat
import Combine
import Foundation

class PurchaseService: ObservableObject {
    
    static let main = PurchaseService()
    
    @Published var isSubscribed: Bool = false
    @Published var offerings: Offerings?
    
    var currentPlan: Package? {
        offerings?.current?.availablePackages.filter({ $0.packageType == .annual }).first
    }
    
    private var cancellables = Set<AnyCancellable>()
    
    init() {}
    
    enum PurchaseStatus {
        case subscribed
        case notSubscribed
        case interrupted
    }
    
    enum Entitlements: String {
        case premium = "Klick Premium"
    }
    
    static func configure() {
        Purchases.logLevel = .debug
        Purchases.configure(withAPIKey: "test_SwbyJSjRivjKDENfHzinbrEPKoG")
    }
    
    static func setupAdditionalAttributes(fullName: String?, email: String?, other: [String: String]) {
        Purchases.shared.attribution.setEmail(email)
        Purchases.shared.attribution.setDisplayName(fullName)
        Purchases.shared.attribution.setAttributes(other)
    }
    
    func refreshSubscriptionStatus() async {
        guard let customer = try? await Purchases.shared.customerInfo() else {
            return
        }
        
        /// Refreshes subscription status by checking customer owned entitlements
        let didPurchase = customer.entitlements.all[Entitlements.premium.rawValue]?.isActive ?? false
        let status: PurchaseStatus = didPurchase ? .subscribed : .notSubscribed
        await handlePurchaseStatusUpdates(status)
        
        /// Reqeust to fetch subscription offerings
        await fetchSubscriptionOfferings()
    }
    
    @discardableResult
    func fetchSubscriptionOfferings() async -> Offerings? {
        let offerings: Offerings? = await withCheckedContinuation { continuation in
            Purchases.shared.getOfferings { offerings, error in
                if let offerings = offerings {
                    continuation.resume(returning: offerings)
                    return
                }
                
                continuation.resume(returning: nil)
            }
        }
        
        await MainActor.run {
            self.offerings = offerings
        }
        
        return offerings
    }
    
    func purchase(package: Package) async -> PurchaseStatus {
        let status: PurchaseStatus = await withCheckedContinuation { continuation in
            Purchases.shared.purchase(package: package) { transaction, customer, error, userCancelled in
                let didPurchase = customer?.entitlements.all[Entitlements.premium.rawValue]?.isActive ?? false
                
                DispatchQueue.main.async { [unowned self] in
                    self.isSubscribed = didPurchase
                }
                
                if didPurchase {
                    // 🤑 Subscription purchase was successfully
                    continuation.resume(returning: .subscribed)
                } else {
                    // 😭 If user didn't cancel and there wasn't any error with the purchase, then proceed to close paywall
                    if !userCancelled && error == nil {
                        continuation.resume(returning: .notSubscribed)
                    } else {
                        continuation.resume(returning: .interrupted)
                    }
                }
            }
        }
        
        await handlePurchaseStatusUpdates(status)
        return status
    }
    
    func restorePurchases() async -> PurchaseStatus  {
        let status: PurchaseStatus = await withCheckedContinuation { continuation in
            Purchases.shared.restorePurchases { transactions, error in
                if let error = error {
                    continuation.resume(returning: .interrupted)
//                    SVLogger.main.log(message: "Error restoring purchases", info: error.localizedDescription, logLevel: .error)
                } else {
                    let didPurchase = transactions?.entitlements.all[Entitlements.premium.rawValue]?.isActive ?? false
                    continuation.resume(returning: didPurchase ? .subscribed : .notSubscribed)
//                    SVLogger.main.log(message: "Successfully restored purchases", logLevel: .success)
                }
            }
        }
        
        await handlePurchaseStatusUpdates(status)
        return status
    }
 
    @MainActor
    func handlePurchaseStatusUpdates(_ status: PurchaseStatus) {
        isSubscribed = status == .subscribed
        UserPreferenceKeys.eligibleForPremium.save(status == .subscribed)
    }
}
