import SwiftUI
import AVFoundation
import Vision

struct CameraView: View {
    @Binding var feedbackMessage: String?
    @Binding var feedbackIcon: String?
    @Binding var showFeedback: Bool
    @Binding var detectedFaceBoundingBox: CGRect?
    @Binding var isFacialRecognitionEnabled: Bool
    @ObservedObject var compositionManager: CompositionManager
    @Binding var cameraQuality: CameraQuality
    @Binding var flashMode: FlashMode
    @Binding var isSessionActive: Bool
    let onCameraReady: () -> Void
    let onPhotoCaptured: ((UIImage) -> Void)?
    
    // Focus-related state
    @State private var focusPoint: CGPoint = .zero
    @State private var showFocusIndicator = false
    
    @State private var isChangingQuality = false

    var body: some View {
        ZStack {
            // Camera view
            CameraUIViewRepresentable(
                feedbackMessage: $feedbackMessage,
                feedbackIcon: $feedbackIcon,
                showFeedback: $showFeedback,
                detectedFaceBoundingBox: $detectedFaceBoundingBox,
                isFacialRecognitionEnabled: $isFacialRecognitionEnabled,
                compositionManager: compositionManager,
                cameraQuality: $cameraQuality,
                flashMode: $flashMode,
                isSessionActive: $isSessionActive,
                onCameraReady: onCameraReady,
                focusPoint: $focusPoint,
                showFocusIndicator: $showFocusIndicator,
                onPhotoCaptured: onPhotoCaptured
            )
            
            // Show loading overlay during quality change
            if isChangingQuality {
                ProgressView()
                    .scaleEffect(0.8)
                    .background(.ultraThinMaterial)
                    .clipShape(Circle())
            }
            
            // Focus indicator overlay
            if showFocusIndicator {
                FocusIndicatorView(point: focusPoint)
                    .transition(.scale.combined(with: .opacity))
            }
        }
    }
    
    // Public method to trigger photo capture
    func capturePhoto() {
        // This will be handled by the UIViewRepresentable coordinator
    }
}

struct CameraUIViewRepresentable: UIViewRepresentable {
    @Binding var feedbackMessage: String?
    @Binding var feedbackIcon: String?
    @Binding var showFeedback: Bool
    @Binding var detectedFaceBoundingBox: CGRect?
    @Binding var isFacialRecognitionEnabled: Bool
    @ObservedObject var compositionManager: CompositionManager
    @Binding var cameraQuality: CameraQuality
    @Binding var flashMode: FlashMode
    @Binding var isSessionActive: Bool
    let onCameraReady: () -> Void
    @Binding var focusPoint: CGPoint
    @Binding var showFocusIndicator: Bool
    let onPhotoCaptured: ((UIImage) -> Void)?
    
    func makeUIView(context: Context) -> UIView {
        let view = UIView()
        view.backgroundColor = .black
        
        // Add tap gesture recognizer for focus
        let tapGesture = UITapGestureRecognizer(target: context.coordinator, action: #selector(context.coordinator.handleTap(_:)))
        view.addGestureRecognizer(tapGesture)
        
        // Store the capture callback in coordinator
        context.coordinator.onPhotoCaptured = onPhotoCaptured
        
        // Set up camera session asynchronously to avoid blocking UI
        DispatchQueue.global(qos: .userInitiated).async {
            self.setupCameraSession(for: view, context: context)
        }
        
        return view
    }
    
    private func setupCameraSession(for view: UIView, context: Context) {
        print("📷 Starting camera session setup...")
        
        // Create camera session
        let session = AVCaptureSession()
        session.sessionPreset = cameraQuality.sessionPreset
        print("📷 Camera quality set to: \(cameraQuality.displayName) (\(cameraQuality.sessionPreset.rawValue))")
        
        // Add camera input
        guard let camera = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back),
              let input = try? AVCaptureDeviceInput(device: camera) else {
            DispatchQueue.main.async {
                print("❌ Failed to setup camera input")
            }
            return
        }
        
        print("✅ Camera input configured")
        session.addInput(input)
        
        // Store camera device reference for focus control
        context.coordinator.cameraDevice = camera
        
        // Add video output for processing
        let videoOutput = AVCaptureVideoDataOutput()
        videoOutput.setSampleBufferDelegate(context.coordinator, queue: DispatchQueue.global(qos: .userInitiated))
        session.addOutput(videoOutput)
        
        // Configure video output connection for proper orientation
        if let connection = videoOutput.connection(with: .video) {
            connection.videoOrientation = .portrait
            if connection.isVideoMirroringSupported {
                connection.isVideoMirrored = false
            }
        }
        
        // Add photo output for capturing images
        let photoOutput = AVCapturePhotoOutput()
        if session.canAddOutput(photoOutput) {
            session.addOutput(photoOutput)
            context.coordinator.photoOutput = photoOutput
            print("✅ Photo output configured")
        } else {
            print("❌ Failed to add photo output")
        }
        
        print("✅ Video output configured")
        
        // Create preview layer on main thread
        DispatchQueue.main.async {
            let previewLayer = AVCaptureVideoPreviewLayer(session: session)
            previewLayer.videoGravity = .resizeAspectFill
            previewLayer.frame = view.bounds
            view.layer.addSublayer(previewLayer)
            
            print("✅ Preview layer added to view")
            
            // Store references in coordinator
            context.coordinator.session = session
            context.coordinator.previewLayer = previewLayer
            context.coordinator.viewFrame = view.bounds
            
            // Start session in background
            DispatchQueue.global(qos: .background).async {
                print("🚀 Starting camera session...")
                session.startRunning()
                
                // Set camera start time when session actually starts
                context.coordinator.cameraStartTime = CACurrentMediaTime()
                print("⏱️ Camera start time set")
                
                // Notify when camera is ready - only if session is actually running
                if session.isRunning {
                    print("✅ Camera session is running")
                    DispatchQueue.main.async {
                        // Small delay to ensure camera is fully initialized
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                            print("🎉 Triggering camera ready callback")
                            self.onCameraReady()
                            context.coordinator.cameraReady = true
                        }
                    }
                } else {
                    // Handle case where session failed to start
                    DispatchQueue.main.async {
                        print("❌ Camera session failed to start")
                    }
                }
            }
        }
    }
    
    func updateUIView(_ uiView: UIView, context: Context) {
        // Update both preview layer and stored view frame
        context.coordinator.previewLayer?.frame = uiView.bounds
        context.coordinator.viewFrame = uiView.bounds
        
        // Update the photo capture callback
        context.coordinator.onPhotoCaptured = onPhotoCaptured
        
        // Handle session active/inactive state
        if let session = context.coordinator.session {
            if isSessionActive && !session.isRunning {
                // Start session if it should be active but isn't running
                DispatchQueue.global(qos: .background).async {
                    session.startRunning()
                    print("📷 Camera session started (from updateUIView)")
                }
            } else if !isSessionActive && session.isRunning {
                // Stop session if it should be inactive but is running
                DispatchQueue.global(qos: .background).async {
                    session.stopRunning()
                    print("📷 Camera session stopped (from updateUIView)")
                }
            }
        }
        
        // Update camera quality if it has changed
        if let session = context.coordinator.session,
           session.sessionPreset != cameraQuality.sessionPreset {
            updateCameraQuality(session: session, newQuality: cameraQuality, forContext: context)
        }
    }
    
    private func updateCameraQuality(session: AVCaptureSession, newQuality: CameraQuality, forContext context: Context) {
        DispatchQueue.global(qos: .userInitiated).async {
            // Check if the new preset is supported
            guard session.canSetSessionPreset(newQuality.sessionPreset) else {
                print("⚠️ Camera quality \(newQuality.displayName) not supported")
                return
            }
            
            // Begin configuration transaction
            session.beginConfiguration()
            
            // Set the new preset
            session.sessionPreset = newQuality.sessionPreset
            
            // Reconfigure video output for optimal quality
            if let videoOutput = session.outputs.first(where: { $0 is AVCaptureVideoDataOutput }) as? AVCaptureVideoDataOutput {
                
                // Use optimal video settings without forcing specific dimensions
                let videoSettings: [String: Any] = [
                    kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32BGRA
                ]
                
                videoOutput.videoSettings = videoSettings
                
                // Ensure proper connection configuration
                if let connection = videoOutput.connection(with: .video) {
                    connection.videoOrientation = .portrait
                    if connection.isVideoMirroringSupported {
                        connection.isVideoMirrored = false
                    }
                    
                    // Enable video stabilization for better quality
                    if connection.isVideoStabilizationSupported {
                        connection.preferredVideoStabilizationMode = .auto
                    }
                }
            }
            
            // Commit all changes atomically
            session.commitConfiguration()
            
            // Brief pause to allow session to stabilize
            Thread.sleep(forTimeInterval: 0.1)
            
            print("✅ Camera quality updated to: \(newQuality.displayName) (\(newQuality.sessionPreset.rawValue))")
            
            // Update UI on main thread
            DispatchQueue.main.async {
                // Force preview layer to refresh
                if let previewLayer = context.coordinator.previewLayer {
                    previewLayer.connection?.isEnabled = false
                    previewLayer.connection?.isEnabled = true
                }
            }
        }
    }

    // Helper methods for optimal resolution (kept for reference but not used to avoid crashes)
    private func getOptimalWidth(for quality: CameraQuality) -> Int {
        switch quality {
        case .hd720p: return 1280
        case .hd1080p: return 1920
        case .uhd4K: return 3840
        }
    }

    private func getOptimalHeight(for quality: CameraQuality) -> Int {
        switch quality {
        case .hd720p: return 720
        case .hd1080p: return 1080
        case .uhd4K: return 2160
        }
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, AVCaptureVideoDataOutputSampleBufferDelegate, AVCapturePhotoCaptureDelegate {
        private var frameCount = 0
        private var isAppInBackground = false
        
        var parent: CameraUIViewRepresentable
        var session: AVCaptureSession?
        var previewLayer: AVCaptureVideoPreviewLayer?
        var viewFrame: CGRect = .zero
        var cameraStartTime = CACurrentMediaTime()
        var cameraReady = false
        var cameraDevice: AVCaptureDevice?
        var photoOutput: AVCapturePhotoOutput?
        var onPhotoCaptured: ((UIImage) -> Void)?
    
        init(_ parent: CameraUIViewRepresentable) {
            self.parent = parent
            super.init()
            
            // Monitor app lifecycle to prevent background processing
            NotificationCenter.default.addObserver(
                self,
                selector: #selector(appDidEnterBackground),
                name: UIApplication.didEnterBackgroundNotification,
                object: nil
            )
            
            NotificationCenter.default.addObserver(
                self,
                selector: #selector(appWillEnterForeground),
                name: UIApplication.willEnterForegroundNotification,
                object: nil
            )
            
            // Listen for capture photo notifications
            NotificationCenter.default.addObserver(
                self,
                selector: #selector(capturePhotoNotification),
                name: NSNotification.Name("CapturePhoto"),
                object: nil
            )
        }
        
        // MARK: - Photo Capture Methods
        
        func capturePhoto() {
            guard let photoOutput = photoOutput else {
                print("❌ Photo output not available")
                return
            }
            
            // Create photo settings with preferred codec
            let settings: AVCapturePhotoSettings
            
            // Configure photo settings based on available codecs
            if photoOutput.availablePhotoCodecTypes.contains(.hevc) {
                settings = AVCapturePhotoSettings(format: [AVVideoCodecKey: AVVideoCodecType.hevc])
            } else if photoOutput.availablePhotoCodecTypes.contains(.jpeg) {
                settings = AVCapturePhotoSettings(format: [AVVideoCodecKey: AVVideoCodecType.jpeg])
            } else {
                // Fallback to default settings
                settings = AVCapturePhotoSettings()
            }
            
            // Enable high resolution capture if available (modern API)
            // Only set quality prioritization if the output supports it
            if photoOutput.maxPhotoQualityPrioritization.rawValue >= AVCapturePhotoOutput.QualityPrioritization.balanced.rawValue {
                settings.photoQualityPrioritization = .balanced
            }
            
            // If the output supports quality prioritization, use it
            if photoOutput.maxPhotoQualityPrioritization == .quality {
                settings.photoQualityPrioritization = .quality
            }
            
            // Set flash mode based on user selection
            let desiredFlashMode = parent.flashMode.captureFlashMode
            if photoOutput.supportedFlashModes.contains(desiredFlashMode) {
                settings.flashMode = desiredFlashMode
            } else {
                // Fallback to off if desired mode not supported
                settings.flashMode = .off
            }
            
            // Capture the photo
            photoOutput.capturePhoto(with: settings, delegate: self)
            print("📸 Photo capture initiated")
        }
        
        // MARK: - AVCapturePhotoCaptureDelegate
        
        func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
            if let error = error {
                print("❌ Photo capture error: \(error.localizedDescription)")
                return
            }
            
            guard let imageData = photo.fileDataRepresentation(),
                  let image = UIImage(data: imageData) else {
                print("❌ Failed to convert photo to UIImage")
                return
            }
            
            // Correct image orientation for portrait mode
            let correctedImage = image.fixOrientation()
            
            print("✅ Photo captured successfully")
            
            // Call the callback on main thread
            DispatchQueue.main.async {
                self.onPhotoCaptured?(correctedImage)
            }
        }
        
        func photoOutput(_ output: AVCapturePhotoOutput, didCapturePhotoFor resolvedSettings: AVCaptureResolvedPhotoSettings) {
            // Photo capture started - could add capture animation here
            print("📷 Photo capture started")
        }
        
        @objc private func appDidEnterBackground() {
            isAppInBackground = true
            // Stop camera session to prevent background processing
            DispatchQueue.global(qos: .background).async { [weak self] in
                self?.session?.stopRunning()
            }
        }
        
        @objc private func appWillEnterForeground() {
            isAppInBackground = false
            // Restart camera session when returning to foreground
            DispatchQueue.global(qos: .background).async { [weak self] in
                guard let session = self?.session, !session.isRunning else { return }
                session.startRunning()
            }
        }
        
        @objc private func capturePhotoNotification() {
            // Only capture if camera is ready and not in background
            guard cameraReady && !isAppInBackground else {
                print("⚠️ Cannot capture photo - camera not ready or app in background")
                return
            }
            
            capturePhoto()
        }
        
        deinit {
            NotificationCenter.default.removeObserver(self)
        }
        
        @objc func handleTap(_ gesture: UITapGestureRecognizer) {
            guard let cameraDevice = cameraDevice,
                  let previewLayer = previewLayer,
                  cameraDevice.isFocusPointOfInterestSupported else {
                return
            }
            
            // Get tap location in view coordinates
            let tapPoint = gesture.location(in: gesture.view)
            
            // Convert to camera coordinates (0,0 to 1,1)
            let focusPoint = previewLayer.captureDevicePointConverted(fromLayerPoint: tapPoint)
            
            // Update focus point for visual feedback
            DispatchQueue.main.async {
                self.parent.focusPoint = tapPoint
                self.parent.showFocusIndicator = true
                
                // Hide focus indicator after animation
                DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                    withAnimation(.easeOut(duration: 0.3)) {
                        self.parent.showFocusIndicator = false
                    }
                }
            }
            
            // Set focus point on camera device
            do {
                try cameraDevice.lockForConfiguration()
                
                if cameraDevice.isFocusPointOfInterestSupported {
                    cameraDevice.focusPointOfInterest = focusPoint
                    cameraDevice.focusMode = .autoFocus
                }
                
                if cameraDevice.isExposurePointOfInterestSupported {
                    cameraDevice.exposurePointOfInterest = focusPoint
                    cameraDevice.exposureMode = .autoExpose
                }
                
                cameraDevice.unlockForConfiguration()
                print("🎯 Focus set to point: \(focusPoint)")
            } catch {
                print("❌ Failed to set focus: \(error)")
            }
        }
        
        func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
            // Skip processing if app is in background to prevent GPU errors
            guard !isAppInBackground else { return }
            
            // Lazy vision processing - only start after camera is stable
            guard cameraReady else { return }
            
            // Only process after camera has been running for at least 1 second
            let currentTime = CACurrentMediaTime()
            guard currentTime - cameraStartTime > 1.0 else { return }
            
            // Process every 3rd frame to reduce CPU load
            frameCount += 1
            guard frameCount % 3 == 0 else { return }
            
            guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }
            
            // Only perform subject detection if facial recognition is enabled
            if parent.isFacialRecognitionEnabled {
                performSubjectDetection(pixelBuffer: pixelBuffer)
            } else {
                // Clear face bounding box when facial recognition is disabled
                DispatchQueue.main.async {
                    self.parent.detectedFaceBoundingBox = nil
                    self.parent.feedbackMessage = nil
                    self.parent.feedbackIcon = nil
                    self.parent.showFeedback = false
                }
            }
        }
        
        private func performSubjectDetection(pixelBuffer: CVPixelBuffer) {
            // Perform face detection in background
            DispatchQueue.global(qos: .userInitiated).async { [weak self] in
                guard let self = self else { return }
                
                let faceRequest = VNDetectFaceRectanglesRequest { [weak self] request, error in
                    guard let self = self else { return }
                    
                    DispatchQueue.main.async {
                        if let results = request.results as? [VNFaceObservation], !results.isEmpty {
                            // 🔧 MINIMAL CHANGE: Better face selection for distant faces
                            // Filter faces with slightly lower confidence threshold for distant detection
                            let validFaces = results.filter { $0.confidence > 0.3 } // Lowered from implicit ~0.5
                            
                            let selectedFace: VNFaceObservation
                            if !validFaces.isEmpty {
                                // Use best face by combining confidence and size (helps with distant faces)
                                selectedFace = validFaces.max { face1, face2 in
                                    let area1 = face1.boundingBox.width * face1.boundingBox.height
                                    let area2 = face2.boundingBox.width * face2.boundingBox.height
                                    let score1 = Double(face1.confidence) * area1
                                    let score2 = Double(face2.confidence) * area2
                                    return score1 < score2
                                } ?? validFaces[0]
                            } else {
                                // Fallback to original behavior if no valid faces
                                selectedFace = results[0]
                            }
                            
                            // Convert Vision coordinates to screen coordinates with improved conversion
                            let convertedRect = self.convertVisionToScreenCoordinates(
                                visionRect: selectedFace.boundingBox,
                                pixelBuffer: pixelBuffer
                            )
                            
                            self.parent.detectedFaceBoundingBox = convertedRect
                            self.evaluateComposition(observation: selectedFace, pixelBuffer: pixelBuffer)
                        } else {
                            // Try human detection if no face found
                            self.parent.detectedFaceBoundingBox = nil
                            self.performHumanDetection(pixelBuffer: pixelBuffer)
                        }
                    }
                }
                
                // Configure face detection for better accuracy
                faceRequest.revision = VNDetectFaceRectanglesRequestRevision3
                
                // 🔧 MINIMAL CHANGE: Enhanced options for better distant face detection
                let options: [VNImageOption: Any] = [
                    .ciContext: CIContext(options: [.useSoftwareRenderer: false])
                ]
                let handler = VNImageRequestHandler(cvPixelBuffer: pixelBuffer, options: options)
                try? handler.perform([faceRequest])
            }
        }
        
        private func performHumanDetection(pixelBuffer: CVPixelBuffer) {
            // Perform human detection in background
            DispatchQueue.global(qos: .userInitiated).async { [weak self] in
                guard let self = self else { return }
                
                let humanRequest = VNDetectHumanRectanglesRequest { [weak self] request, error in
                    guard let self = self else { return }
                    
                    DispatchQueue.main.async {
                        if let results = request.results as? [VNHumanObservation], !results.isEmpty {
                            // Use the first detected human
                            let human = results[0]
                            self.evaluateComposition(observation: human, pixelBuffer: pixelBuffer)
                        } else {
                            // No subject detected
                            self.parent.feedbackMessage = nil
                            self.parent.feedbackIcon = nil
                            self.parent.showFeedback = false
                            self.parent.detectedFaceBoundingBox = nil
                        }
                    }
                }
                
                // Configure human detection for better accuracy
                humanRequest.revision = VNDetectHumanRectanglesRequestRevision2
                
                let handler = VNImageRequestHandler(cvPixelBuffer: pixelBuffer, options: [:])
                try? handler.perform([humanRequest])
            }
        }
        
        /// Improved coordinate conversion from Vision framework to screen coordinates
        private func convertVisionToScreenCoordinates(visionRect: CGRect, pixelBuffer: CVPixelBuffer) -> CGRect {
            guard let previewLayer = previewLayer else {
                // Fallback to simple conversion if preview layer not available
                return CGRect(
                    x: visionRect.origin.x * viewFrame.width,
                    y: (1 - visionRect.origin.y - visionRect.height) * viewFrame.height,
                    width: visionRect.width * viewFrame.width,
                    height: visionRect.height * viewFrame.height
                )
            }
            
            // Get pixel buffer dimensions
            let bufferWidth = CVPixelBufferGetWidth(pixelBuffer)
            let bufferHeight = CVPixelBufferGetHeight(pixelBuffer)
            
            // Calculate the actual displayed area within the preview layer
            let previewLayerFrame = previewLayer.frame
            let bufferAspectRatio = Double(bufferWidth) / Double(bufferHeight)
            let viewAspectRatio = Double(previewLayerFrame.width) / Double(previewLayerFrame.height)
            
            var displayedRect: CGRect
            
            if bufferAspectRatio > viewAspectRatio {
                // Buffer is wider than view - top and bottom are cropped
                let displayedHeight = previewLayerFrame.width / CGFloat(bufferAspectRatio)
                let yOffset = (previewLayerFrame.height - displayedHeight) / 2
                displayedRect = CGRect(
                    x: previewLayerFrame.origin.x,
                    y: previewLayerFrame.origin.y + yOffset,
                    width: previewLayerFrame.width,
                    height: displayedHeight
                )
            } else {
                // Buffer is taller than view - left and right are cropped
                let displayedWidth = previewLayerFrame.height * CGFloat(bufferAspectRatio)
                let xOffset = (previewLayerFrame.width - displayedWidth) / 2
                displayedRect = CGRect(
                    x: previewLayerFrame.origin.x + xOffset,
                    y: previewLayerFrame.origin.y,
                    width: displayedWidth,
                    height: previewLayerFrame.height
                )
            }
            
            // Convert Vision coordinates (normalized, bottom-left origin) to screen coordinates
            let x = displayedRect.origin.x + visionRect.origin.x * displayedRect.width
            let y = displayedRect.origin.y + (1 - visionRect.origin.y - visionRect.height) * displayedRect.height
            let width = visionRect.width * displayedRect.width
            let height = visionRect.height * displayedRect.height
            
            return CGRect(x: x, y: y, width: width, height: height)
        }
        
        private func evaluateComposition(observation: VNDetectedObjectObservation, pixelBuffer: CVPixelBuffer) {
            // Only evaluate composition if analysis is enabled
            guard parent.compositionManager.isEnabled else { 
                // Clear feedback when analysis is disabled
                DispatchQueue.main.async {
                    self.parent.feedbackMessage = nil
                    self.parent.feedbackIcon = nil
                    self.parent.showFeedback = false
                }
                return 
            }
            
            // Get the current preview layer frame size
            guard let previewLayer = previewLayer else { return }
            let frameSize = previewLayer.frame.size
            
            // Use the composition manager to evaluate the current composition
            let result = parent.compositionManager.evaluate(
                observation: observation,
                frameSize: frameSize,
                pixelBuffer: pixelBuffer
            )
            
            // Update UI with the composition result
            withAnimation(.bouncy) {
                parent.feedbackMessage = result.feedbackMessage
                parent.feedbackIcon = result.feedbackIcon
                parent.showFeedback = true
            }
        }
    }
}

struct FocusIndicatorView: View {
    let point: CGPoint
    @State private var scale: CGFloat = 1.0
    @State private var opacity: Double = 1.0
    
    var body: some View {
        Circle()
            .fill(.ultraThinMaterial)
            .frame(width: 50, height: 50)
            .scaleEffect(scale)
            .opacity(opacity)
            .position(point)
            .onAppear {
                // Initial scale animation
                withAnimation(.easeOut(duration: 0.2)) {
                    scale = 0.8
                }
                
                // Pulse animation
                withAnimation(.easeInOut(duration: 0.6).repeatCount(3, autoreverses: true)) {
                    opacity = 0.6
                }
                
                // Final fade out
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.8) {
                    withAnimation(.easeOut(duration: 0.3)) {
                        opacity = 0.0
                        scale = 0.6
                    }
                }
            }
    }
}

// MARK: - UIImage Extension for Orientation Correction

extension UIImage {
    func fixOrientation() -> UIImage {
        // If the image is already in the correct orientation, return it as is
        if imageOrientation == .up {
            return self
        }
        
        // Calculate the transform needed to fix the orientation
        var transform = CGAffineTransform.identity
        
        switch imageOrientation {
        case .down, .downMirrored:
            transform = transform.translatedBy(x: size.width, y: size.height)
            transform = transform.rotated(by: .pi)
        case .left, .leftMirrored:
            transform = transform.translatedBy(x: size.width, y: 0)
            transform = transform.rotated(by: .pi / 2)
        case .right, .rightMirrored:
            transform = transform.translatedBy(x: 0, y: size.height)
            transform = transform.rotated(by: -.pi / 2)
        default:
            break
        }
        
        switch imageOrientation {
        case .upMirrored, .downMirrored:
            transform = transform.translatedBy(x: size.width, y: 0)
            transform = transform.scaledBy(x: -1, y: 1)
        case .leftMirrored, .rightMirrored:
            transform = transform.translatedBy(x: size.height, y: 0)
            transform = transform.scaledBy(x: -1, y: 1)
        default:
            break
        }
        
        // Create a new context and apply the transform
        guard let cgImage = cgImage,
              let colorSpace = cgImage.colorSpace,
              let context = CGContext(data: nil,
                                     width: Int(size.width),
                                     height: Int(size.height),
                                     bitsPerComponent: cgImage.bitsPerComponent,
                                     bytesPerRow: 0,
                                     space: colorSpace,
                                     bitmapInfo: cgImage.bitmapInfo.rawValue) else {
            return self
        }
        
        context.concatenate(transform)
        
        switch imageOrientation {
        case .left, .leftMirrored, .right, .rightMirrored:
            context.draw(cgImage, in: CGRect(x: 0, y: 0, width: size.height, height: size.width))
        default:
            context.draw(cgImage, in: CGRect(x: 0, y: 0, width: size.width, height: size.height))
        }
        
        guard let newCGImage = context.makeImage() else {
            return self
        }
        
        return UIImage(cgImage: newCGImage)
    }
}
