//
//  CompositionShareView.swift
//  Klick
//
//  Created on 2025-12-18.
//  Composition Achievement Shareable Screen
//

import SwiftUI
import UIKit

/// A screen that displays a captured photo with composition achievement details
/// and provides sharing functionality via iOS native share sheet
struct CompositionShareView: View {
    // MARK: - Properties
    
    /// The captured photo to display
    let photo: UIImage
    
    /// The composition technique that was applied
    let compositionTechnique: String
    
    /// Educational description of the technique
    let techniqueDescription: String
    
    /// Called when the user successfully shares a photo (review hotspot)
    var onShared: (() -> Void)? = nil
    
    /// Environment for dismissing the view
    @Environment(\.dismiss) private var dismiss
    
    /// State for showing share sheet
    @State private var showingShareSheet = false
    
    /// Track view start time for time spent calculation
    @State private var viewStartTime: Date?
    
    /// Track if we've already logged the screen viewed event (prevents duplicates)
    @State private var hasLoggedViewEvent = false
    
    // MARK: - Animation States
    
    @State private var showHeader = false
    @State private var showTitle = false
    @State private var showSocialProof = false
    @State private var showPhoto = false
    @State private var showDescription = false
    @State private var showButton = false
    
    // Animated gradient rotation for hero card border
    @State private var gradientRotation: Double = 0
    
    // Animated glow intensity for smooth shimmer
    @State private var glowIntensity: Double = 0.3
    
    // MARK: - Body
    
    var body: some View {
        // Mesh-like gradient background
        // meshGradientBackground
        
        VStack(spacing: 20) {
            // Content
            VStack(spacing: 32) {
                // Title
                VStack(spacing: 12) {
                    VStack(spacing: 15) {
                        Image(.appLogo)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 32, height: 32)
                            .cornerRadius(6)
                            .shadow(color: .white.opacity(0.3), radius: 8, x: -1, y: -1)
                        
                        VStack {
                            Text("Your shot deserves")
                                .font(.system(size: 28, weight: .bold, design: .rounded))
                                .foregroundColor(.white)
                            Text("to be seen")
                                .font(.system(size: 28, weight: .medium, design: .rounded))
                                .foregroundColor(.white)
                        }
                    }
                    .opacity(showTitle ? 1 : 0)
                    .offset(y: showTitle ? 0 : 15)
                    
                    // Social Proof
                    VStack {
                        Image(.socialProofX3)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 65, height: 30)
                        
                        Text("Be among **300+** photographers who share their best shots")
                            .font(.system(size: 12, weight: .regular))
                            .foregroundColor(.white.opacity(0.9))
                            .multilineTextAlignment(.center)
                            .lineSpacing(4)
                            .padding(.horizontal, 24)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .opacity(showSocialProof ? 1 : 0)
                    .offset(y: showSocialProof ? 0 : 15)
                }
                
                // Photo Card
                photoCard
                    .opacity(showPhoto ? 1 : 0)
                    .scaleEffect(showPhoto ? 1 : 0.92)
                
                // Technique Description
                VStack(spacing: 12) {
                    Text("What you nailed")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.white.opacity(0.5))
                        .textCase(.uppercase)
                        .tracking(1.2)
                    
                    Text(techniqueDescription)
                        .font(.system(size: 16, weight: .regular))
                        .foregroundColor(.white.opacity(0.9))
                        .multilineTextAlignment(.center)
                        .lineSpacing(4)
                        .padding(.horizontal, 12)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .opacity(showDescription ? 1 : 0)
                .offset(y: showDescription ? 0 : 15)
            }
            
            Spacer()
            
            // Share CTA
            shareButton
                .opacity(showButton ? 1 : 0)
                .offset(y: showButton ? 0 : 15)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.horizontal, 24)
        .padding(.top, 32)
        .padding(.bottom, 40)
        .background(.black)
        .sheet(isPresented: $showingShareSheet) {
            ShareSheet(items: [photo]) { completed, destination in
                if completed {
                    // Track successful share
                    Task {
                        await EventTrackingManager.shared.trackPhotoShared(shareDestination: destination)
                    }
                    
                    onShared?()
                    
                    // Track dismiss with sharing
                    if let startTime = viewStartTime {
                        let timeSpent = Date().timeIntervalSince(startTime)
                        Task {
                            await EventTrackingManager.shared.trackShareScreenDismissed(
                                timeSpent: timeSpent,
                                shared: true
                            )
                        }
                    }
                    
                    // Dismiss the share view after successful share
                    dismiss()
                }
            }
        }
        .onAppear {
            // Track share screen viewed (only once to prevent duplicates)
            if !hasLoggedViewEvent {
                hasLoggedViewEvent = true
                viewStartTime = Date()
                Task {
                    await EventTrackingManager.shared.trackShareScreenViewed(
                        compositionType: compositionTechnique,
                        filterApplied: nil
                    )
                }
            }
            
            // Sequential reveal animations mimicking onboarding flow
            
            // 1. Header (logo + close button)
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                withAnimation(.easeOut(duration: 0.5)) {
                    showHeader = true
                }
            }
            
            // 2. Title
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
                withAnimation(.easeOut(duration: 0.6)) {
                    showTitle = true
                }
            }
            
            // 3. Social proof
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                withAnimation(.easeOut(duration: 0.6)) {
                    showSocialProof = true
                }
            }
            
            // 4. Photo card with spring animation
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.55) {
                withAnimation(.spring(response: 0.7, dampingFraction: 0.8)) {
                    showPhoto = true
                }
            }
            
            // 5. Technique description
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.75) {
                withAnimation(.easeOut(duration: 0.6)) {
                    showDescription = true
                }
            }
            
            // 6. Share button
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.9) {
                withAnimation(.easeOut(duration: 0.6)) {
                    showButton = true
                }
            }
        }
        .overlay(alignment: .top) {
            // Header with close button
            HStack {
                Spacer()
                
                Button(action: {
                    // Track dismiss without sharing
                    if let startTime = viewStartTime {
                        let timeSpent = Date().timeIntervalSince(startTime)
                        Task {
                            await EventTrackingManager.shared.trackShareScreenDismissed(
                                timeSpent: timeSpent,
                                shared: false
                            )
                        }
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
            .padding(.top, 32)
            .padding(.horizontal, 24)
            .opacity(showHeader ? 1 : 0)
            .offset(y: showHeader ? 0 : -10)
        }
    }
    
    
    // MARK: - Components
    
    /// Mesh-like gradient background with golden yellow and orange tones
    var meshGradientBackground: some View {
        ZStack {
            // Base golden gradient
            LinearGradient(
                colors: [
                    Color(red: 245/255, green: 176/255, blue: 2/255),  // Golden yellow
                    Color.orange
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            
            // Mesh effect - Top right blob
            RadialGradient(
                colors: [
                    Color.orange.opacity(0.8),
                    Color.clear
                ],
                center: .topTrailing,
                startRadius: 50,
                endRadius: 300
            )
            
            // Mesh effect - Bottom left blob
            RadialGradient(
                colors: [
                    Color(red: 255/255, green: 140/255, blue: 0/255).opacity(0.6), // Dark orange
                    Color.clear
                ],
                center: .bottomLeading,
                startRadius: 80,
                endRadius: 350
            )
            
            // Mesh effect - Middle accent
            RadialGradient(
                colors: [
                    Color(red: 255/255, green: 200/255, blue: 50/255).opacity(0.5), // Light golden
                    Color.clear
                ],
                center: .center,
                startRadius: 100,
                endRadius: 400
            )
            
            // Subtle overlay for depth
            LinearGradient(
                colors: [
                    Color.black.opacity(0.2),
                    Color.clear,
                    Color.black.opacity(0.3)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
        }
        .ignoresSafeArea()
    }
    
    private var photoCard: some View {
        ZStack {
            // Animated gradient border layer
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(
                    AngularGradient(
                        gradient: Gradient(colors: [
                            Color(red: 245/255, green: 176/255, blue: 2/255),  // Golden yellow
                            Color.orange,                                        // Orange
                            Color(red: 255/255, green: 220/255, blue: 100/255), // Light gold
                            Color.white,                                         // White
                            Color(red: 255/255, green: 140/255, blue: 0/255),   // Dark orange
                            Color(red: 245/255, green: 176/255, blue: 2/255)    // Back to golden
                        ]),
                        center: .center,
                        startAngle: .degrees(gradientRotation),
                        endAngle: .degrees(gradientRotation + 360)
                    )
                )
                .frame(width: 244, height: 324) // 2pt larger on each side for border
                .blur(radius: 2) // Slight blur for softer glow
                .shadow(
                    color: Color(red: 245/255, green: 176/255, blue: 2/255).opacity(glowIntensity),
                    radius: 10,
                    x: 0,
                    y: 0
                )
                .shadow(
                    color: Color.orange.opacity(glowIntensity * 0.5),
                    radius: 20,
                    x: 0,
                    y: 0
                )
            
            // Photo with inner border
            Image(uiImage: photo)
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(width: 240, height: 320)
                .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                        .stroke(Color.black.opacity(0.2), lineWidth: 1)
                )
                .shadow(color: .black.opacity(0.3), radius: 30, x: 0, y: 15)
                .overlay(alignment: .bottom) {
                    HStack {
                        Spacer()
                        Text(compositionTechnique)
                            .font(.system(size: 12, weight: .medium, design: .rounded))
                            .foregroundStyle(.black)
                            .padding(.vertical, 4)
                            .padding(.horizontal, 8)
                            .background(Color.yellow)
                            .clipShape(Capsule())
                        Spacer()
                    }
                    .padding(.bottom, 10)
                }
        }
        .onAppear {
            // Start infinite rotation animation when photo appears
            withAnimation(
                .linear(duration: 4)
                .repeatForever(autoreverses: false)
            ) {
                gradientRotation = 360
            }
            
            // Start smooth glow pulse animation
            withAnimation(
                .easeInOut(duration: 2.5)
                .repeatForever(autoreverses: true)
            ) {
                glowIntensity = 0.6
            }
        }
    }
    
    private var compositionBadge: some View {
        HStack(spacing: 4) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(.yellow)
            
            Text(compositionTechnique)
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(.white)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(
            Capsule()
                .fill(Color.black)
                .overlay(
                    Capsule()
                        .stroke(Color.white.opacity(0.3), lineWidth: 1)
                )
        )
        .shadow(color: .yellow.opacity(0.2), radius: 10, x: 0, y: 5)
    }
    
    private var shareButton: some View {
        Button(action: {
            showingShareSheet = true
        }) {
            HStack(spacing: 12) {
                Text("Share")
                    .font(.system(size: 18, weight: .semibold))
                
                Image(systemName: "square.and.arrow.up")
                    .font(.system(size: 16, weight: .semibold))
            }
            .foregroundColor(.black)
            .frame(maxWidth: .infinity)
            .frame(height: 56)
            .background(
                RoundedRectangle(cornerRadius: 32, style: .continuous)
                    .fill(.white)
            )
            .shadow(color: .white.opacity(0.2), radius: 15, x: 0, y: 8)
        }
    }
}

// MARK: - Share Sheet

/// UIKit ShareSheet wrapper for SwiftUI
struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]
    var onComplete: ((Bool, String?) -> Void)?
    
    func makeUIViewController(context: Context) -> UIActivityViewController {
        let controller = UIActivityViewController(
            activityItems: items,
            applicationActivities: nil
        )
        
        controller.completionWithItemsHandler = { activityType, completed, returnedItems, error in
            let destination = activityType?.rawValue
            onComplete?(completed, destination)
        }
        
        return controller
    }
    
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {
        // No updates needed
    }
}

// MARK: - Preview

#Preview("Composition Share - Rule of Thirds") {
    CompositionShareView(
        photo: .perspective1,
        compositionTechnique: "Rule of Thirds",
        techniqueDescription: "You positioned your subject perfectly, creating a balanced composition."
    )
}

