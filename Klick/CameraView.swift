import SwiftUI
import AVFoundation
import Vision

struct CameraView: UIViewRepresentable {
    @Binding var isGridVisible: Bool
    @Binding var feedbackMessage: String?
    @Binding var showFeedback: Bool
    @Binding var detectedFaceBoundingBox: CGRect?
    
    func makeUIView(context: Context) -> UIView {
        let view = UIView()
        view.backgroundColor = .black
        
        // Set up camera session
        let session = AVCaptureSession()
        session.sessionPreset = .photo
        
        // Add camera input
        guard let camera = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back),
              let input = try? AVCaptureDeviceInput(device: camera) else {
            return view
        }
        
        session.addInput(input)
        
        // Add video output for processing
        let videoOutput = AVCaptureVideoDataOutput()
        videoOutput.setSampleBufferDelegate(context.coordinator, queue: DispatchQueue.global(qos: .userInitiated))
        session.addOutput(videoOutput)
        
        // Create preview layer
        let previewLayer = AVCaptureVideoPreviewLayer(session: session)
        previewLayer.videoGravity = .resizeAspectFill
        previewLayer.frame = view.bounds
        view.layer.addSublayer(previewLayer)
        
        // Store references
        context.coordinator.session = session
        context.coordinator.previewLayer = previewLayer
        
        // Start session
        DispatchQueue.global(qos: .background).async {
            session.startRunning()
        }
        
        return view
    }
    
    func updateUIView(_ uiView: UIView, context: Context) {
        context.coordinator.previewLayer?.frame = uiView.bounds
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, AVCaptureVideoDataOutputSampleBufferDelegate {
        var parent: CameraView
        var session: AVCaptureSession?
        var previewLayer: AVCaptureVideoPreviewLayer?
        private var frameCount = 0
        
        init(_ parent: CameraView) {
            self.parent = parent
        }
        
        func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
            // Process every 3rd frame to reduce CPU load
            frameCount += 1
            guard frameCount % 3 == 0 else { return }
            
            guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }
            
            // Perform subject detection
            performSubjectDetection(pixelBuffer: pixelBuffer)
        }
        
        private func performSubjectDetection(pixelBuffer: CVPixelBuffer) {
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
                        self.evaluateRuleOfThirds(face: face)
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
        
        private func performHumanDetection(pixelBuffer: CVPixelBuffer) {
            let humanRequest = VNDetectHumanRectanglesRequest { [weak self] request, error in
                guard let self = self else { return }
                
                DispatchQueue.main.async {
                    if let results = request.results as? [VNHumanObservation], !results.isEmpty {
                        // Use the first detected human
                        let human = results[0]
                        self.evaluateRuleOfThirds(human: human)
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
        
        private func evaluateRuleOfThirds(face: VNFaceObservation? = nil, human: VNHumanObservation? = nil) {
            guard let observation = face ?? human else { return }
            
            // Get the center point of the detected subject
            let centerX = observation.boundingBox.midX
            let centerY = observation.boundingBox.midY
            
            // Calculate Rule of Thirds intersection points
            let thirdX1 = 0.33
            let thirdX2 = 0.67
            let thirdY1 = 0.33
            let thirdY2 = 0.67
            
            // Check if subject is near any intersection point (within 10% tolerance)
            let tolerance: Double = 0.1
            
            let isNearThirdX1 = abs(centerX - thirdX1) < tolerance
            let isNearThirdX2 = abs(centerX - thirdX2) < tolerance
            let isNearThirdY1 = abs(centerY - thirdY1) < tolerance
            let isNearThirdY2 = abs(centerY - thirdY2) < tolerance
            
            if (isNearThirdX1 || isNearThirdX2) && (isNearThirdY1 || isNearThirdY2) {
                parent.feedbackMessage = "✅ Nice framing!"
                parent.showFeedback = true
            } else {
                parent.feedbackMessage = "⚠️ Try placing your subject on a third"
                parent.showFeedback = true
            }
        }
    }
} 