import SwiftUI
import AVFoundation
import Photos

// MARK: - Flash Mode Enum
enum FlashMode: String, CaseIterable {
    case off = "off"
    case auto = "auto"
    case on = "on"
    
    var displayName: String {
        switch self {
        case .off:
            return "OFF"
        case .auto:
            return "AUTO"
        case .on:
            return "ON"
        }
    }
    
    var iconName: String {
        switch self {
        case .off:
            return "bolt.slash"
        case .auto:
            return "bolt.badge.a"
        case .on:
            return "bolt"
        }
    }
    
    var captureFlashMode: AVCaptureDevice.FlashMode {
        switch self {
        case .off:
            return .off
        case .auto:
            return .auto
        case .on:
            return .on
        }
    }
    
    var captureColor: Color {
        switch self {
        case .on:
            return .yellow
        default:
            return .white
        }
    }
}

// MARK: - Flash Control View
struct FlashControl: View {
    @Binding var selectedFlashMode: FlashMode
    @State private var showFlashChange = false
    
    var body: some View {
        Button(action: {
            withAnimation(.easeInOut(duration: 0.2)) {
                showFlashChange = true
                
                // Cycle through flash modes
                let allCases = FlashMode.allCases
                if let currentIndex = allCases.firstIndex(of: selectedFlashMode) {
                    let nextIndex = (currentIndex + 1) % allCases.count
                    selectedFlashMode = allCases[nextIndex]
                }
            }
        }) {
            VStack(spacing: 4) {
                Image(systemName: selectedFlashMode.iconName)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(selectedFlashMode.captureColor)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(Color.black.opacity(0.5))
            .clipShape(Capsule())
            .scaleEffect(showFlashChange ? 1.1 : 1.0)
        }
        .onChange(of: showFlashChange) { newValue in
            if newValue {
                // Reset scale after animation
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                    withAnimation(.easeOut(duration: 0.1)) {
                        showFlashChange = false
                    }
                }
            }
        }
    }
}

struct ContentView: View {
    @AppStorage("photoAlbumSnapshot") private var photoAlbumSnapshot: Bool = false
    
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
    
    // Camera quality state
    @State private var selectedCameraQuality: CameraQuality = .hd720p
    
    // Flash state
    @State private var selectedFlashMode: FlashMode = .auto
    
    // Photo album state
    @State private var photoAlbumOffset: CGFloat = 0
    @State private var showPhotoAlbumGlimpse = false
    @State private var isPhotoAlbumFullScreen = false
    @State private var isCameraSessionActive = true
    
    // Photo management
    @StateObject private var photoManager = PhotoManager()
    @State private var cameraViewRef: CameraView?
    
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
                    cameraQuality: $selectedCameraQuality,
                    flashMode: $selectedFlashMode,
                    isSessionActive: $isCameraSessionActive,
                    onCameraReady: {
                        // Camera is ready, hide loading
                        print("Camera ready callback triggered")
                        withAnimation(.easeOut(duration: 0.5)) {
                            cameraLoading = false
                        }
                    },
                    onPhotoCaptured: { image in
                        // Save the captured photo with composition info
                        let compositionType = compositionManager.currentCompositionType.displayName
                        let compositionScore = compositionManager.lastResult?.score ?? 0.7
                        photoManager.savePhoto(image, compositionType: compositionType, compositionScore: compositionScore)
                        print("📸 Photo captured and saved")
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
            
            // Top controls - composition indicator, quality selector and flash control
            if hasCameraPermission && !cameraLoading {
                VStack {
                    HStack(alignment: .center) {
                        // Camera quality selector (left)
                        CameraQualitySelector(selectedQuality: $selectedCameraQuality)
                        
                        Spacer()
                        
                        // Composition indicator (center)
                        CompositionIndicatorView(compositionManager: compositionManager, compositionType: compositionManager.currentCompositionType.displayName)
                        
                        Spacer()
                        
                        // Flash control (right)
                        FlashControl(selectedFlashMode: $selectedFlashMode)
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
                            
                            Text(hasCameraPermission ? "" : "Requesting camera access...")
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
                        
                        HStack(spacing: 8) {
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
                                .padding(.vertical, 12)
                        }
                        .padding(.horizontal, 8)
                        .padding(.trailing, 4)
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
                                .background(.ultraThinMaterial)
                                .clipShape(Circle())
                        }
                        
                        // Capture button
                        Button(action: {
                            // Trigger photo capture
                            capturePhoto()
                            
                            if !photoAlbumSnapshot {
                                photoAlbumSnapshot = true
                            }
                            
                            // Show glimpse of photo album when capturing
                            withAnimation(.easeInOut(duration: 0.3)) {
                                showPhotoAlbumGlimpse = true
                            }
                            
                            // Hide glimpse after 1.5 seconds
                            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                                withAnimation(.easeInOut(duration: 0.3)) {
                                    showPhotoAlbumGlimpse = false
                                }
                            }
                            
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
                                .background(.ultraThinMaterial)
                                .clipShape(Circle())
                        }
                    }
                    .padding(.bottom, 50)
                }
                .transition(.move(edge: .bottom).combined(with: .opacity).combined(with: .scale(scale: 0.8)))
            }
            
            // Photo Album View - positioned at the bottom and can be dragged up
            if hasCameraPermission && !cameraLoading && photoAlbumSnapshot {
                GeometryReader { geometry in
                    let screenHeight = geometry.size.height
                    let glimpseHeight: CGFloat = 70
                    let fullScreenOffset: CGFloat = 0
                    let hiddenOffset: CGFloat = screenHeight - 50
                    let glimpseOffset: CGFloat = showPhotoAlbumGlimpse ? screenHeight - glimpseHeight : 0
                    
                    PhotoAlbumView(
                        glipseRevealStarted: glimpseOffset > 0,
                        isFullScreen: $isPhotoAlbumFullScreen,
                        photoManager: photoManager,
                        onTap: {
                            withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                                if isPhotoAlbumFullScreen {
                                    // Close full screen - return to hidden state
                                    photoAlbumOffset = hiddenOffset
                                    isPhotoAlbumFullScreen = false
                                    showPhotoAlbumGlimpse = false
                                } else {
                                    // Open full screen
                                    photoAlbumOffset = fullScreenOffset
                                    isPhotoAlbumFullScreen = true
                                    showPhotoAlbumGlimpse = false
                                }
                            }
                        }
                    )
                    .frame(height: screenHeight)
                    .offset(y: calculatePhotoAlbumOffset(
                        screenHeight: screenHeight,
                        glimpseHeight: glimpseHeight,
                        fullScreenOffset: fullScreenOffset,
                        hiddenOffset: hiddenOffset,
                        glimpseOffset: glimpseOffset
                    ))
                    .animation(.easeInOut(duration: 0.3), value: showPhotoAlbumGlimpse)
                }
                .ignoresSafeArea()
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
                
                // Request photo library permission for saving photos
                photoManager.requestPhotoLibraryPermission()
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
    
    private func calculatePhotoAlbumOffset(
        screenHeight: CGFloat,
        glimpseHeight: CGFloat,
        fullScreenOffset: CGFloat,
        hiddenOffset: CGFloat,
        glimpseOffset: CGFloat
    ) -> CGFloat {
        if isPhotoAlbumFullScreen {
            return fullScreenOffset
        } else if showPhotoAlbumGlimpse {
            return glimpseOffset
        } else {
            return hiddenOffset
        }
    }
    
    private func capturePhoto() {
        // This will be implemented by accessing the camera coordinator directly
        // For now, we'll use a notification-based approach
        NotificationCenter.default.post(name: NSNotification.Name("CapturePhoto"), object: nil)
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
