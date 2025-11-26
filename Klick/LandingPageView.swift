import SwiftUI

struct LandingPageView: View {
    // TEST MODE: Set to true to always show onboarding
    private let testMode = true
    
    @AppStorage("onboardingIntroduction") var onboardingIntroduction: Bool = false
    @AppStorage("onboardingFlowCompleted") var onboardingFlowCompleted: Bool = false
    @AppStorage("permissionGranted") var permissionGranted: Bool = false
    @AppStorage("hasSeenProUpsell") var hasSeenProUpsell: Bool = false
    @AppStorage("userCreativeGoal") var userCreativeGoal: String = ""
    
    @State private var scrollOffset1: CGFloat = 0
    @State private var scrollOffset2: CGFloat = 0
    
    // Navigation and transition states
    @State private var isTransitioning = false
    @State private var showRows = true
    @State private var showOnboardingFlow = false
    @State private var showPermissionFlow = false
    
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
            } else if !onboardingFlowCompleted {
                // Show onboarding flow
                OnboardingFlowView(isPresented: $showOnboardingFlow)
                    .onAppear {
                        showOnboardingFlow = true
                    }
                    .onChange(of: showOnboardingFlow) { newValue in
                        if !newValue {
                            // User completed or skipped onboarding
                            onboardingFlowCompleted = true
                        }
                    }
            } else if !permissionGranted {
                // Show permission flow
                PermissionFlowView(
                    isPresented: $showPermissionFlow,
                    permissionGranted: $permissionGranted
                )
                    .onAppear {
                        showPermissionFlow = true
                    }
            } else {
                // Show ContentView after permissions are granted
                ContentView()
            }
        }
        .onAppear {
            // Reset all onboarding states in test mode on app launch
            if testMode {
                resetOnboardingStates()
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
                }
                
                
                Spacer()
                
                // Headline and subtitle
                VStack(spacing: 8) {
                    Text("Klick")
                        .font(.system(size: 48, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                        .tracking(2)
                    
                    Text("those perfect frames")
                        .font(.system(size: 18, weight: .medium, design: .rounded))
                        .foregroundColor(.white.opacity(0.8))
                        .italic()
                    
                    // Composition style icons
                    HStack(spacing: 14) {
                        Spacer()
                        Image(systemName: "squareshape.split.2x2.dotted")
                            .font(.system(size: 20, weight: .medium))
                            .foregroundColor(.white.opacity(0.7))
                        
                        Image(systemName: "plus.viewfinder") // dot.circle
                            .font(.system(size: 20, weight: .medium))
                            .foregroundColor(.white.opacity(0.7))
                        
                        Image(systemName: "rectangle.split.2x1") // arrow.left.arrow.right
                            .font(.system(size: 20, weight: .medium))
                            .foregroundColor(.white.opacity(0.7))
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
            }
            .opacity(showRows ? 1 : 0)
            .animation(.easeOut(duration: 0.5), value: showRows)
        }
    }
    
    private func startTransition() {
        isTransitioning = true
        
        // Simple fade out animation
        withAnimation(.easeOut(duration: 0.5)) {
            showRows = false
        }
        
        // Navigate to ContentView after fade out
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
            onboardingIntroduction = true
        }
    }
    
    private func resetOnboardingStates() {
        onboardingIntroduction = false
        onboardingFlowCompleted = false
        permissionGranted = false
        hasSeenProUpsell = false
        userCreativeGoal = ""
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
}
