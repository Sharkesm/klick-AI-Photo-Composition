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
    
    @Published var entitlement: Entitlements = .pro
    
    var currentPlan: Package? {
        offerings?.current?.availablePackages.filter({ $0.packageType == .annual }).first
    }
    
    private var cancellables = Set<AnyCancellable>()
    
    init() {}
    
    struct PurchaseResult {
        let status: PurchaseStatus
        /// The StoreKit transaction returned by RevenueCat on a successful purchase.
        /// Use this to log the GA4 `purchase` event with the correct transaction ID and price.
        let transaction: StoreTransaction?
    }

    enum PurchaseStatus {
        case subscribed
        case notSubscribed
        case interrupted
    }
    
    enum Entitlements: String {
        case pro = "Klick Pro"
        case premium = "Klick Premium"
    }
    
    static func configure() {
        #if DEBUG || DEVELOPMENT
            Purchases.logLevel = .debug
            Purchases.configure(withAPIKey: "test_SwbyJSjRivjKDENfHzinbrEPKoG")
        #else
            Purchases.configure(withAPIKey: "appl_CIlcdylBRgdYSgYQFRDibNUGbdg")
        #endif
    }
    
    static func setupAdditionalAttributes(fullName: String?, email: String?, other: [String: String]) {
        Purchases.shared.attribution.setEmail(email)
        Purchases.shared.attribution.setDisplayName(fullName)
        Purchases.shared.attribution.setAttributes(other)
    }
    
    func refreshSubscriptionStatus() async {
        guard let customer = try? await Purchases.shared.customerInfo() else {
            SVLogger.main.log(message: "Failed to fetch customer info", logLevel: .error)
            return
        }
        
        /// Refreshes subscription status by checking customer owned entitlements
        let didPurchase = customer.entitlements.all[entitlement.rawValue]?.isActive ?? false
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
                
                SVLogger.main.log(message: "Failed to fetch offerings", info: error?.localizedDescription ?? "No error description", logLevel: .error)
                continuation.resume(returning: nil)
            }
        }
        
        await MainActor.run {
            self.offerings = offerings
        }
        
        return offerings
    }
    
    func purchase(package: Package) async -> PurchaseResult {
        let result: PurchaseResult = await withCheckedContinuation { continuation in
            Purchases.shared.purchase(package: package) { transaction, customer, error, userCancelled in
                let didPurchase = customer?.entitlements.all[self.entitlement.rawValue]?.isActive ?? false

                DispatchQueue.main.async { [unowned self] in
                    self.isSubscribed = didPurchase
                }

                if didPurchase {
                    continuation.resume(returning: PurchaseResult(status: .subscribed, transaction: transaction))
                } else {
                    if !userCancelled && error == nil {
                        continuation.resume(returning: PurchaseResult(status: .notSubscribed, transaction: nil))
                    } else {
                        continuation.resume(returning: PurchaseResult(status: .interrupted, transaction: nil))
                    }
                }
            }
        }

        await handlePurchaseStatusUpdates(result.status)
        return result
    }
    
    func restorePurchases() async -> PurchaseStatus  {
        let status: PurchaseStatus = await withCheckedContinuation { continuation in
            Purchases.shared.restorePurchases { transactions, error in
                if let error = error {
                    SVLogger.main.log(message: "Error restoring purchases", info: error.localizedDescription, logLevel: .error)
                    continuation.resume(returning: .interrupted)
                } else {
                    let didPurchase = transactions?.entitlements.all[self.entitlement.rawValue]?.isActive ?? false
                    SVLogger.main.log(message: "Purchases restored successfully", logLevel: .success)
                    continuation.resume(returning: didPurchase ? .subscribed : .notSubscribed)
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
