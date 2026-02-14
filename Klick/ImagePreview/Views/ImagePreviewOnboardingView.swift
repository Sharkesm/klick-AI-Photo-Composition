//
//  ImagePreviewOnboardingView.swift
//  Klick
//
//  Created by Manase on 12/10/2025.
//
import SwiftUI

struct ImagePreviewOnboardingView: View {
    @Binding var isVisible: Bool
    let onComplete: () -> Void
    
    @State private var pulseAnimation = false
    @State private var pointingHandOffset: CGFloat = 0
    @State private var scaleAnimation = false
    @State private var isHandFilled = false
    
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: isHandFilled ? "hand.tap.fill" : "hand.tap")
                .font(.system(size: 48, weight: .medium))
                .foregroundColor(.yellow)
                .scaleEffect(pulseAnimation ? 1.2 : 1.0)
                .offset(y: pointingHandOffset)
                .shadow(color: .yellow.opacity(0.4), radius: 8, x: 0, y: 4)
                .animation(.easeInOut(duration: 1.0), value: isHandFilled)
            
            Text("Hold to Compare")
                .font(.title2)
                .fontWeight(.semibold)
                .foregroundColor(.white)
                .shadow(color: .black.opacity(0.8), radius: 4, x: 0, y: 2)
        }
        .scaleEffect(scaleAnimation ? 1.0 : 0.8)
        .opacity(isVisible ? 1.0 : 0.0)
        .onAppear {
            // Track image preview intro viewed
            Task {
                await EventTrackingManager.shared.trackOnboardingGuideViewed(
                    guideType: .imagePreview,
                    trigger: "first_filter"
                )
            }
            
            startAnimations()
            
            // Auto-dismiss after 4 seconds
            DispatchQueue.main.asyncAfter(deadline: .now() + 4.5) {
                dismissOnboarding()
            }
        }
        .onTapGesture {
            dismissOnboarding()
        }
    }
    
    private func startAnimations() {
        // Initial scale-in animation
        withAnimation(.spring(response: 0.6, dampingFraction: 0.7)) {
            scaleAnimation = true
        }
        
        // Pulse animation for the hand icon
        withAnimation(.easeInOut(duration: 1.0).repeatForever(autoreverses: true)) {
            pulseAnimation = true
        }
        
        // Pointing gesture animation
        withAnimation(.easeInOut(duration: 1.4).repeatForever(autoreverses: true)) {
            pointingHandOffset = -10
        }
        
        // Hand morphing animation (tap to tap.fill)
        withAnimation(.easeInOut(duration: 1.6).repeatForever(autoreverses: true)) {
            isHandFilled = true
        }
    }
    
    private func dismissOnboarding() {
        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
            isVisible = false
            scaleAnimation = false
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
            onComplete()
        }
    }
}
