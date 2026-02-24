//
//  CompositionStylesOnboardingView.swift
//  Klick
//
//  One-time onboarding bottom sheet explaining composition styles.
//

import SwiftUI

struct CompositionStylesOnboardingView: View {
    @Binding var isPresented: Bool
    @State private var viewStartTime: Date = Date()

    var body: some View {
        VStack(spacing: 0) {
            coverSection
            
            Spacer()
            
            VStack(spacing: 25) {
                stylesSection
                gotItButton
            }
            .padding(.bottom, 34)
            .padding(.horizontal, 20)

        }
        .background(Color.black)
        .onAppear {
            viewStartTime = Date()
            Task {
                await EventTrackingManager.shared.trackOnboardingGuideViewed(guideType: .compositionStyles)
            }
        }
    }

    // MARK: - Cover Image

    private var coverSection: some View {
        Image(.onboarding2)
            .resizable()
            .aspectRatio(contentMode: .fill)
            .frame(maxWidth: .infinity)
            .frame(height: 400)
            .clipped()
            .overlay(alignment: .bottom, content: {
                LinearGradient(
                    stops: [
                        .init(color: .clear, location: 0),
                        .init(color: .black.opacity(0.45), location: 0.65),
                        .init(color: .black, location: 1)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
            })
            .overlay(alignment: .bottom) {
                VStack(spacing: 6) {
                    Text("Composition Styles")
                        .font(.system(size: 24, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)

                    Text("Pick your style and Klick guides you to the perfect portrait.")
                        .font(.system(size: 14, weight: .regular, design: .default))
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)
                }
                .padding(.horizontal, 40)
                .padding(.bottom, 50)
            }
    }

    // MARK: - Styles List

    private var stylesSection: some View {
        VStack(spacing: 20) {
            ForEach(CompositionType.allCases, id: \.self) { style in
                styleRow(for: style)
            }
        }
    }

    private func styleRow(for style: CompositionType) -> some View {
        HStack(alignment: .top, spacing: 16) {
            Image(systemName: style.icon)
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.white)
                .frame(width: 40, height: 40)
                .background(Circle().fill(Color.white.opacity(0.1)))

            VStack(alignment: .leading, spacing: 3) {
                Text(style.displayName)
                    .font(.system(size: 16, weight: .semibold, design: .default))
                    .foregroundColor(Color(white: 0.95))

                Text(styleHeadline(style))
                    .font(.system(size: 14, weight: .medium, design: .default))
                    .foregroundColor(Color(white: 0.75))

                Text(bestFor(style))
                    .font(.system(size: 14, weight: .regular, design: .default))
                    .foregroundColor(Color(white: 0.55))
                    .fixedSize(horizontal: false, vertical: true)
                    .lineSpacing(2)
                    .padding(.top, 1)
            }

            Spacer()
        }
    }

    // MARK: - CTA

    private var gotItButton: some View {
        Button(action: complete) {
            Text("Got It")
                .font(.system(size: 17, weight: .semibold))
                .foregroundColor(.black)
                .padding(.horizontal, 48)
                .padding(.vertical, 16)
                .background(
                    RoundedRectangle(cornerRadius: 25)
                        .fill(Color.white)
                )
                .shadow(color: .black.opacity(0.2), radius: 10, x: 0, y: 5)
        }
    }

    // MARK: - Actions

    private func complete() {
        let timeSpent = Date().timeIntervalSince(viewStartTime)
        Task {
            await EventTrackingManager.shared.trackOnboardingGuideDismissed(
                guideType: .compositionStyles,
                timeSpent: timeSpent
            )
        }
        withAnimation {
            isPresented = false
        }
    }

    private func dismiss() {
        let timeSpent = Date().timeIntervalSince(viewStartTime)
        Task {
            await EventTrackingManager.shared.trackOnboardingGuideDismissed(
                guideType: .compositionStyles,
                timeSpent: timeSpent
            )
        }
        withAnimation {
            isPresented = false
        }
    }

    // MARK: - Copy

    private func styleHeadline(_ style: CompositionType) -> String {
        switch style {
        case .ruleOfThirds:
            return "Master Balanced Compositions"
        case .centerFraming:
            return "Focus on What Matters"
        case .symmetry:
            return "Capture Perfect Harmony"
        }
    }

    private func bestFor(_ style: CompositionType) -> String {
        switch style {
        case .ruleOfThirds:
            return "Group photos, candid moments & portraits with energy"
        case .centerFraming:
            return "Solo portraits, professional headshots & close-up face shots"
        case .symmetry:
            return "Facing-forward portraits, couples & mirrored poses"
        }
    }
}

// MARK: - Preview

#Preview {
    ZStack {
        Color.black.ignoresSafeArea()
        VStack {
            CompositionStylesOnboardingView(isPresented: .constant(true))
        }
        .ignoresSafeArea(.container, edges: .bottom)
    }
}
