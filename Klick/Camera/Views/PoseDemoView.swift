//
//  PoseDemoView.swift
//  Klick
//
//  Created by Assistant on 11/09/2025.
//

import SwiftUI

/// Interactive pose demo view for onboarding
/// Shows smooth before/after transition with pose adjustments
struct PoseDemoView: View {
    // Animation state
    @State private var currentPhase: AnimationPhase = .showBefore
    @State private var beforeOpacity: Double = 1
    @State private var afterOpacity: Double = 0
    @State private var beforeScale: CGFloat = 1
    @State private var afterScale: CGFloat = 0.95
    @State private var showOverlay = false
    @State private var flashOpacity: Double = 0
    
    // Pose guidance indicators
    @State private var showHeadTiltGuide = false
    @State private var showSmileGuide = false
    @State private var showPostureGuide = false
    
    enum AnimationPhase {
        case showBefore, transition, showAfter, feedback, reset
    }
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Before Image (original pose)
                Image("pose_before")
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: geometry.size.width, height: geometry.size.height)
                    .clipped()
                    .opacity(beforeOpacity)
                    .scaleEffect(beforeScale)
                
                // After Image (improved pose)
                Image("pose_after")
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: geometry.size.width, height: geometry.size.height)
                    .clipped()
                    .opacity(afterOpacity)
                    .scaleEffect(afterScale)
                
                // Subtle guidance overlays during transition
                if showOverlay {
                    PoseGuidanceOverlay(
                        geometry: geometry,
                        showHeadTilt: showHeadTiltGuide,
                        showSmile: showSmileGuide,
                        showPosture: showPostureGuide
                    )
                }
                
                // Green flash overlay on transition
                Rectangle()
                    .fill(Color.green.opacity(0.3))
                    .frame(width: geometry.size.width, height: geometry.size.height)
                    .opacity(flashOpacity)
                    .allowsHitTesting(false)
            }
            .frame(width: geometry.size.width, height: geometry.size.height)
        }
        .aspectRatio(3/4, contentMode: .fit)
        .background(Color(red: 0.02, green: 0.05, blue: 0.13))
        .clipShape(RoundedRectangle(cornerRadius: 24))
        .shadow(color: .black.opacity(0.3), radius: 20, x: 0, y: 10)
        .onAppear {
            runAnimationSequence()
        }
    }
    
    func runAnimationSequence() {
        Task {
            while true {
                // Reset state
                await resetState()
                
                // Phase 1: Show Before (1.5s)
                currentPhase = .showBefore
                try? await Task.sleep(nanoseconds: 1_500_000_000)
                
                // Phase 2: Show guidance overlays (0.8s)
                withAnimation(.easeOut(duration: 0.3)) {
                    showOverlay = true
                }
                try? await Task.sleep(nanoseconds: 200_000_000)
                
                // Animate guidance indicators sequentially
                withAnimation(.easeOut(duration: 0.3)) {
                    showHeadTiltGuide = true
                }
                try? await Task.sleep(nanoseconds: 2_500_000_000)
                
                // Dismiss overlays first
                withAnimation(.easeOut(duration: 0.3)) {
                    showOverlay = false
                }
                try? await Task.sleep(nanoseconds: 300_000_000)
                
                // Phase 3: Green flash after indicators dismiss
                currentPhase = .transition
                
                // Trigger green flash (quick flash in)
                withAnimation(.easeIn(duration: 0.15)) {
                    flashOpacity = 1
                }
                
                // Fade out flash quickly
                try? await Task.sleep(nanoseconds: 150_000_000)
                withAnimation(.easeOut(duration: 0.3)) {
                    flashOpacity = 0
                }
                
                // Start the crossfade transition
                withAnimation(.timingCurve(0.4, 0.0, 0.2, 1.0, duration: 1.2)) {
                    beforeOpacity = 0
                    afterOpacity = 1
                    beforeScale = 1.05
                    afterScale = 1
                }
                try? await Task.sleep(nanoseconds: 1_200_000_000)
                
                // Phase 4: Show After (1.5s)
                currentPhase = .showAfter
                try? await Task.sleep(nanoseconds: 1_500_000_000)
                
                // Phase 5: Feedback (0.5s)
                currentPhase = .feedback
                try? await Task.sleep(nanoseconds: 500_000_000)
                
                // Phase 6: Reset (0.5s)
                currentPhase = .reset
                try? await Task.sleep(nanoseconds: 500_000_000)
            }
        }
    }
    
    func resetState() async {
        withAnimation(.linear(duration: 0.3)) {
            beforeOpacity = 1
            afterOpacity = 0
            beforeScale = 1
            afterScale = 0.95
            showOverlay = false
            flashOpacity = 0
            showHeadTiltGuide = false
            showSmileGuide = false
            showPostureGuide = false
        }
        try? await Task.sleep(nanoseconds: 300_000_000)
    }
    
    // MARK: - Pose Guidance Overlay
    struct PoseGuidanceOverlay: View {
        let geometry: GeometryProxy
        let showHeadTilt: Bool
        let showSmile: Bool
        let showPosture: Bool
        
        var body: some View {
            ZStack {
                // Head tilt guide (curved arc at head position)
                if showHeadTilt {
                    ArcGuide(color: .blue)
                        .position(x: geometry.size.width * 0.5, y: geometry.size.height * 0.25)
                        .transition(.opacity.combined(with: .scale(scale: 0.8)))
                }
            }
        }
    }
    
    // MARK: - Arc Guide (for head tilt)
    struct ArcGuide: View {
        let color: Color
        @State private var animationProgress: CGFloat = 0
        
        var body: some View {
            Circle()
                .trim(from: 0, to: 0.25)
                .stroke(
                    style: StrokeStyle(
                        lineWidth: 3,
                        lineCap: .round,
                        dash: [8, 4]
                    )
                )
                .fill(color.opacity(0.6))
                .frame(width: 80, height: 80)
                .rotationEffect(.degrees(-45))
                .shadow(color: color.opacity(0.5), radius: 8)
                .scaleEffect(1 + animationProgress * 0.1)
                .onAppear {
                    withAnimation(
                        .easeInOut(duration: 0.8)
                        .repeatForever(autoreverses: true)
                    ) {
                        animationProgress = 1
                    }
                }
        }
    }
}
