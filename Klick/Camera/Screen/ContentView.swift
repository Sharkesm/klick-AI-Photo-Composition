import SwiftUI
import AVFoundation
import Photos

struct ContentView: View {
    @AppStorage("photoAlbumSnapshot") private var photoAlbumSnapshot: Bool = false
    @AppStorage("hasShowedIntroductionGuide") private var hasShowedIntroductionGuide: Bool = false
    @AppStorage("isFacialRecognitionEnabled") private var isFacialRecognitionEnabled = true
    @AppStorage("isCompositionAnalysisEnabled") private var isCompositionAnalysisEnabled = true
    @AppStorage("areOverlaysHidden") private var areOverlaysHidden = false
    @AppStorage("isLiveFeedbackEnabled") private var isLiveFeedbackEnabled = true
    @AppStorage("hasShowedCameraQualityIntro") private var hasShowedCameraQualityIntro: Bool = false
    
    @State private var showFeedback = false
    @State private var hasCameraPermission = false
    @State private var cameraLoading = true
    @State private var permissionStatus: AVAuthorizationStatus = .notDetermined
    @State private var detectedFaceBoundingBox: CGRect?
    @State private var faceDetectionConfidence: CGFloat = 0.0
    @StateObject private var compositionManager = CompositionManager()
    @StateObject private var featureManager = FeatureManager()
    
    @State private var showCompositionPractice = false
    
    // Frame settings state
    @State private var showFrameSettings = false

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
    
    // Image Preview - Using item-based presentation to ensure fresh state
    @State private var capturedPhotoData: CapturedPhotoData?
    @State private var isProcessingImage = false
    
    // Composition Share Screen - Using item-based presentation
    @State private var shareScreenData: ShareScreenData?
    
    // Upgrade prompts
    @State private var showUpgradePrompt = false
    @State private var upgradeContext: FeatureManager.UpgradeContext = .photoLimit
    @State private var showSalesPage = false
    @State private var paywallSource: PaywallSource = .upgradePrompt
    
    // Camera quality intro
    @State private var showCameraQualityIntro = false
    @State private var shouldAutoExpandCameraQuality = false
    
    // Swipe composition selector
    @State private var dragOffset: CGFloat = 0
    @State private var showSwipeOverlay = false
    @State private var swipeCompositionPreview: CompositionType?
    @State private var isAnimatingTextOut = false
    @State private var swipeDirection: Int = 0 // 1 = right, -1 = left
    @State private var showLabel = false
    @State private var labelScale: CGFloat = 0
    @State private var canvasProgress: CGFloat = 0 // 0 = edge, 1 = center (animated independently)
    @State private var hasTriggeredThreshold = false // Prevent multiple threshold triggers
    @State private var isProcessingSwipe = false // Prevent overlapping swipe gestures
    
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
                                    // Track photo captured
                                    Task {
                                        let cameraQuality = selectedCameraQuality == .standard ? CameraQuality.standard : CameraQuality.pro
                                        let flashMode: TrackingFlashMode = {
                                            switch selectedFlashMode {
                                            case .off: return .off
                                            case .auto: return .auto
                                            case .on: return .on
                                            }
                                        }()
                                        let zoomLevel = TrackingZoomLevel(fromFactor: selectedZoomLevel.zoomFactor)
                                        let facesDetected = detectedFaceBoundingBox != nil ? 1 : 0
                                        let compositionScore = compositionManager.lastResult?.score
                                        
                                        await EventTrackingManager.shared.trackPhotoCaptured(
                                            compositionType: compositionManager.currentCompositionType,
                                            cameraQuality: cameraQuality,
                                            flashMode: flashMode,
                                            zoomLevel: zoomLevel,
                                            facesDetected: facesDetected,
                                            compositionScore: compositionScore
                                        )
                                    }
                                    
                                    // Create captured photo data struct
                                    // Item-based presentation guarantees fresh state (fixes first-capture-empty bug)
                                    
                                    // Get composition data from manager
                                    let compositionType = compositionManager.currentCompositionType.displayName
                                    let compositionDescription = compositionManager.lastResult?.achievementContext ?? "You positioned your subject perfectly, creating a balanced composition."
                                    
                                    let photoData = CapturedPhotoData(
                                        processedImage: processedImage,
                                        rawImage: rawImage,
                                        cameraQuality: selectedCameraQuality,
                                        compositionType: compositionType,
                                        compositionDescription: compositionDescription
                                    )
                                    
                                    // Setting this triggers the fullScreenCover(item:) presentation
                                    withAnimation(.easeInOut(duration: 0.3)) {
                                        capturedPhotoData = photoData
                                    }
                                }
                            )
                            .overlay(alignment: .top, content: {
                                // Top controls
                                TopControlsView(
                                    featureManager: featureManager,
                                    selectedCameraQuality: $selectedCameraQuality,
                                    selectedFlashMode: $selectedFlashMode,
                                    selectedZoomLevel: $selectedZoomLevel,
                                    showFrameSettings: $showFrameSettings,
                                    showCompositionPractice: $showCompositionPractice,
                                    showSalesPage: $showSalesPage,
                                    paywallSource: $paywallSource,
                                    showUpgradePrompt: $showUpgradePrompt,
                                    showCameraQualityIntro: $showCameraQualityIntro,
                                    shouldAutoExpandCameraQuality: $shouldAutoExpandCameraQuality,
                                    compositionManager: compositionManager,
                                    hasCameraPermission: hasCameraPermission,
                                    cameraLoading: cameraLoading,
                                    hasShowedCameraQualityIntro: hasShowedCameraQualityIntro,
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
                        .gesture(
                            DragGesture(minimumDistance: 20)
                                .onChanged { value in
                                    handleSwipeChanged(translation: value.translation.width)
                                }
                                .onEnded { value in
                                    handleSwipeEnded(translation: value.translation.width)
                                }
                        )
                        .overlay(alignment: .bottom) {
                            VStack {
                                Spacer()
                                FeedbackOverlayView(
                                    showFeedback: showFeedback,
                                    hasCameraPermission: hasCameraPermission,
                                    cameraLoading: cameraLoading,
                                    isCompositionAnalysisEnabled: isCompositionAnalysisEnabled,
                                    feedback: getFeedback()
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
                        .overlay(alignment: .center, content: {
                             // Swipe overlay for composition switching (dev mode)
                             if showSwipeOverlay {
                                 let displayComposition = swipeCompositionPreview ?? compositionManager.currentCompositionType
                                 CompositionSwipeOverlay(
                                     composition: displayComposition,
                                     canvasProgress: canvasProgress,
                                     swipeDirection: swipeDirection,
                                     showLabel: showLabel,
                                     labelScale: labelScale,
                                     isAnimatingOut: isAnimatingTextOut
                                 )
                                 .frame(height: height)
                                 .cornerRadius(30)
                                 .allowsHitTesting(false)
                                 .onAppear {
                                     print("🖼️ Overlay appeared with composition: \(displayComposition.displayName)")
                                 }
                             }
                        })
                        
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
            .onAppear {
                // Track photo album opened
                Task {
                    await EventTrackingManager.shared.trackCameraPhotoAlbumOpened(
                        photoCount: photoManager.photoCount
                    )
                }
            }
        })
        .sheet(isPresented: $showOnboarding) {
            OnboardingView(isPresented: $showOnboarding)
        }
        .sheet(isPresented: $showCompositionPractice) {
            CompositionStyleEdView(
                featureManager: featureManager,
                onShowSalesPage: {
                    // Close practice view and show sales page
                    paywallSource = .compositionPractice
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
                // Track practice opened
                Task {
                    await EventTrackingManager.shared.trackCameraPracticeOpened(compositionType: compositionManager.currentCompositionType)
                }
            }
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
                featureManager: featureManager,
                onShowSalesPage: { source in
                    // Close frame settings and show sales page
                    paywallSource = source
                    withAnimation(.easeInOut(duration: 0.3)) {
                        showFrameSettings = false
                    }
                    // Small delay to allow settings view to dismiss
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                        showSalesPage = true
                    }
                },
                onDismiss: nil
            )
            .presentationDetents([.fraction(0.8), .large])
            .onAppear {
                // Track settings opened
                Task {
                    await EventTrackingManager.shared.trackCameraSettingsOpened()
                }
            }
        }
        .fullScreenCover(isPresented: $showSalesPage) {
            SalesPageView(source: paywallSource)
        }
        .ngBottomSheet(isPresented: $showUpgradePrompt, sheetContent: {
            UpgradePromptAlert(
                context: upgradeContext,
                isPresented: $showUpgradePrompt,
                featureManager: featureManager,
                onUpgrade: {
                    // Show sales page
                    showSalesPage = true
                }
            )
        })
        .ngBottomSheet(isPresented: $showCameraQualityIntro, sheetContent: {
            CameraQualityIntroView(
                isPresented: $showCameraQualityIntro,
                onDismiss: {
                    // Trigger auto-expand of quality selector
                    shouldAutoExpandCameraQuality = true
                }
            )
        })
        .fullScreenCover(item: $capturedPhotoData) { photoData in
            ImagePreviewView(
                image: .constant(photoData.processedImage),
                originalImage: photoData.processedImage,
                rawImage: photoData.rawImage,
                cameraQuality: photoData.cameraQuality,
                compositionType: photoData.compositionType,
                isProcessing: $isProcessingImage,
                featureManager: featureManager,
                onSave: { savedImage in
                    // Save the processed image (with any filters/blur applied in preview)
                    let compositionType = photoData.compositionType
                    let compositionScore = compositionManager.lastResult?.score ?? 0.7
                    photoManager.savePhoto(savedImage, compositionType: compositionType, compositionScore: compositionScore)
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
                    
                    // Close preview by clearing the item (item-based dismissal)
                    withAnimation(.easeInOut(duration: 0.3)) {
                        capturedPhotoData = nil
                    }
                    
                    // Prepare share screen data with compressed image
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                        let shareData = ShareScreenData(
                            photo: savedImage,
                            compositionTechnique: photoData.compositionType,
                            techniqueDescription: photoData.compositionDescription
                        )
                        
                        // Show composition share screen (item-based presentation)
                        shareScreenData = shareData
                    }
                },
                onDiscard: {
                    // MEMORY OPTIMIZATION: Clear all caches when discarding
                    BackgroundBlurManager.shared.endEditingSession(clearAll: true)
                    
                    // Close preview by clearing the item (item-based dismissal)
                    withAnimation(.easeInOut(duration: 0.3)) {
                        capturedPhotoData = nil
                    }
                },
                onShowSalesPage: { source in
                    // Set paywall source and show sales page
                    paywallSource = source
                    // Small delay to allow preview to dismiss before showing sales page
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                        showSalesPage = true
                    }
                }
            )
        }
        .fullScreenCover(item: $shareScreenData) { shareData in
            CompositionShareView(
                photo: shareData.photo,
                compositionTechnique: shareData.compositionTechnique,
                techniqueDescription: shareData.techniqueDescription
            )
        }
        .onAppear {
            // Track camera screen viewed
            Task {
                await EventTrackingManager.shared.trackCameraScreenViewed(
                    sessionId: UUID().uuidString
                )
            }
            
            // Inject FeatureManager into PhotoManager
            photoManager.setFeatureManager(featureManager)
            
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
                
                // Map context to paywall source
                paywallSource = mapUpgradeContextToPaywallSource(context)
                
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
            paywallSource = .photoLimit
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
    
    /// Get appropriate feedback based on live feedback setting
    private func getFeedback() -> CompositionFeedback? {
        if isLiveFeedbackEnabled {
            return compositionManager.lastResult?.feedback
        } else {
            // Return "Live feedback disabled" feedback
            return CompositionFeedback(
                label: "exclamationmark.message",
                suggestion: "Live feedback disabled",
                compositionLevel: -1,
                color: .yellow
            )
        }
    }
    
    private func capturePhoto() {
        let currentComposition = compositionManager.currentCompositionType
        
        // First check: Photo count limit
        guard featureManager.canCapture || currentComposition == .ruleOfThirds else {
            print("🔒 Photo capture blocked - storage limit reached")
            featureManager.showUpgradePrompt(context: .photoLimit)
            return
        }
        
        // Second check: Advanced composition gating
        // Rule of Thirds is always free, but Center Framing and Symmetry require Pro or trial period
        if currentComposition != .ruleOfThirds && !featureManager.canUseAdvancedComposition {
            print("🔒 Photo capture blocked - advanced composition (\(currentComposition.displayName)) requires Pro")
            featureManager.showUpgradePrompt(context: .advancedComposition)
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
    
    // MARK: - Swipe Gesture Handlers
    
    private func handleSwipeChanged(translation: CGFloat) {
        // Prevent updates if already processing swipe end
        guard !isProcessingSwipe else { return }
        
        // Determine swipe direction (positive = right, negative = left)
        let direction = translation > 0 ? 1 : -1
        swipeDirection = direction
        
        // Check if swipe is valid based on current position and boundaries
        guard canSwipeInDirection(direction) else {
            // At boundary - don't allow further swiping in this direction
            return
        }
        
        dragOffset = translation
        
        // Show overlay when drag starts
        if !showSwipeOverlay {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                showSwipeOverlay = true
            }
        }
        
        // Calculate which composition to preview based on drag direction
        let threshold: CGFloat = 80
        if abs(translation) > threshold {
            print("⚡️ Threshold crossed - translation: \(translation), direction: \(direction)")
            
            // Show and slam the label when threshold is crossed (only once)
            if !hasTriggeredThreshold {
                let newComposition = getAdjacentComposition(direction: direction)
                print("⚡️ Setting swipeCompositionPreview to: \(newComposition.displayName)")
                
                // Haptic feedback when threshold crossed
                HapticFeedback.medium.generate()
                
                // Set preview for overlay display (synchronous)
                swipeCompositionPreview = newComposition
                hasTriggeredThreshold = true
                print("🎨 Swipe threshold crossed - showing label for: \(newComposition.displayName)")
                
                // Only trigger visual animations - NO composition manager update yet
                DispatchQueue.main.async {
                    // Show label
                    self.showLabel = true
                    
                    // Perform slam animation
                    self.performSlamAnimation()
                    
                    // Automatically complete canvas slide-in animation
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.75)) {
                        self.canvasProgress = 1.0
                    }
                }
            } else {
                // Update preview even if threshold was already triggered
                let newComposition = getAdjacentComposition(direction: direction)
                swipeCompositionPreview = newComposition
            }
        } else {
            // Reset threshold flag if user swipes back below threshold
            if hasTriggeredThreshold {
                hasTriggeredThreshold = false
                showLabel = false
                labelScale = 0
            }
            
            // Update canvas progress based on drag (before threshold)
            canvasProgress = min(abs(translation) / threshold, 1.0)
        }
    }
    
    private func handleSwipeEnded(translation: CGFloat) {
        // Prevent multiple simultaneous swipe endings
        guard !isProcessingSwipe else { return }
        isProcessingSwipe = true
        
        let threshold: CGFloat = 80
        
        // Determine if swipe was significant enough to change composition
        if abs(translation) > threshold {
            // Apply composition change AFTER visual animations complete (smoother performance)
            if let newComposition = swipeCompositionPreview {
                // Delay composition change until after slam animation settles
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
                    print("🎨 Applying composition change to: \(newComposition.displayName)")
                    
                    // Selection haptic when composition actually changes
                    HapticFeedback.selection.generate()
                    
                    // Track composition swiped
                    let direction = translation > 0 ? "right" : "left"
                    Task {
                        await EventTrackingManager.shared.trackCompositionSwiped(
                            fromComposition: compositionManager.currentCompositionType,
                            toComposition: newComposition,
                            swipeDirection: direction
                        )
                    }
                    
                    self.compositionManager.switchToCompositionType(newComposition)
                }
            }
            
            // Keep label visible for a moment before starting exit animation
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
                // Animate text out (scale down and fade) - slower animation
                withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                    self.isAnimatingTextOut = true
                }
            }
            
            // Hide overlay after animation completes (longer delay for better visibility)
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.25) {
                withAnimation(.spring(response: 0.4, dampingFraction: 0.85)) {
                    self.showSwipeOverlay = false
                    self.isAnimatingTextOut = false
                    self.showLabel = false
                    self.labelScale = 0
                    self.dragOffset = 0
                    self.canvasProgress = 0
                    self.swipeCompositionPreview = nil
                    self.swipeDirection = 0
                    self.hasTriggeredThreshold = false
                    self.isProcessingSwipe = false
                }
            }
        } else {
            // Swipe not significant enough - reset with spring animation
            withAnimation(.spring(response: 0.3, dampingFraction: 0.85)) {
                self.showSwipeOverlay = false
                self.isAnimatingTextOut = false
                self.showLabel = false
                self.labelScale = 0
                self.dragOffset = 0
                self.canvasProgress = 0
                self.swipeCompositionPreview = nil
                self.swipeDirection = 0
                self.hasTriggeredThreshold = false
            }
            
            // Reset processing flag after animation
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                self.isProcessingSwipe = false
            }
        }
    }
    
    private func performSlamAnimation() {
        // Slam effect: Scale up quickly (overshoot), then settle
        withAnimation(.spring(response: 0.4, dampingFraction: 0.6)) {
            labelScale = 1.2 // Overshoot (contained within screen bounds)
        }
        
        // Light haptic when label slams in
        HapticFeedback.light.generate()
        
        // Then settle to normal size (longer delay)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.75)) {
                labelScale = 1.0
            }
        }
    }
    
    /// Check if swipe in given direction is allowed based on current position
    /// - Parameter direction: 1 = right swipe (go left in array), -1 = left swipe (go right in array)
    /// - Returns: true if swipe is allowed, false if at boundary
    private func canSwipeInDirection(_ direction: Int) -> Bool {
        let compositions = CompositionType.allCases
        guard let currentIndex = compositions.firstIndex(of: compositionManager.currentCompositionType) else {
            return true
        }
        
        // Order: [Rule of Thirds (0), Center (1), Symmetry (2)]
        // Right swipe (direction = 1) → Move to lower index (left in list)
        // Left swipe (direction = -1) → Move to higher index (right in list)
        
        if direction > 0 {
            // Right swipe - trying to go left in the array
            // Can't go left if already at Rule of Thirds (index 0)
            return currentIndex > 0
        } else {
            // Left swipe - trying to go right in the array
            // Can't go right if already at Symmetry (last index)
            return currentIndex < compositions.count - 1
        }
    }
    
    private func getAdjacentComposition(direction: Int) -> CompositionType {
        let compositions = CompositionType.allCases
        guard let currentIndex = compositions.firstIndex(of: compositionManager.currentCompositionType) else {
            return compositionManager.currentCompositionType
        }
        
        print("🔍 getAdjacentComposition - Current: \(compositionManager.currentCompositionType.displayName) (index: \(currentIndex)), Direction: \(direction)")
        
        // direction: 1 = right swipe (go to previous/left), -1 = left swipe (go to next/right)
        let newIndex: Int
        if direction > 0 {
            // Right swipe - go to previous (left in array) - NO wrap around
            newIndex = max(0, currentIndex - 1)
        } else {
            // Left swipe - go to next (right in array) - NO wrap around
            newIndex = min(compositions.count - 1, currentIndex + 1)
        }
        
        let result = compositions[newIndex]
        print("🔍 getAdjacentComposition - Result: \(result.displayName) (index: \(newIndex))")
        
        return result
    }
    
    // MARK: - Helper Functions
    
    /// Map upgrade context to paywall source for event tracking
    private func mapUpgradeContextToPaywallSource(_ context: FeatureManager.UpgradeContext) -> PaywallSource {
        switch context {
        case .photoLimit:
            return .photoLimit
        case .lastFreePhoto:
            return .photoLimit
        case .advancedComposition:
            return .advancedComposition
        case .premiumFilter:
            return .imagePreviewPremiumFilter
        case .backgroundBlur:
            return .imagePreviewBackgroundBlur
        case .portraitPractices:
            return .compositionPractice
        case .liveFeedback:
            return .frameSettingsLiveFeedback
        case .hideOverlays:
            return .frameSettingsHideOverlays
        case .proCameraQuality:
            return .cameraQualityPro
        case .batchDelete:
            return .upgradePrompt
        case .filterAdjustments:
            return .upgradePrompt
        }
    }
}

// MARK: - Composition Swipe Overlay

struct CompositionSwipeOverlay: View {
    let composition: CompositionType
    let canvasProgress: CGFloat
    let swipeDirection: Int
    let showLabel: Bool
    let labelScale: CGFloat
    let isAnimatingOut: Bool
    
    var overlayColor: Color {
        return Color.black
    }
    
    var body: some View {
        GeometryReader { geometry in
            let screenWidth = geometry.size.width
            
            // Calculate canvas position - slides from edges based on progress (0 to 1)
            let canvasOffset: CGFloat = {
                let startOffset = swipeDirection > 0 ? -screenWidth : screenWidth
                return startOffset * (1 - canvasProgress) // Slide from edge to center
            }()
            
            ZStack {
                overlayColor
                    .opacity(0.5)
                    .overlay(overlayColor.opacity(0.2))
                    .offset(x: canvasOffset)
            
                // Label - only shows when canvas is centered (slam animation)
                if showLabel {
                    // Composition text
                    Text(composition.displayName)
                        .font(.system(size: 56, weight: .heavy, design: .rounded))
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)
                        .shadow(color: .black.opacity(0.5), radius: 20, x: 0, y: 8)
                        .shadow(color: .black.opacity(0.3), radius: 40, x: 0, y: 0)
                        .scaleEffect(isAnimatingOut ? 0.3 : labelScale)
                        .opacity(isAnimatingOut ? 0.0 : (labelScale > 0 ? 1.0 : 0.0))
                        .animation(.spring(response: 0.5, dampingFraction: 0.8), value: isAnimatingOut)
                        .onAppear {
                            print("📱 Overlay showing label: \(composition.displayName) (scale: \(labelScale))")
                        }
                        .onChange(of: labelScale) { newScale in
                            print("📱 Label scale changed to: \(newScale) for \(composition.displayName)")
                        }
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .clipShape(RoundedRectangle(cornerRadius: 30))
        }
    }
}
