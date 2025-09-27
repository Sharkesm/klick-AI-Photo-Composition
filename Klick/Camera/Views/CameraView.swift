import SwiftUI
import AVFoundation
import Vision

struct CameraView: View {
    @Binding var feedbackMessage: String?
    @Binding var feedbackIcon: String?
    @Binding var showFeedback: Bool
    @Binding var detectedFaceBoundingBox: CGRect?
    @Binding var faceDetectionConfidence: CGFloat
    @Binding var isFacialRecognitionEnabled: Bool
    @ObservedObject var compositionManager: CompositionManager
    @Binding var cameraQuality: CameraQuality
    @Binding var flashMode: FlashMode
    @Binding var zoomLevel: ZoomLevel
    @Binding var isSessionActive: Bool
    let onCameraReady: () -> Void
    let onPhotoCaptured: ((UIImage, UIImage?, Data?) -> Void)?
    
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
                faceDetectionConfidence: $faceDetectionConfidence,
                isFacialRecognitionEnabled: $isFacialRecognitionEnabled,
                compositionManager: compositionManager,
                cameraQuality: $cameraQuality,
                flashMode: $flashMode,
                zoomLevel: $zoomLevel,
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
}

struct CameraUIViewRepresentable: UIViewRepresentable {
    @Binding var feedbackMessage: String?
    @Binding var feedbackIcon: String?
    @Binding var showFeedback: Bool
    @Binding var detectedFaceBoundingBox: CGRect?
    @Binding var faceDetectionConfidence: CGFloat
    @Binding var isFacialRecognitionEnabled: Bool
    @ObservedObject var compositionManager: CompositionManager
    @Binding var cameraQuality: CameraQuality
    @Binding var flashMode: FlashMode
    @Binding var zoomLevel: ZoomLevel
    @Binding var isSessionActive: Bool
    let onCameraReady: () -> Void
    @Binding var focusPoint: CGPoint
    @Binding var showFocusIndicator: Bool
    let onPhotoCaptured: ((UIImage, UIImage?, Data?) -> Void)?
    
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
        session.sessionPreset = .photo
        
        print("📷 Camera quality set to: \(cameraQuality.displayName)")
        
        // Add camera input - select camera based on zoom level
        let deviceType = zoomLevel.deviceType
        guard let camera = AVCaptureDevice.default(deviceType, for: .video, position: .back) ?? 
              AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back),
              let input = try? AVCaptureDeviceInput(device: camera) else {
            DispatchQueue.main.async {
                print("❌ Failed to setup camera input for zoom level \(zoomLevel.displayName)")
            }
            return
        }
        
        print("✅ Camera input configured for zoom level \(zoomLevel.displayName) using device: \(camera.deviceType.rawValue)")
        session.addInput(input)
        
        // Store camera device reference for focus control
        context.coordinator.cameraDevice = camera
        context.coordinator.currentZoomLevel = zoomLevel
        
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
        
        // Update camera device if zoom level has changed
        if let session = context.coordinator.session,
           context.coordinator.currentZoomLevel != zoomLevel {
            updateCameraDevice(session: session, newZoomLevel: zoomLevel, forContext: context)
        }
    }
    
    private func updateCameraDevice(session: AVCaptureSession, newZoomLevel: ZoomLevel, forContext context: Context) {
        DispatchQueue.global(qos: .userInitiated).async {
            // Begin configuration transaction
            session.beginConfiguration()
            
            // Remove existing camera input
            if let currentInput = session.inputs.first as? AVCaptureDeviceInput {
                session.removeInput(currentInput)
            }
            
            // Add new camera input based on zoom level
            let deviceType = newZoomLevel.deviceType
            guard let newCamera = AVCaptureDevice.default(deviceType, for: .video, position: .back) ?? 
                  AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back),
                  let newInput = try? AVCaptureDeviceInput(device: newCamera) else {
                print("❌ Failed to create input for zoom level \(newZoomLevel.displayName)")
                session.commitConfiguration()
                return
            }
            
            // Add the new input
            if session.canAddInput(newInput) {
                session.addInput(newInput)
                
                // Update coordinator references
                context.coordinator.cameraDevice = newCamera
                context.coordinator.currentZoomLevel = newZoomLevel
                
                print("✅ Camera device updated to zoom level \(newZoomLevel.displayName) using device: \(newCamera.deviceType.rawValue)")
            } else {
                print("❌ Cannot add input for zoom level \(newZoomLevel.displayName)")
            }
            
            // Commit all changes atomically
            session.commitConfiguration()
            
            // Brief pause to allow session to stabilize
            Thread.sleep(forTimeInterval: 0.1)
            
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
        var onPhotoCaptured: ((UIImage, UIImage?, Data?) -> Void)?
        var currentZoomLevel: ZoomLevel = .wide
        
        // Storage for dual-capture in Pro mode
        private var capturedProcessedImage: UIImage?
        private var capturedRawImage: UIImage?
        private var capturedMetadata: Data?
        private var isExpectingDualCapture = false
    
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
            
            // Reset capture state for new photo
            resetCaptureState()
            
            // Configure photo settings based on available codecs
            switch parent.cameraQuality {
            case .standard:
                isExpectingDualCapture = false
                if photoOutput.availablePhotoCodecTypes.contains(.hevc) {
                    settings = AVCapturePhotoSettings(format: [AVVideoCodecKey: AVVideoCodecType.hevc])
                } else if photoOutput.availablePhotoCodecTypes.contains(.jpeg) {
                    settings = AVCapturePhotoSettings(format: [AVVideoCodecKey: AVVideoCodecType.jpeg])
                } else {
                    // Fallback to default settings
                    settings = AVCapturePhotoSettings()
                }
            case .pro:
                if let rawFormat = photoOutput.availableRawPhotoPixelFormatTypes.first {
                    // Pro mode with RAW+Processed - expect dual capture
                    isExpectingDualCapture = true
                    settings = AVCapturePhotoSettings(rawPixelFormatType: rawFormat, processedFormat: [AVVideoCodecKey: AVVideoCodecType.hevc])
                    print("📸 Pro mode: Expecting dual capture (RAW + Processed)")
                } else {
                    // Pro mode but no RAW available - single capture
                    isExpectingDualCapture = false
                    if photoOutput.availablePhotoCodecTypes.contains(.hevc) {
                        settings = AVCapturePhotoSettings(format: [AVVideoCodecKey: AVVideoCodecType.hevc])
                    } else {
                        settings = AVCapturePhotoSettings()
                    }
                    print("⚠️ Pro mode: RAW not available, using processed only")
                }
            }
            
            // Enable high resolution capture if available (modern API)
            // Note: photoQualityPrioritization is not supported when capturing RAW
            if !isExpectingDualCapture {
                // Only set quality prioritization for non-RAW captures
                // Check the maximum supported quality prioritization
                let maxQuality = photoOutput.maxPhotoQualityPrioritization
                let desiredQuality = AVCapturePhotoOutput.QualityPrioritization.quality
                
                if desiredQuality.rawValue <= maxQuality.rawValue {
                    settings.photoQualityPrioritization = desiredQuality
                    print("📸 Quality prioritization set to: \(desiredQuality.rawValue) (max: \(maxQuality.rawValue))")
                } else {
                    settings.photoQualityPrioritization = maxQuality
                    print("📸 Quality prioritization limited to max supported: \(maxQuality.rawValue)")
                }
            } else {
                print("📸 Skipping quality prioritization for RAW+Processed capture")
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
            
            if isExpectingDualCapture {
                print("📸 Pro mode capture initiated - expecting RAW + Processed")
            } else {
                print("📸 Standard capture initiated")
            }
        }
        
        // MARK: - AVCapturePhotoCaptureDelegate
        
        func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
            if let error = error {
                print("❌ Photo capture error: \(error.localizedDescription)")
                resetCaptureState()
                return
            }
            
            guard let imageData = photo.fileDataRepresentation(),
                  let image = UIImage(data: imageData) else {
                print("❌ Failed to convert photo to UIImage")
                resetCaptureState()
                return
            }
            
            let correctedImage = image.fixOrientation()
            
            // Handle dual capture for Pro mode
            if isExpectingDualCapture {
                if photo.isRawPhoto {
                    // This is the RAW image
                    capturedRawImage = correctedImage
                    print("✅ RAW image captured - Pure sensor data")
                } else {
                    // This is the processed image
                    capturedProcessedImage = correctedImage
                    
                    // Log metadata and create enhanced data from processed image
                    self.logCaptureMetadata(photo: photo)
                    capturedMetadata = self.createImageDataWithActualMetadata(image: correctedImage, capturePhoto: photo)
                    
                    print("✅ Processed image captured - With computational photography")
                }
                
                // Check if we have both images (or processed image is ready)
                if let processedImg = capturedProcessedImage {
                    let rawImg = capturedRawImage // May be nil if RAW processing failed
                    let metadata = capturedMetadata
                    
                    print("✅ Dual capture completed - Processed: ✓, RAW: \(rawImg != nil ? "✓" : "✗")")
                    
                    // Send callback with both images
                    DispatchQueue.main.async {
                        self.onPhotoCaptured?(processedImg, rawImg, metadata)
                    }
                    
                    // Reset for next capture
                    resetCaptureState()
                }
            } else {
                // Standard single capture
                self.logCaptureMetadata(photo: photo)
                let enhancedImageData = self.createImageDataWithActualMetadata(image: correctedImage, capturePhoto: photo)
                
                print("✅ Standard capture completed")
                
                DispatchQueue.main.async {
                    self.onPhotoCaptured?(correctedImage, nil, enhancedImageData)
                }
            }
        }
        
        // MARK: - Capture State Management
        
        private func resetCaptureState() {
            capturedProcessedImage = nil
            capturedRawImage = nil
            capturedMetadata = nil
            isExpectingDualCapture = false
        }
        
        // MARK: - Enhanced Metadata Creation
        
        private func createImageDataWithActualMetadata(image: UIImage, capturePhoto: AVCapturePhoto) -> Data? {
            guard let cgImage = image.cgImage else {
                return image.jpegData(compressionQuality: 0.9)
            }
            
            // Get actual metadata from captured photo
            let photoMetadata = capturePhoto.metadata
            
            // Create mutable data for the image
            let mutableData = NSMutableData()
            
            // Create image destination with JPEG format
            guard let destination = CGImageDestinationCreateWithData(mutableData, UTType.jpeg.identifier as CFString, 1, nil) else {
                return image.jpegData(compressionQuality: 0.9)
            }
            
            // Use actual captured metadata instead of hardcoded values
            CGImageDestinationAddImage(destination, cgImage, photoMetadata as CFDictionary)
            
            // Finalize the image creation
            if CGImageDestinationFinalize(destination) {
                print("✅ Image created with actual capture metadata")
                return mutableData as Data
            } else {
                // Fallback to standard JPEG creation
                print("⚠️ Failed to create image with metadata, using standard JPEG")
                return image.jpegData(compressionQuality: 0.9)
            }
        }
        
        // MARK: - Enhanced Metadata Logging
        
        private func logCaptureMetadata(photo: AVCapturePhoto) {
            // Log available metadata from the capture
            let metadata = photo.metadata
            print("📊 Capture Metadata Available:")
                
            // Log EXIF data
            if let exifDict = metadata[kCGImagePropertyExifDictionary as String] as? [String: Any] {
                if let iso = exifDict[kCGImagePropertyExifISOSpeedRatings as String] as? [Int] {
                    print("   📷 ISO: \(iso)")
                }
                if let exposureTime = exifDict[kCGImagePropertyExifExposureTime as String] as? Double {
                    print("   ⏱️ Exposure Time: \(exposureTime) sec")
                }
                if let focalLength = exifDict[kCGImagePropertyExifFocalLength as String] as? Double {
                    print("   🔍 Focal Length: \(focalLength)mm")
                }
                if let flash = exifDict[kCGImagePropertyExifFlash as String] as? Int {
                    print("   ⚡ Flash: \(flash)")
                }
            }
            
            // Log TIFF data
            if let tiffDict = metadata[kCGImagePropertyTIFFDictionary as String] as? [String: Any] {
                if let make = tiffDict[kCGImagePropertyTIFFMake as String] as? String {
                    print("   📱 Camera Make: \(make)")
                }
                if let model = tiffDict[kCGImagePropertyTIFFModel as String] as? String {
                    print("   📱 Camera Model: \(model)")
                }
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
                    self.parent.faceDetectionConfidence = 0.0
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
                            self.parent.faceDetectionConfidence = CGFloat(selectedFace.confidence)
                            self.evaluateComposition(observation: selectedFace, pixelBuffer: pixelBuffer)
                        } else {
                            // Try human detection if no face found
                            self.parent.detectedFaceBoundingBox = nil
                            self.parent.faceDetectionConfidence = 0.0
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
                            self.parent.faceDetectionConfidence = 0.0
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
