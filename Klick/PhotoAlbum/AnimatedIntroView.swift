//
//  AnimatedIntroView.swift
//  Klick
//
//  Created by Manase on 03/08/2025.
//
import SwiftUI

// MARK: - Animated Intro View Component
struct AnimatedIntroView: View {
    let onCaptureButtonTap: () -> Void
    
    @State private var scaleImages = false
    @State private var showLeftImage = false
    @State private var showRightImage = false
    @State private var showTitle = false
    @State private var showSubtitle = false
    @State private var showCaptureButton = false
    
    // Animation values
    @State private var leftImageOffset: CGFloat = 0
    @State private var rightImageOffset: CGFloat = 0
    @State private var leftImageRotation: Double = 0
    @State private var rightImageRotation: Double = 0
    
    var body: some View {
        VStack(spacing: 35) {
            Spacer()
            
            // Stacked images with animations
            ZStack {
                // Left image (Rectangle_8) - behind and to the left
                Image("Rectangle_13")
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 140, height: 180)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .shadow(color: .black.opacity(0.2), radius: 8, x: 0, y: 4)
                    .scaleEffect(scaleImages ? 1.0 : 0.1)
                    .offset(x: leftImageOffset, y: 0)
                    .rotationEffect(.degrees(leftImageRotation))
                    .opacity(showLeftImage ? 1.0 : 0.8)
                    .animation(.spring(response: 0.8, dampingFraction: 0.7, blendDuration: 0.3), value: scaleImages)
                    .animation(.spring(response: 0.6, dampingFraction: 0.8, blendDuration: 0.2).delay(0.4), value: showLeftImage)
                
                // Right image (Rectangle_3) - behind and to the right
                Image("Rectangle_12")
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 140, height: 180)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .shadow(color: .black.opacity(0.2), radius: 8, x: 0, y: 4)
                    .scaleEffect(scaleImages ? 1.0 : 0.1)
                    .offset(x: rightImageOffset, y: 0)
                    .rotationEffect(.degrees(rightImageRotation))
                    .opacity(showRightImage ? 1.0 : 0.8)
                    .animation(.spring(response: 0.8, dampingFraction: 0.7, blendDuration: 0.3), value: scaleImages)
                    .animation(.spring(response: 0.6, dampingFraction: 0.8, blendDuration: 0.2).delay(0.5), value: showRightImage)
                
                // Center image (Rectangle_7) - front and center
                Image("Rectangle_11")
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 140, height: 180)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .shadow(color: .black.opacity(0.3), radius: 12, x: 0, y: 6)
                    .scaleEffect(scaleImages ? 1.0 : 0.1)
                    .animation(.spring(response: 0.8, dampingFraction: 0.7, blendDuration: 0.3), value: scaleImages)
            }
            .frame(height: 180)
            
            VStack(spacing: 12) {
                // Animated title
                Text("No Photos")
                    .font(.system(size: 20, weight: .bold, design: .rounded))
                    .foregroundColor(.black)
                    .opacity(showTitle ? 1.0 : 0.0)
                    .offset(y: showTitle ? 0 : 20)
                    .animation(.easeOut(duration: 0.6).delay(0.8), value: showTitle)
                
                // Animated subtitle
                Text("Capture your first photo to get started")
                    .font(.system(size: 16))
                    .foregroundColor(.black.opacity(0.7))
                    .multilineTextAlignment(.center)
                    .opacity(showSubtitle ? 1.0 : 0.0)
                    .offset(y: showSubtitle ? 0 : 20)
                    .animation(.easeOut(duration: 0.6).delay(1.2), value: showSubtitle)
            }
            .padding(.top, 20)
            
            // Animated capture button
            Button(action: onCaptureButtonTap) {
                Text("Capture")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.white)
                    .padding(.vertical, 16)
                    .padding(.horizontal, 32)
                    .background(Color.black)
                    .clipShape(Capsule())
            }
            .opacity(showCaptureButton ? 1.0 : 0.0)
            .scaleEffect(showCaptureButton ? 1.0 : 0.8)
            .animation(.spring(response: 0.5, dampingFraction: 0.7, blendDuration: 0.2).delay(1.6), value: showCaptureButton)
            
            Spacer()
        }
        .frame(maxWidth: .infinity)
        .onAppear {
            startAnimationSequence()
        }
    }
    
    private func startAnimationSequence() {
        // Start with scaling in the images
        withAnimation {
            scaleImages = true
        }
        
        // After scaling is almost complete, tilt and reveal the side images
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
            withAnimation {
                showLeftImage = true
                leftImageOffset = -100
                leftImageRotation = -13
                
                showRightImage = true
                rightImageOffset = 100
                rightImageRotation = 13
            }
        }
        
        // Show title
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
            withAnimation {
                showTitle = true
            }
        }
        
        // Show subtitle
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
            withAnimation {
                showSubtitle = true
            }
        }
        
        // Show capture button
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.6) {
            withAnimation {
                showCaptureButton = true
            }
        }
    }
}
