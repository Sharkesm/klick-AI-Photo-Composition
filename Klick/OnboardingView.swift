//
//  OnboardingView.swift
//  Klick
//
//  Created by Assistant on 12/07/2025.
//

import SwiftUI

struct OnboardingView: View {
    @Binding var isPresented: Bool
    @State private var currentPage = 0
    @State private var showContent = false
    @State private var animateFeatures = false
    
    // Feature data matching the provided copy
    private let features = [
        OnboardingFeature(
            icon: "brain.head.profile",
            title: "Smart Composition",
            description: "Klick gives you live tips while you shoot — think \"Move left\" or \"Perfect thirds!\" so your portraits always look on point."
        ),
        OnboardingFeature(
            icon: "face.smiling",
            title: "Face-Focused",
            description: "Our camera spots faces in real time and helps you frame them beautifully."
        ),
        OnboardingFeature(
            icon: "viewfinder.rectangular",
            title: "Framing Controls",
            description: "Switch overlays, hide guides, or change composition styles without leaving the camera."
        ),
        OnboardingFeature(
            icon: "photo.on.rectangle.angled",
            title: "Your Gallery, Your Rules",
            description: "All your shots stay on your device — view, delete, or keep them in your private gallery."
        ),
        OnboardingFeature(
            icon: "lightbulb.max",
            title: "Learn As You Shoot",
            description: "Tap the info icon anytime to get quick, beginner-friendly photography tips."
        )
    ]
    
    var body: some View {
        ZStack {
            // Background
            Color.black
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Header with close button
                headerView
                
                ZStack {
                    // Main content
                    ScrollView {
                        VStack(spacing: 10) {
                            coverSection
                            
                            VStack(alignment: .leading, spacing: 40) {
                                // Title section
                                titleSection
                                
                                // Features list
                                featuresSection
                            }
                            .padding(.bottom, 115) // Space for floating button
                        }
                        .padding(.horizontal, 24)
                    }
                    .opacity(showContent ? 1 : 0)
                    .offset(y: showContent ? 0 : 20)
                    
                    // Bottom gradient for smooth scroll reveal
                    VStack {
                        Spacer()
                        LinearGradient(
                            stops: [
                                .init(color: Color.clear, location: 0),
                                .init(color: Color.black.opacity(0.3), location: 0.3),
                                .init(color: Color.black.opacity(0.7), location: 0.6),
                                .init(color: Color.black, location: 1)
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                        .frame(height: 100)
                    }
                    .ignoresSafeArea(edges: .bottom)
                    
                    // Floating button - always on top
                    VStack {
                        Spacer()
                        getStartedButton
                            .padding(.bottom, 20)
                    }
                }
            }
        }
        .onAppear {
            startAnimation()
        }
    }
    
    private var coverSection: some View {
        Image(.onboarding1)
            .resizable()
            .aspectRatio(contentMode: .fill)
            .frame(maxWidth: 280)
            .frame(height: 338)
            .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
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
                .cornerRadius(20)
            )
            .padding(.top, 30)
            .padding(.horizontal, 40)
    }
    
    private var headerView: some View {
        HStack {
            Spacer()
            
            Button(action: {
                withAnimation(.easeInOut(duration: 0.3)) {
                    isPresented = false
                }
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
        .padding(.horizontal, 24)
        .padding(.top, 20)
        .opacity(showContent ? 1 : 0)
    }
    
    private var titleSection: some View {
        VStack(spacing: 16) {
            Text("How Klick Works")
                .font(.system(size: 24, weight: .bold, design: .rounded))
                .foregroundColor(.white)
                .multilineTextAlignment(.center)
                .opacity(showContent ? 1 : 0)
                .scaleEffect(showContent ? 1 : 0.9)
                .frame(maxWidth: .infinity, alignment: .center)
        }
        .padding(.top, 20)
    }
    
    private var featuresSection: some View {
        VStack(spacing: 32) {
            ForEach(Array(features.enumerated()), id: \.offset) { index, feature in
                FeatureCard(
                    feature: feature,
                    animationDelay: Double(index) * 0.15
                )
                .opacity(animateFeatures ? 1 : 0)
                .offset(x: animateFeatures ? 0 : -30)
                .animation(
                    .easeOut(duration: 0.6)
                    .delay(Double(index) * 0.15),
                    value: animateFeatures
                )
            }
        }
    }
    
    private var getStartedButton: some View {
        Button(action: {
            withAnimation(.easeInOut(duration: 0.3)) {
                isPresented = false
            }
        }) {
            HStack {
                Text("Get Started")
                    .font(.system(size: 18, weight: .semibold, design: .rounded))
                    .foregroundColor(.black)
                
                Image(systemName: "arrow.right")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.black)
            }
            .padding(.horizontal, 32)
            .padding(.vertical, 16)
            .background(
                RoundedRectangle(cornerRadius: 25)
                    .fill(Color.white)
            )
            .shadow(color: .white.opacity(0.2), radius: 10, x: 0, y: 5)
        }
        .opacity(animateFeatures ? 1 : 0)
        .scaleEffect(animateFeatures ? 1 : 0.9)
        .animation(
            .easeOut(duration: 0.6)
            .delay(Double(features.count) * 0.15 + 0.3),
            value: animateFeatures
        )
    }
    
    private func startAnimation() {
        // Start content animation
        withAnimation(.easeOut(duration: 0.8)) {
            showContent = true
        }
        
        // Start features animation with delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
            animateFeatures = true
        }
    }
}

struct FeatureCard: View {
    let feature: OnboardingFeature
    let animationDelay: Double
    
    var body: some View {
        HStack(alignment: .top, spacing: 20) {
            // Icon
            VStack {
                Image(systemName: feature.icon)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.white)
                    .frame(width: 40, height: 40)
                    .background(
                        Circle()
                            .fill(Color.white.opacity(0.1))
                    )
            }
            
            // Content
            VStack(alignment: .leading, spacing: 8) {
                Text(feature.description)
                    .font(.system(size: 14, weight: .regular, design: .default))
                    .foregroundColor(.white)
                    .lineLimit(nil)
                    .multilineTextAlignment(.leading)
            }
            
            Spacer()
        }
        .padding(.horizontal, 4)
    }
}

struct OnboardingFeature {
    let icon: String
    let title: String
    let description: String
}

// Preview
struct OnboardingView_Previews: PreviewProvider {
    static var previews: some View {
        OnboardingView(isPresented: .constant(true))
            .preferredColorScheme(.dark)
    }
}
