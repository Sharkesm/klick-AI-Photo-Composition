//
//  ImageComparisonSlider.swift
//  Klick
//
//  Created by Assistant on 11/01/2025.
//

import SwiftUI

/// Interactive image comparison slider component
/// Allows users to compare before/after images by dragging a vertical divider
struct ImageComparisonSlider: View {
    // Props
    let beforeImageName: String
    let afterImageName: String
    var initialSliderPosition: CGFloat = 50.0
    
    // State
    @State private var sliderPosition: CGFloat
    @State private var isDragging: Bool = false
    
    // Init
    init(beforeImageName: String, afterImageName: String, initialSliderPosition: CGFloat = 50.0) {
        self.beforeImageName = beforeImageName
        self.afterImageName = afterImageName
        self._sliderPosition = State(initialValue: initialSliderPosition)
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Image comparison slider canvas
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    // Layer 1: Before Image (Full width, always visible)
                    Image(beforeImageName)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: geometry.size.width, height: geometry.size.height)
                        .clipped()
                        .opacity(ComparisonSliderConfig.beforeImageOpacity)
                        .blur(radius: ComparisonSliderConfig.beforeImageBlur)
                        .accessibilityLabel("Original image before enhancement")
                    
                    // Layer 2: After Image (Masked/Clipped)
                    Image(afterImageName)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: geometry.size.width, height: geometry.size.height)
                        .clipped()
                        .mask(
                            HStack(spacing: 0) {
                                Rectangle()
                                    .frame(width: geometry.size.width * (sliderPosition / 100))
                                Spacer(minLength: 0)
                            }
                        )
                        .accessibilityLabel("Enhanced image after processing")
                 
                    // Layer 3: Divider & Handle
                    ZStack {
                        // Divider Line
                        Rectangle()
                            .fill(ComparisonSliderConfig.primaryColor.opacity(0.65))
                            .frame(width: ComparisonSliderConfig.dividerWidth)
                            .frame(height: geometry.size.height)
                            .shadow(
                                color: .black.opacity(0.3),
                                radius: ComparisonSliderConfig.dividerShadowRadius,
                                x: 0,
                                y: 0
                            )
                        
                        // Drag Handle
                        Circle()
                            .fill(ComparisonSliderConfig.nobeColor)
                            .frame(width: ComparisonSliderConfig.handleSize, height: ComparisonSliderConfig.handleSize)
                            .overlay(
                                Circle()
                                    .stroke(ComparisonSliderConfig.handleBorderColor, lineWidth: ComparisonSliderConfig.handleBorderWidth)
                            )
                            .shadow(
                                color: .black.opacity(0.3),
                                radius: ComparisonSliderConfig.handleShadowRadius,
                                x: 0,
                                y: ComparisonSliderConfig.handleShadowY
                            )
                            .overlay(
                                // Left/Right arrow icons
                                HStack(spacing: 2) {
                                    Image(systemName: "chevron.left")
                                        .font(.system(size: 12, weight: .semibold))
                                        .foregroundColor(ComparisonSliderConfig.nobeContentColor)
                                    
                                    Image(systemName: "chevron.right")
                                        .font(.system(size: 12, weight: .semibold))
                                        .foregroundColor(ComparisonSliderConfig.nobeContentColor)
                                }
                            )
                            .scaleEffect(isDragging ? 1.05 : 1.0)
                            .accessibilityLabel("Comparison slider handle, double tap and drag to compare images")
                    }
                    .position(
                        x: geometry.size.width * (sliderPosition / 100),
                        y: geometry.size.height / 2
                    )
                    
                    // Layer 4: Before/After Labels
                    VStack {
                        Spacer()
                        
                        HStack {
                            // Before Label (leading)
                            Text("Before")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(.white)
                                .padding(.vertical, 8)
                                .padding(.horizontal, 12)
                                .background(
                                    RoundedRectangle(cornerRadius: 16)
                                        .fill(.ultraThinMaterial)
                                )
                                .shadow(color: .black.opacity(0.3), radius: 8, x: 0, y: 4)
                                .opacity(beforeLabelOpacity)
                                .scaleEffect(beforeLabelOpacity > 0 ? 1 : 0.8)
                                .animation(.spring(response: 0.3, dampingFraction: 0.7), value: sliderPosition)
                                .padding(.leading, 16)
                            
                            Spacer()
                            
                            // After Label (trailing)
                            Text("After")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(.white)
                                .padding(.vertical, 8)
                                .padding(.horizontal, 12)
                                .background(
                                    RoundedRectangle(cornerRadius: 16)
                                        .fill(.ultraThinMaterial)
                                )
                                .shadow(color: .black.opacity(0.3), radius: 8, x: 0, y: 4)
                                .opacity(afterLabelOpacity)
                                .scaleEffect(afterLabelOpacity > 0 ? 1 : 0.8)
                                .animation(.spring(response: 0.3, dampingFraction: 0.7), value: sliderPosition)
                                .padding(.trailing, 16)
                            
                        }
                        .padding(.bottom, 16)
                    }
                }
                .frame(width: geometry.size.width, height: geometry.size.height)
                .contentShape(Rectangle())
                .accessibilityElement(children: .combine)
                .accessibilityLabel("Image comparison slider. Drag left or right to compare before and after images.")
                .gesture(
                    DragGesture(minimumDistance: 0)
                        .onChanged { value in
                            if !isDragging {
                                isDragging = true
                            }
                            
                            let dragX = value.location.x
                            sliderPosition = calculatePosition(dragX: dragX, containerWidth: geometry.size.width)
                        }
                        .onEnded { _ in
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                isDragging = false
                            }
                        }
                )
            }
            .aspectRatio(ComparisonSliderConfig.aspectRatio, contentMode: .fit)
            .background(ComparisonSliderConfig.backgroundColor)
            .clipShape(RoundedRectangle(cornerRadius: ComparisonSliderConfig.cornerRadius))
            .shadow(color: .black.opacity(0.3), radius: 20, x: 0, y: 10)
            
            // Instruction label below the canvas
            Text("Drag the slider to compare")
                .font(.system(size: 14, weight: .regular, design: .rounded))
                .foregroundColor(.white.opacity(0.6))
                .padding(.top, 12)
                .multilineTextAlignment(.center)
        }
    }
    
    // MARK: - Computed Properties
    
    /// Calculate opacity for "Before" label based on slider position
    /// More visible when slider is on the left (showing more before image)
    private var beforeLabelOpacity: Double {
        // When sliderPosition < 50%, show "Before" label
        // Fade in as we move left, fade out as we move right
        if sliderPosition < 50 {
            // Map 0-50% slider position to 0-1 opacity
            return Double(1 - (sliderPosition / 50))
        } else {
            return 0
        }
    }
    
    /// Calculate opacity for "After" label based on slider position
    /// More visible when slider is on the right (showing more after image)
    private var afterLabelOpacity: Double {
        // When sliderPosition > 50%, show "After" label
        // Fade in as we move right, fade out as we move left
        if sliderPosition > 50 {
            // Map 50-100% slider position to 0-1 opacity
            return Double((sliderPosition - 50) / 50)
        } else {
            return 0
        }
    }
    
    // MARK: - Helper Functions
    
    /// Calculate slider position from drag location
    private func calculatePosition(dragX: CGFloat, containerWidth: CGFloat) -> CGFloat {
        let percentage = (dragX / containerWidth) * 100
        return min(max(percentage, 0), 100)
    }
}

// MARK: - Configuration Constants

enum ComparisonSliderConfig {
    static let aspectRatio: CGFloat = 0.75  // 3:4
    static let defaultSliderPosition: CGFloat = 50.0
    static let cornerRadius: CGFloat = 24.0
    
    // Handle
    static let handleSize: CGFloat = 42.0
    static let handleBorderWidth: CGFloat = 2.0
    static let handleShadowRadius: CGFloat = 12.0
    static let handleShadowY: CGFloat = 4.0
    
    // Divider
    static let dividerWidth: CGFloat = 2.0
    static let dividerShadowRadius: CGFloat = 8.0
    
    // Images
    static let beforeImageOpacity: CGFloat = 0.8
    static let beforeImageBlur: CGFloat = 0.5
    
    // Colors
    static let primaryColor: Color = .yellow
    static let nobeColor: Color = .white
    static let nobeContentColor: Color = .black
    static let handleBorderColor: Color = .white
    static let backgroundColor: Color = Color(red: 0.02, green: 0.05, blue: 0.13)
}

// MARK: - Preview

#Preview {
    ImageComparisonSlider(
        beforeImageName: "pose_before",
        afterImageName: "pose_after",
        initialSliderPosition: 50
    )
    .frame(height: 340)
    .padding()
    .background(Color.black)
}

