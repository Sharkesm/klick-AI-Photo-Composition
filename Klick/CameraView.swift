import SwiftUI
import AVFoundation
import Vision

struct CameraView: UIViewRepresentable {
    @Binding var feedbackMessage: String?
    @Binding var feedbackIcon: String?
    @Binding var showFeedback: Bool
    @Binding var detectedFaceBoundingBox: CGRect?
    @Binding var isFacialRecognitionEnabled: Bool
    @ObservedObject var compositionManager: CompositionManager
    let onCameraReady: () -> Void
    
    func makeUIView(context: Context) -> UIView {
        let view = UIView()
        view.backgroundColor = .black
        
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
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, AVCaptureVideoDataOutputSampleBufferDelegate {
        private var frameCount = 0
        private var isAppInBackground = false
        
        var parent: CameraView
        var session: AVCaptureSession?
        var previewLayer: AVCaptureVideoPreviewLayer?
        var viewFrame: CGRect = .zero
        var cameraStartTime = CACurrentMediaTime()
        var cameraReady = false
    
        init(_ parent: CameraView) {
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
        
        deinit {
            NotificationCenter.default.removeObserver(self)
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
                            // Use the first detected face
                            let face = results[0]
                            
                            // Convert Vision coordinates to screen coordinates with improved conversion
                            let convertedRect = self.convertVisionToScreenCoordinates(
                                visionRect: face.boundingBox,
                                pixelBuffer: pixelBuffer
                            )
                            
                            self.parent.detectedFaceBoundingBox = convertedRect
                            self.evaluateComposition(observation: face, pixelBuffer: pixelBuffer)
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
