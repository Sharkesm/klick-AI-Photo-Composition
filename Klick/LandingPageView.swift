import SwiftUI

struct LandingPageView: View {
    @AppStorage("onboardingIntroduction") var onboardingIntroduction: Bool = false
    
    @State private var scrollOffset1: CGFloat = 0
    @State private var scrollOffset2: CGFloat = 0
    @State private var isAnimating = false
    
    // Animation states
    @State private var showHeadline = false
    @State private var showSubtitle = false
    @State private var showIcon1 = false
    @State private var showIcon2 = false
    @State private var showIcon3 = false
    @State private var showButton = false
    
    // Navigation and transition states
    @State private var isTransitioning = false
    @State private var showRows = true
    
    // Array of image names from the Introduction folder
    private let introductionImages = [
        "Rectangle_1", "Rectangle_2", "Rectangle_3", "Rectangle_4", "Rectangle_5",
        "Rectangle_6", "Rectangle_7", "Rectangle_8", "Rectangle_9", "Rectangle_10"
    ]
    
    // Split images into two rows
    private var row1Images: [String] {
        introductionImages.reversed()
    }
    
    private var row2Images: [String] {
       introductionImages
    }
    
    var body: some View {
        ZStack {
            if !onboardingIntroduction {
                // Landing page content
                landingPageContent
            } else {
                // Show ContentView directly
                ContentView()
            }
        }
    }
    
    private var landingPageContent: some View {
        ZStack {
            // Black background
            Color.black
                .ignoresSafeArea()
            
            VStack {
                Spacer()
                
                // Dual-row scrolling animation
                VStack(spacing: 0) {
                    // Row 1: Left to Right
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 0) {
                            ForEach(0..<6, id: \.self) { repetition in
                                ForEach(0..<row1Images.count, id: \.self) { index in
                                    Image(row1Images[index])
                                        .resizable()
                                        .aspectRatio(contentMode: .fill)
                                        .frame(width: UIScreen.main.bounds.width / 3, height: 200)
                                        .clipped()
                                        .opacity(0.8)
                                }
                            }
                        }
                        .offset(x: scrollOffset1)
                    }
                    .frame(height: 200)
                    .clipped()
                    .disabled(true)
                    
                    // Row 2: Right to Left
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 0) {
                            ForEach(0..<6, id: \.self) { repetition in
                                ForEach(0..<row2Images.count, id: \.self) { index in
                                    Image(row2Images[index])
                                        .resizable()
                                        .aspectRatio(contentMode: .fill)
                                        .frame(width: UIScreen.main.bounds.width / 3, height: 200)
                                        .clipped()
                                        .opacity(0.8)
                                }
                            }
                        }
                        .offset(x: scrollOffset2)
                    }
                    .frame(height: 200)
                    .clipped()
                    .disabled(true)
                }
                .frame(height: 400)
                .onAppear {
                    startScrollingAnimations()
                    startSequentialAnimations()
                }
                
                
                Spacer()
                
                // Headline and subtitle
                VStack(spacing: 8) {
                    Text("Klick")
                        .font(.system(size: 48, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                        .tracking(2)
                        .opacity(showHeadline ? 1 : 0)
                        .offset(y: showHeadline ? 0 : 50)
                        .animation(.easeOut(duration: 0.8), value: showHeadline)
                    
                    Text("those perfect frames")
                        .font(.system(size: 18, weight: .medium, design: .rounded))
                        .foregroundColor(.white.opacity(0.8))
                        .italic()
                        .opacity(showSubtitle ? 1 : 0)
                        .scaleEffect(showSubtitle ? 1 : 0.8)
                        .animation(.easeOut(duration: 0.6).delay(0.3), value: showSubtitle)
                    
                    // Composition style icons
                    HStack(spacing: 14) {
                        Spacer()
                        Image(systemName: "squareshape.split.2x2.dotted")
                            .font(.system(size: 20, weight: .medium))
                            .foregroundColor(.white.opacity(0.7))
                            .opacity(showIcon1 ? 1 : 0)
                            .animation(.easeOut(duration: 0.5).delay(0.8), value: showIcon1)
                        
                        Image(systemName: "plus.viewfinder") // dot.circle
                            .font(.system(size: 20, weight: .medium))
                            .foregroundColor(.white.opacity(0.7))
                            .opacity(showIcon2 ? 1 : 0)
                            .animation(.easeOut(duration: 0.5).delay(1.0), value: showIcon2)
                        
                        Image(systemName: "rectangle.split.2x1") // arrow.left.arrow.right
                            .font(.system(size: 20, weight: .medium))
                            .foregroundColor(.white.opacity(0.7))
                            .opacity(showIcon3 ? 1 : 0)
                            .animation(.easeOut(duration: 0.5).delay(1.2), value: showIcon3)
                        Spacer()
                    }
                    .padding(.top, 20)
                }
                .padding(.top, 30)
                .padding(.bottom, 60)
                
                Spacer()
                
                // Let's go button
                Button(action: {
                    startTransition()
                }) {
                    Text("Let's go")
                        .font(.system(size: 18, weight: .semibold, design: .rounded))
                        .foregroundColor(.black)
                        .padding(.horizontal, 40)
                        .padding(.vertical, 16)
                        .background(
                            RoundedRectangle(cornerRadius: 30)
                                .fill(Color.white)
                        )
                        .shadow(color: .white.opacity(0.3), radius: 10, x: 0, y: 5)
                }
                .padding(.bottom, 50)
                .scaleEffect(isAnimating ? 1.05 : 1.0)
                .animation(.easeInOut(duration: 2).repeatForever(autoreverses: true), value: isAnimating)
                .opacity(showButton ? 1 : 0)
                .offset(y: showButton ? 0 : 30)
                .animation(.easeOut(duration: 0.8).delay(1.6), value: showButton)
                .onAppear {
                    isAnimating = true
                }
            }
            .opacity(showRows ? 1 : 0)
            .animation(.easeOut(duration: 0.5), value: showRows)
        }
    }
    
    private func startTransition() {
        isTransitioning = true
        
        // Simple fade out animation
        withAnimation(.easeOut(duration: 0.5)) {
            showButton = false
            showIcon1 = false
            showIcon2 = false
            showIcon3 = false
            showSubtitle = false
            showHeadline = false
            showRows = false
        }
        
        // Navigate to ContentView after fade out
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
            onboardingIntroduction = true
        }
    }
    
    private func startScrollingAnimations() {
        // Set initial positions to cover full screen width
        scrollOffset1 = -UIScreen.main.bounds.width / 2  // Row 1 starts at neutral position
        scrollOffset2 = 0  // Row 2 starts at neutral position
        
        // Start both animations simultaneously with controlled movement
        DispatchQueue.main.async {
            // Row 1: Left to Right animation (subtle movement within visible area)
            withAnimation(.linear(duration: 15).repeatForever(autoreverses: true)) {
                scrollOffset1 = -UIScreen.main.bounds.width / 1.5
            }
            
            // Row 2: Right to Left animation (opposite direction, subtle movement)
            withAnimation(.linear(duration: 15).repeatForever(autoreverses: true)) {
                scrollOffset2 = -100
            }
        }
    }
    
    private func startSequentialAnimations() {
        // Headline animation
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            showHeadline = true
        }
        
        // Subtitle animation
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
            showSubtitle = true
        }
        
        // Icon animations (one by one)
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.3) {
            showIcon1 = true
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            showIcon2 = true
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.7) {
            showIcon3 = true
        }
        
        // Button animation
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.1) {
            showButton = true
        }
    }
}
