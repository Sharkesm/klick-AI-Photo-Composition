//
//  CameraPermissionModalView.swift
//  Klick
//
//  Created by Manase on 19/10/2025.
//

import SwiftUI

struct CameraPermissionModalView: View {
    
    var onAction: () -> Void
    
    var body: some View {
        VStack(spacing: 30) {
            // Header
            VStack(spacing: 20) {
                VStack(spacing: 12) {
                    Text("Let's Set Things up")
                        .font(.title2.weight(.semibold))
                        .foregroundStyle(Color.white)
                        .multilineTextAlignment(.center)
                    
                    Text("We’ll guide you through a quick setup so your experience feels seamless.")
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(0.8))
                        .multilineTextAlignment(.center)
                        .lineLimit(nil)
                }
                
                // Camera permission
                SettingRow(
                    icon: "camera.on.rectangle",
                    title: "Camera Permission",
                    description: "We’ll need access to your camera to help you capture and frame live shots.",
                    isEnabled: .constant(false),
                    hideSwitchControl: true,
                    accentColor: .green
                )
            }
            
            // Let's go button
            Button(action: {
                onAction()
            }) {
                Text("Allow Access")
                    .font(.system(size: 18, weight: .semibold, design: .rounded))
                    .foregroundColor(.black)
                    .padding(.horizontal, 40)
                    .padding(.vertical, 16)
                    .background(
                        RoundedRectangle(cornerRadius: 30)
                            .fill(Color.white)
                    )
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 32)
        .background(Color(hue: 232/255, saturation: 20/255, brightness: 18/255))
        .cornerRadius(30)
    }
}


#Preview {
    VStack {
        Spacer()
        
        CameraPermissionModalView(onAction: {})
            .padding()
        
        Spacer()
    }
    .background(Color.black)
}
