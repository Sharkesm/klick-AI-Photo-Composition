//
//  CameraQualityIntroView.swift
//  Klick
//
//  Introductory sheet for Camera Quality feature
//

import SwiftUI

struct CameraQualityIntroView: View {
    @AppStorage("hasShowedCameraQualityIntro") private var hasShowedCameraQualityIntro: Bool = false
    
    @Binding var isPresented: Bool
    let onDismiss: () -> Void
    @State private var viewStartTime: Date?
    
    var body: some View {
        VStack(spacing: 0) {
            
            // Intro card
            VStack(spacing: 24) {
                // Preview Image
                Image("CameraQualityIntro")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(maxWidth: .infinity)
                    .frame(height: 280)
                    .offset(x: -10)
                
                // Title
                Text("Camera Quality")
                    .font(.system(size: 24, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                
                // Description
                VStack(alignment: .leading, spacing: 16) {
                    // HQ Option
                    HStack(alignment: .top, spacing: 20) {
                        Image(systemName: "sparkles")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.white)
                            .frame(width: 40, height: 40)
                            .background(
                                Circle()
                                    .fill(Color.white.opacity(0.1))
                            )
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text("High Quality")
                                .font(.system(size: 16, weight: .semibold, design: .default))
                                .foregroundColor(.white)
                            
                            Text("Quick and polished, ready to share. Perfect for everyday shots and instant posts.")
                                .font(.system(size: 14))
                                .foregroundColor(.white.opacity(0.8))
                                .fixedSize(horizontal: false, vertical: true)
                        }
                        
                        Spacer()
                    }
                    
                    // Pro Option
                    HStack(alignment: .top, spacing: 20) {
                        Image(systemName: "camera.aperture")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.white)
                            .frame(width: 40, height: 40)
                            .background(
                                Circle()
                                    .fill(Color.white.opacity(0.1))
                            )
                        
                        VStack(alignment: .leading, spacing: 4) {
                            HStack(spacing: 6) {
                                Text("Pro")
                                    .font(.system(size: 16, weight: .semibold, design: .default))
                                    .foregroundColor(.white)
                                
                                Image(systemName: "crown.fill")
                                    .font(.system(size: 12, weight: .medium))
                                    .foregroundColor(.yellow)
                            }
                            
                            Text("Maximum detail, full editing power. RAW files unlock next-level control.")
                                .font(.system(size: 14))
                                .foregroundColor(.white.opacity(0.8))
                                .fixedSize(horizontal: false, vertical: true)
                        }
                        
                        Spacer()
                    }
                }
                .padding(.horizontal, 8)
                
                // Got It button
                Button(action: {
                    // Track intro dismissed
                    if let startTime = viewStartTime {
                        let timeSpent = Date().timeIntervalSince(startTime)
                        Task {
                            await EventTrackingManager.shared.trackCameraQualityIntroDismissed(timeSpent: timeSpent)
                        }
                    }
                    
                    withAnimation {
                        isPresented = false
                    }
                    // Trigger auto-expand after sheet dismisses
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                        onDismiss()
                    }
                }) {
                    Text("Got It")
                        .font(.system(size: 17, weight: .semibold))
                        .padding(.horizontal, 48)
                        .padding(.vertical, 16)
                        .foregroundColor(.black)
                        .background(
                            RoundedRectangle(cornerRadius: 25)
                                .fill(Color.white)
                        )
                        .shadow(color: .black.opacity(0.2), radius: 10, x: 0, y: 5)
                }
                .padding(.top, 8)
            }
            .background(.black)
            .padding(.top, 10)
        }
        .onAppear {
            viewStartTime = Date()
            
            if !hasShowedCameraQualityIntro {
                hasShowedCameraQualityIntro = true
            }
            
            // Track camera quality intro viewed (onboarding event)
            Task {
                await EventTrackingManager.shared.trackOnboardingGuideViewed(guideType: .cameraQuality)
            }
            
            // Track camera quality intro viewed (dedicated event)
            Task {
                await EventTrackingManager.shared.trackCameraQualityIntroViewed()
            }
        }
    }
}

#Preview {
    ZStack {
        Color.black.ignoresSafeArea()
        
        CameraQualityIntroView(
            isPresented: .constant(true),
            onDismiss: {}
        )
    }
}

