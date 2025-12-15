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
    @State private var faceDetectionConfidence: CGFloat = 0.0
    @StateObject private var compositionManager = CompositionManager()
    @State private var showCompositionPractice = false
    
    // Frame settings state
    @State private var showFrameSettings = false
    @AppStorage("isFacialRecognitionEnabled") private var isFacialRecognitionEnabled = true
    @AppStorage("isCompositionAnalysisEnabled") private var isCompositionAnalysisEnabled = true
    @AppStorage("areOverlaysHidden") private var areOverlaysHidden = false
    @AppStorage("isLiveFeedbackEnabled") private var isLiveFeedbackEnabled = true
    
    // Camera quality state
    @State private var selectedCameraQuality: CameraQuality = .standard
    
    // Flash state
    @State private var selectedFlashMode: FlashMode = .auto
    
    // Zoom state
    @State private var selectedZoomLevel: ZoomLevel = .wide
    
    // Photo album state
    @State private var photoAlbumOffset: CGFloat = 0
    @State private var showPhotoAlbumGlimpse = false
    @State private var isPhotoAlbumFullScreen = false
    @State private var isCameraSessionActive = true
    @State private var showPhotoAlbum: Bool = false
    
    // Photo management
    @StateObject private var photoManager = PhotoManager()
    @State private var cameraViewRef: CameraView?
    
    // Onboarding
    @State private var showOnboarding = false
    
    // Image Preview
    @State private var showImagePreview = false
    @State private var capturedPreviewImage: UIImage?
    @State private var capturedRawImage: UIImage? // New: RAW image for Pro mode
    @State private var processedImage: UIImage?
    @State private var isProcessingImage = false
    
    // Upgrade prompts
    @State private var showUpgradePrompt = false
    @State private var upgradeContext: FeatureManager.UpgradeContext = .photoLimit
    @State private var showSalesPage = false
    
    private var shouldShowPhotoAlbum: Bool {
        return hasCameraPermission && !cameraLoading && photoAlbumSnapshot
    }
    
    var body: some View {
        ZStack {
            // Black background
            Color.black
                .ignoresSafeArea()
            
            // Camera view - show immediately when permissions granted
            if hasCameraPermission {
                GeometryReader { geometry in
                    let screenHeight = geometry.size.height
                    let height = shouldShowPhotoAlbum ? screenHeight - 45 : screenHeight
                    
                    VStack {
                        ZStack {
                            CameraView(
                                feedbackMessage: $feedbackMessage,
                                feedbackIcon: $feedbackIcon,
                                showFeedback: $showFeedback,
                                detectedFaceBoundingBox: $detectedFaceBoundingBox,
                                faceDetectionConfidence: $faceDetectionConfidence,
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
                                onPhotoCaptured: { processedImage, rawImage, imageData in
                                    // Show preview instead of immediately saving
                                    capturedPreviewImage = processedImage
                                    capturedRawImage = rawImage // Store RAW image if available
                                    self.processedImage = processedImage // Initialize with processed image
                                    withAnimation(.easeInOut(duration: 0.3)) {
                                        showImagePreview = true
                                    }
                                    print("📸 Photo captured - Processed: ✓, RAW: \(rawImage != nil ? "✓" : "✗"), showing preview")
                                }
                            )
                            .overlay(alignment: .top, content: {
                                // Top controls
                                TopControlsView(
                                    selectedCameraQuality: $selectedCameraQuality,
                                    selectedFlashMode: $selectedFlashMode,
                                    selectedZoomLevel: $selectedZoomLevel,
                                    showFrameSettings: $showFrameSettings,
                                    showCompositionPractice: $showCompositionPractice,
                                    showSalesPage: $showSalesPage,
                                    showUpgradePrompt: $showUpgradePrompt,
                                    compositionManager: compositionManager,
                                    hasCameraPermission: hasCameraPermission,
                                    cameraLoading: cameraLoading
                                )
                                .padding(.top, 20)
                            })
                            .overlay(alignment: .center, content: {
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
                                    FaceHighlightOverlayView(
                                        faceBoundingBox: detectedFaceBoundingBox,
                                        isFaceDetected: detectedFaceBoundingBox != nil,
                                        recognitionConfidence: faceDetectionConfidence
                                    )
                                    .ignoresSafeArea()
                                    .transition(.opacity)
                                }
                            })
                            .overlay(alignment: .center) {
                                if cameraLoading || !hasCameraPermission {
                                    // Loading overlay
                                    LoadingOverlayView(permissionStatus: permissionStatus)
                                }
                            }
                            
                            // Ultra thin material overlay when camera is paused
                            if !isCameraSessionActive {
                                Rectangle()
                                    .fill(.ultraThinMaterial)
                                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                                    .transition(.opacity)
                            }
                        }
                        .frame(height: height)
                        .cornerRadius(30)
                        .overlay(alignment: .bottom) {
                            VStack {
                                Spacer()
                                FeedbackOverlayView(
                                    showFeedback: showFeedback,
                                    feedbackMessage: isLiveFeedbackEnabled ? feedbackMessage : "Live feedback disabled",
                                    feedbackIcon: isLiveFeedbackEnabled ? feedbackIcon : "exclamationmark.message",
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
                                        // Do nothing
                                    }
                                )
                            }
                            .padding(.bottom, 20)
                        }
                        
                        if shouldShowPhotoAlbum {
                            VStack {
                                Text("Photo Album")
                                    .font(.system(size: 16, weight: .medium))
                                    .foregroundColor(.black)
                            }
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                            .background(Color.yellow)
                            .clipShape(
                                RoundedCorners(topLeading: 30, topTrailing: 30, bottomLeading: 0, bottomTrailing: 0)
                            )
                            .onTapGesture {
                                withAnimation(.spring) {
                                    showPhotoAlbum = true
                                }
                            }
                        }
                    }
                    .ignoresSafeArea(.container, edges: .bottom)
                }
            }
        }
        .sheet(isPresented: $showPhotoAlbum, content: {
            PhotoAlbumView(photoManager: photoManager, onTap: {
                withAnimation(.spring) {
                    showPhotoAlbum = false
                }
            })
            .presentationDetents([.large])
        })
        .sheet(isPresented: $showOnboarding) {
            OnboardingView(isPresented: $showOnboarding)
        }
        .sheet(isPresented: $showCompositionPractice) {
            CompositionStyleEdView(
                onShowSalesPage: {
                    // Close practice view and show sales page
                    withAnimation(.easeInOut(duration: 0.3)) {
                        showCompositionPractice = false
                    }
                    // Small delay to allow practice view to dismiss before showing sales page
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                        showSalesPage = true
                    }
                }
            )
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
                isLiveFeedbackEnabled: $isLiveFeedbackEnabled,
                compositionManager: compositionManager,
                onShowSalesPage: {
                    // Close frame settings and show sales page
                    withAnimation(.easeInOut(duration: 0.3)) {
                        showFrameSettings = false
                    }
                    // Small delay to allow settings view to dismiss
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                        showSalesPage = true
                    }
                }
            )
            .presentationDetents([.fraction(0.8), .large])
        }
        .fullScreenCover(isPresented: $showSalesPage) {
            SalesPageView()
        }
        .ngBottomSheet(isPresented: $showUpgradePrompt, sheetContent: {
            UpgradePromptAlert(
                context: upgradeContext,
                isPresented: $showUpgradePrompt,
                onUpgrade: {
                    // Show sales page
                    showSalesPage = true
                }
            )
        })
        .fullScreenCover(isPresented: $showImagePreview) {
            ImagePreviewView(
                image: $processedImage,
                originalImage: capturedPreviewImage,
                rawImage: capturedRawImage,
                cameraQuality: selectedCameraQuality,
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
                    // MEMORY OPTIMIZATION: Clear all caches when discarding
                    BackgroundBlurManager.shared.endEditingSession(clearAll: true)
                    
                    // Close preview without saving
                    withAnimation(.easeInOut(duration: 0.3)) {
                        showImagePreview = false
                    }
                    capturedPreviewImage = nil
                    capturedRawImage = nil
                    processedImage = nil
                },
                onShowSalesPage: {
                    // Small delay to allow preview to dismiss before showing sales page
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                        showSalesPage = true
                    }
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
        .onReceive(NotificationCenter.default.publisher(for: .showUpgradePrompt)) { notification in
            // Show upgrade prompt when triggered
            if let contextString = notification.userInfo?["context"] as? String,
               let context = FeatureManager.UpgradeContext(rawValue: contextString) {
                upgradeContext = context
                withAnimation {
                    showUpgradePrompt = true
                }
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .autoDisableLiveFeedback)) { _ in
            // Auto-disable live feedback when trial ends
            print("🔒 Auto-disabling Live Feedback - trial ended")
            withAnimation {
                isLiveFeedbackEnabled = false
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .autoDisableHideOverlays)) { _ in
            // Auto-disable hide overlays when trial ends
            print("🔒 Auto-disabling Hide Overlays - trial ended")
            withAnimation {
                areOverlaysHidden = false
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .lastFreePhotoWarning)) { _ in
            // Show warning before last free photo
            print("⚠️ Last free photo warning triggered")
            upgradeContext = .lastFreePhoto
            withAnimation {
                showUpgradePrompt = true
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
        let currentComposition = compositionManager.currentCompositionType
        
        // First check: Photo count limit
        guard FeatureManager.shared.canCapture || currentComposition == .ruleOfThirds else {
            print("🔒 Photo capture blocked - storage limit reached")
            FeatureManager.shared.showUpgradePrompt(context: .photoLimit)
            return
        }
        
        // Second check: Advanced composition gating
        // Rule of Thirds is always free, but Center Framing and Symmetry require Pro or trial period
        if currentComposition != .ruleOfThirds && !FeatureManager.shared.canUseAdvancedComposition {
            print("🔒 Photo capture blocked - advanced composition (\(currentComposition.displayName)) requires Pro")
            FeatureManager.shared.showUpgradePrompt(context: .advancedComposition)
            return
        }
        
        // All checks passed - proceed with capture
        // This will be implemented by accessing the camera coordinator directly
        // For now, we'll use a notification-based approach
        NotificationCenter.default.post(name: NSNotification.Name("CapturePhoto"), object: nil)
    }
    
    private func requestCameraPermission() {
        // Permission should already be granted from PermissionFlowView
        // This function now just checks status and shows onboarding modal
        let currentStatus = AVCaptureDevice.authorizationStatus(for: .video)
        permissionStatus = currentStatus
        
        print("🎥 Camera permission status: \(currentStatus)")
        
        switch currentStatus {
        case .authorized:
            print("✅ Camera permission already granted")
            hasCameraPermission = true
            // Camera loading will be handled by the camera view callback
            cameraLoading = true
            
            // Show onboarding modal after camera loads
            guard !hasShowedIntroductionGuide else { return }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
                withAnimation(.easeIn) {
                    hasShowedIntroductionGuide = true
                    showOnboarding = true
                }
            }
            
        case .notDetermined:
            // This should not happen if flow is correct, but handle it anyway
            print("⚠️ Permission not determined - user may have skipped flow")
            hasCameraPermission = false
            cameraLoading = false
            
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
