import SwiftUI
import Vision
import CoreImage
import Accelerate

// MARK: - Enhanced Composition Service Protocol

/// Protocol for composition detection services
protocol CompositionService {
    /// The name of the composition technique
    var name: String { get }
    
    /// Evaluate composition for a given subject observation
    /// - Parameters:
    ///   - observation: The detected subject (face or human)
    ///   - frameSize: The size of the camera frame
    ///   - pixelBuffer: The current frame's pixel buffer for advanced analysis
    /// - Returns: Enhanced composition result with context and suggestions
    func evaluate(observation: VNDetectedObjectObservation, frameSize: CGSize, pixelBuffer: CVPixelBuffer?) -> EnhancedCompositionResult
}

// MARK: - Composition Feedback Model

/// Structured feedback model for live suggestions
struct CompositionFeedback {
    let label: String           // SF Symbol name
    let suggestion: String      // Text for suggestion
    let compositionLevel: Int   // 1-6 grading (1 = best)
    let color: Color           // Icon color
    
    /// Level descriptions for reference:
    /// - Level 1: Perfect composition ✅ (green)
    /// - Level 2: Good composition ✅ (blue)
    /// - Level 3: Almost there / Minor adjustment (yellow)
    /// - Level 4: Needs directional adjustment (orange)
    /// - Level 5: Needs distance/framing adjustment (orange)
    /// - Level 6: Critical issue (red)
}

// MARK: - Enhanced Result Types

/// Enhanced result of composition evaluation with context awareness
struct EnhancedCompositionResult {
    let composition: String // composition type identifier
    let score: Double // 0.0 to 1.0 confidence score
    let status: CompositionStatus // Perfect, Good, Needs Adjustment
    let suggestion: String // Actionable user guidance
    let context: CompositionContext // Subject and scene analysis
    let overlayElements: [OverlayElement] // Visual guidance elements
    let feedbackIcon: String // SF Symbol for feedback UI
    let feedback: CompositionFeedback // Structured feedback model
    
    // Legacy compatibility
    var isWellComposed: Bool {
        status == .perfect || status == .good
    }
    
    var feedbackMessage: String {
        suggestion
    }
    
    var compositionType: CompositionType {
        CompositionType(rawValue: composition) ?? .ruleOfThirds
    }
}

/// Composition quality status
enum CompositionStatus: String, CaseIterable {
    case perfect = "Perfect"
    case good = "Good" 
    case needsAdjustment = "Needs Adjustment"
    
    var icon: String {
        switch self {
        case .perfect: return "star.fill"
        case .good: return "hand.thumbsup.fill"
        case .needsAdjustment: return "arrow.trianglehead.2.clockwise"
        }
    }
    
    var iconColor: Color {
        switch self {
        case .perfect: return .green
        case .good: return .blue
        case .needsAdjustment: return .orange
        }
    }
}

/// Context information about subject and scene
struct CompositionContext {
    let subjectSize: SubjectSize // small, medium, large
    let subjectOffsetX: Double // -1.0 to 1.0 from center
    let subjectOffsetY: Double // -1.0 to 1.0 from center
    let multipleSubjects: Bool
    let edgeProximity: EdgeProximity // safety analysis
    let headroom: HeadroomAnalysis // portrait-specific analysis
}

enum SubjectSize: String {
    case small = "small"     // < 25% of frame
    case medium = "medium"   // 25-45% of frame  
    case large = "large"     // > 45% of frame
}

struct EdgeProximity {
    let tooCloseToEdge: Bool
    let dangerousEdges: [String] // ["top", "left", etc.]
    let safetyMargin: Double // 0.0 to 1.0
}

struct HeadroomAnalysis {
    let excessiveHeadroom: Bool
    let cutoffLimbs: Bool
    let portraitOptimal: Bool
}

/// Types of composition techniques
enum CompositionType: String, CaseIterable {
    case ruleOfThirds = "rule_of_thirds"
    case centerFraming = "center_framing"
    case symmetry = "symmetry"
    
    var displayName: String {
        switch self {
        case .ruleOfThirds: return "Rule of Thirds"
        case .centerFraming: return "Center Framing"
        case .symmetry: return "Symmetry"
        }
    }
    
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
    case safetyZone
}

// MARK: - Context Analysis Helper

class CompositionContextAnalyzer {
    static func analyzeContext(observation: VNDetectedObjectObservation, frameSize: CGSize) -> CompositionContext {
        let boundingBox = observation.boundingBox
        
        // Calculate subject size - relaxed thresholds for distant subjects
        let subjectArea = boundingBox.width * boundingBox.height
        let subjectSize: SubjectSize
        if subjectArea < 0.15 {  // Lowered from 0.25 to accommodate distant subjects
            subjectSize = .small
        } else if subjectArea < 0.35 {  // Lowered from 0.45 to be more inclusive
            subjectSize = .medium
        } else {
            subjectSize = .large
        }
        
        // Calculate offsets from center (-1.0 to 1.0)
        let centerX = boundingBox.midX
        let centerY = boundingBox.midY
        let offsetX = (centerX - 0.5) * 2.0 // Normalize to -1.0 to 1.0
        let offsetY = (centerY - 0.5) * 2.0
        
        // Edge proximity analysis - more lenient for distant subjects
        let edgeMargin = 0.03 // Reduced from 0.05 to 3% safety margin
        let tooCloseToEdge = boundingBox.minX < edgeMargin || 
                            boundingBox.maxX > (1.0 - edgeMargin) ||
                            boundingBox.minY < edgeMargin || 
                            boundingBox.maxY > (1.0 - edgeMargin)
        
        var dangerousEdges: [String] = []
        if boundingBox.minX < edgeMargin { dangerousEdges.append("left") }
        if boundingBox.maxX > (1.0 - edgeMargin) { dangerousEdges.append("right") }
        if boundingBox.minY < edgeMargin { dangerousEdges.append("bottom") }
        if boundingBox.maxY > (1.0 - edgeMargin) { dangerousEdges.append("top") }
        
        let safetyMargin = min(
            min(boundingBox.minX, 1.0 - boundingBox.maxX),
            min(boundingBox.minY, 1.0 - boundingBox.maxY)
        )
        
        let edgeProximity = EdgeProximity(
            tooCloseToEdge: tooCloseToEdge,
            dangerousEdges: dangerousEdges,
            safetyMargin: safetyMargin
        )
        
        // Headroom analysis (portrait-specific) - more lenient
        let headroomRatio = 1.0 - boundingBox.maxY // Space above subject
        let excessiveHeadroom = headroomRatio > 0.4 // Increased from 0.3 to 40% headroom
        let cutoffLimbs = boundingBox.minY < 0.01 // Very close to bottom edge (1% instead of 2%)
        let portraitOptimal = headroomRatio > 0.05 && headroomRatio < 0.4 && !cutoffLimbs // More lenient range
        
        let headroom = HeadroomAnalysis(
            excessiveHeadroom: excessiveHeadroom,
            cutoffLimbs: cutoffLimbs,
            portraitOptimal: portraitOptimal
        )
        
        return CompositionContext(
            subjectSize: subjectSize,
            subjectOffsetX: offsetX,
            subjectOffsetY: offsetY,
            multipleSubjects: false, // TODO: Implement multi-subject detection
            edgeProximity: edgeProximity,
            headroom: headroom
        )
    }
}

// MARK: - Background State Monitor

class BackgroundStateMonitor {
    static let shared = BackgroundStateMonitor()
    
    @Published var isInBackground = false
    
    private init() {
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
        isInBackground = true
    }
    
    @objc private func appWillEnterForeground() {
        isInBackground = false
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
}

// MARK: - Center Framing Service

class CenterFramingService: CompositionService {
    let name = "Center Framing"
    private let centerTolerance: Double = 0.12  // More strict tolerance for proper centering
    
    func evaluate(observation: VNDetectedObjectObservation, frameSize: CGSize, pixelBuffer: CVPixelBuffer?) -> EnhancedCompositionResult {
        let context = CompositionContextAnalyzer.analyzeContext(observation: observation, frameSize: frameSize)
        
        let subjectCenter = CGPoint(
            x: observation.boundingBox.midX,
            y: observation.boundingBox.midY
        )
        
        // Use simple geometric center for all subjects - no complexity
        let frameCenter = CGPoint(x: 0.5, y: 0.5)
        
        // Calculate distance from center (normalized coordinates)
        let distanceFromCenterX = subjectCenter.x - frameCenter.x
        let distanceFromCenterY = subjectCenter.y - frameCenter.y
        let totalDistance = sqrt(distanceFromCenterX * distanceFromCenterX + distanceFromCenterY * distanceFromCenterY)
        
        // Simple evaluation - is it centered or not?
        let isCentered = totalDistance <= centerTolerance
        
        // Calculate score based on distance from center
        let maxDistance = sqrt(0.5 * 0.5 + 0.5 * 0.5)
        let baseScore = max(0, 1 - (totalDistance / maxDistance))
        
        // Optional symmetry analysis for bonus scoring (only if centered)
        var finalScore = baseScore
        var symmetryScore: Double = 0.0
        
        if let pixelBuffer = pixelBuffer, isCentered {
            symmetryScore = calculateSymmetryScore(pixelBuffer: pixelBuffer)
            finalScore = (baseScore * 0.8) + (symmetryScore * 0.2) // Light symmetry bonus
        }
        
        // Generate simple, clear feedback
        let (status, suggestion) = generateSimpleCenterFramingFeedback(
            isCentered: isCentered,
            symmetryScore: symmetryScore,
            distanceFromCenterX: distanceFromCenterX,
            distanceFromCenterY: distanceFromCenterY,
            context: context
        )
        
        // Create simple overlays (don't duplicate basic overlays - they're handled separately)
        var overlayElements: [OverlayElement] = []
        
        // Add symmetry indicator if well-centered
        if isCentered && symmetryScore > 0.7 {
            overlayElements.append(createSymmetryIndicator(
                frameSize: frameSize, 
                isSymmetrical: true
            ))
        }
        
        // Add safety zone only if actually too close to edge
        if context.edgeProximity.tooCloseToEdge {
            overlayElements.append(createSafetyZoneOverlay(frameSize: frameSize))
        }
        
        // Get appropriate icon for the suggestion
        let icon = getCenterFramingIcon(for: suggestion, status: status)
        
        // Create structured feedback model
        let feedback = getCenterFramingFeedback(for: suggestion, status: status, icon: icon)
        
        return EnhancedCompositionResult(
            composition: CompositionType.centerFraming.rawValue,
            score: finalScore,
            status: status,
            suggestion: suggestion,
            context: context,
            overlayElements: overlayElements,
            feedbackIcon: icon,
            feedback: feedback
        )
    }
    
    private func generateSimpleCenterFramingFeedback(
        isCentered: Bool,
        symmetryScore: Double,
        distanceFromCenterX: Double,
        distanceFromCenterY: Double,
        context: CompositionContext
    ) -> (CompositionStatus, String) {
        
        // Handle edge proximity first (only if truly dangerous)
        if context.edgeProximity.safetyMargin < 0.03 {
            return (.needsAdjustment, "Step back")
        }
        
        // Handle severe headroom issues
        if context.headroom.excessiveHeadroom && context.headroom.cutoffLimbs {
            return (.needsAdjustment, "Get closer")
        }
        
        // Simple centering feedback
        if isCentered {
            if symmetryScore > 0.8 {
                return (.perfect, "Perfect!")
            } else {
                return (.good, "Nice center!")
            }
        } else {
            // Provide simple directional guidance
            let suggestion = generateSimpleDirection(
                distanceFromCenterX: distanceFromCenterX,
                distanceFromCenterY: distanceFromCenterY
            )
            return (.needsAdjustment, suggestion)
        }
    }
    
    /// Generate simple, clear directional guidance from USER'S PERSPECTIVE
    private func generateSimpleDirection(
        distanceFromCenterX: Double,
        distanceFromCenterY: Double
    ) -> String {
        
        let horizontalMagnitude = abs(distanceFromCenterX)
        let verticalMagnitude = abs(distanceFromCenterY)
        
        let horizontalDirection = distanceFromCenterX > 0 ? "left" : "right"
        let verticalDirection = distanceFromCenterY > 0 ? "up" : "down"
        
        // Use stricter thresholds for directional guidance
        let directionThreshold = 0.05 // 5% threshold for direction guidance
        
        // Simple, clear guidance
        if horizontalMagnitude > directionThreshold && verticalMagnitude > directionThreshold {
            return "Go \(verticalDirection)-\(horizontalDirection)"
        } else if horizontalMagnitude > directionThreshold {
            return "Shift \(horizontalDirection)"
        } else if verticalMagnitude > directionThreshold {
            return "Shift \(verticalDirection)"
        } else {
            return "Almost there"
        }
    }
    
    /// Create simple center crosshair
    func createCenterCrosshair(frameSize: CGSize) -> OverlayElement {
        var path = Path()
        let centerX = frameSize.width / 2
        let centerY = frameSize.height / 2
        let crosshairSize: CGFloat = 24
        
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
            lineWidth: 1.5
        )
    }
    
    private func createSafetyZoneOverlay(frameSize: CGSize) -> OverlayElement {
        var path = Path()
        let margin: CGFloat = frameSize.width * 0.05
        
        let safeRect = CGRect(
            x: margin,
            y: margin,
            width: frameSize.width - (margin * 2),
            height: frameSize.height - (margin * 2)
        )
        
        path.addRect(safeRect)
        
        return OverlayElement(
            type: .safetyZone,
            path: path,
            color: .orange,
            opacity: 0.0,
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
    
    /// Get appropriate SF Symbol for Center Framing feedback
    private func getCenterFramingIcon(for suggestion: String, status: CompositionStatus) -> String {
        switch suggestion {
        case "Step back":
            return "arrow.up.backward"
        case "Get closer":
            return "arrow.down.circle"
        case "Perfect!":
            return "checkmark.circle.fill"
        case "Nice center!":
            return "circle.circle.fill"
        case let str where str.starts(with: "Go up-left"):
            return "arrow.up.left"
        case let str where str.starts(with: "Go down-left"):
            return "arrow.down.left"
        case let str where str.starts(with: "Go up-right"):
            return "arrow.up.right"
        case let str where str.starts(with: "Go down-right"):
            return "arrow.down.right"
        case "Shift left":
            return "arrow.left"
        case "Shift right":
            return "arrow.right"
        case "Shift up":
            return "arrow.up"
        case "Shift down":
            return "arrow.down"
        case "Almost there":
            return "scope"
        default:
            return status.icon
        }
    }
    
    /// Get structured feedback model for Center Framing
    private func getCenterFramingFeedback(for suggestion: String, status: CompositionStatus, icon: String) -> CompositionFeedback {
        let level: Int
        var color: Color = .white
        
        switch suggestion {
        case "Perfect!":
            level = 1
            color = Color(red: 0x38 / 255.0, green: 0xb0 / 255.0, blue: 0x00 / 255.0) // Custom green #38b000
        case "Nice center!":
            level = 2
        case "Almost there":
            level = 3
        case let str where str.starts(with: "Go "):
            level = 4
        case let str where str.starts(with: "Shift "):
            level = 4
        case "Step back", "Get closer":
            level = 5
        default:
            level = 4
        }
        
        return CompositionFeedback(
            label: icon,
            suggestion: suggestion,
            compositionLevel: level,
            color: color
        )
    }
    
    // Optimized symmetry calculation for real-time performance
    private func calculateSymmetryScore(pixelBuffer: CVPixelBuffer) -> Double {
        // Ultra-fast symmetry using 64x64 downsampling for <50ms performance
        guard let downsampledImage = downsamplePixelBuffer(pixelBuffer, targetSize: CGSize(width: 64, height: 64)) else {
            return 0.0
        }
        
        return calculateVerticalSymmetry(pixelBuffer: downsampledImage)
    }
    
    private func downsamplePixelBuffer(_ pixelBuffer: CVPixelBuffer, targetSize: CGSize) -> CVPixelBuffer? {
        let ciImage = CIImage(cvPixelBuffer: pixelBuffer)
        
        // Use software renderer when app is in background to avoid GPU permission errors
        let useSoftwareRenderer = BackgroundStateMonitor.shared.isInBackground
        let context = CIContext(options: [.useSoftwareRenderer: useSoftwareRenderer])
        
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
        let sampleStep = max(1, height / 32) // Sample every nth row for performance
        
        for y in stride(from: 0, to: height, by: sampleStep) {
            let rowStart = y * bytesPerRow
            
            for x in stride(from: 0, to: midWidth, by: 2) { // Sample every 2nd pixel
                let leftPixelIndex = rowStart + x * 4
                let rightPixelIndex = rowStart + (width - 1 - x) * 4
                
                // Compare only luminance for speed (approximate RGB average)
                let leftLuma = (Double(data[leftPixelIndex]) + Double(data[leftPixelIndex + 1]) + Double(data[leftPixelIndex + 2])) / 3.0
                let rightLuma = (Double(data[rightPixelIndex]) + Double(data[rightPixelIndex + 1]) + Double(data[rightPixelIndex + 2])) / 3.0
                
                totalDifference += abs(leftLuma - rightLuma)
                totalPixels += 1
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

// MARK: - Dedicated Symmetry Service

class SymmetryService: CompositionService {
    let name = "Symmetry"
    
    func evaluate(observation: VNDetectedObjectObservation, frameSize: CGSize, pixelBuffer: CVPixelBuffer?) -> EnhancedCompositionResult {
        let context = CompositionContextAnalyzer.analyzeContext(observation: observation, frameSize: frameSize)
        
        // For symmetry, we need the subject to be reasonably centered first
        let subjectCenter = CGPoint(
            x: observation.boundingBox.midX,
            y: observation.boundingBox.midY
        )
        
        let frameCenter = CGPoint(x: 0.5, y: 0.5)
        let distanceFromCenter = sqrt(
            pow(subjectCenter.x - frameCenter.x, 2) + 
            pow(subjectCenter.y - frameCenter.y, 2)
        )
        
        var symmetryScore: Double = 0.0
        var balanceAnalysis = "balanced"
        
        if let pixelBuffer = pixelBuffer {
            symmetryScore = calculateAdvancedSymmetry(pixelBuffer: pixelBuffer, observation: observation)
            balanceAnalysis = analyzeBalance(observation: observation)
        }
        
        // Combine centering and symmetry for final score
        let centeringScore = max(0, 1 - (distanceFromCenter * 4)) // Penalty for off-center
        let finalScore = (symmetryScore * 0.8) + (centeringScore * 0.2)
        
        let (status, suggestion) = generateSymmetryFeedback(
            symmetryScore: symmetryScore,
            centeringScore: centeringScore,
            balanceAnalysis: balanceAnalysis,
            context: context
        )
        
        // Create overlays (don't duplicate basic overlays - they're handled separately)
        var overlayElements: [OverlayElement] = []
        
        if context.edgeProximity.tooCloseToEdge {
            overlayElements.append(createSafetyZoneOverlay(frameSize: frameSize))
        }
        
        // Get appropriate icon for the suggestion
        let icon = getSymmetryIcon(for: suggestion, status: status)
        
        // Create structured feedback model
        let feedback = getSymmetryFeedback(for: suggestion, status: status, icon: icon)
        
        return EnhancedCompositionResult(
            composition: CompositionType.symmetry.rawValue,
            score: finalScore,
            status: status,
            suggestion: suggestion,
            context: context,
            overlayElements: overlayElements,
            feedbackIcon: icon,
            feedback: feedback
        )
    }
    
    private func calculateAdvancedSymmetry(pixelBuffer: CVPixelBuffer, observation: VNDetectedObjectObservation) -> Double {
        // Ultra-fast symmetry using 64x64 downsampling for <50ms performance
        guard let downsampledImage = downsamplePixelBuffer(pixelBuffer, targetSize: CGSize(width: 64, height: 64)) else {
            return 0.0
        }
        
        return calculateVerticalSymmetry(pixelBuffer: downsampledImage)
    }
    
    private func downsamplePixelBuffer(_ pixelBuffer: CVPixelBuffer, targetSize: CGSize) -> CVPixelBuffer? {
        let ciImage = CIImage(cvPixelBuffer: pixelBuffer)
        
        // Use software renderer when app is in background to avoid GPU permission errors
        let useSoftwareRenderer = BackgroundStateMonitor.shared.isInBackground
        let context = CIContext(options: [.useSoftwareRenderer: useSoftwareRenderer])
        
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
        let sampleStep = max(1, height / 32) // Sample every nth row for performance
        
        for y in stride(from: 0, to: height, by: sampleStep) {
            let rowStart = y * bytesPerRow
            
            for x in stride(from: 0, to: midWidth, by: 2) { // Sample every 2nd pixel
                let leftPixelIndex = rowStart + x * 4
                let rightPixelIndex = rowStart + (width - 1 - x) * 4
                
                // Compare only luminance for speed (approximate RGB average)
                let leftLuma = (Double(data[leftPixelIndex]) + Double(data[leftPixelIndex + 1]) + Double(data[leftPixelIndex + 2])) / 3.0
                let rightLuma = (Double(data[rightPixelIndex]) + Double(data[rightPixelIndex + 1]) + Double(data[rightPixelIndex + 2])) / 3.0
                
                totalDifference += abs(leftLuma - rightLuma)
                totalPixels += 1
            }
        }
        
        if totalPixels == 0 { return 0.0 }
        
        // Calculate similarity score (0.0 to 1.0)
        let avgDifference = totalDifference / Double(totalPixels)
        let maxDifference = 255.0 // Max possible difference for 8-bit values
        let similarity = 1.0 - (avgDifference / maxDifference)
        
        return max(0.0, min(1.0, similarity))
    }
    
    private func analyzeBalance(observation: VNDetectedObjectObservation) -> String {
        let centerX = observation.boundingBox.midX
        
        if centerX < 0.45 {
            return "left-weighted"
        } else if centerX > 0.55 {
            return "right-weighted"
        } else {
            return "balanced"
        }
    }
    
    private func generateSymmetryFeedback(
        symmetryScore: Double,
        centeringScore: Double,
        balanceAnalysis: String,
        context: CompositionContext
    ) -> (CompositionStatus, String) {
        
        // Handle edge proximity first
        if context.edgeProximity.tooCloseToEdge {
            return (.needsAdjustment, "Step back")
        }
        
        // Symmetry-specific feedback
        if symmetryScore > 0.8 && centeringScore > 0.7 {
            return (.perfect, "So balanced!")
        } else if symmetryScore > 0.6 {
            if balanceAnalysis == "balanced" {
                return (.good, "Well balanced")
            } else {
                return (.good, "Good balance")
            }
        } else {
            switch balanceAnalysis {
            case "left-weighted":
                return (.needsAdjustment, "Shift right")
            case "right-weighted":
                return (.needsAdjustment, "Shift left")
            default:
                return (.needsAdjustment, "Find center")
            }
        }
    }
    
    func createSymmetryLine(frameSize: CGSize) -> OverlayElement {
        var path = Path()
        let centerX = frameSize.width / 2
        
        // Vertical symmetry line
        path.move(to: CGPoint(x: centerX, y: 0))
        path.addLine(to: CGPoint(x: centerX, y: frameSize.height))
        
        return OverlayElement(
            type: .symmetryLine,
            path: path,
            color: .cyan,
            opacity: 0.4,
            lineWidth: 1
        )
    }
    
    private func createSafetyZoneOverlay(frameSize: CGSize) -> OverlayElement {
        var path = Path()
        let margin: CGFloat = frameSize.width * 0.05
        
        let safeRect = CGRect(
            x: margin,
            y: margin,
            width: frameSize.width - (margin * 2),
            height: frameSize.height - (margin * 2)
        )
        
        path.addRect(safeRect)
        
        return OverlayElement(
            type: .safetyZone,
            path: path,
            color: .purple,
            opacity: 0.0,
            lineWidth: 1
        )
    }
    
    /// Get appropriate SF Symbol for Symmetry feedback
    private func getSymmetryIcon(for suggestion: String, status: CompositionStatus) -> String {
        switch suggestion {
        case "Step back":
            return "arrow.up.backward"
        case "So balanced!":
            return "checkmark.circle.fill"
        case "Well balanced":
            return "checkmark.seal.fill"
        case "Good balance":
            return "equal.circle"
        case "Shift right":
            return "arrow.right"
        case "Shift left":
            return "arrow.left"
        case "Find center":
            return "plus.viewfinder"
        default:
            return status.icon
        }
    }
    
    /// Get structured feedback model for Symmetry
    private func getSymmetryFeedback(for suggestion: String, status: CompositionStatus, icon: String) -> CompositionFeedback {
        let level: Int
        let color: Color
        
        switch suggestion {
        case "So balanced!":
            level = 1
            color = Color(red: 0x38 / 255.0, green: 0xb0 / 255.0, blue: 0x00 / 255.0) // Custom green #38b000
        case "Well balanced":
            level = 2
            color = .white
        case "Good balance":
            level = 3
            color = .white
        case let str where str.starts(with: "Shift "):
            level = 4
            color = .white
        case "Find center":
            level = 4
            color = .white
        case "Step back":
            level = 5
            color = .white
        default:
            level = 4
            color = .white
        }
        
        return CompositionFeedback(
            label: icon,
            suggestion: suggestion,
            compositionLevel: level,
            color: color
        )
    }
}

// MARK: - JSON Conversion Extension

extension EnhancedCompositionResult {
    /// Convert to JSON-compatible dictionary matching the required format
    func toJSON() -> [String: Any] {
        return [
            "composition": composition,
            "score": Double(round(score * 100) / 100), // Round to 2 decimal places
            "status": status.rawValue,
            "suggestion": suggestion,
            "feedbackIcon": feedbackIcon,
            "context": [
                "subjectSize": context.subjectSize.rawValue,
                "subjectOffsetX": Double(round(context.subjectOffsetX * 100) / 100),
                "subjectOffsetY": Double(round(context.subjectOffsetY * 100) / 100),
                "multipleSubjects": context.multipleSubjects
            ]
        ]
    }
    
    /// Convert to JSON string
    func toJSONString() -> String? {
        guard let jsonData = try? JSONSerialization.data(withJSONObject: toJSON(), options: .prettyPrinted) else {
            return nil
        }
        return String(data: jsonData, encoding: .utf8)
    }
}

// MARK: - Enhanced Rule of Thirds Service

class RuleOfThirdsService: CompositionService {
    let name = "Rule of Thirds"
    // More realistic tolerances for photography
    private let baseIntersectionTolerance: Double = 0.18  // Increased from 0.12
    private let baseLineTolerance: Double = 0.15         // Increased from 0.08
    
    func evaluate(observation: VNDetectedObjectObservation, frameSize: CGSize, pixelBuffer: CVPixelBuffer?) -> EnhancedCompositionResult {
        let context = CompositionContextAnalyzer.analyzeContext(observation: observation, frameSize: frameSize)
        
        // Use smarter subject positioning - prioritize top portion for faces
        let (subjectX, subjectY) = getOptimalSubjectPosition(observation: observation)
        
        // Adaptive tolerance based on subject size and context
        let sizeMultiplier: Double = context.subjectSize == .large ? 1.8 : 1.2  // More generous
        let intersectionTolerance = baseIntersectionTolerance * sizeMultiplier
        let lineTolerance = baseLineTolerance * sizeMultiplier
        
      
        // Check intersection alignment (high priority)
        let intersectionScore = calculateIntersectionScore(
            centerX: subjectX, centerY: subjectY,
            tolerance: intersectionTolerance
        )
        
        // Check line alignment (equal priority now)
        let lineScore = calculateLineScore(
            centerX: subjectX, centerY: subjectY,
            tolerance: lineTolerance
        )
        
        // Improved scoring - both intersection and line alignment are valuable
        let finalScore = max(intersectionScore, lineScore * 0.85)  // Less penalty for line alignment
        
        // Determine status and create suggestion
        let (status, suggestion) = generateStatusAndSuggestion(
            intersectionScore: intersectionScore,
            lineScore: lineScore,
            centerX: subjectX,
            centerY: subjectY,
            context: context
        )
        
        // Create overlays with adaptive elements (don't duplicate basic overlays - they're handled separately)
        var overlayElements: [OverlayElement] = []
        
        // Add safety zone overlay if subject is too close to edge
        if context.edgeProximity.tooCloseToEdge {
            overlayElements.append(createSafetyZoneOverlay(frameSize: frameSize))
        }
        
        // Get appropriate icon for the suggestion
        let icon = getRuleOfThirdsIcon(for: suggestion, status: status)
        
        // Create structured feedback model
        let feedback = getRuleOfThirdsFeedback(for: suggestion, status: status, icon: icon)
        
        return EnhancedCompositionResult(
            composition: CompositionType.ruleOfThirds.rawValue,
            score: finalScore,
            status: status,
            suggestion: suggestion,
            context: context,
            overlayElements: overlayElements,
            feedbackIcon: icon,
            feedback: feedback
        )
    }
    
    /// Get optimal subject position for composition analysis
    /// For faces, prioritize upper portion; for full body, use center
    private func getOptimalSubjectPosition(observation: VNDetectedObjectObservation) -> (Double, Double) {
        let boundingBox = observation.boundingBox
        
        // If it's likely a face/portrait (small to medium, more vertical than horizontal)
        let aspectRatio = boundingBox.width / boundingBox.height
        let subjectArea = boundingBox.width * boundingBox.height
        
        if subjectArea < 0.4 && aspectRatio < 1.2 {
            // Portrait mode - use upper third of bounding box (approximate eye level)
            let eyeLevelY = boundingBox.maxY - (boundingBox.height * 0.25)  // 25% down from top
            return (boundingBox.midX, eyeLevelY)
        } else {
            // Full body or landscape - use geometric center
            return (boundingBox.midX, boundingBox.midY)
        }
    }
    
    private func calculateIntersectionScore(centerX: Double, centerY: Double, tolerance: Double) -> Double {
        let intersections = [
            (1.0/3.0, 1.0/3.0), (1.0/3.0, 2.0/3.0),
            (2.0/3.0, 1.0/3.0), (2.0/3.0, 2.0/3.0)
        ]
        
        let distances = intersections.map { intersection in
            let dx = centerX - intersection.0
            let dy = centerY - intersection.1
            return sqrt(dx * dx + dy * dy)
        }
        
        guard let minDistance = distances.min() else { return 0.0 }
        
        if minDistance <= tolerance {
            // Smoother scoring curve
            let score = 1.0 - (minDistance / tolerance)
            return pow(score, 0.7)  // Less harsh falloff
        }
        
        return 0.0
    }
    
    private func calculateLineScore(centerX: Double, centerY: Double, tolerance: Double) -> Double {
        let verticalLines = [1.0/3.0, 2.0/3.0]
        let horizontalLines = [1.0/3.0, 2.0/3.0]
        
        // Check vertical line alignment
        let verticalDistances = verticalLines.map { line in abs(centerX - line) }
        let minVerticalDistance = verticalDistances.min() ?? 1.0
        
        // Check horizontal line alignment  
        let horizontalDistances = horizontalLines.map { line in abs(centerY - line) }
        let minHorizontalDistance = horizontalDistances.min() ?? 1.0
        
        var score = 0.0
        
        // Score for vertical alignment (more important for portraits)
        if minVerticalDistance <= tolerance {
            let verticalScore = 1.0 - (minVerticalDistance / tolerance)
            score += 0.6 * pow(verticalScore, 0.7)  // Smoother curve, higher weight
        }
        
        // Score for horizontal alignment
        if minHorizontalDistance <= tolerance {
            let horizontalScore = 1.0 - (minHorizontalDistance / tolerance)
            score += 0.4 * pow(horizontalScore, 0.7)  // Smoother curve
        }
        
        return min(1.0, score)  // Cap at 1.0
    }
    
    private func generateStatusAndSuggestion(
        intersectionScore: Double,
        lineScore: Double,
        centerX: Double,
        centerY: Double,
        context: CompositionContext
    ) -> (CompositionStatus, String) {
        
        // Handle edge proximity first
        if context.edgeProximity.tooCloseToEdge {
            return (.needsAdjustment, "Step back")
        }
        
        // Handle headroom issues
        if context.headroom.excessiveHeadroom {
            return (.needsAdjustment, "Get closer")
        }
        
        if context.headroom.cutoffLimbs {
            return (.needsAdjustment, "Subject cut off")
        }
        
        // More realistic composition-based feedback
        if intersectionScore > 0.7 {  // Lowered from 0.8
            return (.perfect, "Nailed it!")
        } else if intersectionScore > 0.4 || lineScore > 0.7 {  // More achievable thresholds
            return (.good, "Looking good!")
        } else if lineScore > 0.4 {  // Lowered from 0.6
            return (.good, "Almost there")
        } else {
            // Provide directional guidance
            let suggestion = generateDirectionalGuidance(centerX: centerX, centerY: centerY)
            return (.needsAdjustment, suggestion)
        }
    }
    
    private func generateDirectionalGuidance(centerX: Double, centerY: Double) -> String {
        let intersections = [
            (1.0/3.0, 1.0/3.0, "lower-left"),
            (1.0/3.0, 2.0/3.0, "upper-left"), 
            (2.0/3.0, 1.0/3.0, "lower-right"),
            (2.0/3.0, 2.0/3.0, "upper-right")
        ]
        
        let distances = intersections.map { intersection in
            let dx = centerX - intersection.0
            let dy = centerY - intersection.1
            let distance = sqrt(dx * dx + dy * dy)
            return (distance, intersection.2)
        }
        
        guard let nearest = distances.min(by: { $0.0 < $1.0 }) else {
            return "Find your spot"
        }
        
        return "Go \(nearest.1)"
    }
    
    private func createSafetyZoneOverlay(frameSize: CGSize) -> OverlayElement {
        var path = Path()
        let margin: CGFloat = frameSize.width * 0.05 // 5% safety margin
        
        let safeRect = CGRect(
            x: margin,
            y: margin,
            width: frameSize.width - (margin * 2),
            height: frameSize.height - (margin * 2)
        )
        
        path.addRect(safeRect)
        
        return OverlayElement(
            type: .safetyZone,
            path: path,
            color: .yellow,
            opacity: 0.0,
            lineWidth: 2
        )
    }
    
    /// Get appropriate SF Symbol for Rule of Thirds feedback
    private func getRuleOfThirdsIcon(for suggestion: String, status: CompositionStatus) -> String {
        switch suggestion {
        case "Step back":
            return "arrow.up.backward"
        case "Get closer":
            return "arrow.down.circle"
        case "Subject cut off":
            return "person.fill.viewfinder"
        case "Nailed it!":
            return "checkmark.circle.fill"
        case "Looking good!":
            return "hand.thumbsup.fill"
        case "Almost there":
            return "target"
        case let str where str.starts(with: "Go lower-left"):
            return "arrow.down.left"
        case let str where str.starts(with: "Go upper-left"):
            return "arrow.up.left"
        case let str where str.starts(with: "Go lower-right"):
            return "arrow.down.right"
        case let str where str.starts(with: "Go upper-right"):
            return "arrow.up.right"
        default:
            return status.icon
        }
    }
    
    /// Get structured feedback model for Rule of Thirds
    private func getRuleOfThirdsFeedback(for suggestion: String, status: CompositionStatus, icon: String) -> CompositionFeedback {
        let level: Int
        let color: Color
        
        switch suggestion {
        case "Nailed it!":
            level = 1
            color = Color(red: 0x38 / 255.0, green: 0xb0 / 255.0, blue: 0x00 / 255.0) // Custom green #38b000
        case "Looking good!":
            level = 2
            color = .white
        case "Almost there":
            level = 3
            color = .white
        case let str where str.starts(with: "Go "):
            level = 4
            color = .white
        case "Step back", "Get closer":
            level = 5
            color = .white
        case "Subject cut off":
            level = 6
            color = .white
        default:
            level = 4
            color = .white
        }
        
        return CompositionFeedback(
            label: icon,
            suggestion: suggestion,
            compositionLevel: level,
            color: color
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
