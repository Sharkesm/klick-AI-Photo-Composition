import SwiftUI

struct CameraGlowOverlayView: View {
    // MARK: - Properties
    let isSubjectDetected: Bool
    let compositionScore: Double
    let cornerRadius: CGFloat
    let glowColor: Color
    let basePulseDuration: Double
    
    // MARK: - State
    @State private var pulseScale: CGFloat = 1.0
    @State private var shimmerOffset: CGFloat = -1.0
    @State private var glowIntensity: Double = 0.0
    
    // MARK: - Computed Properties
    private var effectiveScore: Double {
        max(0.0, min(1.0, compositionScore))
    }
    
    private var pulseDuration: Double {
        // Higher score = faster pulse (more energetic)
        let speedMultiplier = 0.3 + (effectiveScore * 0.7) // 0.3 to 1.0
        return basePulseDuration / speedMultiplier
    }
    
    private var glowOpacity: Double {
        isSubjectDetected ? effectiveScore * 0.8 : 0.0
    }
    
    private var shimmerOpacity: Double {
        isSubjectDetected ? 0.15 + (effectiveScore * 0.25) : 0.0
    }
    
    // MARK: - Initializer
    init(
        isSubjectDetected: Bool,
        compositionScore: Double,
        cornerRadius: CGFloat = 20.0,
        glowColor: Color = .yellow,
        basePulseDuration: Double = 4.0
    ) {
        self.isSubjectDetected = isSubjectDetected
        self.compositionScore = compositionScore
        self.cornerRadius = cornerRadius
        self.glowColor = glowColor
        self.basePulseDuration = basePulseDuration
    }
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Main glow container
                RoundedRectangle(cornerRadius: cornerRadius)
                    .strokeBorder(
                        LinearGradient(
                            colors: [
                                glowColor.opacity(glowOpacity * 0.8),
                                glowColor.opacity(glowOpacity * 0.4),
                                glowColor.opacity(glowOpacity * 0.2),
                                Color.clear
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 20
                    )
                    .background(
                        // Inner glow effect
                        RoundedRectangle(cornerRadius: cornerRadius)
                            .fill(
                                RadialGradient(
                                    colors: [
                                        Color.clear,
                                        Color.clear,
                                        glowColor.opacity(glowOpacity * 0.1)
                                    ],
                                    center: .center,
                                    startRadius: geometry.size.width * 0.3,
                                    endRadius: geometry.size.width * 0.5
                                )
                            )
                    )
                    .scaleEffect(pulseScale)
                
                // Glossy shimmer overlay
                if isSubjectDetected {
                    RoundedRectangle(cornerRadius: cornerRadius)
                        .strokeBorder(
                            LinearGradient(
                                colors: [
                                    Color.white.opacity(shimmerOpacity * 0.4),
                                    Color.yellow.opacity(shimmerOpacity * 0.3),
                                    Color.clear,
                                    Color.clear
                                ],
                                startPoint: UnitPoint(x: shimmerOffset, y: shimmerOffset),
                                endPoint: UnitPoint(x: shimmerOffset + 0.3, y: shimmerOffset + 0.3)
                            ),
                            lineWidth: 20
                        )
                        .blendMode(.softLight)
                        .clipped()
                }
                
                // Enhanced edge glow for high scores
                if effectiveScore > 0.7 {
                    RoundedRectangle(cornerRadius: cornerRadius)
                        .strokeBorder(
                            glowColor.opacity((effectiveScore - 0.7) * 2.0 * 0.6),
                            lineWidth: 6.0
                        )
                        .blur(radius: 4.0)
                        .scaleEffect(pulseScale * 1.02)
                }
            }
        }
        .onChange(of: isSubjectDetected) { detected in
            updateAnimations()
        }
        .onChange(of: effectiveScore) { _ in
            updateAnimations()
        }
        .onAppear {
            startAnimations()
        }
    }
    
    // MARK: - Animation Methods
    private func startAnimations() {
        // Start shimmer animation
        withAnimation(
            .linear(duration: 2.0)
            .repeatForever(autoreverses: false)
        ) {
            shimmerOffset = 1.0
        }
        
        // Start pulse animation if subject detected
        if isSubjectDetected {
            startPulseAnimation()
        }
    }
    
    private func startPulseAnimation() {
        withAnimation(
            .easeInOut(duration: pulseDuration)
            .repeatForever(autoreverses: true)
        ) {
            pulseScale = 1.0 + (effectiveScore * 0.05) // Subtle scale change
        }
    }
    
    private func updateAnimations() {
        if isSubjectDetected {
            // Smooth transition to target glow intensity
            withAnimation(.easeInOut(duration: 0.5)) {
                glowIntensity = effectiveScore
            }
            
            // Start or update pulse animation
            startPulseAnimation()
        } else {
            // Fade out glow when no subject
            withAnimation(.easeOut(duration: 0.8)) {
                glowIntensity = 0.0
                pulseScale = 1.0
            }
        }
    }
}

// MARK: - Preview
#Preview {
    ZStack {
        // Simulated camera background
        Rectangle()
            .fill(Color.black)
            .overlay(
                Text("Camera Preview")
                    .foregroundColor(.white)
                    .font(.title2)
            )
        
        // Glow overlay
        CameraGlowOverlayView(
            isSubjectDetected: true,
            compositionScore: 0.8
        )
    }
    .frame(width: 300, height: 400)
    .cornerRadius(20)
}
