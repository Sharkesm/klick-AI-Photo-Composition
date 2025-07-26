import SwiftUI
import AVFoundation

struct ContentView: View {
    @State private var feedbackMessage: String?
    @State private var feedbackIcon: String?
    @State private var showFeedback = false
    @State private var showEducationalContent = false
    @State private var hasCameraPermission = false
    @State private var cameraLoading = true
    @State private var permissionStatus: AVAuthorizationStatus = .notDetermined
    @State private var detectedFaceBoundingBox: CGRect?
    @StateObject private var compositionManager = CompositionManager()
    @State private var showCompositionPicker = false
    
    // Frame settings state
    @State private var showFrameSettings = false
    @State private var isFacialRecognitionEnabled = true
    @State private var isCompositionAnalysisEnabled = true
    @State private var areOverlaysHidden = false
    
    var body: some View {
        ZStack {
            // Black background
            Color.black
                .ignoresSafeArea()
            
            // Camera view - show immediately when permissions granted
            if hasCameraPermission {
                CameraView(
                    feedbackMessage: $feedbackMessage,
                    feedbackIcon: $feedbackIcon,
                    showFeedback: $showFeedback,
                    detectedFaceBoundingBox: $detectedFaceBoundingBox,
                    isFacialRecognitionEnabled: $isFacialRecognitionEnabled,
                    compositionManager: compositionManager,
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
            
            // Composition overlay - only show when camera is ready, analysis is enabled, and overlays are not hidden
            if hasCameraPermission && !cameraLoading && compositionManager.isEnabled && isCompositionAnalysisEnabled && !areOverlaysHidden {
                GeometryReader { geometry in
                    // Always show basic overlays (grid, crosshair, etc.)
                    ForEach(Array(compositionManager.getBasicOverlays(frameSize: geometry.size).enumerated()), id: \.offset) { index, element in
                        element.path
                            .stroke(element.color.opacity(element.opacity), lineWidth: element.lineWidth)
                    }
                    
                    // Show subject-specific overlays when available
                    if let result = compositionManager.lastResult {
                        ForEach(Array(result.overlayElements.enumerated()), id: \.offset) { index, element in
                            element.path
                                .stroke(element.color.opacity(element.opacity), lineWidth: element.lineWidth)
                        }
                    }
                }
                .ignoresSafeArea()
                .transition(.opacity)
            }
            
            // Face highlight overlay - only show when camera is ready and facial recognition is enabled
            if hasCameraPermission && !cameraLoading && isFacialRecognitionEnabled {
                FaceHighlightOverlayView(faceBoundingBox: detectedFaceBoundingBox)
                    .ignoresSafeArea()
                    .transition(.opacity)
            }
            
            // Top controls - composition indicator and frame settings
            if hasCameraPermission && !cameraLoading {
                VStack {
                    HStack(alignment: .center) {
                        Spacer()
                        // Composition indicator
                        CompositionIndicatorView(compositionManager: compositionManager, compositionType: compositionManager.currentCompositionType.displayName)
                        Spacer()
                        
                    }
                    .frame(alignment: .center)
                    .padding(.top, 60)
                    .padding(.horizontal, 20)
                    
                    Spacer()
                }
                .ignoresSafeArea()
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
            
            // Feedback overlay - only show when camera is ready and analysis is enabled
            if hasCameraPermission && !cameraLoading && isCompositionAnalysisEnabled {
                if showFeedback, let message = feedbackMessage {
                    VStack {
                        Spacer()
                        
                        HStack(spacing: 0) {
                            // System image icon with translucent background
                            Image(systemName: feedbackIcon ?? "questionmark.circle")
                                .font(.title2)
                                .foregroundColor(.white)
                                .frame(width: 32, height: 32)
                                .background(.ultraThinMaterial)
                                .clipShape(Circle())
                            
                            // Feedback message
                            Text(message)
                                .font(.headline)
                                .foregroundColor(.white)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 12)
                        }
                        .background(.ultraThinMaterial)
                        .cornerRadius(25)
                        .padding(.bottom, 150) // 20 points above bottom controls
                        .scaleEffect(showFeedback ? 1.0 : 0.01)
                        .opacity(showFeedback ? 1.0 : 0.0)
                        .animation(.spring, value: showFeedback)
                    }
                }
            }
            
            // Bottom controls - only show when camera is ready
            if hasCameraPermission && !cameraLoading {
                VStack {
                    Spacer()
                    
                    HStack(spacing: 40) {
                        // Composition type selector button
                        Button(action: {
                            withAnimation(.easeInOut(duration: 0.3)) {
                                showCompositionPicker = true
                            }
                        }) {
                            Image(systemName: compositionManager.currentCompositionType.icon)
                                .font(.system(size: 22))
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
                        
                        Button(action: {
                            withAnimation(.easeInOut(duration: 0.3)) {
                                showFrameSettings = true
                            }
                        }) {
                            Image(systemName: "gear")
                                .font(.system(size: 22))
                                .foregroundColor(.white)
                                .frame(width: 60, height: 60)
                                .background(Color.black.opacity(0.5))
                                .clipShape(Circle())
                        }
                    }
                    .padding(.bottom, 50)
                }
                .transition(.move(edge: .bottom).combined(with: .opacity).combined(with: .scale(scale: 0.8)))
            }
        }
        .sheet(isPresented: $showEducationalContent) {
            EducationalContentView(isPresented: $showEducationalContent)
                .presentationDetents([.medium])
        }
        .sheet(isPresented: $showCompositionPicker) {
            CompositionPickerView(
                compositionManager: compositionManager,
                isPresented: $showCompositionPicker
            )
            .presentationDetents([.fraction(0.7)])
        }
        .sheet(isPresented: $showFrameSettings) {
            FrameSettingsView(
                isPresented: $showFrameSettings,
                isFacialRecognitionEnabled: $isFacialRecognitionEnabled,
                isCompositionAnalysisEnabled: $isCompositionAnalysisEnabled,
                areOverlaysHidden: $areOverlaysHidden,
                compositionManager: compositionManager
            )
            .presentationDetents([.fraction(0.8)])
        }
        .onAppear {
            // Add small delay to ensure transition completes before requesting camera
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                print("ContentView onAppear - requesting camera permission")
                requestCameraPermission()
            }
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
        
        print("🎥 Camera permission status: \(currentStatus)")
        
        switch currentStatus {
        case .authorized:
            print("✅ Camera permission already granted")
            hasCameraPermission = true
            // Camera loading will be handled by the camera view callback
            cameraLoading = true
        case .notDetermined:
            print("❓ Camera permission not determined, requesting...")
            AVCaptureDevice.requestAccess(for: .video) { granted in
                DispatchQueue.main.async {
                    print("📱 Camera permission request result: \(granted)")
                    self.permissionStatus = granted ? .authorized : .denied
                    self.hasCameraPermission = granted
                    if granted {
                        // Camera loading will be handled by the camera view callback
                        self.cameraLoading = true
                        print("🎬 Camera loading set to true")
                    }
                }
            }
        case .denied, .restricted:
            print("❌ Camera permission denied or restricted")
            hasCameraPermission = false
            cameraLoading = false
        @unknown default:
            print("❓ Unknown camera permission status")
            hasCameraPermission = false
            cameraLoading = false
        }
    }
}

#Preview {
    ContentView()
}
