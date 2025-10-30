//
//  OnboardFlowView.swift
//  Klick
//
//  Created by Manase on 19/10/2025.
//

import SwiftUI

struct OnboardFlowView: View {
    @Binding var isPresented: Bool
    @State private var showContent = false
    @State private var animateCards = false
    @State private var animateButton = false
    @State private var currentCardIndex = 0
    
    // Action-oriented cards data
    private let achievementCards: [(icon: String, number: String, title: String, description: String, gradientColors: [Color])] = [
        (
            icon: "camera.fill",
            number: "1",
            title: "Point & Shoot",
            description: "Just open and tap to capture",
            gradientColors: [
                Color(red: 0.4, green: 0.1, blue: 0.3),
                Color(red: 0.2, green: 0.05, blue: 0.2)
            ]
        ),
        (
            icon: "squareshape.split.2x2.dotted",
            number: "2",
            title: "Get Guided",
            description: "On-screen guides help you frame perfectly",
            gradientColors: [
                Color(red: 0.1, green: 0.3, blue: 0.5),
                Color(red: 0.05, green: 0.2, blue: 0.35)
            ]
        ),
        (
            icon: "wand.and.stars",
            number: "3",
            title: "Make It Pop",
            description: "Add filters and save to your gallery",
            gradientColors: [
                Color(red: 0.5, green: 0.4, blue: 0.1),
                Color(red: 0.3, green: 0.25, blue: 0.05)
            ]
        )
    ]
    
    var body: some View {
        ZStack {
            // Dark background with subtle gradient
            LinearGradient(
                stops: [
                    .init(color: Color(red: 0.05, green: 0.05, blue: 0.08), location: 0),
                    .init(color: Color.black, location: 1)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
            
            VStack(spacing: 0) {
                
                // Achievement cards carousel with peek effect
                CarouselView(
                    currentIndex: $currentCardIndex,
                    itemCount: achievementCards.count,
                    animateCards: animateCards
                ) { index in
                    let card = achievementCards[index]
                    AchievementCard(
                        icon: card.icon,
                        number: card.number,
                        title: card.title,
                        description: card.description,
                        gradientColors: card.gradientColors
                    )
                }
                .frame(height: 300)
                
                Spacer()
                    .frame(height: 12)
                
                // Page indicator dots
                HStack(spacing: 8) {
                    ForEach(0..<achievementCards.count, id: \.self) { index in
                        Circle()
                            .fill(index == currentCardIndex ? Color.white : Color.white.opacity(0.3))
                            .frame(width: index == currentCardIndex ? 8 : 6, height: index == currentCardIndex ? 8 : 6)
                            .animation(.spring(response: 0.4, dampingFraction: 0.7), value: currentCardIndex)
                    }
                }
                .opacity(animateCards ? 1 : 0)
                .animation(.easeOut(duration: 0.6).delay(0.6), value: animateCards)
                
                Spacer()
                    .frame(height: 20)
                
                // Feature highlight pill
                HStack(spacing: 8) {
                    Image(systemName: "sparkles")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(Color(red: 1.0, green: 0.8, blue: 0.0))
                    
                    Text("Learn by doing")
                        .font(.system(size: 13, weight: .medium, design: .rounded))
                        .foregroundColor(.white)
                    
                    Text("Interactive")
                        .font(.system(size: 13, weight: .semibold, design: .rounded))
                        .foregroundColor(Color(red: 1.0, green: 0.8, blue: 0.0))
                }
                .padding(.horizontal, 18)
                .padding(.vertical, 10)
                .background(
                    Capsule()
                        .fill(Color.white.opacity(0.1))
                        .overlay(
                            Capsule()
                                .stroke(Color.white.opacity(0.15), lineWidth: 1)
                        )
                )
                .opacity(animateCards ? 1 : 0)
                .scaleEffect(animateCards ? 1 : 0.8)
                .animation(.spring(response: 0.6, dampingFraction: 0.7).delay(0.5), value: animateCards)
                
                Spacer()
                    .frame(height: 32)
                
                // Main congratulations message
                VStack(spacing: 8) {
                    Text("Ready to start")
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                    
                    Text("capturing?")
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                }
                .multilineTextAlignment(.center)
                .opacity(showContent ? 1 : 0)
                .offset(y: showContent ? 0 : 20)
                .animation(.easeOut(duration: 0.8).delay(0.7), value: showContent)
                
                Spacer()
                    .frame(height: 12)
                
                // Subtitle
                Text("Get instant guidance as you shoot\nwith simple on-screen guides")
                    .font(.system(size: 15, weight: .regular, design: .rounded))
                    .foregroundColor(.white.opacity(0.7))
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .padding(.horizontal, 32)
                    .opacity(showContent ? 1 : 0)
                    .animation(.easeOut(duration: 0.8).delay(0.85), value: showContent)
                
                Spacer()
                
                // Continue button
                Button(action: {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        isPresented = false
                    }
                }) {
                    Text("Continue")
                        .font(.system(size: 17, weight: .semibold, design: .rounded))
                        .foregroundColor(.black)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(
                            RoundedRectangle(cornerRadius: 28)
                                .fill(Color.white)
                        )
                        .shadow(color: .white.opacity(0.2), radius: 15, x: 0, y: 8)
                }
                .padding(.horizontal, 32)
                .opacity(animateButton ? 1 : 0)
                .scaleEffect(animateButton ? 1 : 0.9)
                .animation(.spring(response: 0.6, dampingFraction: 0.7).delay(1.0), value: animateButton)
                
                Spacer()
                    .frame(height: 16)
                
                // Skip option
                Button(action: {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        isPresented = false
                    }
                }) {
                    Text("Skip for now")
                        .font(.system(size: 15, weight: .medium, design: .rounded))
                        .foregroundColor(.white.opacity(0.5))
                }
                .opacity(animateButton ? 1 : 0)
                .animation(.easeOut(duration: 0.6).delay(1.2), value: animateButton)
                
                Spacer()
                    .frame(height: 40)
            }
        }
        .onAppear {
            startAnimations()
        }
    }
    
    private func startAnimations() {
        withAnimation {
            showContent = true
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            animateCards = true
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            animateButton = true
        }
    }
}

// Carousel View with Peek Effect
struct CarouselView<Content: View>: View {
    @Binding var currentIndex: Int
    let itemCount: Int
    let animateCards: Bool
    @ViewBuilder let content: (Int) -> Content
    
    @GestureState private var dragOffset: CGFloat = 0
    
    var body: some View {
        GeometryReader { geometry in
            let cardWidth = geometry.size.width * 0.85 // 85% of screen width for better visibility
            let spacing: CGFloat = 16
            let totalWidth = cardWidth + spacing
            
            HStack(spacing: spacing) {
                ForEach(0..<itemCount, id: \.self) { index in
                    content(index)
                        .frame(width: cardWidth)
                        .opacity(animateCards ? 1 : 0)
                        .scaleEffect(animateCards ? 1 : 0.9)
                        .animation(.spring(response: 0.8, dampingFraction: 0.7).delay(Double(index) * 0.15), value: animateCards)
                }
            }
            .offset(x: -CGFloat(currentIndex) * totalWidth + dragOffset + (geometry.size.width - cardWidth) / 2)
            .gesture(
                DragGesture()
                    .updating($dragOffset) { value, state, _ in
                        state = value.translation.width
                    }
                    .onEnded { value in
                        let threshold = cardWidth / 3
                        let offset = value.translation.width
                        
                        if offset < -threshold && currentIndex < itemCount - 1 {
                            withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                                currentIndex += 1
                            }
                        } else if offset > threshold && currentIndex > 0 {
                            withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                                currentIndex -= 1
                            }
                        }
                    }
            )
            .animation(.spring(response: 0.6, dampingFraction: 0.8), value: currentIndex)
        }
    }
}

// Achievement Card Component
struct AchievementCard: View {
    let icon: String
    let number: String
    let title: String
    let description: String
    let gradientColors: [Color]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Spacer()
            
            // Icon with glow effect
            ZStack {
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [
                                gradientColors[0].opacity(0.3),
                                Color.clear
                            ],
                            center: .center,
                            startRadius: 0,
                            endRadius: 60
                        )
                    )
                    .frame(width: 90, height: 90)
                
                Image(systemName: icon)
                    .font(.system(size: 28, weight: .medium))
                    .foregroundColor(.white)
            }
            
            Spacer()
            
            // Number
            Text(number)
                .font(.system(size: 56, weight: .bold, design: .rounded))
                .foregroundColor(.white)
                .shadow(color: gradientColors[0].opacity(0.5), radius: 15, x: 0, y: 8)
            
            Spacer()
                .frame(height: 12)
            
            // Title
            Text(title)
                .font(.system(size: 14, weight: .semibold, design: .rounded))
                .foregroundColor(gradientColors[0].opacity(0.9))
            
            // Description
            Text(description)
                .font(.system(size: 13, weight: .regular, design: .rounded))
                .foregroundColor(.white.opacity(0.9))
                .lineLimit(2)
                .multilineTextAlignment(.leading)
            
            Spacer()
                .frame(height: 16)
        }
        .padding(16)
        .frame(maxWidth: .infinity)
        .frame(height: 300)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(
                    LinearGradient(
                        colors: gradientColors + [gradientColors.last!.opacity(0.8)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(
                            LinearGradient(
                                colors: [
                                    Color.white.opacity(0.2),
                                    Color.white.opacity(0.05)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1
                        )
                )
        )
        .shadow(color: gradientColors[0].opacity(0.3), radius: 15, x: 0, y: 8)
    }
}

#Preview {
    OnboardFlowView(isPresented: .constant(true))
        .preferredColorScheme(.dark)
}
