import SwiftUI

struct ShimmeringText: View {
    let text: String
    let duration: Double
    @State private var animate = false

    var body: some View {
        ZStack {
            Text(text)
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(.white)
                .overlay(
                    GeometryReader { geometry in
                        LinearGradient(
                            gradient: Gradient(colors: [
                                .white.opacity(0.0),
                                .white.opacity(0.3),
                                .white.opacity(0.7),
                                .white.opacity(0.3),
                                .white.opacity(0.0)
                            ]),
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                        .frame(width: 80)
                        .offset(x: animate ? geometry.size.width : -80)
                        .animation(
                            Animation.linear(duration: duration)
                                .repeatForever(autoreverses: false),
                            value: animate
                        )
                    }
                )
                .mask(
                    Text(text)
                        .font(.system(size: 11, weight: .medium))
                )
        }
        .onAppear {
            animate = true
        }
    }
}

struct ShimmeringProgressBar: View {
    let progress: Double
    @State private var overlayOffset: CGFloat = -1.0
    
    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                // Background track with 3D effect
                Capsule()
                    .fill(
                        LinearGradient(
                            gradient: Gradient(colors: [
                                Color.white.opacity(0.1),
                                Color.white.opacity(0.2),
                                Color.white.opacity(0.1)
                            ]),
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
                
                // Main progress bar with gradient
                Capsule()
                    .fill(
                        LinearGradient(
                            gradient: Gradient(colors: [
                                Color.blue.opacity(0.8),
                                Color.blue,
                                Color.blue.opacity(0.9)
                            ]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: max(0, geometry.size.width * progress / 100))
                    .shadow(color: .blue.opacity(0.3), radius: 3, x: 0, y: 2)
                    .animation(.easeInOut(duration: 0.5), value: progress)
                
                // Animated overlay with lighter gradient
                Capsule()
                    .fill(
                        LinearGradient(
                            gradient: Gradient(colors: [
                                Color.white.opacity(0.0),
                                Color.white.opacity(0.4),
                                Color.white.opacity(0.7),
                                Color.white.opacity(0.4),
                                Color.white.opacity(0.0)
                            ]),
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(width: max(0, geometry.size.width * progress / 100))
                    .offset(x: overlayOffset * geometry.size.width)
                    .animation(
                        .linear(duration: 2.0)
                        .repeatForever(autoreverses: false),
                        value: overlayOffset
                    )
            }
            .frame(height: 12)
            .onAppear {
                // Start the overlay animation
                overlayOffset = 1.0
            }
        }
    }
}

struct AnalysisProgressView: View {
    let progress: AnalysisProgress
    
    var body: some View {
        VStack {
            if progress.isCompleted {
                HStack(spacing: 8) {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                    Text("Composition analysis complete")
                        .foregroundColor(.white)
                        .fontWeight(.semibold)
                }
                .transition(.opacity)
            } else {
                VStack(alignment: .leading, spacing: 12) {
                    // Shimmering progress bar
                    ShimmeringProgressBar(progress: progress.percent)
                        .frame(height: 12)
                    
                    // Dynamic progress message with shimmer
                    ShimmeringText(text: progress.message, duration: 2.0)
                }
                .padding()
                .background(Color.black.opacity(0.8))
                .cornerRadius(12)
                .padding(.horizontal, 50)
                .padding(.bottom, 50)
            }
        }
    }
} 
