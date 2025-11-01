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
    
    enum NavigationDirection {
        case forward
        case backward
    }
    
    enum OnboardingScreen: Int, CaseIterable {
        case welcome = 1
        case composition = 2
        case posing = 3
        case editing = 4
        case proUpsell = 5
        case personalization = 6
        
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
                        case .proUpsell:
                            OnboardingScreen5(
                                onUpgrade: handleProUpgrade,
                                onMaybeLater: moveToNext
                            )
                        case .personalization:
                            OnboardingScreen6(
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
    }
    
    // MARK: - Navigation Actions
    
    private func moveToNext() {
        guard let nextScreen = OnboardingScreen(rawValue: currentScreen.rawValue + 1) else {
            handleComplete()
            return
        }
        
        navigationDirection = .forward
        withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
            currentScreen = nextScreen
        }
    }
    
    private func handleBack() {
        guard let previousScreen = OnboardingScreen(rawValue: currentScreen.rawValue - 1) else {
            return
        }
        
        navigationDirection = .backward
        withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
            currentScreen = previousScreen
        }
    }
    
    private func handleSkip() {
        withAnimation(.easeInOut(duration: 0.3)) {
            isPresented = false
        }
    }
    
    private func handleProUpgrade() {
        // TODO: Handle Pro upgrade flow
        hasSeenProUpsell = true
        moveToNext()
    }
    
    private func handleComplete() {
        withAnimation(.easeInOut(duration: 0.3)) {
            isPresented = false
        }
    }
}

// MARK: - Onboarding Header Component

struct OnboardingHeader: View {
    let progress: CGFloat
    let showBackButton: Bool
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
            
            // Skip button
            Button(action: onSkip) {
                Text("Skip")
                    .font(.system(size: 16, weight: .medium, design: .rounded))
                    .foregroundColor(.white.opacity(0.7))
                    .frame(minWidth: 44)
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
            
            // Hero image
            Image("Rectangle_1")
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(maxWidth: .infinity)
                .frame(height: 340)
                .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .stroke(Color.white.opacity(0.1), lineWidth: 1)
                )
                .shadow(color: .black.opacity(0.3), radius: 20, x: 0, y: 10)
                .opacity(showImage ? 1 : 0)
                .scaleEffect(showImage ? 1 : 0.96)
            
            Spacer()
            
            // Continue button (no animation)
            Button(action: onContinue) {
                Text("Let's get started")
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
            Text("Frame like a pro.")
                .font(.system(size: 32, weight: .bold, design: .rounded))
                .foregroundColor(.white)
                .frame(maxWidth: .infinity, alignment: .leading)
                .opacity(showHeadline ? 1 : 0)
                .offset(y: showHeadline ? 0 : 15)
            
            Spacer()
                .frame(height: 16)
            
            // Subtext
            Text("Get smart composition guides that help you capture balance, light, and the perfect angle — every time.")
                .font(.system(size: 16, weight: .regular, design: .rounded))
                .foregroundColor(.white.opacity(0.75))
                .lineLimit(4)
                .frame(maxWidth: .infinity, alignment: .leading)
                .opacity(showDescription ? 1 : 0)
                .offset(y: showDescription ? 0 : 15)
            
            Spacer()
                .frame(height: 40)
            
            // Hero image
            Image("Rectangle_3")
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(maxWidth: .infinity)
                .frame(height: 340)
                .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .stroke(Color.white.opacity(0.1), lineWidth: 1)
                )
                .shadow(color: .black.opacity(0.3), radius: 20, x: 0, y: 10)
                .opacity(showImage ? 1 : 0)
                .scaleEffect(showImage ? 1 : 0.96)
            
            Spacer()
            
            // Continue button (no animation)
            Button(action: onContinue) {
                Text("Show me how")
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
            
            // Hero image
            Image("Rectangle_7")
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(maxWidth: .infinity)
                .frame(height: 340)
                .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .stroke(Color.white.opacity(0.1), lineWidth: 1)
                )
                .shadow(color: .black.opacity(0.3), radius: 20, x: 0, y: 10)
                .opacity(showImage ? 1 : 0)
                .scaleEffect(showImage ? 1 : 0.96)
            
            Spacer()
            
            // Continue button (no animation)
            Button(action: onContinue) {
                Text("Let's pose")
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
            
            // Hero image
            Image("Rectangle_10")
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(maxWidth: .infinity)
                .frame(height: 340)
                .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .stroke(Color.white.opacity(0.1), lineWidth: 1)
                )
                .shadow(color: .black.opacity(0.3), radius: 20, x: 0, y: 10)
                .opacity(showImage ? 1 : 0)
                .scaleEffect(showImage ? 1 : 0.96)
            
            Spacer()
            
            // Continue button (no animation)
            Button(action: onContinue) {
                Text("Try editing magic")
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

struct OnboardingScreen5: View {
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

struct OnboardingScreen6: View {
    @Binding var selectedGoal: String
    let onContinue: () -> Void
    
    var body: some View {
        VStack {
            Text("Screen 6: Personalization")
                .foregroundColor(.white)
            Button("Continue", action: onContinue)
        }
    }
}

// MARK: - Preview

#Preview {
    OnboardingFlowView(isPresented: .constant(true))
        .preferredColorScheme(.dark)
}

