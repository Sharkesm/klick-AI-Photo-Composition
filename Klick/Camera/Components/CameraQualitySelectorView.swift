import SwiftUI
import AVFoundation

// MARK: - Camera Quality Enum
enum CameraQuality: String, CaseIterable {
    case standard
    case pro
    
    var displayName: String {
        switch self {
        case .standard:
            return "HQ"
        case .pro:
            return "Pro"
        }
    }
}

// MARK: - Camera Quality Selector View
struct CameraQualitySelectorView: View {
    @Binding var selectedQuality: CameraQuality
    @State private var showQualityChange = false
    @State private var isRevealed = false
    
    var onSelectionCompletion: (() -> Void)?
    
    let impactFeedback = UIImpactFeedbackGenerator(style: .light)
    
    // Constants for consistent sizing
    private let controlWidth: CGFloat = 42
    private let buttonSize: CGFloat = 36
    private let expandedButtonSpacing: CGFloat = 4
    
    var body: some View {
        VStack(spacing: 5) {
            // Main toggle button - always at the top
            Button {
                withAnimation(.spring(response: 0.6, dampingFraction: 0.8, blendDuration: 0)) {
                    isRevealed.toggle()
                }
            } label: {
                ZStack {
                    // Animated background with smooth color transition
                    RoundedRectangle(cornerRadius: 21, style: .continuous)
                        .fill(
                            LinearGradient(
                                colors: isRevealed ? 
                                    [Color.white, Color.white.opacity(0.95)] : 
                                    [Color.black.opacity(0.5), Color.black.opacity(0.6)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .background(.ultraThinMaterial.opacity(0.1))
                        .shadow(
                            color: isRevealed ? Color.black.opacity(0.1) : .clear, 
                            radius: isRevealed ? 8 : 0, 
                            x: 0, 
                            y: isRevealed ? 4 : 0
                        )
                        .animation(.easeInOut(duration: 0.4), value: isRevealed)
                    
                    // Content with smooth cross-fade transition
                    ZStack {
                        // Quality text (visible when collapsed)
                        Text(selectedQuality.displayName)
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(.white)
                            .opacity(isRevealed ? 0.0 : 1.0)
                            .scaleEffect(isRevealed ? 0.7 : 1.0)
                            .rotationEffect(.degrees(isRevealed ? 90 : 0))
                            .animation(.easeInOut(duration: 0.3), value: isRevealed)
                        
                        // X mark icon (visible when expanded)
                        Image(systemName: "xmark")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.black)
                            .opacity(isRevealed ? 1.0 : 0.0)
                            .scaleEffect(isRevealed ? 1.0 : 0.3)
                            .rotationEffect(.degrees(isRevealed ? 0 : -90))
                            .animation(.easeInOut(duration: 0.3).delay(0.1), value: isRevealed)
                    }
                }
            }
            .frame(width: controlWidth, height: controlWidth)
            .animation(.spring(response: 0.5, dampingFraction: 0.7), value: isRevealed)
            
            // Expanded container that slides down smoothly with unified animation
            ZStack {
                if isRevealed {
                    RoundedRectangle(cornerRadius: 21, style: .continuous)
                        .fill(Color.black.opacity(0.4))
                        .background(.ultraThinMaterial.opacity(0.1))
                        .shadow(color: Color.black.opacity(0.15), radius: 12, x: 0, y: 6)
                }
                
                VStack(spacing: expandedButtonSpacing) {
                    ForEach(Array(CameraQuality.allCases.enumerated()), id: \.element) { index, quality in
                        Button(action: {
                            impactFeedback.impactOccurred()
                            impactFeedback.prepare()
                            
                            withAnimation(.easeInOut(duration: 0.25)) {
                                selectedQuality = quality
                                showQualityChange = true
                            }
                            
                            // Collapse after selection with unified animation
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                                withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                                    isRevealed = false
                                    onSelectionCompletion?()
                                }
                            }
                        }) {
                            Text(quality.displayName)
                                .font(.system(size: 11, weight: .medium))
                                .foregroundColor(selectedQuality == quality ? .yellow : .white)
                        }
                        .frame(width: buttonSize, height: buttonSize)
                        .background(Color.black.opacity(selectedQuality == quality ? 0.6 : 0.3))
                        .clipShape(Circle())
                        .scaleEffect(selectedQuality == quality ? 1.0 : 0.9)
                        .shadow(color: selectedQuality == quality ? .yellow.opacity(0.3) : .clear, radius: 2)
                        .opacity(isRevealed ? 1.0 : 0.0)
                        .scaleEffect(isRevealed ? 1.0 : 0.3)
                        .offset(y: isRevealed ? 0 : -15)
                        .animation(
                            .spring(response: 0.7, dampingFraction: 0.8)
                            .delay(Double(index) * 0.1), 
                            value: isRevealed
                        )
                        .animation(.easeInOut(duration: 0.25), value: selectedQuality)
                    }
                }
                .padding(.vertical, 8)
            }
            .frame(width: controlWidth)
            .frame(height: isRevealed ? CGFloat(CameraQuality.allCases.count * Int(buttonSize + expandedButtonSpacing) + 16) : 0)
            .clipShape(RoundedRectangle(cornerRadius: 21, style: .continuous))
            .scaleEffect(y: isRevealed ? 1.0 : 0.1, anchor: .top)
            .opacity(isRevealed ? 1.0 : 0.0)
            .offset(y: isRevealed ? 0 : -25)
            .animation(.spring(response: 0.7, dampingFraction: 0.8), value: isRevealed)
        }
        .frame(width: controlWidth) // Fixed width to prevent parent layout shifts
        .animation(.spring(response: 0.8, dampingFraction: 0.9), value: isRevealed)
        .onChange(of: showQualityChange) { newValue in
            if newValue {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    withAnimation(.easeOut(duration: 0.1)) {
                        showQualityChange = false
                    }
                }
            }
        }
        .onTapGesture {
            // Tap outside to collapse with unified animation
            if isRevealed {
                withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                    isRevealed = false
                }
            }
        }
    }
}
