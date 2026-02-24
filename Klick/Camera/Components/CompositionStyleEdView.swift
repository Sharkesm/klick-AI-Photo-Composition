//
//  CompositionStyleEdView.swift
//  Klick
//
//  Created by Manase on 23/08/2025.
//

import SwiftUI

struct CompositionStyleEdView: View {
    @State private var selectedSection: CompositionSection? = nil
    @State private var showContent = false
    @State private var animateSections = false
    @State private var viewStartTime: Date?
    @ObservedObject var featureManager: FeatureManager
    @State private var showUpgradePrompt = false
    @State private var upgradeContext: FeatureManager.UpgradeContext = .portraitPractices
    let onShowSalesPage: (() -> Void)?
    var onPracticeSectionViewed: (() -> Void)? = nil
    @Environment(\.dismiss) private var dismiss
    
    // Portrait essentials sections
    private let sections = [
        CompositionSection(
            id: "lighting",
            icon: "light.max",
            title: "Lighting",
            description: "Light makes or breaks your portrait.\n\nSoft light, smooth skin and dreamy vibes.",
            detailedDescription: "Good lighting is like free photo editing. Shooting in harsh midday sun often creates unflattering shadows. Instead, try the golden hour (just after sunrise or before sunset) for warm, flattering tones. Indoors? Stand near a window and let soft daylight wrap around your face.",
            proTip: "Look for catchlights (tiny reflections in the eyes) — they instantly make your portraits feel alive.",
            imageItems: ["Lighting1", "Lighting2", "Lighting3"]
        ),
        CompositionSection(
            id: "expression",
            icon: "face.dashed",
            title: "Expression",
            description: "Real smiles beat fake poses. Relax, laugh, and let your vibe shine through.",
            detailedDescription: "The difference between a \"meh\" photo and a scroll-stopper is emotion. Instead of asking your friend to \"smile,\" crack a joke or play their favorite song. Natural laughter or even a thoughtful gaze looks way better than stiff posing.",
            proTip: "Ask your subject to look away, then look back into the camera — you'll capture a moment that feels real.",
            imageItems: ["Expression1", "Expression2", "Expression3"]
        ),
        CompositionSection(
            id: "angles",
            icon: "angle",
            title: "Angles & Perspective",
            description: "Move around, not just your subject. Angles change the whole story.",
            detailedDescription: "Eye-level is safe, but it's not always the most flattering. Shoot slightly above for a softer, approachable vibe. From below? It adds power and confidence. Even shifting a few steps left or right can make backgrounds cleaner and faces more defined.",
            proTip: "Snap 3 photos — one at eye level, one above, one below. Compare them and see which matches the mood best.",
            imageItems: ["Perspective1", "Perspective2", "Perspective3"]
        ),
        CompositionSection(
            id: "framing",
            icon: "righttriangle",
            title: "Framing & Background",
            description: "What's behind matters too. A clean frame = all eyes on you.",
            detailedDescription: "A busy background can steal the spotlight. Before pressing the shutter, look for trash cans, poles, or random photobombers in the frame. Simple walls, trees, or open skies keep the focus on the subject.",
            proTip: "Use depth — place your subject a few steps away from the background for a natural blur.",
            imageItems: []
        ),
        CompositionSection(
            id: "styling",
            icon: "tshirt",
            title: "Styling & Details",
            description: "Outfits, hair, little touches — small details, big impact.",
            detailedDescription: "Clothing sets the mood: soft pastels feel calm, bold colors pop with energy. Avoid loud patterns that distract. A quick check for flyaway hair, wrinkled sleeves, or uneven accessories makes portraits look instantly more polished.",
            proTip: "A casual beach shoot? Light, flowing outfits. Urban vibe? Denim, sneakers, sharp lines.",
            imageItems: ["Style1", "Style2", "Style3"]
        )
    ]
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea(.all)
            
            if let selectedSection = selectedSection {
                CompositionDetailView(
                    section: selectedSection,
                    onBack: {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            self.selectedSection = nil
                        }
                    }
                )
            } else {
                ScrollView {
                    VStack(spacing: 10) {
                        coverSection
                        
                        VStack(alignment: .leading, spacing: 32) {
                            sectionsGrid
                        }
                        .padding(.horizontal, 24)
                        .padding(.bottom, 40)
                    }
                }
                .opacity(showContent ? 1 : 0)
                .offset(y: showContent ? 0 : 20)
            }
        }
        .onAppear {
            viewStartTime = Date()
            Task {
                await EventTrackingManager.shared.trackPracticeViewed(compositionType: "portrait_essentials")
            }
            startAnimation()
        }
        .onDisappear {
            if let startTime = viewStartTime {
                let timeSpent = Date().timeIntervalSince(startTime)
                Task {
                    await EventTrackingManager.shared.trackPracticeDismissed(
                        compositionType: "portrait_essentials",
                        timeSpent: timeSpent
                    )
                }
            }
        }
        .ngBottomSheet(isPresented: $showUpgradePrompt, sheetContent: {
            UpgradePromptAlert(
                context: upgradeContext,
                isPresented: $showUpgradePrompt,
                featureManager: featureManager,
                onUpgrade: {
                    // Show sales page
                    onShowSalesPage?()
                }
            )
        })
    }
}

extension CompositionStyleEdView {
    
    var coverSection: some View {
        Image(.rectangle1)
            .resizable()
            .aspectRatio(contentMode: .fill)
            .frame(maxWidth: .infinity)
            .frame(height: 400)
            .clipShape(Rectangle())
            .overlay(
                // Bottom gradient overlay
                LinearGradient(
                    stops: [
                        .init(color: Color.clear, location: 0),
                        .init(color: Color.black.opacity(0.5), location: 0.6),
                        .init(color: Color.black.opacity(0.8), location: 0.78),
                        .init(color: Color.black, location: 1)
                    ],
                    startPoint: .init(x: 0.5, y: 0),
                    endPoint: .bottom
                )
            )
            .overlay(alignment: .bottomLeading) {
                Text("Best Practices\nfor Portraits")
                    .font(.system(size: 32, weight: .bold, design: .rounded))
                    .foregroundStyle(Color.white)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 10)
            }
    }
    
    var sectionsGrid: some View {
        VStack(spacing: 24) {
            ForEach(Array(sections.enumerated()), id: \.offset) { index, section in
                CompositionSectionCard(
                    section: section,
                    isLocked: !isPracticeUnlocked(section.id),
                    onTap: {
                        // Check if practice is locked
                        if !isPracticeUnlocked(section.id) {
                            SVLogger.main.log(message: "Practice '\(section.title)' blocked - requires Pro", logLevel: .warning)
                            onShowSalesPage?()
                            return
                        }
                        
                        // Track example selected
                        Task {
                            await EventTrackingManager.shared.trackPracticeExampleSelected(
                                compositionType: "portrait_essentials",
                                exampleType: section.id
                            )
                        }
                        
                        onPracticeSectionViewed?()
                        
                        withAnimation(.easeInOut(duration: 0.3)) {
                            selectedSection = section
                        }
                    }
                )
                .opacity(animateSections ? 1 : 0)
                .offset(x: animateSections ? 0 : -30)
                .animation(
                    .easeOut(duration: 0.6)
                    .delay(Double(index) * 0.15),
                    value: animateSections
                )
            }
        }
    }
    
    /// Check if a practice is unlocked for the current user
    private func isPracticeUnlocked(_ practiceId: String) -> Bool {
        // Pro users or users in trial period can access all practices
        if featureManager.isPro || featureManager.isInTrialPeriod {
            return true
        }
        
        // Free users can only access "lighting" practice
        return practiceId == "lighting"
    }
    
    private func startAnimation() {
        // Start content animation
        withAnimation(.easeOut(duration: 0.8)) {
            showContent = true
        }
        
        // Start sections animation with delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
            animateSections = true
        }
    }
}

// MARK: - Section Card View
struct CompositionSectionCard: View {
    let section: CompositionSection
    let isLocked: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            ZStack(alignment: .bottomTrailing) {
                HStack(alignment: .top, spacing: 20) {
                    // Icon
                    VStack {
                        Image(systemName: section.icon)
                            .font(.system(size: 18, weight: .medium))
                            .foregroundColor(isLocked ? .white.opacity(0.5) : .white)
                            .frame(width: 40, height: 40)
                            .background(
                                Circle()
                                    .fill(Color.white.opacity(0.1))
                            )
                    }
                    
                    // Content
                    VStack(alignment: .leading, spacing: 8) {
                        Text(section.title)
                            .font(.system(size: 18, weight: .semibold, design: .rounded))
                            .foregroundColor(isLocked ? .white.opacity(0.5) : .white)
                            .multilineTextAlignment(.leading)
                        
                        Text(section.description)
                            .font(.system(size: 14, weight: .regular))
                            .foregroundColor(isLocked ? .white.opacity(0.4) : .white.opacity(0.8))
                            .lineLimit(3)
                            .multilineTextAlignment(.leading)
                    }
                    
                    Spacer()
                    
                    // Arrow
                    Image(systemName: "chevron.right")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(isLocked ? .white.opacity(0.3) : .white.opacity(0.6))
                }
                .padding(20)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color.white.opacity(isLocked ? 0.03 : 0.05))
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(Color.white.opacity(isLocked ? 0.05 : 0.1), lineWidth: 1)
                        )
                )
                
                // Lock icon at bottom right
                if isLocked {
                    Image(systemName: "lock.fill")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(.white.opacity(0.6))
                        .frame(width: 24, height: 24)
                        .background(
                            Circle()
                                .fill(Color.black.opacity(0.6))
                        )
                        .padding(12)
                }
            }
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Detail View
struct CompositionDetailView: View {
    let section: CompositionSection
    let onBack: () -> Void
    @State private var showContent = false
    @State private var animateTips = false
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea(.all)
            
            ScrollView {
                VStack(spacing: 24) {
                    // Header
                    headerView
                    
                    VStack(alignment: .leading, spacing: 32) {
                        // Title and description
                        titleSection
                        
                        // Tips
                        tipsSection
                        
                        // Examples of images
                        
                        if section.imageItems.count > 0 {
                            LazyHStack(spacing: 5) {
                                ForEach(section.imageItems, id: \.self) { imageString in
                                    Image(imageString)
                                        .resizable()
                                        .aspectRatio(contentMode: .fill)
                                        .frame(width: 110, height: 150)
                                        .cornerRadius(12)
                                }
                            }
                            .frame(maxWidth: .infinity)
                        }
                    }
                    .padding(.horizontal, 24)
                    .padding(.bottom, 40)
                }
            }
        }
        .opacity(showContent ? 1 : 0)
        .offset(y: showContent ? 0 : 20)
        .onAppear {
            startAnimation()
        }
    }
    
    private var headerView: some View {
        HStack {
            Button(action: onBack) {
                Image(systemName: "chevron.left")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.white.opacity(0.7))
                    .frame(width: 32, height: 32)
                    .background(
                        Circle()
                            .fill(Color.white.opacity(0.1))
                    )
            }
            
            Spacer()
        }
        .padding(.horizontal, 24)
        .padding(.top, 20) // Increased to account for safe area
        .opacity(showContent ? 1 : 0)
    }
    
    private var titleSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 10) {
                Image(systemName: section.icon)
                    .font(.system(size: 18, weight: .medium))
                    .foregroundColor(.white)
                    .frame(width: 40, height: 40)
                    .foregroundColor(.white)
                
                Text(section.title)
                    .font(.system(size: 24, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
            }
            
            VStack(alignment: .leading, spacing: 10) {
                Text(section.description)
                    .font(.system(size: 16, weight: .regular))
                    .foregroundColor(.white.opacity(0.8))
                    .lineLimit(nil)
                
                Text(section.detailedDescription)
                    .font(.system(size: 16, weight: .regular))
                    .foregroundColor(.white.opacity(0.9))
                    .lineLimit(nil)
            }
        }
        .opacity(showContent ? 1 : 0)
        .scaleEffect(showContent ? 1 : 0.9)
    }
    
    private var tipsSection: some View {
        // Detailed description
        VStack(alignment: .leading, spacing: 16) {
            // Pro tip
            VStack(alignment: .leading, spacing: 4) {
                Text("👉 Pro tip:")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.white.opacity(0.7))
                
                Text(section.proTip)
                    .font(.system(size: 14, weight: .regular))
                    .foregroundColor(.white.opacity(0.8))
                    .lineLimit(nil)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white.opacity(0.05))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.white.opacity(0.1), lineWidth: 1)
                )
        )
        .opacity(animateTips ? 1 : 0)
        .offset(x: animateTips ? 0 : -30)
        .animation(
            .easeOut(duration: 0.6),
            value: animateTips
        )
    }
    
    private func startAnimation() {
        withAnimation(.easeOut(duration: 0.8)) {
            showContent = true
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
            animateTips = true
        }
    }
}

// MARK: - Data Models
struct CompositionSection {
    let id: String
    let icon: String
    let title: String
    let description: String
    let detailedDescription: String
    let proTip: String
    let imageItems: [String]
}

struct CompositionStylePracticeControl: View {
    @Binding var showCompositionPractice: Bool
    
    var body: some View {
        Button(action: {
            withAnimation(.easeInOut(duration: 0.2)) {
                showCompositionPractice = true
            }
        }) {
            Image(systemName: "graduationcap")
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.white)
        }
        .frame(width: 42, height: 42)
        .background(Color.black.opacity(0.5))
        .clipShape(Capsule())
    }
}

#Preview(body: {
    CompositionStyleEdView(featureManager: .init(), onShowSalesPage: nil)
})
