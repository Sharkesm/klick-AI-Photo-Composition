//
//  SalesPageView.swift
//  Klick
//
//  Created by Manase on 30/09/2025.
//

import SwiftUI
import RevenueCat

public struct SalesPageView: View {
    
    private let source: PaywallSource
    
    @Environment(\.dismiss) var dismiss
    @Environment(\.openURL) private var openURL
    
    private var purchaseService: PurchaseService = .main
    
    @State private var currentOffering: Offering?
    @State private var currentPlan: Package?
    @State private var selectedPackage: Package?
    @State private var isPurchasing: Bool = false
    @State private var showSuccessPage: Bool = false
    @State private var fadeOutSalesContent: Bool = false
    
    // Event tracking state
    @State private var viewStartTime: Date = Date()
    @State private var selectedPackageTime: Date?
    
    init(source: PaywallSource) {
        self.source = source
    }
    
    public var body: some View {
        ZStack {
            // Background
            Color.black
                .ignoresSafeArea()
            
            if !showSuccessPage {
                // Sales page content
                salesPageContent
                    .opacity(fadeOutSalesContent ? 0 : 1)
                    .animation(.easeOut(duration: 0.6), value: fadeOutSalesContent)
            } else {
                // Success page content
                SuccessSalesPageView(
                    packageType: selectedPackage.map { PackageType(from: $0.packageType) } ?? .unknown,
                    source: source,
                    onComplete: {
                        dismiss()
                    }
                )
                .transition(.opacity)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .ignoresSafeArea()
        .onAppear {
            viewStartTime = Date()
            
            /// Fetch subscription offerings
            currentOffering = purchaseService.offerings?.current
            currentPlan = purchaseService.currentPlan
            
            /// Set default selection to annual/yearly package
            if let offering = currentOffering {
                selectedPackage = offering.annual ?? offering.availablePackages.first
            }
            
            // Track paywall viewed
            Task {
                await EventTrackingManager.shared.trackPaywallViewed(
                    source: source,
                    offeringsCount: currentOffering?.availablePackages.count ?? 0,
                    defaultPackage: selectedPackage.map { PackageType(from: $0.packageType).rawValue }
                )
            }
        }
    }
    
    private var salesPageContent: some View {
        ZStack(alignment: .top) {
            coverImageView
        
            VStack(alignment: .leading, spacing: 30) {
                Spacer()
                headlineView
                subscriptionOfferView
                subscriptionButton
            }
            .padding(.horizontal, 40)
            .padding(.bottom, 28)
            .frame(maxWidth: .infinity)
            
            headerView
        }
    }
    
    private var coverImageView: some View {
        ZStack(alignment: .bottom) {
            Image(.sales1)
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(maxWidth: .infinity)
            
            LinearGradient(
                stops: [
                    .init(color: Color.clear, location: 0),
                    .init(color: Color.black.opacity(0.6), location: 0.3),
                    .init(color: Color.black.opacity(0.7), location: 0.6),
                    .init(color: Color.black, location: 1)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .frame(height: 200)
        }
        .frame(height: 260)
    }
    
    private var headerView: some View {
        HStack {
            Spacer()
            
            Button(action: {
                // Track paywall dismissed
                let timeSpent = Date().timeIntervalSince(viewStartTime)
                Task {
                    await EventTrackingManager.shared.trackPaywallDismissed(
                        source: source,
                        timeSpent: timeSpent,
                        packageSelected: selectedPackage != nil
                    )
                }
                dismiss()
            }) {
                Image(systemName: "xmark")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.white.opacity(0.7))
                    .frame(width: 32, height: 32)
                    .background(
                        Circle()
                            .fill(Color.white.opacity(0.1))
                    )
            }
        }
        .padding(.horizontal, 48)
        .padding(.top, 40)
    }
    
    private var headlineView: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("KlickPhoto")
                    .font(.system(size: 16, weight: .medium, design: .rounded))
                    .foregroundColor(.white)
                
                VStack {
                    Text("Pro")
                        .font(.system(size: 14, weight: .medium, design: .rounded))
                        .foregroundStyle(Color.white)
                        .padding(.vertical, 2)
                        .padding(.horizontal, 8)
                }
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.white.opacity(0.05))
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color.white.opacity(0.1), lineWidth: 1)
                        )
                )
            }
            
            Text("Go Pro with smart photo capture")
                .font(.system(size: 23, weight: .medium, design: .rounded))
                .foregroundColor(.white)
            
            Text("Unlock all unlimited color profiles, image enhancement, and exlcusive editing updates.")
                .font(.system(size: 16, weight: .light, design: .rounded))
                .foregroundColor(.white)
        }
        .padding(.horizontal, 16)
    }
    
    private var subscriptionOfferView: some View {
        HStack(spacing: 10) {
            if let offering = currentOffering {
                // Sort packages: weekly, monthly, annual, lifetime
                let sortedPackages = sortPackages(offering.availablePackages)
                
                ForEach(sortedPackages, id: \.identifier) { package in
                SubscriptionOfferButton(
                    package: package,
                    isHighlighted: selectedPackage?.identifier == package.identifier,
                    onSelect: {
                        selectedPackage = package
                        selectedPackageTime = Date()
                        
                        // Track package selected
                        Task {
                            await EventTrackingManager.shared.trackPaywallPackageSelected(package: package)
                        }
                    }
                )
            }
            } else {
                // Fallback to placeholder while loading
                SubscriptionOfferButton(
                    content: .init(period: "Loading...", amount: 0.0, savedAmount: 0.0),
                    isHighlighted: false,
                    onSelect: {}
                )
            }
        }
    }
    
    /// Sort packages in display order: weekly, monthly, annual, lifetime
    private func sortPackages(_ packages: [Package]) -> [Package] {
        let order: [PackageType] = [.weekly, .monthly, .annual, .lifetime]
        return packages.sorted { package1, package2 in
            let index1 = order.firstIndex(of: PackageType(from: package1.packageType)) ?? Int.max
            let index2 = order.firstIndex(of: PackageType(from: package2.packageType)) ?? Int.max
            return index1 < index2
        }
    }
    
    private var subscriptionButton: some View {
        VStack(alignment: .center, spacing: 16) {
            Text("By tapping Continue, you will be charged, your subscription will auto-renew for the same price and package length until you cancel via App store settings, and you agree to our Terms.")
                .foregroundStyle(Color.white)
                .font(.system(size: 11, weight: .light))
                .multilineTextAlignment(.center)
           
            Button(action: {
                guard let package = selectedPackage else { return }
                Task {
                    await processSubscription(for: package)
                }
            }) {
                HStack(spacing: 8) {
                    if isPurchasing {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .black))
                    }
                    Text(isPurchasing ? "Processing..." : "Continue")
                        .font(.system(size: 18, weight: .semibold, design: .rounded))
                        .foregroundColor(.black)
                }
                .padding(.horizontal, 40)
                .padding(.vertical, 16)
                .frame(maxWidth: .infinity)
                .background(
                    RoundedRectangle(cornerRadius: 30)
                        .fill(Color.white)
                )
                .shadow(color: .white.opacity(0.3), radius: 10, x: 0, y: 5)
            }
            .disabled(isPurchasing || selectedPackage == nil)
            .opacity((isPurchasing || selectedPackage == nil) ? 0.6 : 1.0)
            .padding(.bottom, 10)
 
            HStack(spacing: 15) {
                Button {
                    if let url = URL(string: "https://www.klickphoto.app/terms") {
                        openURL(url)
                    }
                } label: {
                    Text("Terms of Use")
                        .underline(color: .white)
                        .foregroundStyle(Color.white)
                        .font(.system(size: 11, weight: .medium))
                }
                
                Text("•")
                    .foregroundStyle(Color.white)
                    .font(.system(size: 11, weight: .medium))
                
                Button {
                    if let url = URL(string: "https://www.klickphoto.app/privacy") {
                        openURL(url)
                    }
                } label: {
                    Text("Privacy Policy")
                        .underline(color: .white)
                        .foregroundStyle(Color.white)
                        .font(.system(size: 11, weight: .medium))
                }
                
                Text("•")
                    .foregroundStyle(Color.white)
                    .font(.system(size: 11, weight: .medium))
                
                Button {
                    Task {
                        await restorePurchases()
                    }
                } label: {
                    Text("Restore")
                        .underline(color: .white)
                        .foregroundStyle(Color.white)
                        .font(.system(size: 11, weight: .medium))
                }
            }
        }
        .padding(.horizontal, 16)
    }
}

extension SalesPageView {
    private func processSubscription(for package: Package) async {
        /// - Set purchasing state as true before initiating a subscription purchase
        isPurchasing = true
        
        // Track subscribe tapped
        await EventTrackingManager.shared.trackPaywallSubscribeTapped(package: package)
        
        let purchaseResult = await purchaseService.purchase(package: package)
        isPurchasing = false
        
        guard purchaseResult.status != .interrupted else {
            // Track interrupted
            await EventTrackingManager.shared.trackPaywallPurchaseInterrupted(package: package)
            return
        }

        if purchaseResult.status == .subscribed {
            
            // Track purchase completed (custom event for PostHog/internal analytics)
            let timeToComplete = selectedPackageTime.map { Date().timeIntervalSince($0) } ?? 0
            await EventTrackingManager.shared.trackPaywallPurchaseCompleted(
                package: package,
                timeToComplete: timeToComplete
            )

            // Log the GA4 reserved `purchase` event so Firebase revenue dashboards populate.
            // Firebase only counts revenue from events named exactly "purchase" with value as
            // a Double, a valid ISO 4217 currency code, and a unique transaction_id.
            let price = package.storeProduct.priceDecimalNumber.doubleValue
            let currency = package.storeProduct.currencyCode ?? "USD"
            let transactionId = purchaseResult.transaction?.transactionIdentifier
                ?? "\(package.storeProduct.productIdentifier)-\(Int(Date().timeIntervalSince1970))"
            await EventTrackingManager.shared.logFirebasePurchase(
                value: price,
                currency: currency,
                transactionId: transactionId,
                productId: package.storeProduct.productIdentifier,
                productName: package.storeProduct.localizedTitle
            )
            
            // Set user properties
            await EventTrackingManager.shared.setUserProperty("is_pro", value: true)
            await EventTrackingManager.shared.setUserProperty(
                "subscription_type",
                value: PackageType(from: package.packageType).rawValue
            )
            await EventTrackingManager.shared.setUserProperty("last_purchase_source", value: source.rawValue)
            
            // Smooth transition to success page
            withAnimation(.easeOut(duration: 0.6)) {
                fadeOutSalesContent = true
            }
            
            // Show success page after fade out
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.7) {
                withAnimation(.easeIn(duration: 0.6)) {
                    showSuccessPage = true
                }
            }
        }
    }
    
    private func restorePurchases() async {
        isPurchasing = true
        
        // Track restore tapped
        await EventTrackingManager.shared.trackPaywallRestoreTapped()
        
        let purchaseStatus = await purchaseService.restorePurchases()
        isPurchasing = false
            
        if purchaseStatus == .subscribed {
            // Track restore completed
            await EventTrackingManager.shared.trackPaywallRestoreCompleted(
                entitlements: ["Klick Premium"]
            )
            
            // Set user properties
            await EventTrackingManager.shared.setUserProperty("is_pro", value: true)
            
            // Smooth transition to success page
            withAnimation(.easeOut(duration: 0.6)) {
                fadeOutSalesContent = true
            }
            
            // Show success page after fade out
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.7) {
                withAnimation(.easeIn(duration: 0.6)) {
                    showSuccessPage = true
                }
            }
        } else if purchaseStatus == .notSubscribed {
            // Track restore failed
            await EventTrackingManager.shared.trackPaywallRestoreFailed(
                error: NSError(domain: "PaywallRestore", code: 1, userInfo: [NSLocalizedDescriptionKey: "No active subscriptions found"])
            )
            // TODO: Show alert to user
        } else {
            // Track restore failed
            await EventTrackingManager.shared.trackPaywallRestoreFailed(
                error: NSError(domain: "PaywallRestore", code: 2, userInfo: [NSLocalizedDescriptionKey: "Restore interrupted"])
            )
            // TODO: Show error alert
        }
    }
}

struct SubscriptionOfferButton: View {
    var package: Package?
    var content: Content?
    var isHighlighted: Bool
    var onSelect: () -> Void
    
    struct Content {
        var period: String
        var amount: Double
        var savedAmount: Double
    }
    
    // Convenience initializer for Package
    init(package: Package, isHighlighted: Bool, onSelect: @escaping () -> Void) {
        self.package = package
        self.content = nil
        self.isHighlighted = isHighlighted
        self.onSelect = onSelect
    }
    
    // Convenience initializer for Content (fallback/loading)
    init(content: Content, isHighlighted: Bool, onSelect: @escaping () -> Void) {
        self.package = nil
        self.content = content
        self.isHighlighted = isHighlighted
        self.onSelect = onSelect
    }
    
    private var displayContent: Content {
        if let package = package {
            return Content(
                period: package.displayPeriod,
                amount: package.displayPrice,
                savedAmount: package.savingsPercentage
            )
        } else if let content = content {
            return content
        } else {
            return Content(period: "Unknown", amount: 0.0, savedAmount: 0.0)
        }
    }
    
    var body: some View {
        Button {
            HapticFeedback.selection.generate()
            onSelect()
        } label: {
            VStack(alignment: .leading, spacing: 4) {
                Text(displayContent.period)
                    .font(.system(size: 14, weight: .medium))
                Spacer()
                Text(package?.storeProduct.localizedPriceString ?? "RM \(String(format: "%.1f", displayContent.amount))")
                    .font(.system(size: 18, weight: .bold))
            }
            .foregroundStyle(Color.white)
            .padding(.vertical, 12)
            .padding(.horizontal, 8)
        }
        .frame(width: 120, height: 120)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white.opacity(0.05))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(isHighlighted ? Color.yellow : Color.white.opacity(0.1), lineWidth: isHighlighted ? 2 : 1)
                )
        )
        .overlay(alignment: .topTrailing) {
            if displayContent.savedAmount > 0 {
                RoundedRectangle(cornerRadius: 6)
                    .fill(Color.yellow)
                    .frame(width: 70, height: 20)
                    .overlay(alignment: .center) {
                        Text("\(String(format: "%.0f", displayContent.savedAmount))% OFF")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundStyle(Color.black)
                    }
                    .offset(x: 10, y: -10)
            }
        }
    }
}
// MARK: - Package Extensions

extension Package {
    
    /// Display period (e.g., "Weekly", "Monthly", "Yearly", "Lifetime")
    var displayPeriod: String {
        switch packageType {
        case .weekly:
            return "Weekly"
        case .monthly:
            return "Monthly"
        case .annual:
            return "Yearly"
        case .lifetime:
            return "Lifetime"
        default:
            return storeProduct.subscriptionPeriod?.periodTitle ?? "Unknown"
        }
    }
    
    /// Get the numerical price value for calculations
    var displayPrice: Double {
        return storeProduct.priceDecimalNumber.doubleValue
    }
    
    /// Calculate savings percentage (comparing to weekly rate)
    /// This assumes weekly is the baseline for comparison
    var savingsPercentage: Double {
        guard let period = storeProduct.subscriptionPeriod else { return 0.0 }
        
        let pricePerWeek: Double
        switch period.unit {
        case .week:
            pricePerWeek = displayPrice / Double(period.value)
        case .month:
            pricePerWeek = displayPrice / (Double(period.value) * 4.33) // average weeks per month
        case .year:
            pricePerWeek = displayPrice / (Double(period.value) * 52)
        default:
            return 0.0
        }
        
        // Calculate based on annual being the "standard"
        // Annual typically has the best savings
        if packageType == .annual {
            // Annual vs Monthly comparison (typical 40-50% savings)
            return 45.0
        } else if packageType == .lifetime {
            // Don't show savings for lifetime
            return 0.0
        }
        
        return pricePerWeek
    }
    
    /// Check if package has an introductory discount
    var hasIntroductoryDiscount: Bool {
        guard let intro = storeProduct.introductoryDiscount else { return false }
        return intro.price.isZero
    }
    
    /// Get the terms description for the package
    func terms(for package: Package) -> String {
        guard let intro = package.storeProduct.introductoryDiscount else {
            return "Unlocks Klick Pro"
        }
        
        if intro.price.isZero {
            return "\(intro.subscriptionPeriod.periodTitle) free trial"
        } else {
            return "\(package.localizedIntroductoryPriceString ?? "") for \(intro.subscriptionPeriod.periodTitle)"
        }
    }
}

// MARK: - SubscriptionPeriod Extensions

extension SubscriptionPeriod {
    
    /// Duration title (e.g., "day", "week", "month", "year")
    var durationTitle: String {
        switch unit {
        case .day: return "day"
        case .week: return "week"
        case .month: return "month"
        case .year: return "year"
        @unknown default: return "Unknown"
        }
    }
    
    /// Period title with pluralization (e.g., "1 week", "3 months", "1 year")
    var periodTitle: String {
        let periodString = "\(self.value) \(self.durationTitle)"
        let pluralized = self.value > 1 ? "\(periodString)s" : periodString
        return pluralized
    }
}


