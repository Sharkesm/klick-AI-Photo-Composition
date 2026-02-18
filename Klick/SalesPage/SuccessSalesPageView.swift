//
//  SuccessSalesPageView.swift
//  Klick
//
//  Created by Manase on 26/11/2025.
//

import SwiftUI
import DotLottie

struct SuccessSalesPageView: View {
    
    let packageType: PackageType
    let source: PaywallSource
    
    @Environment(\.dismiss) var dismiss
    var onComplete: (() -> Void)?
    
    @State private var logoScale: CGFloat = 0.0
    @State private var glowOpacity: Double = 0.0
    @State private var showFirstText: Bool = false
    @State private var showSecondText: Bool = false
    @State private var showThirdText: Bool = false
    @State private var showConfetti: Bool = false
    @State private var showButton: Bool = false
    
    // Glow animation states
    @State private var glowOffset1: CGSize = .zero
    @State private var glowOffset2: CGSize = .zero
    @State private var glowOffset3: CGSize = .zero
    @State private var glowScale1: CGFloat = 1.0
    @State private var glowScale2: CGFloat = 1.0
    @State private var glowScale3: CGFloat = 1.0
    @State private var glowRotation: Double = 0
    
    // Shape morphing states
    @State private var shape1Corner: CGFloat = 50
    @State private var shape2Corner: CGFloat = 50
    @State private var shape3Corner: CGFloat = 50
    
    var body: some View {
        ZStack {
            // Background
            Color.black
                .ignoresSafeArea()
            
            // Confetti Animation - Full Screen Coverage
            if showConfetti {
                // Top confetti (falling down)
                DotLottieAnimation(fileName: "confetti", config: AnimationConfig(autoplay: true, loop: false))
                    .view()
                    .frame(maxHeight: .infinity)
                    .ignoresSafeArea()
            }
            
            VStack(spacing: 40) {
                Spacer()
                
                // Logo Animation
                logoView
                
                Spacer()
                    .frame(height: 30)
                
                // Success Messages
                VStack(spacing: 20) {
                    Text("Thank you for subscribing! 🎉")
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)
                        .opacity(showFirstText ? 1 : 0)
                        .offset(y: showFirstText ? 0 : 20)
                        .animation(.easeOut(duration: 0.8), value: showFirstText)
                    
                    Text("All the filters, all the styles, all the blur, all the nerdy camera magic — it's yours now.")
                        .font(.system(size: 18, weight: .medium, design: .rounded))
                        .foregroundColor(.white.opacity(0.8))
                        .multilineTextAlignment(.center)
                        .opacity(showSecondText ? 1 : 0)
                        .offset(y: showSecondText ? 0 : 20)
                        .animation(.easeOut(duration: 0.8), value: showSecondText)
                    
                    Text("Go make your photos question their own existence.")
                        .font(.system(size: 18, weight: .medium, design: .rounded))
                        .foregroundColor(.white.opacity(0.8))
                        .multilineTextAlignment(.center)
                        .opacity(showThirdText ? 1 : 0)
                        .offset(y: showThirdText ? 0 : 20)
                        .animation(.easeOut(duration: 0.8), value: showThirdText)
                }
                .padding(.horizontal, 40)
                
                Spacer()
                
                // CTA Button
                ctaButton
                    .opacity(showButton ? 1 : 0)
                    .scaleEffect(showButton ? 1 : 0.9)
                    .animation(.spring(response: 0.6, dampingFraction: 0.7), value: showButton)
            }
            .padding(.bottom, 40)
        }
        .onAppear {
            // Track success page viewed
            Task {
                await EventTrackingManager.shared.trackPaywallSuccessViewed(
                    packageType: packageType,
                    source: source
                )
            }
            
            startAnimationSequence()
        }
    }
    
    private var logoView: some View {
        VStack(alignment: .center, spacing: 12) {
            ZStack {
                // Dreamy morphing colorful glow background
                ZStack {
                    // First glow blob - Deep Magenta/Purple (morphing shape)
                    RoundedRectangle(cornerRadius: shape1Corner)
                        .fill(
                            RadialGradient(
                                colors: [
                                    Color(red: 0.8, green: 0.2, blue: 0.8).opacity(0.7),  // Deep magenta
                                    Color(red: 0.5, green: 0.2, blue: 0.9).opacity(0.5),  // Rich purple
                                    Color.clear
                                ],
                                center: .center,
                                startRadius: 0,
                                endRadius: 60
                            )
                        )
                        .frame(width: 100, height: 100)
                        .offset(glowOffset1)
                        .scaleEffect(glowScale1)
                        .blur(radius: 40)
                    
                    // Second glow blob - Electric Blue/Cyan (morphing shape)
                    RoundedRectangle(cornerRadius: shape2Corner)
                        .fill(
                            RadialGradient(
                                colors: [
                                    Color(red: 0.1, green: 0.6, blue: 1.0).opacity(0.7),  // Electric blue
                                    Color(red: 0.2, green: 0.8, blue: 0.9).opacity(0.5),  // Bright cyan
                                    Color.clear
                                ],
                                center: .center,
                                startRadius: 0,
                                endRadius: 60
                            )
                        )
                        .frame(width: 110, height: 110)
                        .offset(glowOffset2)
                        .scaleEffect(glowScale2)
                        .blur(radius: 40)
                    
                    // Third glow blob - Rose/Coral Pink (morphing shape)
                    RoundedRectangle(cornerRadius: shape3Corner)
                        .fill(
                            RadialGradient(
                                colors: [
                                    Color(red: 1.0, green: 0.3, blue: 0.5).opacity(0.6),  // Rose pink
                                    Color(red: 1.0, green: 0.5, blue: 0.4).opacity(0.5),  // Coral
                                    Color.clear
                                ],
                                center: .center,
                                startRadius: 0,
                                endRadius: 60
                            )
                        )
                        .frame(width: 100, height: 100)
                        .offset(glowOffset3)
                        .scaleEffect(glowScale3)
                        .blur(radius: 40)
                }
                .rotationEffect(.degrees(glowRotation))
                .opacity(glowOpacity)
                
                // Logo on top with colorful glow
                Image(.appLogo)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 100, height: 100)
                    .clipShape(RoundedRectangle(cornerRadius: 25))
                    .shadow(color: Color(red: 0.8, green: 0.2, blue: 0.8).opacity(0.3), radius: 15, x: 0, y: 8) // Magenta glow
                    .shadow(color: Color(red: 0.1, green: 0.6, blue: 1.0).opacity(0.2), radius: 20, x: -5, y: 5) // Blue accent
            }
            .scaleEffect(logoScale)
            
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
            .opacity(logoScale) // Fade in with logo
        }
    }
    
    private var ctaButton: some View {
        Button(action: {
            HapticFeedback.success.generate()
            
            // Track continue tapped
            Task {
                await EventTrackingManager.shared.trackPaywallSuccessContinueTapped(
                    packageType: packageType
                )
            }
            
            dismiss()
            // Dismiss the sales page underneath after a short delay
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                onComplete?()
            }
        }) {
            Text("Continue")
                .font(.system(size: 18, weight: .semibold, design: .rounded))
                .foregroundColor(.black)
                .padding(.horizontal, 40)
                .padding(.vertical, 16)
                .frame(maxWidth: .infinity)
                .background(
                    RoundedRectangle(cornerRadius: 30)
                        .fill(Color.white)
                )
                .shadow(color: .white.opacity(0.3), radius: 10, x: 0, y: 5)
        }
        .padding(.horizontal, 40)
    }
    
    private func startAnimationSequence() {
        // Step 1: Logo scales in slowly from center (1.2s)
        withAnimation(.easeInOut(duration: 1.2)) {
            logoScale = 1.0
        }
        
        // Step 2: After logo is fully scaled, reveal glow effects (0.8s delay from logo start)
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
            withAnimation(.easeIn(duration: 0.8)) {
                glowOpacity = 0.8
            }
            // Start continuous glow morphing animations
            startGlowMorphing()
        }
        
        // Step 3: Show confetti and first text after logo + glow complete (2.4s delay)
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.4) {
            withAnimation(.easeOut(duration: 0.6)) {
                showConfetti = true
                showFirstText = true
            }
            HapticFeedback.success.generate()
        }
        
        // Step 4: Show second text with spacing (3.8s delay)
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.8) {
            withAnimation(.easeOut(duration: 0.6)) {
                showSecondText = true
            }
        }
        
        // Step 5: Show third text with spacing (5.2s delay)
        DispatchQueue.main.asyncAfter(deadline: .now() + 5.2) {
            withAnimation(.easeOut(duration: 0.6)) {
                showThirdText = true
            }
        }
        
        // Step 6: Show button (6.6s delay)
        DispatchQueue.main.asyncAfter(deadline: .now() + 6.6) {
            withAnimation(.easeOut(duration: 0.5)) {
                showButton = true
                showConfetti = false
            }
        }
    }
    
    private func startGlowMorphing() {
        // Glow blob 1 - Position and scale morphing
        withAnimation(.easeInOut(duration: 3.5).repeatForever(autoreverses: true)) {
            glowOffset1 = CGSize(width: 20, height: -15)
            glowScale1 = 1.5
        }
        
        // Glow blob 1 - Shape morphing (circle to rounded square)
        withAnimation(.easeInOut(duration: 4.0).repeatForever(autoreverses: true)) {
            shape1Corner = 15 // Becomes more square-like
        }
        
        // Glow blob 2 - Position and scale morphing
        withAnimation(.easeInOut(duration: 4.5).repeatForever(autoreverses: true)) {
            glowOffset2 = CGSize(width: -22, height: 12)
            glowScale2 = 1.6
        }
        
        // Glow blob 2 - Shape morphing (circle to soft rounded)
        withAnimation(.easeInOut(duration: 3.0).repeatForever(autoreverses: true)) {
            shape2Corner = 25 // Becomes softer
        }
        
        // Glow blob 3 - Position and scale morphing
        withAnimation(.easeInOut(duration: 4.0).repeatForever(autoreverses: true)) {
            glowOffset3 = CGSize(width: 15, height: 18)
            glowScale3 = 1.4
        }
        
        // Glow blob 3 - Shape morphing (circle to rounded square)
        withAnimation(.easeInOut(duration: 3.5).repeatForever(autoreverses: true)) {
            shape3Corner = 20 // Becomes more geometric
        }
        
        // Slow rotation of entire glow system (25 second cycle)
        withAnimation(.linear(duration: 25.0).repeatForever(autoreverses: false)) {
            glowRotation = 360
        }
    }
}

