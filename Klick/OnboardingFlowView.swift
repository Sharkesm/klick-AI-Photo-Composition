//
//  OnboardingFlowView.swift
//  Klick
//
//  Created by Assistant on 11/01/2025.
//

import SwiftUI

struct OnboardingFlowView: View {
    @Binding var isPresented: Bool
    @State private var currentScreen: OnboardingScreen = .welcome
    @State private var navigationDirection: NavigationDirection = .forward
    
    // AppStorage for tracking
    @AppStorage("hasSeenProUpsell") private var hasSeenProUpsell: Bool = false
    @AppStorage("userCreativeGoal") private var userCreativeGoal: String = ""
    
    // Event tracking state
    @State private var flowStartTime: Date = Date()
    @State private var screenStartTime: Date = Date()
    @State private var screensViewed: Set<Int> = []
    @State private var skippedCount: Int = 0
    @State private var cameFromSkip: Bool = false
    @State private var previousGoalSelection: String = ""
    
    enum NavigationDirection {
        case forward
        case backward
    }
    
    enum OnboardingScreen: Int, CaseIterable {
        case welcome = 1
        case composition = 2
        case posing = 3
        case editing = 4
        case achievement = 5
        case proUpsell = 6
        case personalization = 7
        
        var progress: CGFloat {
            CGFloat(self.rawValue) / CGFloat(OnboardingScreen.allCases.count)
        }
    }
    
    var body: some View {
        ZStack {
            // Background
            Color.black
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Header with progress bar, back button, and skip
                OnboardingHeader(
                    progress: currentScreen.progress,
                    showBackButton: currentScreen != .welcome,
                    showSkipButton: shouldShowSkipButton(),
                    onBack: handleBack,
                    onSkip: handleSkip
                )
                .padding(.top, 20)
                
                // Content area
                ZStack {
                    Group {
                        switch currentScreen {
                        case .welcome:
                            OnboardingScreen1(onContinue: moveToNext)
                        case .composition:
                            OnboardingScreen2(onContinue: moveToNext)
                        case .posing:
                            OnboardingScreen3(onContinue: moveToNext)
                        case .editing:
                            OnboardingScreen4(onContinue: moveToNext)
                        case .achievement:
                            OnboardingScreen5_Achievement(onContinue: moveToNext)
                        case .proUpsell:
                            OnboardingScreen6_ProUpsell(
                                onUpgrade: handleProUpgrade,
                                onMaybeLater: moveToNext
                            )
                        case .personalization:
                            OnboardingScreen7_Personalization(
                                selectedGoal: $userCreativeGoal,
                                onContinue: handleComplete
                            )
                        }
                    }
                    .transition(.asymmetric(
                        insertion: .move(edge: navigationDirection == .forward ? .trailing : .leading)
                            .combined(with: .opacity),
                        removal: .move(edge: navigationDirection == .forward ? .leading : .trailing)
                            .combined(with: .opacity)
                    ))
                }
                .frame(maxHeight: .infinity)
            }
        }
        .onAppear {
            flowStartTime = Date()
            trackScreenView()
        }
        .onChange(of: currentScreen) { _ in
            trackScreenView()
        }
    }
    
    // MARK: - Navigation Actions
    
    private func moveToNext() {
        // Track screen completion
        trackScreenCompletion()
        
        guard let nextScreen = OnboardingScreen(rawValue: currentScreen.rawValue + 1) else {
            handleComplete()
            return
        }
        
        navigationDirection = .forward
        cameFromSkip = false
        withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
            currentScreen = nextScreen
        }
    }
    
    private func handleBack() {
        guard let previousScreen = OnboardingScreen(rawValue: currentScreen.rawValue - 1) else {
            return
        }
        
        // Track back navigation
        Task {
            await EventTrackingManager.shared.trackOnboardingScreenBack(
                fromScreen: currentScreen.rawValue,
                toScreen: previousScreen.rawValue
            )
        }
        
        navigationDirection = .backward
        cameFromSkip = false
        withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
            currentScreen = previousScreen
        }
    }
    
    private func handleSkip() {
        // Track skip event
        Task {
            await EventTrackingManager.shared.trackOnboardingScreenSkipped(
                fromScreen: mapToEventScreen(currentScreen),
                fromScreenNumber: currentScreen.rawValue
            )
        }
        
        skippedCount += 1
        cameFromSkip = true
        
        // Skip takes user directly to Pro Upsell screen
        navigationDirection = .forward
        withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
            currentScreen = .proUpsell
        }
    }
    
    private func shouldShowSkipButton() -> Bool {
        // Show skip button only on screens 1-5 (before Pro Upsell)
        switch currentScreen {
        case .welcome, .composition, .posing, .editing, .achievement:
            return true
        case .proUpsell, .personalization:
            return false
        }
    }
    
    private func handleProUpgrade() {
        // Track Pro upgrade tapped
        let timeOnScreen = Date().timeIntervalSince(screenStartTime)
        Task {
            await EventTrackingManager.shared.trackOnboardingProUpsellUpgradeTapped(timeOnScreen: timeOnScreen)
        }
        
        hasSeenProUpsell = true
        moveToNext()
    }
    
    private func handleComplete() {
        // Track goal confirmation
        if let goal = UserCreativeGoal(rawValue: userCreativeGoal) {
            let timeOnScreen = Date().timeIntervalSince(screenStartTime)
            Task {
                await EventTrackingManager.shared.trackOnboardingGoalConfirmed(
                    goal: goal,
                    timeSpent: timeOnScreen
                )
                
                // Track flow completion
                let totalTime = Date().timeIntervalSince(flowStartTime)
                await EventTrackingManager.shared.trackOnboardingFlowCompleted(
                    timeSpent: totalTime,
                    screensViewed: screensViewed.count,
                    skippedCount: skippedCount
                )
            }
        }
        
        withAnimation(.easeInOut(duration: 0.3)) {
            isPresented = false
        }
    }
    
    // MARK: - Event Tracking Helpers
    
    private func trackScreenView() {
        screenStartTime = Date()
        screensViewed.insert(currentScreen.rawValue)
        
        Task {
            await EventTrackingManager.shared.trackOnboardingScreenViewed(
                screen: mapToEventScreen(currentScreen),
                screenNumber: currentScreen.rawValue
            )
            
            // Track Pro upsell viewed
            if currentScreen == .proUpsell {
                await EventTrackingManager.shared.trackOnboardingProUpsellViewed(cameFromSkip: cameFromSkip)
            }
        }
    }
    
    private func trackScreenCompletion() {
        let timeOnScreen = Date().timeIntervalSince(screenStartTime)
        
        Task {
            await EventTrackingManager.shared.trackOnboardingScreenCompleted(
                screen: mapToEventScreen(currentScreen),
                screenNumber: currentScreen.rawValue,
                timeOnScreen: timeOnScreen
            )
            
            // Track Pro upsell skipped (Maybe later button)
            if currentScreen == .proUpsell {
                await EventTrackingManager.shared.trackOnboardingProUpsellSkipped(timeOnScreen: timeOnScreen)
            }
        }
    }
    
    private func mapToEventScreen(_ screen: OnboardingScreen) -> Klick.OnboardingScreen {
        switch screen {
        case .welcome:
            return .welcome
        case .composition:
            return .composition
        case .posing:
            return .posing
        case .editing:
            return .editing
        case .achievement:
            return .achievement
        case .proUpsell:
            return .proUpsell
        case .personalization:
            return .personalization
        }
    }
}

// MARK: - Onboarding Header Component

struct OnboardingHeader: View {
    let progress: CGFloat
    let showBackButton: Bool
    let showSkipButton: Bool
    let onBack: () -> Void
    let onSkip: () -> Void
    
    var body: some View {
        HStack(spacing: 16) {
            // Back button
            Button(action: onBack) {
                Image(systemName: "chevron.left")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(width: 40, height: 40)
                    .background(
                        Circle()
                            .fill(Color.white.opacity(0.1))
                    )
            }
            .opacity(showBackButton ? 1 : 0)
            .disabled(!showBackButton)
            
            // Progress bar (center, flexible)
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    // Background
                    Capsule()
                        .fill(Color.white.opacity(0.2))
                        .frame(height: 4)
                    
                    // Progress
                    Capsule()
                        .fill(Color.white)
                        .frame(width: geometry.size.width * progress, height: 4)
                        .animation(.spring(response: 0.6, dampingFraction: 0.8), value: progress)
                }
            }
            .frame(height: 4)
            
            // Skip button (conditionally shown)
            if showSkipButton {
                Button(action: onSkip) {
                    Text("Skip")
                        .font(.system(size: 16, weight: .medium, design: .rounded))
                        .foregroundColor(.white.opacity(0.7))
                        .frame(minWidth: 44)
                }
            } else {
                // Spacer to maintain layout when skip button is hidden
                Spacer()
                    .frame(width: 44)
            }
        }
        .frame(height: 40)
        .padding(.horizontal, 24)
    }
}

// MARK: - Screen 1: Welcome / Core Promise

struct OnboardingScreen1: View {
    let onContinue: () -> Void
    @State private var showHeadline = false
    @State private var showDescription = false
    @State private var showImage = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Spacer()
                .frame(height: 32)
            
            // Headline
            VStack(alignment: .leading, spacing: 8) {
                Text("Capture people,")
                    .font(.system(size: 32, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                
                Text("beautifully.")
                    .font(.system(size: 32, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .opacity(showHeadline ? 1 : 0)
            .offset(y: showHeadline ? 0 : 15)
            
            Spacer()
                .frame(height: 16)
            
            // Subtext
            Text("Master the art of portraits — from composition to expression — in just a few taps.")
                .font(.system(size: 16, weight: .regular, design: .rounded))
                .foregroundColor(.white.opacity(0.75))
                .lineLimit(3)
                .frame(maxWidth: .infinity, alignment: .leading)
                .opacity(showDescription ? 1 : 0)
                .offset(y: showDescription ? 0 : 15)
            
            Spacer()
                .frame(height: 40)
            
            // Portrait carousel with composition overlays
            PortraitCarouselView()
                .frame(maxWidth: .infinity)
                .frame(height: 360)
                .opacity(showImage ? 1 : 0)
                .scaleEffect(showImage ? 1 : 0.96)
            
            Spacer()
            
            // Continue button (no animation)
            Button(action: onContinue) {
                Text("Continue")
                    .font(.system(size: 18, weight: .semibold, design: .rounded))
                    .foregroundColor(.black)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 18)
                    .background(
                        RoundedRectangle(cornerRadius: 30)
                            .fill(Color.white)
                    )
                    .shadow(color: .white.opacity(0.2), radius: 15, x: 0, y: 8)
            }
            
            Spacer()
                .frame(height: 40)
        }
        .padding(.horizontal, 24)
        .onAppear {
            // Sequential animations with initial delay for smooth presentation
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                withAnimation(.easeOut(duration: 0.6)) {
                    showHeadline = true
                }
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
                withAnimation(.easeOut(duration: 0.6)) {
                    showDescription = true
                }
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                withAnimation(.spring(response: 0.7, dampingFraction: 0.8)) {
                    showImage = true
                }
            }
        }
    }
}

// MARK: - Screen 2: Composition Focus

struct OnboardingScreen2: View {
    let onContinue: () -> Void
    @State private var showHeadline = false
    @State private var showDescription = false
    @State private var showImage = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Spacer()
                .frame(height: 32)
            
            // Headline
            Text("We'll guide your every frame — live.")
                .font(.system(size: 32, weight: .bold, design: .rounded))
                .foregroundColor(.white)
                .frame(maxWidth: .infinity, alignment: .leading)
                .opacity(showHeadline ? 1 : 0)
                .offset(y: showHeadline ? 0 : 15)
            
            Spacer()
                .frame(height: 16)
            
            // Subtext
            VStack(alignment: .leading, spacing: 8) {
                Text("Think: Move left. Perfect symmetry!")
                    .font(.system(size: 16, weight: .medium, design: .rounded))
                    .foregroundColor(.white.opacity(0.85))
                    .lineLimit(2)
                
                Text("You focus on the moment; we'll handle the rest.")
                    .font(.system(size: 16, weight: .regular, design: .rounded))
                    .foregroundColor(.white.opacity(0.7))
                    .lineLimit(2)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .opacity(showDescription ? 1 : 0)
            .offset(y: showDescription ? 0 : 15)
            
            Spacer()
                .frame(height: 40)
            
            // Interactive composition demo
            CompositionDemoView()
                .frame(maxWidth: .infinity)
                .frame(height: 360)
                .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                .shadow(color: .black.opacity(0.3), radius: 20, x: 0, y: 10)
                .opacity(showImage ? 1 : 0)
                .scaleEffect(showImage ? 1 : 0.96)
            
            Spacer()
            
            // Continue button (no animation)
            Button(action: onContinue) {
                Text("Continue")
                    .font(.system(size: 18, weight: .semibold, design: .rounded))
                    .foregroundColor(.black)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 18)
                    .background(
                        RoundedRectangle(cornerRadius: 30)
                            .fill(Color.white)
                    )
                    .shadow(color: .white.opacity(0.2), radius: 15, x: 0, y: 8)
            }
            
            Spacer()
                .frame(height: 40)
        }
        .padding(.horizontal, 24)
        .onAppear {
            // Sequential animations
            withAnimation(.easeOut(duration: 0.6)) {
                showHeadline = true
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                withAnimation(.easeOut(duration: 0.6)) {
                    showDescription = true
                }
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                withAnimation(.spring(response: 0.7, dampingFraction: 0.8)) {
                    showImage = true
                }
            }
        }
    }
}

// MARK: - Screen 3: Posing & Expression

struct OnboardingScreen3: View {
    let onContinue: () -> Void
    @State private var showHeadline = false
    @State private var showDescription = false
    @State private var showImage = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Spacer()
                .frame(height: 32)
            
            // Headline
            Text("Bring out your best side.")
                .font(.system(size: 32, weight: .bold, design: .rounded))
                .foregroundColor(.white)
                .frame(maxWidth: .infinity, alignment: .leading)
                .opacity(showHeadline ? 1 : 0)
                .offset(y: showHeadline ? 0 : 15)
            
            Spacer()
                .frame(height: 16)
            
            // Subtext
            Text("Explore pose ideas, expression tips, and real-time feedback made for portraits and people.")
                .font(.system(size: 16, weight: .regular, design: .rounded))
                .foregroundColor(.white.opacity(0.75))
                .lineLimit(3)
                .frame(maxWidth: .infinity, alignment: .leading)
                .opacity(showDescription ? 1 : 0)
                .offset(y: showDescription ? 0 : 15)
            
            Spacer()
                .frame(height: 40)
            
            // Interactive pose comparison slider
            ImageComparisonSlider(
                beforeImageName: "pose_before",
                afterImageName: "pose_after",
                initialSliderPosition: 20.0
            )
            .frame(maxWidth: .infinity)
            .frame(height: 380)
            .opacity(showImage ? 1 : 0)
            .scaleEffect(showImage ? 1 : 0.96)
            
            Spacer()
            
            // Continue button (no animation)
            Button(action: onContinue) {
                Text("Continue")
                    .font(.system(size: 18, weight: .semibold, design: .rounded))
                    .foregroundColor(.black)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 18)
                    .background(
                        RoundedRectangle(cornerRadius: 30)
                            .fill(Color.white)
                    )
                    .shadow(color: .white.opacity(0.2), radius: 15, x: 0, y: 8)
            }
            
            Spacer()
                .frame(height: 40)
        }
        .padding(.horizontal, 24)
        .onAppear {
            // Sequential animations
            withAnimation(.easeOut(duration: 0.6)) {
                showHeadline = true
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                withAnimation(.easeOut(duration: 0.6)) {
                    showDescription = true
                }
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                withAnimation(.spring(response: 0.7, dampingFraction: 0.8)) {
                    showImage = true
                }
            }
        }
    }
}

struct OnboardingScreen4: View {
    let onContinue: () -> Void
    @State private var showHeadline = false
    @State private var showDescription = false
    @State private var showImage = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Spacer()
                .frame(height: 32)
            
            // Headline
            Text("Edit smarter, not harder.")
                .font(.system(size: 32, weight: .bold, design: .rounded))
                .foregroundColor(.white)
                .frame(maxWidth: .infinity, alignment: .leading)
                .opacity(showHeadline ? 1 : 0)
                .offset(y: showHeadline ? 0 : 15)
            
            Spacer()
                .frame(height: 16)
            
            // Subtext
            Text("Apply studio-quality filters, adjust lighting, or retouch naturally — all guided by your style.")
                .font(.system(size: 16, weight: .regular, design: .rounded))
                .foregroundColor(.white.opacity(0.75))
                .lineLimit(3)
                .frame(maxWidth: .infinity, alignment: .leading)
                .opacity(showDescription ? 1 : 0)
                .offset(y: showDescription ? 0 : 15)
            
            Spacer()
                .frame(height: 40)
            
            // Hero image - centered horizontally, sized by aspect ratio
            HStack {
                Spacer()
                
                GeometryReader { geometry in
                    Image("Rectangle_15")
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: geometry.size.width, height: geometry.size.height)
                        .clipped()
                }
                .aspectRatio(3/4, contentMode: .fit)
                .frame(height: 360)
                .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .stroke(Color.white.opacity(0.1), lineWidth: 1)
                )
                .shadow(color: .black.opacity(0.3), radius: 20, x: 0, y: 10)
                .opacity(showImage ? 1 : 0)
                .scaleEffect(showImage ? 1 : 0.96)
                
                Spacer()
            }
            
            Spacer()
            
            // Continue button (no animation)
            Button(action: onContinue) {
                Text("Continue")
                    .font(.system(size: 18, weight: .semibold, design: .rounded))
                    .foregroundColor(.black)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 18)
                    .background(
                        RoundedRectangle(cornerRadius: 30)
                            .fill(Color.white)
                    )
                    .shadow(color: .white.opacity(0.2), radius: 15, x: 0, y: 8)
            }
            
            Spacer()
                .frame(height: 40)
        }
        .padding(.horizontal, 24)
        .onAppear {
            // Sequential animations
            withAnimation(.easeOut(duration: 0.6)) {
                showHeadline = true
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                withAnimation(.easeOut(duration: 0.6)) {
                    showDescription = true
                }
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                withAnimation(.spring(response: 0.7, dampingFraction: 0.8)) {
                    showImage = true
                }
            }
        }
    }
}

// MARK: - Screen 5: Achievement/Social Proof

struct OnboardingScreen5_Achievement: View {
    let onContinue: () -> Void
    @State private var showHeadline = false
    @State private var showDescription = false
    @State private var showStats = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Spacer()
            
            // Content group (centered vertically)
            VStack(alignment: .leading, spacing: 0) {
                // Stat badge - Updated colors
                HStack(spacing: 8) {
                    Image(systemName: "chart.line.uptrend.xyaxis")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(Color(red: 1.0, green: 0.8, blue: 0.0))
                    
                    Text("User Success Rate")
                        .font(.system(size: 12, weight: .semibold, design: .rounded))
                        .foregroundColor(Color.white)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .cornerRadius(16)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color.clear)
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(Color.white, lineWidth: 1)
                        )
                )
                .opacity(showStats ? 1 : 0)
                .scaleEffect(showStats ? 1 : 0.9)
                
                Spacer()
                    .frame(height: 24)
                
                // Headline with percentage
                VStack(alignment: .leading, spacing: 12) {
                    HStack(alignment: .firstTextBaseline, spacing: 8) {
                        Text("89%")
                            .font(.system(size: 56, weight: .bold, design: .rounded))
                            .foregroundColor(Color(red: 1.0, green: 0.8, blue: 0.0))
                        
                        Text("of users")
                            .font(.system(size: 24, weight: .semibold, design: .rounded))
                            .foregroundColor(.white)
                    }
                    
                    Text("see a huge difference after their first 3 photos.")
                        .font(.system(size: 24, weight: .semibold, design: .rounded))
                        .foregroundColor(.white)
                        .lineLimit(3)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .opacity(showHeadline ? 1 : 0)
                .offset(y: showHeadline ? 0 : 15)
                
                Spacer()
                    .frame(height: 24)
                
                // Description
                Text("With our smart composition guide, your photos instantly look more balanced, expressive, and natural — no studio lighting needed.")
                    .font(.system(size: 16, weight: .regular, design: .rounded))
                    .foregroundColor(.white.opacity(0.75))
                    .lineLimit(4)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .opacity(showDescription ? 1 : 0)
                    .offset(y: showDescription ? 0 : 15)
            }
            
            Spacer()
            
            // Continue button
            Button(action: onContinue) {
                Text("Continue")
                    .font(.system(size: 18, weight: .semibold, design: .rounded))
                    .foregroundColor(.black)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 18)
                    .background(
                        RoundedRectangle(cornerRadius: 30)
                            .fill(Color.white)
                    )
                    .shadow(color: .white.opacity(0.2), radius: 15, x: 0, y: 8)
            }
            
            Spacer()
                .frame(height: 40)
        }
        .padding(.horizontal, 24)
        .onAppear {
            // Sequential animations
            withAnimation(.spring(response: 0.6, dampingFraction: 0.7).delay(0.1)) {
                showStats = true
            }
            
            withAnimation(.easeOut(duration: 0.6).delay(0.3)) {
                showHeadline = true
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                withAnimation(.easeOut(duration: 0.6)) {
                    showDescription = true
                }
            }
        }
    }
}

// MARK: - Screen 6: Pro Upsell (formerly Screen 5)

struct OnboardingScreen6_ProUpsell: View {
    let onUpgrade: () -> Void
    let onMaybeLater: () -> Void
    @State private var showHeader = false
    @State private var showFeature1 = false
    @State private var showFeature2 = false
    @State private var showFeature3 = false
    @State private var showFeature4 = false
    
    // Pro features list
    private let proFeatures = [
        (icon: "sparkles", text: "Exclusive premium filters"),
        (icon: "wand.and.stars", text: "Advanced editing tools"),
        (icon: "bolt.fill", text: "Early feature releases"),
        (icon: "eye.slash.fill", text: "No ads, no limits")
    ]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Spacer()
                .frame(height: 32)
            
            // Header group (Headline + Description together)
            VStack(alignment: .leading, spacing: 16) {
                // Headline
                Text("Unlock your creative edge.")
                    .font(.system(size: 32, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity, alignment: .leading)
                
                // Subtext
                Text("Go Pro to access exclusive features and unlock your full potential.")
                    .font(.system(size: 16, weight: .regular, design: .rounded))
                    .foregroundColor(.white.opacity(0.75))
                    .lineLimit(2)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .opacity(showHeader ? 1 : 0)
            .offset(y: showHeader ? 0 : 15)
            
            Spacer()
                .frame(height: 40)
            
            // Pro features list - each feature animates individually
            VStack(alignment: .leading, spacing: 20) {
                // Feature 1
                ProFeatureRow(
                    icon: proFeatures[0].icon,
                    text: proFeatures[0].text,
                    isVisible: showFeature1
                )
                
                // Feature 2
                ProFeatureRow(
                    icon: proFeatures[1].icon,
                    text: proFeatures[1].text,
                    isVisible: showFeature2
                )
                
                // Feature 3
                ProFeatureRow(
                    icon: proFeatures[2].icon,
                    text: proFeatures[2].text,
                    isVisible: showFeature3
                )
                
                // Feature 4
                ProFeatureRow(
                    icon: proFeatures[3].icon,
                    text: proFeatures[3].text,
                    isVisible: showFeature4
                )
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            
            Spacer()
            
            // Primary button - Upgrade to Pro
            Button(action: onUpgrade) {
                HStack(spacing: 8) {
                    Image(systemName: "star.fill")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.black)
                    
                    Text("Upgrade to Pro")
                        .font(.system(size: 18, weight: .semibold, design: .rounded))
                        .foregroundColor(.black)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 18)
                .background(
                    RoundedRectangle(cornerRadius: 30)
                        .fill(Color.white)
                )
                .shadow(color: .white.opacity(0.2), radius: 15, x: 0, y: 8)
            }
            
            Spacer()
                .frame(height: 12)
            
            // Secondary button - Maybe Later
            Button(action: onMaybeLater) {
                Text("Maybe later")
                    .font(.system(size: 16, weight: .medium, design: .rounded))
                    .foregroundColor(.white.opacity(0.6))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
            }
            
            Spacer()
                .frame(height: 40)
        }
        .padding(.horizontal, 24)
        .onAppear {
            // Sequential animations
            // 1. Show header (headline + description together)
            withAnimation(.easeOut(duration: 0.6)) {
                showHeader = true
            }
            
            // 2. Show features one by one
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                withAnimation(.easeOut(duration: 0.5)) {
                    showFeature1 = true
                }
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                withAnimation(.easeOut(duration: 0.5)) {
                    showFeature2 = true
                }
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.7) {
                withAnimation(.easeOut(duration: 0.5)) {
                    showFeature3 = true
                }
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.9) {
                withAnimation(.easeOut(duration: 0.5)) {
                    showFeature4 = true
                }
            }
        }
    }
}

// MARK: - Pro Feature Row Component

struct ProFeatureRow: View {
    let icon: String
    let text: String
    let isVisible: Bool
    
    var body: some View {
        HStack(spacing: 16) {
            // Icon
            Image(systemName: icon)
                .font(.system(size: 20, weight: .medium))
                .foregroundColor(Color(red: 1.0, green: 0.8, blue: 0.0))
                .frame(width: 40, height: 40)
                .background(
                    Circle()
                        .fill(Color.white.opacity(0.1))
                )
            
            // Feature text
            Text(text)
                .font(.system(size: 16, weight: .medium, design: .rounded))
                .foregroundColor(.white)
            
            Spacer()
        }
        .opacity(isVisible ? 1 : 0)
        .offset(x: isVisible ? 0 : -20)
    }
}

// MARK: - Screen 7: Personalization (formerly Screen 6)

struct OnboardingScreen7_Personalization: View {
    @Binding var selectedGoal: String
    let onContinue: () -> Void
    @State private var showHeader = false
    @State private var showOption1 = false
    @State private var showOption2 = false
    @State private var showOption3 = false
    @State private var showOption4 = false
    @State private var localSelection: String = "" // Local state, not persisted
    @State private var previousSelection: String = "" // Track selection changes
    
    // Creative goals with subtexts
    private let goals = [
        (id: "self-portraits", icon: "camera.fill", text: "Better Self-Portraits", subtext: "Smarter selfies made simple"),
        (id: "pro-shots", icon: "wand.and.stars", text: "Pro-Looking Shots", subtext: "Shoot like a pro, no gear needed"),
        (id: "aesthetic-feed", icon: "sparkles", text: "Aesthetic Feed", subtext: "Stand out with your style"),
        (id: "learn-composition", icon: "square.grid.3x3", text: "Learn Composition", subtext: "Level up your framing skills")
    ]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Spacer()
                .frame(height: 32)
            
            // Header group (Headline + Description together)
            VStack(alignment: .leading, spacing: 16) {
                // Headline
                Text("Let's get to know you 👋 What brings you here?")
                    .font(.system(size: 32, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity, alignment: .leading)
                
                // Subtext
                Text("This helps us understand your goals and build better experiences for you.")
                    .font(.system(size: 16, weight: .regular, design: .rounded))
                    .foregroundColor(.white.opacity(0.75))
                    .lineLimit(3)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .opacity(showHeader ? 1 : 0)
            .offset(y: showHeader ? 0 : 15)
            
            Spacer()
                .frame(height: 40)
            
            // Goal options
            VStack(spacing: 12) {
                // Option 1
                GoalOptionButton(
                    icon: goals[0].icon,
                    text: goals[0].text,
                    subtext: goals[0].subtext,
                    isSelected: localSelection == goals[0].id,
                    isVisible: showOption1,
                    action: {
                        HapticFeedback.selection.generate()
                        trackGoalSelection(goals[0].id)
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                            localSelection = goals[0].id
                        }
                    }
                )
                
                // Option 2
                GoalOptionButton(
                    icon: goals[1].icon,
                    text: goals[1].text,
                    subtext: goals[1].subtext,
                    isSelected: localSelection == goals[1].id,
                    isVisible: showOption2,
                    action: {
                        HapticFeedback.selection.generate()
                        trackGoalSelection(goals[1].id)
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                            localSelection = goals[1].id
                        }
                    }
                )
                
                // Option 3
                GoalOptionButton(
                    icon: goals[2].icon,
                    text: goals[2].text,
                    subtext: goals[2].subtext,
                    isSelected: localSelection == goals[2].id,
                    isVisible: showOption3,
                    action: {
                        HapticFeedback.selection.generate()
                        trackGoalSelection(goals[2].id)
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                            localSelection = goals[2].id
                        }
                    }
                )
                
                // Option 4
                GoalOptionButton(
                    icon: goals[3].icon,
                    text: goals[3].text,
                    subtext: goals[3].subtext,
                    isSelected: localSelection == goals[3].id,
                    isVisible: showOption4,
                    action: {
                        HapticFeedback.selection.generate()
                        trackGoalSelection(goals[3].id)
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                            localSelection = goals[3].id
                        }
                    }
                )
            }
            
            Spacer()
            
            // Continue button
            Button(action: {
                // Save selection to AppStorage when continuing
                selectedGoal = localSelection
                onContinue()
            }) {
                Text("Continue")
                    .font(.system(size: 18, weight: .semibold, design: .rounded))
                    .foregroundColor(.black)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 18)
                    .background(
                        RoundedRectangle(cornerRadius: 30)
                            .fill(localSelection.isEmpty ? Color.white.opacity(0.3) : Color.white)
                    )
                    .shadow(color: localSelection.isEmpty ? .clear : .white.opacity(0.2), radius: 15, x: 0, y: 8)
            }
            .disabled(localSelection.isEmpty)
            
            Spacer()
                .frame(height: 40)
        }
        .padding(.horizontal, 24)
        .onAppear {
            // Sequential animations
            // 1. Show header
            withAnimation(.easeOut(duration: 0.6)) {
                showHeader = true
            }
            
            // 2. Show options one by one
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                withAnimation(.easeOut(duration: 0.5)) {
                    showOption1 = true
                }
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                withAnimation(.easeOut(duration: 0.5)) {
                    showOption2 = true
                }
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.7) {
                withAnimation(.easeOut(duration: 0.5)) {
                    showOption3 = true
                }
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.9) {
                withAnimation(.easeOut(duration: 0.5)) {
                    showOption4 = true
                }
            }
        }
    }
    
    // MARK: - Tracking Helper
    
    private func trackGoalSelection(_ goalId: String) {
        guard let goal = UserCreativeGoal(rawValue: goalId) else { return }
        
        let changedSelection = !previousSelection.isEmpty && previousSelection != goalId
        previousSelection = goalId
        
        Task {
            await EventTrackingManager.shared.trackOnboardingGoalSelected(
                goal: goal,
                changedSelection: changedSelection
            )
        }
    }
}

// MARK: - Goal Option Button Component

struct GoalOptionButton: View {
    let icon: String
    let text: String
    let subtext: String
    let isSelected: Bool
    let isVisible: Bool
    let action: () -> Void
    
    // Golden yellow color for selection
    private let selectedColor = Color(red: 1.0, green: 0.8, blue: 0.0)
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                // Icon
                Image(systemName: icon)
                    .font(.system(size: 18, weight: .medium))
                    .foregroundColor(isSelected ? .black : .white)
                    .frame(width: 36, height: 36)
                    .background(
                        Circle()
                            .fill(isSelected ? Color.black.opacity(0.15) : Color.white.opacity(0.1))
                    )
                
                // Text content
                VStack(alignment: .leading, spacing: 4) {
                    Text(text)
                        .font(.system(size: 16, weight: .semibold, design: .rounded))
                        .foregroundColor(isSelected ? .black : .white)
                    
                    Text(subtext)
                        .font(.system(size: 13, weight: .regular, design: .rounded))
                        .foregroundColor(isSelected ? .black.opacity(0.7) : .white.opacity(0.6))
                }
                
                Spacer()
                
                // Selection indicator (radio button)
                ZStack {
                    Circle()
                        .stroke(isSelected ? Color.black : Color.white.opacity(0.3), lineWidth: 2)
                        .frame(width: 24, height: 24)
                    
                    if isSelected {
                        Circle()
                            .fill(Color.black)
                            .frame(width: 12, height: 12)
                    }
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 18)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(isSelected ? selectedColor : Color.white.opacity(0.05))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(isSelected ? selectedColor.opacity(0.3) : Color.white.opacity(0.1), lineWidth: 1)
                    )
            )
            .shadow(color: isSelected ? selectedColor.opacity(0.3) : .clear, radius: 10, x: 0, y: 4)
        }
        .buttonStyle(PlainButtonStyle())
        .opacity(isVisible ? 1 : 0)
        .offset(y: isVisible ? 0 : 15)
    }
}

// MARK: - Preview

#Preview {
    OnboardingFlowView(isPresented: .constant(true))
        .preferredColorScheme(.dark)
}

