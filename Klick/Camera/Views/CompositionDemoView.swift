//
//  CompositionDemoView.swift
//  Klick
//
//  Created by Assistant on 11/08/2025.
//

import SwiftUI

/// Interactive composition demo view for onboarding
/// Mimics the real composition feedback UI with animations
struct CompositionDemoView: View {
    // Animation state
    @State private var currentStep: AnimationStep = .grid
    @State private var gridVisible = false
    @State private var subjectPosition: CGFloat = 20
    @State private var backgroundOffset: CGFloat = 8
    @State private var showArrow = false
    @State private var showConfirmation = false
    @State private var photoQuality: PhotoQuality? = .good
    
    // Grid animation states
    @State private var verticalLine1Scale: CGFloat = 0
    @State private var verticalLine2Scale: CGFloat = 0
    @State private var horizontalLine1Scale: CGFloat = 0
    @State private var horizontalLine2Scale: CGFloat = 0
    @State private var intersectionPointsVisible = false
    
    enum AnimationStep {
        case grid, drift, arrow, confirm, reset
    }
    
    enum PhotoQuality {
        case good, perfect
    }
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Background Image Layer
                ZStack {
                    Image(.perspective4)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: geometry.size.width, height: geometry.size.height)
                        .clipped()
                }
                .scaleEffect(1.15)
                .offset(x: backgroundOffset / 100 * geometry.size.width)
                .animation(.timingCurve(0.43, 0.13, 0.23, 0.96, duration: 1.5), value: backgroundOffset)
                
                // Rule of Thirds Grid Overlay
                if gridVisible {
                    RuleOfThirdsGrid(
                        verticalLine1Scale: verticalLine1Scale,
                        verticalLine2Scale: verticalLine2Scale,
                        horizontalLine1Scale: horizontalLine1Scale,
                        horizontalLine2Scale: horizontalLine2Scale,
                        intersectionPointsVisible: intersectionPointsVisible
                    )
                    .transition(.opacity)
                }
                
                // Subject Indicator - REMOVED per user request
                
                // Directional Arrow - synced with "Move to LEFT" label
                if photoQuality != .perfect {
                    DirectionalArrow()
                        .position(x: geometry.size.width * 0.25, y: geometry.size.height * 0.5)
                        .transition(.opacity.combined(with: .offset(x: 40)))
                        .opacity(gridVisible ? 1 : 0)
                        .animation(.easeOut(duration: 0.3), value: gridVisible)
                }
                
                // Photo Quality Label
                if let quality = photoQuality {
                    PhotoQualityLabel(quality: quality)
                        .position(x: geometry.size.width * 0.5, y: 40)
                        .transition(.opacity.combined(with: .offset(y: -10)))
                }
                
                // Instruction Text
                VStack {
                    Spacer()
                    
                    Text("Move to LEFT")
                        .font(.system(size: 17, weight: .medium))
                        .foregroundColor(.white)
                        .opacity(photoQuality == .perfect ? 0 : 1)
                        .animation(.easeOut(duration: 0.4), value: photoQuality)
                        .padding(.bottom, 32)
                        .padding(.horizontal, 32)
                }
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
                
                // Step 1: Grid Fade-In (0.4s)
                currentStep = .grid
                await animateGridIn()
                try? await Task.sleep(nanoseconds: 400_000_000)
                
                // Step 2: Subject Drift (1.5s)
                currentStep = .drift
                withAnimation(.timingCurve(0.43, 0.13, 0.23, 0.96, duration: 1.5)) {
                    subjectPosition = 0
                    backgroundOffset = -2
                }
                try? await Task.sleep(nanoseconds: 1_500_000_000)
                
                // Step 3: Quality feedback (0.7s)
                currentStep = .arrow
               
                // Arrow automatically hides when perfect quality is reached
                withAnimation(.easeOut(duration: 0.3)) {
                    photoQuality = .perfect
                }
                try? await Task.sleep(nanoseconds: 200_000_000)
                
                // Step 4: Confirmation (0.5s)
                currentStep = .confirm
                withAnimation(.easeOut(duration: 0.5)) {
                    showConfirmation = true
                }
                try? await Task.sleep(nanoseconds: 500_000_000)
                
                // Step 5: Reset (1s)
                currentStep = .reset
                try? await Task.sleep(nanoseconds: 1_000_000_000)
            }
        }
    }
    
    func resetState() async {
        withAnimation(.linear(duration: 0.2)) {
            gridVisible = false
            subjectPosition = 20
            backgroundOffset = 8
            showConfirmation = false
            photoQuality = nil
            verticalLine1Scale = 0
            verticalLine2Scale = 0
            horizontalLine1Scale = 0
            horizontalLine2Scale = 0
            intersectionPointsVisible = false
        }
        try? await Task.sleep(nanoseconds: 200_000_000)
    }
    
    func animateGridIn() async {
        withAnimation(.easeOut(duration: 0.4)) {
            gridVisible = true
        }
        
        // Animate vertical lines
        withAnimation(.easeOut(duration: 0.4)) {
            verticalLine1Scale = 1
        }
        try? await Task.sleep(nanoseconds: 50_000_000)
        
        withAnimation(.easeOut(duration: 0.4)) {
            verticalLine2Scale = 1
        }
        try? await Task.sleep(nanoseconds: 50_000_000)
        
        // Animate horizontal lines
        withAnimation(.easeOut(duration: 0.4)) {
            horizontalLine1Scale = 1
        }
        try? await Task.sleep(nanoseconds: 50_000_000)
        
        withAnimation(.easeOut(duration: 0.4)) {
            horizontalLine2Scale = 1
        }
        try? await Task.sleep(nanoseconds: 50_000_000)
        
        // Animate intersection points
        withAnimation(.easeOut(duration: 0.3)) {
            intersectionPointsVisible = true
        }
    }
    
    // MARK: - Rule of Thirds Grid
    struct RuleOfThirdsGrid: View {
        let verticalLine1Scale: CGFloat
        let verticalLine2Scale: CGFloat
        let horizontalLine1Scale: CGFloat
        let horizontalLine2Scale: CGFloat
        let intersectionPointsVisible: Bool
        
        var body: some View {
            GeometryReader { geometry in
                ZStack {
                    // Vertical lines
                    Rectangle()
                        .fill(Color.white.opacity(0.35))
                        .frame(width: 1, height: geometry.size.height * verticalLine1Scale)
                        .position(x: geometry.size.width / 3, y: geometry.size.height / 2)
                    
                    Rectangle()
                        .fill(Color.white.opacity(0.35))
                        .frame(width: 1, height: geometry.size.height * verticalLine2Scale)
                        .position(x: geometry.size.width * 2 / 3, y: geometry.size.height / 2)
                    
                    // Horizontal lines
                    Rectangle()
                        .fill(Color.white.opacity(0.35))
                        .frame(width: geometry.size.width * horizontalLine1Scale, height: 1)
                        .position(x: geometry.size.width / 2, y: geometry.size.height / 3)
                    
                    Rectangle()
                        .fill(Color.white.opacity(0.35))
                        .frame(width: geometry.size.width * horizontalLine2Scale, height: 1)
                        .position(x: geometry.size.width / 2, y: geometry.size.height * 2 / 3)
                    
                    // Intersection points
                    if intersectionPointsVisible {
                        ForEach(intersectionPoints, id: \.0) { point in
                            Circle()
                                .fill(Color.white.opacity(0.5))
                                .frame(width: 6, height: 6)
                                .position(
                                    x: geometry.size.width * point.1,
                                    y: geometry.size.height * point.2
                                )
                                .scaleEffect(intersectionPointsVisible ? 1 : 0)
                        }
                    }
                }
            }
        }
        
        var intersectionPoints: [(Int, CGFloat, CGFloat)] {
            [
                (0, 1/3, 1/3),
                (1, 2/3, 1/3),
                (2, 1/3, 2/3),
                (3, 2/3, 2/3)
            ]
        }
    }

    // MARK: - Subject Indicator
    struct SubjectIndicator: View {
        let showConfirmation: Bool
        let geometry: GeometryProxy
        
        var body: some View {
            ZStack {
                // Main circle
                Circle()
                    .strokeBorder(Color.white.opacity(0.6), lineWidth: 2)
                    .background(
                        Circle()
                            .fill(Color.white.opacity(0.1))
                            .background(.ultraThinMaterial)
                    )
                    .frame(width: 112, height: 112)
                    .opacity(showConfirmation ? 0 : 1)
                    .blur(radius: showConfirmation ? 20 : 0)
                    .animation(.easeOut(duration: 0.8), value: showConfirmation)
                
                // Confirmation effects
                if showConfirmation {
                    // Pulse glow
                    Circle()
                        .fill(Color.white.opacity(0.4))
                        .frame(width: 112, height: 112)
                        .scaleEffect(1.8)
                        .opacity(0)
                        .animation(.easeOut(duration: 0.5), value: showConfirmation)
                    
                    // Flash border
                    Circle()
                        .strokeBorder(Color.white, lineWidth: 4)
                        .frame(width: 112, height: 112)
                        .scaleEffect(1)
                        .opacity(0)
                        .onAppear {
                            withAnimation(.linear(duration: 0.5)) {}
                        }
                }
            }
            .position(x: geometry.size.width / 2, y: geometry.size.height / 2)
        }
    }

    // MARK: - Directional Arrow
    struct DirectionalArrow: View {
        @State private var arrowOffset: CGFloat = 0
        
        var body: some View {
            Image(systemName: "arrow.left")
                .font(.system(size: 30, weight: .semibold))
                .foregroundColor(.white)
                .offset(x: arrowOffset)
                .onAppear {
                    withAnimation(
                        .easeInOut(duration: 0.7)
                        .repeatCount(2, autoreverses: true)
                    ) {
                        arrowOffset = 8
                    }
                }
        }
    }

    // MARK: - Photo Quality Label
    struct PhotoQualityLabel: View {
        let quality: CompositionDemoView.PhotoQuality
        @State private var glowScale: CGFloat = 1
        @State private var glowOpacity: Double = 0.5
        
        var body: some View {
            ZStack {
                // Outer glow effect for "Perfect"
                if quality == .perfect {
                    RoundedRectangle(cornerRadius: 20)
                        .fill(Color.green.opacity(0.3))
                        .scaleEffect(glowScale)
                        .opacity(glowOpacity)
                        .onAppear {
                            withAnimation(.easeOut(duration: 0.6)) {
                                glowScale = 1.4
                                glowOpacity = 0
                            }
                        }
                }
                
                // Background container with ultra-thin material
                ZStack {
                    // Stacked text for smooth transition
                    ZStack {
                        // "Good" text
                        Text("Good")
                            .font(.system(size: 17, weight: .medium))
                            .foregroundColor(.white)
                            .opacity(quality == .good ? 1 : 0)
                            .scaleEffect(quality == .good ? 1 : 0.8)
                        
                        // "Perfect" text
                        Text("Perfect")
                            .font(.system(size: 17, weight: .medium))
                            .foregroundColor(.white)
                            .opacity(quality == .perfect ? 1 : 0)
                            .scaleEffect(quality == .perfect ? 1 : 0.8)
                    }
                    .animation(.easeInOut(duration: 0.4), value: quality)
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 8)
                .background(
                    RoundedRectangle(cornerRadius: 20)
                        .fill(.ultraThinMaterial)
                        .overlay(
                            RoundedRectangle(cornerRadius: 20)
                                .strokeBorder(Color.white.opacity(0.2), lineWidth: 1)
                        )
                )
                .shadow(color: .black.opacity(0.2), radius: 8, x: 0, y: 4)
            }
            .transition(.opacity.combined(with: .offset(y: -10)))
        }
    }
}
