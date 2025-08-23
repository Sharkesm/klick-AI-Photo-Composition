import SwiftUI
import AVFoundation
import Photos

struct ContentView: View {
    @AppStorage("photoAlbumSnapshot") private var photoAlbumSnapshot: Bool = false
    @AppStorage("hasShowedIntroductionGuide") private var hasShowedIntroductionGuide: Bool = false
    
    @State private var feedbackMessage: String?
    @State private var feedbackIcon: String?
    @State private var showFeedback = false
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
    
    // Zoom state
    @State private var selectedZoomLevel: ZoomLevel = .wide
    
    // Photo album state
    @State private var photoAlbumOffset: CGFloat = 0
    @State private var showPhotoAlbumGlimpse = false
    @State private var isPhotoAlbumFullScreen = false
    @State private var isCameraSessionActive = true
    
    // Photo management
    @StateObject private var photoManager = PhotoManager()
    @State private var cameraViewRef: CameraView?
    
    // Onboarding
    @State private var showOnboarding = false
    
    // Image Preview
    @State private var showImagePreview = false
    @State private var capturedPreviewImage: UIImage?
    @State private var processedImage: UIImage?
    @State private var isProcessingImage = false
    
    var body: some View {
        ZStack {
            // Black background
            Color.black
                .ignoresSafeArea()
            
            // Camera view - show immediately when permissions granted
            if hasCameraPermission {
                ZStack {
                    CameraView(
                        feedbackMessage: $feedbackMessage,
                        feedbackIcon: $feedbackIcon,
                        showFeedback: $showFeedback,
                        detectedFaceBoundingBox: $detectedFaceBoundingBox,
                        isFacialRecognitionEnabled: $isFacialRecognitionEnabled,
                        compositionManager: compositionManager,
                        cameraQuality: $selectedCameraQuality,
                        flashMode: $selectedFlashMode,
                        zoomLevel: $selectedZoomLevel,
                        isSessionActive: $isCameraSessionActive,
                        onCameraReady: {
                            // Camera is ready, hide loading
                            print("Camera ready callback triggered")
                            withAnimation(.easeOut(duration: 0.5)) {
                                cameraLoading = false
                            }
                        },
                        onPhotoCaptured: { image, imageData in
                            // Show preview instead of immediately saving
                            capturedPreviewImage = image
                            processedImage = image // Initialize with original image
                            withAnimation(.easeInOut(duration: 0.3)) {
                                showImagePreview = true
                            }
                            print("📸 Photo captured, showing preview")
                        }
                    )
                    
                    // Ultra thin material overlay when camera is paused
                    if !isCameraSessionActive {
                        Rectangle()
                            .fill(.ultraThinMaterial)
                            .ignoresSafeArea(edges: .all)
                            .transition(.opacity)
                    }
                }
                .ignoresSafeArea(edges: .all)
            }
            
            // Composition overlays
            CompositionOverlaysView(
                compositionManager: compositionManager,
                hasCameraPermission: hasCameraPermission,
                cameraLoading: cameraLoading,
                isCompositionAnalysisEnabled: isCompositionAnalysisEnabled,
                areOverlaysHidden: areOverlaysHidden
            )
            
            // Face highlight overlay - only show when camera is ready and facial recognition is enabled
            if hasCameraPermission && !cameraLoading && isFacialRecognitionEnabled {
                FaceHighlightOverlayView(faceBoundingBox: detectedFaceBoundingBox)
                    .ignoresSafeArea()
                    .transition(.opacity)
            }
            
            // Top controls
            TopControlsView(
                selectedCameraQuality: $selectedCameraQuality,
                selectedFlashMode: $selectedFlashMode,
                selectedZoomLevel: $selectedZoomLevel,
                compositionManager: compositionManager,
                hasCameraPermission: hasCameraPermission,
                cameraLoading: cameraLoading
            )
            
            // Loading overlay
            LoadingOverlayView(
                permissionStatus: permissionStatus,
                cameraLoading: cameraLoading,
                hasCameraPermission: hasCameraPermission
            )
            
            // Feedback overlay
            FeedbackOverlayView(
                showFeedback: showFeedback,
                feedbackMessage: feedbackMessage,
                feedbackIcon: feedbackIcon,
                hasCameraPermission: hasCameraPermission,
                cameraLoading: cameraLoading,
                isCompositionAnalysisEnabled: isCompositionAnalysisEnabled
            )
            
            // Bottom controls
            BottomControlsView(
                compositionManager: compositionManager,
                hasCameraPermission: hasCameraPermission,
                cameraLoading: cameraLoading,
                onCapturePhoto: {
                    // Trigger photo capture
                    capturePhoto()
                    
                    if !photoAlbumSnapshot {
                        withAnimation(.linear) {
                            photoAlbumSnapshot = true
                        }
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
                },
                onShowCompositionPicker: {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        showCompositionPicker = true
                    }
                },
                onShowFrameSettings: {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        showFrameSettings = true
                    }
                }
            )
            
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
        .sheet(isPresented: $showOnboarding) {
            OnboardingView(isPresented: $showOnboarding)
        }
        .sheet(isPresented: $showCompositionPicker) {
//            CompositionPickerView(
//                compositionManager: compositionManager,
//                isPresented: $showCompositionPicker
//            )
            CompositionStyleEdView()
                .presentationDetents([.fraction(1.0)])
                .presentationDragIndicator(.hidden)
                .onAppear {
                    // Pause camera session when sheet appears
                    withAnimation(.easeInOut(duration: 0.3)) {
                        isCameraSessionActive = false
                    }
                }
                .onDisappear {
                    // Resume camera session when sheet disappears
                    withAnimation(.easeInOut(duration: 0.3)) {
                        isCameraSessionActive = true
                    }
                }
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
        .fullScreenCover(isPresented: $showImagePreview) {
            ImagePreviewView(
                image: $processedImage,
                originalImage: capturedPreviewImage,
                isProcessing: $isProcessingImage,
                onSave: {
                    // Save the processed image
                    if let imageToSave = processedImage {
                        let compositionType = compositionManager.currentCompositionType.displayName
                        let compositionScore = compositionManager.lastResult?.score ?? 0.7
                        photoManager.savePhoto(imageToSave, compositionType: compositionType, compositionScore: compositionScore)
                        print("📸 Processed photo saved with metadata")
                        
                        // Show photo album glimpse
                        if !photoAlbumSnapshot {
                            withAnimation(.linear) {
                                photoAlbumSnapshot = true
                            }
                        }
                        
                        withAnimation(.easeInOut(duration: 0.3)) {
                            showPhotoAlbumGlimpse = true
                        }
                        
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                            withAnimation(.easeInOut(duration: 0.3)) {
                                showPhotoAlbumGlimpse = false
                            }
                        }
                    }
                    
                    // Close preview
                    withAnimation(.easeInOut(duration: 0.3)) {
                        showImagePreview = false
                    }
                },
                onDiscard: {
                    // Close preview without saving
                    withAnimation(.easeInOut(duration: 0.3)) {
                        showImagePreview = false
                    }
                    capturedPreviewImage = nil
                    processedImage = nil
                }
            )
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
            
            guard !hasShowedIntroductionGuide else { return }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
                withAnimation(.easeIn) {
                    hasShowedIntroductionGuide = true
                    showOnboarding = true
                }
            }
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
                        
                        guard !hasShowedIntroductionGuide else { return }
                        
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                            withAnimation(.easeIn) {
                                hasShowedIntroductionGuide = true
                                showOnboarding = true
                            }
                        }
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
