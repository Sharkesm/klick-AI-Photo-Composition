import SwiftUI
import AVFoundation

// MARK: - Loading Overlay View
struct LoadingOverlayView: View {
    let permissionStatus: AVAuthorizationStatus
    
    var body: some View {
        // Semi-transparent overlay to dim camera view during loading
        Color.black.opacity(0.7)
            .ignoresSafeArea()
            .transition(.opacity)
            .overlay(
                VStack(spacing: 20) {
                    if permissionStatus == .denied || permissionStatus == .restricted {
                        // Permission denied state
                        CameraPermissionView()
                    } else {
                        // Loading state
                        VStack(spacing: 16) {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                .scaleEffect(0.85)
                        }
                    }
                }
                .transition(.opacity)
            )
    }
}

// MARK: - Camera Permission View
struct CameraPermissionView: View {
    var body: some View {
        VStack(spacing: 22) {
            VStack(spacing: 16) {
                Image(systemName: "camera.fill")
                    .font(.system(size: 40))
                    .foregroundColor(.white.opacity(0.6))
                
                Text("Camera Access Required")
                    .font(.title2)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                
                Text("Please enable camera access in Settings to use Klick, and capture those amazing photos.")
                    .font(.body)
                    .foregroundColor(.white.opacity(0.8))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
            }
            
            Button(action: {
                // Open Settings
                if let settingsUrl = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(settingsUrl)
                }
            }) {
                Text("Open Settings")
                    .font(.headline)
                    .foregroundColor(.black)
                    .padding(.horizontal, 30)
                    .padding(.vertical, 12)
                    .background(Color.white)
                    .cornerRadius(25)
            }
        }
    }
}

