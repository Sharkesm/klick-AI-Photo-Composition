import SwiftUI
import AVFoundation

struct ContentView: View {
    @State private var isGridVisible = true
    @State private var feedbackMessage: String?
    @State private var showFeedback = false
    @State private var showEducationalContent = false
    @State private var hasCameraPermission = false
    @State private var cameraLoading = true
    @State private var permissionStatus: AVAuthorizationStatus = .notDetermined
    @State private var detectedFaceBoundingBox: CGRect?
    
    var body: some View {
        ZStack {
            // Black background
            Color.black
                .ignoresSafeArea()
            
            // Camera view - show immediately when permissions granted
            if hasCameraPermission {
                CameraView(
                    isGridVisible: $isGridVisible,
                    feedbackMessage: $feedbackMessage,
                    showFeedback: $showFeedback,
                    detectedFaceBoundingBox: $detectedFaceBoundingBox,
                    onCameraReady: {
                        // Camera is ready, hide loading
                        print("Camera ready callback triggered")
                        withAnimation(.easeOut(duration: 0.5)) {
                            cameraLoading = false
                        }
                    }
                )
                .ignoresSafeArea()
            }
            
            // Grid overlay - only show when camera is ready
            if hasCameraPermission && !cameraLoading {
                GridOverlayView(isVisible: isGridVisible)
                    .ignoresSafeArea()
                    .transition(.opacity)
            }
            
            // Face highlight overlay - only show when camera is ready
            if hasCameraPermission && !cameraLoading {
                FaceHighlightOverlayView(faceBoundingBox: detectedFaceBoundingBox)
                    .ignoresSafeArea()
                    .transition(.opacity)
            }
            
            // Composition indicator - only show when camera is ready
            if hasCameraPermission && !cameraLoading {
                VStack {
                    HStack {
                        CompositionIndicatorView(compositionType: "Rule of Thirds")
                        Spacer()
                    }
                    Spacer()
                }
                .ignoresSafeArea()
                .transition(.opacity)
            }
            
            // Loading indicator overlay - shows on top when needed
            if cameraLoading || !hasCameraPermission {
                // Semi-transparent overlay to dim camera view during loading
                Color.black.opacity(0.7)
                    .ignoresSafeArea()
                    .transition(.opacity)
                
                VStack(spacing: 20) {
                    if permissionStatus == .denied || permissionStatus == .restricted {
                        // Permission denied state
                        VStack(spacing: 16) {
                            Image(systemName: "camera.fill")
                                .font(.system(size: 60))
                                .foregroundColor(.white.opacity(0.6))
                            
                            Text("Camera Access Required")
                                .font(.title2)
                                .fontWeight(.semibold)
                                .foregroundColor(.white)
                            
                            Text("Please enable camera access in Settings to use Klick")
                                .font(.body)
                                .foregroundColor(.white.opacity(0.8))
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 40)
                            
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
                    } else {
                        // Loading state
                        VStack(spacing: 16) {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                .scaleEffect(1.5)
                            
                            Text(hasCameraPermission ? "Starting camera..." : "Requesting camera access...")
                                .font(.headline)
                                .foregroundColor(.white)
                        }
                    }
                }
                .transition(.opacity)
            }
            
            // Feedback overlay - only show when camera is ready
            if hasCameraPermission && !cameraLoading {
                if showFeedback, let message = feedbackMessage {
                    VStack {
                        Spacer()
                        
                        Text(message)
                            .font(.headline)
                            .foregroundColor(.white)
                            .padding(.horizontal, 20)
                            .padding(.vertical, 12)
                            .background(Color.black.opacity(0.7))
                            .cornerRadius(25)
                            .padding(.bottom, 150) // 20 points above bottom controls
                    }
                    .transition(.asymmetric(
                        insertion: .scale(scale: 0.1, anchor: .bottom)
                            .combined(with: .opacity),
                        removal: .scale(scale: 0.1, anchor: .bottom)
                            .combined(with: .opacity)
                    ))
                    .animation(.easeInOut(duration: 0.4), value: showFeedback)
                }
            }
            
            // Bottom controls - only show when camera is ready
            if hasCameraPermission && !cameraLoading {
                VStack {
                    Spacer()
                    
                    HStack(spacing: 40) {
                        // Info button
                        Button(action: {
                            withAnimation(.easeInOut(duration: 0.3)) {
                                showEducationalContent = true
                            }
                        }) {
                            Image(systemName: "info.circle.fill")
                                .font(.system(size: 30))
                                .foregroundColor(.white)
                                .frame(width: 60, height: 60)
                                .background(Color.black.opacity(0.5))
                                .clipShape(Circle())
                        }
                        
                        // Capture button
                        Button(action: {
                            // Capture functionality (optional for MVP)
                        }) {
                            Circle()
                                .fill(Color.white)
                                .frame(width: 80, height: 80)
                                .overlay(
                                    Circle()
                                        .stroke(Color.black, lineWidth: 4)
                                        .frame(width: 70, height: 70)
                                )
                        }
                        
                        // Grid toggle button
                        Button(action: {
                            withAnimation(.easeInOut(duration: 0.3)) {
                                isGridVisible.toggle()
                            }
                        }) {
                            Image(systemName: isGridVisible ? "grid" : "grid.slash")
                                .font(.system(size: 30))
                                .foregroundColor(.white)
                                .frame(width: 60, height: 60)
                                .background(Color.black.opacity(0.5))
                                .clipShape(Circle())
                        }
                    }
                    .padding(.bottom, 50)
                }
                .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .sheet(isPresented: $showEducationalContent) {
            EducationalContentView(isPresented: $showEducationalContent)
                .presentationDetents([.medium])
        }
        .onAppear {
            requestCameraPermission()
        }
        .onReceive(NotificationCenter.default.publisher(for: UIApplication.didBecomeActiveNotification)) { _ in
            // Re-check permissions when app becomes active (e.g., returning from Settings)
            if permissionStatus == .denied || permissionStatus == .restricted {
                requestCameraPermission()
            }
        }
        .animation(.easeInOut(duration: 0.3), value: cameraLoading)
        .animation(.easeInOut(duration: 0.3), value: hasCameraPermission)
    }
    
    private func requestCameraPermission() {
        let currentStatus = AVCaptureDevice.authorizationStatus(for: .video)
        permissionStatus = currentStatus
        
        switch currentStatus {
        case .authorized:
            hasCameraPermission = true
            // Camera loading will be handled by the camera view callback
            cameraLoading = true
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { granted in
                DispatchQueue.main.async {
                    self.permissionStatus = granted ? .authorized : .denied
                    self.hasCameraPermission = granted
                    if granted {
                        // Camera loading will be handled by the camera view callback
                        self.cameraLoading = true
                    }
                }
            }
        case .denied, .restricted:
            hasCameraPermission = false
            cameraLoading = false
        @unknown default:
            hasCameraPermission = false
            cameraLoading = false
        }
    }
}

#Preview {
    ContentView()
} 
