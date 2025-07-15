import SwiftUI
import Vision
import CoreImage
import Accelerate

// MARK: - Composition Service Protocol

/// Protocol for composition detection services
protocol CompositionService {
    /// The name of the composition technique
    var name: String { get }
    
    /// Evaluate composition for a given subject observation
    /// - Parameters:
    ///   - observation: The detected subject (face or human)
    ///   - frameSize: The size of the camera frame
    ///   - pixelBuffer: The current frame's pixel buffer for advanced analysis
    /// - Returns: Composition result with feedback and overlay data
    func evaluate(observation: VNDetectedObjectObservation, frameSize: CGSize, pixelBuffer: CVPixelBuffer?) -> CompositionResult
}

// MARK: - Composition Result Types

/// Result of composition evaluation
struct CompositionResult {
    let isWellComposed: Bool
    let feedbackMessage: String
    let overlayElements: [OverlayElement]
    let score: Double // 0.0 to 1.0
    let compositionType: CompositionType
}

/// Types of composition techniques
enum CompositionType: String, CaseIterable {
    case ruleOfThirds = "Rule of Thirds"
    case centerFraming = "Center Framing"
    case symmetry = "Symmetry"
    
    var icon: String {
        switch self {
        case .ruleOfThirds: return "squareshape.split.2x2.dotted"
        case .centerFraming: return "plus.viewfinder"
        case .symmetry: return "rectangle.split.2x1"
        }
    }
}

/// Overlay elements for visual guidance
struct OverlayElement {
    let type: OverlayType
    let path: Path
    let color: Color
    let opacity: Double
    let lineWidth: CGFloat
}

enum OverlayType {
    case grid
    case centerCrosshair
    case symmetryLine
    case guideLine
}

// MARK: - Center Framing Service

class CenterFramingService: CompositionService {
    let name = "Center Framing"
    private let centerTolerance: Double = 0.1 // ±10% of frame size
    
    func evaluate(observation: VNDetectedObjectObservation, frameSize: CGSize, pixelBuffer: CVPixelBuffer?) -> CompositionResult {
        let subjectCenter = CGPoint(
            x: observation.boundingBox.midX,
            y: observation.boundingBox.midY
        )
        
        let frameCenter = CGPoint(x: 0.5, y: 0.5)
        
        // Calculate distance from center (normalized coordinates)
        let distanceFromCenterX = abs(subjectCenter.x - frameCenter.x)
        let distanceFromCenterY = abs(subjectCenter.y - frameCenter.y)
        
        // Check if subject is centered within tolerance
        let isCenteredX = distanceFromCenterX < centerTolerance
        let isCenteredY = distanceFromCenterY < centerTolerance
        let isCentered = isCenteredX && isCenteredY
        
        // Calculate score based on distance from center
        let maxDistance = sqrt(0.5 * 0.5 + 0.5 * 0.5) // Max distance from center
        let currentDistance = sqrt(distanceFromCenterX * distanceFromCenterX + distanceFromCenterY * distanceFromCenterY)
        let score = max(0, 1 - (currentDistance / maxDistance))
        
        var feedbackMessage: String
        var overlayElements: [OverlayElement] = []
        
        // Create center crosshair overlay
        overlayElements.append(createCenterCrosshair(frameSize: frameSize))
        
        // Check for symmetry if centered
        if isCentered, let pixelBuffer = pixelBuffer {
            let symmetryScore = calculateSymmetryScore(pixelBuffer: pixelBuffer)
            if symmetryScore > 0.8 {
                feedbackMessage = "✅ Balanced symmetry achieved!"
                overlayElements.append(createSymmetryIndicator(frameSize: frameSize, isSymmetrical: true))
            } else {
                feedbackMessage = "⚠️ Try aligning your shot with symmetrical elements"
                overlayElements.append(createSymmetryIndicator(frameSize: frameSize, isSymmetrical: false))
            }
        } else {
            feedbackMessage = "⚠️ Try moving subject toward the center"
        }
        
        return CompositionResult(
            isWellComposed: isCentered,
            feedbackMessage: feedbackMessage,
            overlayElements: overlayElements,
            score: score,
            compositionType: .centerFraming
        )
    }
    
    func createCenterCrosshair(frameSize: CGSize) -> OverlayElement {
        var path = Path()
        let centerX = frameSize.width / 2
        let centerY = frameSize.height / 2
        let crosshairSize: CGFloat = 30
        
        // Horizontal line
        path.move(to: CGPoint(x: centerX - crosshairSize, y: centerY))
        path.addLine(to: CGPoint(x: centerX + crosshairSize, y: centerY))
        
        // Vertical line
        path.move(to: CGPoint(x: centerX, y: centerY - crosshairSize))
        path.addLine(to: CGPoint(x: centerX, y: centerY + crosshairSize))
        
        return OverlayElement(
            type: .centerCrosshair,
            path: path,
            color: .white,
            opacity: 0.8,
            lineWidth: 2
        )
    }
    
    private func createSymmetryIndicator(frameSize: CGSize, isSymmetrical: Bool) -> OverlayElement {
        var path = Path()
        let centerX = frameSize.width / 2
        let height = frameSize.height
        
        // Vertical symmetry line
        path.move(to: CGPoint(x: centerX, y: 0))
        path.addLine(to: CGPoint(x: centerX, y: height))
        
        return OverlayElement(
            type: .symmetryLine,
            path: path,
            color: isSymmetrical ? .green : .yellow,
            opacity: 0.4,
            lineWidth: 1
        )
    }
    
    private func calculateSymmetryScore(pixelBuffer: CVPixelBuffer) -> Double {
        // Downscale for performance as specified
        guard let downsampledImage = downsamplePixelBuffer(pixelBuffer, targetSize: CGSize(width: 128, height: 128)) else {
            return 0.0
        }
        
        return calculateVerticalSymmetry(pixelBuffer: downsampledImage)
    }
    
    private func downsamplePixelBuffer(_ pixelBuffer: CVPixelBuffer, targetSize: CGSize) -> CVPixelBuffer? {
        let ciImage = CIImage(cvPixelBuffer: pixelBuffer)
        let context = CIContext()
        
        // Calculate scale to fit target size
        let originalSize = ciImage.extent.size
        let scaleX = targetSize.width / originalSize.width
        let scaleY = targetSize.height / originalSize.height
        let scale = min(scaleX, scaleY)
        
        // Apply transform
        let transform = CGAffineTransform(scaleX: scale, y: scale)
        let scaledImage = ciImage.transformed(by: transform)
        
        // Create pixel buffer for result
        var outputBuffer: CVPixelBuffer?
        let status = CVPixelBufferCreate(
            kCFAllocatorDefault,
            Int(targetSize.width),
            Int(targetSize.height),
            kCVPixelFormatType_32BGRA,
            nil,
            &outputBuffer
        )
        
        guard status == kCVReturnSuccess, let buffer = outputBuffer else {
            return nil
        }
        
        context.render(scaledImage, to: buffer)
        return buffer
    }
    
    private func calculateVerticalSymmetry(pixelBuffer: CVPixelBuffer) -> Double {
        CVPixelBufferLockBaseAddress(pixelBuffer, .readOnly)
        defer { CVPixelBufferUnlockBaseAddress(pixelBuffer, .readOnly) }
        
        guard let baseAddress = CVPixelBufferGetBaseAddress(pixelBuffer) else {
            return 0.0
        }
        
        let width = CVPixelBufferGetWidth(pixelBuffer)
        let height = CVPixelBufferGetHeight(pixelBuffer)
        let bytesPerRow = CVPixelBufferGetBytesPerRow(pixelBuffer)
        
        let data = baseAddress.assumingMemoryBound(to: UInt8.self)
        
        var totalDifference: Double = 0
        var totalPixels = 0
        
        let midWidth = width / 2
        
        for y in 0..<height {
            let rowStart = y * bytesPerRow
            
            for x in 0..<midWidth {
                let leftPixelIndex = rowStart + x * 4
                let rightPixelIndex = rowStart + (width - 1 - x) * 4
                
                // Compare RGB values (skip alpha)
                for channel in 0..<3 {
                    let leftValue = Double(data[leftPixelIndex + channel])
                    let rightValue = Double(data[rightPixelIndex + channel])
                    totalDifference += abs(leftValue - rightValue)
                }
                
                totalPixels += 3 // RGB channels
            }
        }
        
        if totalPixels == 0 { return 0.0 }
        
        // Calculate similarity score (0.0 to 1.0)
        let avgDifference = totalDifference / Double(totalPixels)
        let maxDifference = 255.0 // Max possible difference for 8-bit values
        let similarity = 1.0 - (avgDifference / maxDifference)
        
        return max(0.0, min(1.0, similarity))
    }
}

// MARK: - Rule of Thirds Service (Refactored)

class RuleOfThirdsService: CompositionService {
    let name = "Rule of Thirds"
    private let intersectionTolerance: Double = 0.1
    
    func evaluate(observation: VNDetectedObjectObservation, frameSize: CGSize, pixelBuffer: CVPixelBuffer?) -> CompositionResult {
        let centerX = observation.boundingBox.midX
        let centerY = observation.boundingBox.midY
        
        // Calculate Rule of Thirds intersection points
        let thirdX1 = 0.33
        let thirdX2 = 0.67
        let thirdY1 = 0.33
        let thirdY2 = 0.67
        
        // Check if subject is near any intersection point
        let isNearThirdX1 = abs(centerX - thirdX1) < intersectionTolerance
        let isNearThirdX2 = abs(centerX - thirdX2) < intersectionTolerance
        let isNearThirdY1 = abs(centerY - thirdY1) < intersectionTolerance
        let isNearThirdY2 = abs(centerY - thirdY2) < intersectionTolerance
        
        let isWellComposed = (isNearThirdX1 || isNearThirdX2) && (isNearThirdY1 || isNearThirdY2)
        
        // Calculate score based on distance to nearest intersection
        let score = calculateRuleOfThirdsScore(centerX: centerX, centerY: centerY)
        
        let feedbackMessage = isWellComposed ? "✅ Nice framing!" : "⚠️ Try placing your subject on a third"
        
        // Create grid overlay
        let overlayElements = [createGridOverlay(frameSize: frameSize)]
        
        return CompositionResult(
            isWellComposed: isWellComposed,
            feedbackMessage: feedbackMessage,
            overlayElements: overlayElements,
            score: score,
            compositionType: .ruleOfThirds
        )
    }
    
    private func calculateRuleOfThirdsScore(centerX: Double, centerY: Double) -> Double {
        let intersections = [
            (0.33, 0.33), (0.33, 0.67),
            (0.67, 0.33), (0.67, 0.67)
        ]
        
        let distances = intersections.map { intersection in
            let dx = centerX - intersection.0
            let dy = centerY - intersection.1
            return sqrt(dx * dx + dy * dy)
        }
        
        let minDistance = distances.min() ?? 1.0
        let maxPossibleDistance = sqrt(0.5 * 0.5 + 0.5 * 0.5)
        
        return max(0, 1 - (minDistance / maxPossibleDistance))
    }
    
    func createGridOverlay(frameSize: CGSize) -> OverlayElement {
        var path = Path()
        let width = frameSize.width
        let height = frameSize.height
        
        // Calculate third positions
        let thirdX1 = width / 3
        let thirdX2 = width * 2 / 3
        let thirdY1 = height / 3
        let thirdY2 = height * 2 / 3
        
        // Vertical lines
        path.move(to: CGPoint(x: thirdX1, y: 0))
        path.addLine(to: CGPoint(x: thirdX1, y: height))
        
        path.move(to: CGPoint(x: thirdX2, y: 0))
        path.addLine(to: CGPoint(x: thirdX2, y: height))
        
        // Horizontal lines
        path.move(to: CGPoint(x: 0, y: thirdY1))
        path.addLine(to: CGPoint(x: width, y: thirdY1))
        
        path.move(to: CGPoint(x: 0, y: thirdY2))
        path.addLine(to: CGPoint(x: width, y: thirdY2))
        
        return OverlayElement(
            type: .grid,
            path: path,
            color: .white,
            opacity: 0.6,
            lineWidth: 1
        )
    }
} 