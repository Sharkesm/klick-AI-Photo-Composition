import SwiftUI
import AVFoundation
import Vision

struct CameraView: UIViewRepresentable {
    @Binding var isGridVisible: Bool
    @Binding var feedbackMessage: String?
    @Binding var showFeedback: Bool
    @Binding var detectedFaceBoundingBox: CGRect?
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
        context.coordinator.previewLayer?.frame = uiView.bounds
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, AVCaptureVideoDataOutputSampleBufferDelegate {
        private var frameCount = 0
        
        var parent: CameraView
        var session: AVCaptureSession?
        var previewLayer: AVCaptureVideoPreviewLayer?
        var cameraStartTime = CACurrentMediaTime()
        var cameraReady = false
    
        init(_ parent: CameraView) {
            self.parent = parent
        }
        
        func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
            // Lazy vision processing - only start after camera is stable
            guard cameraReady else { return }
            
            // Only process after camera has been running for at least 1 second
            let currentTime = CACurrentMediaTime()
            guard currentTime - cameraStartTime > 1.0 else { return }
            
            // Process every 3rd frame to reduce CPU load
            frameCount += 1
            guard frameCount % 3 == 0 else { return }
            
            guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }
            
            // Perform subject detection
            performSubjectDetection(pixelBuffer: pixelBuffer)
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
                            // Convert Vision coordinates to screen coordinates using preview layer
                            if let previewLayer = self.previewLayer {
                                let convertedRect = previewLayer.layerRectConverted(fromMetadataOutputRect: face.boundingBox)
                                self.parent.detectedFaceBoundingBox = convertedRect
                            } else {
                                self.parent.detectedFaceBoundingBox = face.boundingBox
                            }
                            self.evaluateComposition(observation: face, pixelBuffer: pixelBuffer)
                        } else {
                            // Try human detection if no face found
                            self.parent.detectedFaceBoundingBox = nil
                            self.performHumanDetection(pixelBuffer: pixelBuffer)
                        }
                    }
                }
                
                let handler = VNImageRequestHandler(cvPixelBuffer: pixelBuffer, options: [:])
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
                            self.parent.showFeedback = false
                            self.parent.detectedFaceBoundingBox = nil
                        }
                    }
                }
                
                let handler = VNImageRequestHandler(cvPixelBuffer: pixelBuffer, options: [:])
                try? handler.perform([humanRequest])
            }
        }
        
        private func evaluateComposition(observation: VNDetectedObjectObservation, pixelBuffer: CVPixelBuffer) {
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
                parent.showFeedback = true
            }
        }
    }
} 
