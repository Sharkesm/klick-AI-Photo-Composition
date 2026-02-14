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
    @State private var permissionRequestTime: Date?
    
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
            // Track permission screen viewed
            Task {
                await EventTrackingManager.shared.trackOnboardingPermissionViewed(
                    permissionType: .camera
                )
            }
            
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
        permissionRequestTime = Date()
        
        // Track permission requested
        Task {
            await EventTrackingManager.shared.trackOnboardingPermissionRequested(
                permissionType: .camera
            )
        }
        
        let status = AVCaptureDevice.authorizationStatus(for: .video)
        
        switch status {
        case .authorized:
            // Already authorized
            permissionGranted = true
            
            // Track granted
            if let requestTime = permissionRequestTime {
                let timeToGrant = Date().timeIntervalSince(requestTime)
                Task {
                    await EventTrackingManager.shared.trackOnboardingPermissionGranted(
                        permissionType: .camera,
                        timeToGrant: timeToGrant
                    )
                }
            }
            
            withAnimation(.easeInOut(duration: 0.3)) {
                isPresented = false
            }
            
        case .notDetermined:
            // Request permission
            AVCaptureDevice.requestAccess(for: .video) { granted in
                DispatchQueue.main.async {
                    self.permissionGranted = granted
                    self.isRequesting = false
                    
                    // Track result
                    if let requestTime = self.permissionRequestTime {
                        let timeToGrant = Date().timeIntervalSince(requestTime)
                        Task {
                            if granted {
                                await EventTrackingManager.shared.trackOnboardingPermissionGranted(
                                    permissionType: .camera,
                                    timeToGrant: timeToGrant
                                )
                            } else {
                                await EventTrackingManager.shared.trackOnboardingPermissionDenied(
                                    permissionType: .camera
                                )
                            }
                        }
                    }
                    
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
            
            // Track settings opened
            Task {
                await EventTrackingManager.shared.trackOnboardingPermissionSettingsOpened(
                    permissionType: .camera
                )
            }
            
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



