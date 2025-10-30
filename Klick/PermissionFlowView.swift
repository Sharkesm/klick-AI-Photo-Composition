//
//  PermissionFlowView.swift
//  Klick
//
//  Created by Assistant on 19/10/2025.
//

import SwiftUI
import AVFoundation

struct PermissionFlowView: View {
    @Binding var isPresented: Bool
    @Binding var permissionGranted: Bool
    
    @State private var showContent = false
    @State private var isRequesting = false
    
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
            
            VStack {
                Spacer()
                
                // Permission modal
                CameraPermissionModalView(onAction: {
                    requestCameraPermission()
                })
                .opacity(showContent ? 1 : 0)
                .scaleEffect(showContent ? 1 : 0.9)
                .animation(.spring(response: 0.6, dampingFraction: 0.75), value: showContent)
                .padding(.horizontal, 20)
                
                Spacer()
            }
        }
        .onAppear {
            // Check if permission is already granted
            let status = AVCaptureDevice.authorizationStatus(for: .video)
            if status == .authorized {
                permissionGranted = true
                isPresented = false
            } else {
                // Show the modal with animation
                withAnimation {
                    showContent = true
                }
            }
        }
    }
    
    private func requestCameraPermission() {
        isRequesting = true
        
        let status = AVCaptureDevice.authorizationStatus(for: .video)
        
        switch status {
        case .authorized:
            // Already authorized
            permissionGranted = true
            withAnimation(.easeInOut(duration: 0.3)) {
                isPresented = false
            }
            
        case .notDetermined:
            // Request permission
            AVCaptureDevice.requestAccess(for: .video) { granted in
                DispatchQueue.main.async {
                    self.permissionGranted = granted
                    self.isRequesting = false
                    
                    if granted {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            self.isPresented = false
                        }
                    }
                }
            }
            
        case .denied, .restricted:
            // Permission denied - open settings
            isRequesting = false
            if let settingsUrl = URL(string: UIApplication.openSettingsURLString) {
                UIApplication.shared.open(settingsUrl)
            }
            
        @unknown default:
            isRequesting = false
        }
    }
}

#Preview {
    PermissionFlowView(
        isPresented: .constant(true),
        permissionGranted: .constant(false)
    )
    .preferredColorScheme(.dark)
}



