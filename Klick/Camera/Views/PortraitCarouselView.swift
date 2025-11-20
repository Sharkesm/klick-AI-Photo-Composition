//
//  PortraitCarouselView.swift
//  Klick
//
//  Created by Assistant on 12/10/2025.
//

import SwiftUI

/// Interactive portrait carousel for onboarding Screen 1
/// Cycles through composition types with matching overlays and icons
struct PortraitCarouselView: View {
    // Animation state
    @State private var currentCompositionIndex: Int = 0
    @State private var currentImageIndex: Int = 0
    @State private var imageOpacity: Double = 1.0
    @State private var overlayOpacity: Double = 0.0
    @State private var iconOpacity: Double = 0.0
    @State private var iconScale: CGFloat = 0.8
    @State private var overlayTrigger: Int = 0 // Trigger overlay animations
    @State private var overlaysEnabled: Bool = true // User toggle for overlays
    
    // Composition data
    private let compositions: [(type: CompositionType, images: [String])] = [
        (.ruleOfThirds, ["ruleOfThird_1", "ruleOfThird_2", "ruleOfThird_3"]),
        (.centerFraming, ["center_1", "center_2", "center_3"]),
        (.symmetry, ["symmetric_1", "symmetric_2", "symmetric_3"])
    ]
    
    var body: some View {
        VStack(spacing: 0) {
            // Image carousel container
            GeometryReader { geometry in
                ZStack {
                    // Background
                    Color(red: 0.02, green: 0.05, blue: 0.13)
                        .ignoresSafeArea()
                    
                    // Current image
                    Image(compositions[currentCompositionIndex].images[currentImageIndex])
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: geometry.size.width, height: geometry.size.height)
                        .clipped()
                        .opacity(imageOpacity)
                    
                    // Composition overlay (only shown if enabled)
                    if overlaysEnabled {
                        CompositionOverlay(
                            type: compositions[currentCompositionIndex].type,
                            geometry: geometry,
                            opacity: overlayOpacity,
                            trigger: overlayTrigger
                        )
                    }
                    
                    // Bottom icon indicator (inside image container)
                    VStack {
                        Spacer()
                        
                        HStack {
                            Spacer()
                            
                            // Composition icon
                            Image(systemName: compositions[currentCompositionIndex].type.icon)
                                .font(.system(size: 20, weight: .medium))
                                .foregroundColor(.white)
                                .frame(width: 40, height: 40)
                                .background(
                                    Circle()
                                        .fill(.ultraThinMaterial)
                                        .overlay(
                                            Circle()
                                                .stroke(Color.white.opacity(0.2), lineWidth: 1)
                                        )
                                )
                                .opacity(iconOpacity)
                                .scaleEffect(iconScale)
                                .shadow(color: .black.opacity(0.3), radius: 8, x: 0, y: 4)
                            
                            Spacer()
                        }
                        .padding(.bottom, 24)
                    }
                }
                .frame(width: geometry.size.width, height: geometry.size.height)
            }
            .aspectRatio(3/4, contentMode: .fit)
            .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .stroke(Color.white.opacity(0.1), lineWidth: 1)
            )
            .shadow(color: .black.opacity(0.3), radius: 20, x: 0, y: 10)
            
            // Toggle button (outside image container, at bottom)
            Button(action: {
                HapticFeedback.selection.generate()
                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                    overlaysEnabled.toggle()
                }
            }) {
                HStack(spacing: 8) {
                    Image(systemName: overlaysEnabled ? "eye.fill" : "eye.slash.fill")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.white)
                    
                    Text(overlaysEnabled ? "Hide Guides" : "Show Guides")
                        .font(.system(size: 13, weight: .medium, design: .rounded))
                        .foregroundColor(.white)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(
                    Capsule()
                        .fill(.ultraThinMaterial)
                        .overlay(
                            Capsule()
                                .stroke(Color.white.opacity(0.2), lineWidth: 1)
                        )
                )
                .shadow(color: .black.opacity(0.2), radius: 4, x: 0, y: 2)
            }
            .buttonStyle(PlainButtonStyle())
            .padding(.top, 12)
        }
        .onAppear {
            // Initialize overlay and icon immediately
            overlayTrigger += 1
            overlayOpacity = 1.0
            iconOpacity = 1.0
            iconScale = 1.0
            
            // Start animation sequence
            runAnimationSequence()
        }
    }
    
    func runAnimationSequence() {
        // Show initial composition immediately
        Task { @MainActor in
            // Show first composition right away
            await showComposition()
            
            // Initial delay before starting the cycle
            try? await Task.sleep(nanoseconds: 500_000_000) // 0.5s
            
            while true {
                // Cycle through images for this composition
                for _ in 0..<compositions[currentCompositionIndex].images.count {
                    try? await Task.sleep(nanoseconds: 2_500_000_000) // 2.5s per image
                    
                    // Transition to next image
                    await transitionToNextImage()
                }
                
                // Move to next composition
                await transitionToNextComposition()
            }
        }
    }
    
    func showComposition() async {
        // Trigger overlay animation
        overlayTrigger += 1
        
        // Fade in overlay
        withAnimation(.easeOut(duration: 0.6)) {
            overlayOpacity = 1.0
        }
        
        // Show icon with animation
        withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
            iconOpacity = 1.0
            iconScale = 1.0
        }
        
        try? await Task.sleep(nanoseconds: 300_000_000) // 0.3s
    }
    
    func transitionToNextImage() async {
        // Fade out current image
        withAnimation(.easeIn(duration: 0.4)) {
            imageOpacity = 0.0
        }
        
        try? await Task.sleep(nanoseconds: 400_000_000) // 0.4s
        
        // Update image index
        currentImageIndex = (currentImageIndex + 1) % compositions[currentCompositionIndex].images.count
        
        // Fade in new image
        withAnimation(.easeOut(duration: 0.4)) {
            imageOpacity = 1.0
        }
        
        try? await Task.sleep(nanoseconds: 400_000_000) // 0.4s
    }
    
    func transitionToNextComposition() async {
        // Fade out overlay and icon
        withAnimation(.easeIn(duration: 0.3)) {
            overlayOpacity = 0.0
            iconOpacity = 0.0
            iconScale = 0.8
        }
        
        try? await Task.sleep(nanoseconds: 300_000_000) // 0.3s
        
        // Update composition index
        currentCompositionIndex = (currentCompositionIndex + 1) % compositions.count
        currentImageIndex = 0
        
        // Reset image opacity for smooth transition
        imageOpacity = 1.0
        
        // Fade in new composition
        await showComposition()
    }
}

// MARK: - Composition Overlay

struct CompositionOverlay: View {
    let type: CompositionType
    let geometry: GeometryProxy
    let opacity: Double
    let trigger: Int
    
    var body: some View {
        ZStack {
            switch type {
            case .ruleOfThirds:
                RuleOfThirdsGridOverlay(geometry: geometry, opacity: opacity, trigger: trigger)
            case .centerFraming:
                CenterCrosshairOverlay(geometry: geometry, opacity: opacity, trigger: trigger)
            case .symmetry:
                SymmetryLineOverlay(geometry: geometry, opacity: opacity, trigger: trigger)
            }
        }
    }
}

// MARK: - Rule of Thirds Grid Overlay

struct RuleOfThirdsGridOverlay: View {
    let geometry: GeometryProxy
    let opacity: Double
    let trigger: Int
    @State private var verticalLine1Scale: CGFloat = 0
    @State private var verticalLine2Scale: CGFloat = 0
    @State private var horizontalLine1Scale: CGFloat = 0
    @State private var horizontalLine2Scale: CGFloat = 0
    @State private var intersectionPointsVisible = false
    
    var body: some View {
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
                }
            }
        }
        .opacity(opacity)
        .onChange(of: trigger) { _ in
            if opacity > 0 {
                animateGridIn()
            } else {
                resetGrid()
            }
        }
        .onAppear {
            if opacity > 0 {
                animateGridIn()
            }
        }
    }
    
    func animateGridIn() {
        // Reset first
        resetGrid()
        
        // Animate vertical lines
        withAnimation(.easeOut(duration: 0.4)) {
            verticalLine1Scale = 1
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
            withAnimation(.easeOut(duration: 0.4)) {
                verticalLine2Scale = 1
            }
        }
        
        // Animate horizontal lines
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            withAnimation(.easeOut(duration: 0.4)) {
                horizontalLine1Scale = 1
            }
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
            withAnimation(.easeOut(duration: 0.4)) {
                horizontalLine2Scale = 1
            }
        }
        
        // Animate intersection points
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            withAnimation(.easeOut(duration: 0.3)) {
                intersectionPointsVisible = true
            }
        }
    }
    
    func resetGrid() {
        verticalLine1Scale = 0
        verticalLine2Scale = 0
        horizontalLine1Scale = 0
        horizontalLine2Scale = 0
        intersectionPointsVisible = false
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

// MARK: - Center Crosshair Overlay

struct CenterCrosshairOverlay: View {
    let geometry: GeometryProxy
    let opacity: Double
    let trigger: Int
    @State private var crosshairScale: CGFloat = 0
    
    var body: some View {
        ZStack {
            let centerX = geometry.size.width / 2
            let centerY = geometry.size.height / 2
            let crosshairSize: CGFloat = 24
            
            // Horizontal line
            Rectangle()
                .fill(Color.white.opacity(0.6))
                .frame(width: crosshairSize * crosshairScale, height: 1.5)
                .position(x: centerX, y: centerY)
            
            // Vertical line
            Rectangle()
                .fill(Color.white.opacity(0.6))
                .frame(width: 1.5, height: crosshairSize * crosshairScale)
                .position(x: centerX, y: centerY)
        }
        .opacity(opacity)
        .onChange(of: trigger) { _ in
            if opacity > 0 {
                withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                    crosshairScale = 1.0
                }
            } else {
                crosshairScale = 0
            }
        }
        .onAppear {
            if opacity > 0 {
                withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                    crosshairScale = 1.0
                }
            }
        }
    }
}

// MARK: - Symmetry Line Overlay

struct SymmetryLineOverlay: View {
    let geometry: GeometryProxy
    let opacity: Double
    let trigger: Int
    @State private var lineScale: CGFloat = 0
    
    var body: some View {
        Rectangle()
            .fill(Color.yellow.opacity(0.4))
            .frame(width: 2, height: geometry.size.height * lineScale)
            .position(x: geometry.size.width / 2, y: geometry.size.height / 2)
            .opacity(opacity)
            .onChange(of: trigger) { _ in
                if opacity > 0 {
                    withAnimation(.easeOut(duration: 0.5)) {
                        lineScale = 1.0
                    }
                } else {
                    lineScale = 0
                }
            }
            .onAppear {
                if opacity > 0 {
                    withAnimation(.easeOut(duration: 0.5)) {
                        lineScale = 1.0
                    }
                }
            }
    }
}
