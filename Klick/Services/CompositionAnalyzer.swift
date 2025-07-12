//
//  CompositionAnalyzer.swift
//  Klick
//
//  Created by AI Assistant on 12/07/2025.
//

import Foundation
import Vision
import UIKit
import SwiftUI
// Combine not needed at the moment

class CompositionAnalyzer: ObservableObject {
    @Published var analysisState: AnalysisState = .idle
    @Published var progress: AnalysisProgress = AnalysisProgress(percent: 0, message: "")
    
    // Vision request handlers
    private var faceDetectionRequest: VNDetectFaceRectanglesRequest?
    private var contourDetectionRequest: VNDetectContoursRequest?
    private var rectangleDetectionRequest: VNDetectRectanglesRequest?
    
    // Dynamic analysis components
    private let dynamicMatcher = DynamicCompositionMatcher()
    // Lightweight processors for staged progress
    private let imageProcessor = AdvancedImageProcessor()
    private let angleDetector = ImageAngleDetector()
    private let leadingLinesDetector = DynamicLeadingLinesDetector()
    
    // Cancellation support
    private var currentAnalysisTask: Task<Void, Never>?
    private var isCancelled = false
    
    init() {
        setupVisionRequests()
    }
    
    private func setupVisionRequests() {
        faceDetectionRequest = VNDetectFaceRectanglesRequest()
        
        contourDetectionRequest = VNDetectContoursRequest()
        contourDetectionRequest?.contrastAdjustment = 1.0
        contourDetectionRequest?.detectsDarkOnLight = true
        
        rectangleDetectionRequest = VNDetectRectanglesRequest()
        rectangleDetectionRequest?.maximumObservations = 10
    }
    
    func analyzeImage(_ image: UIImage) {
        print("🔄 Starting concurrent image analysis...")
        
        // Cancel any existing analysis
        cancelAnalysis()
        
        analysisState = .analyzing
        progress = AnalysisProgress(percent: 0, message: "📱 Initializing composition analysis...")
        isCancelled = false
        
        // Run on background thread with TaskGroup for concurrent processing
        currentAnalysisTask = Task.detached(priority: .userInitiated) { [weak self] in
            guard let self = self else { return }
            
            await self.performConcurrentAnalysis(image: image)
        }
    }
    
    /// Cancel the current analysis operation
    func cancelAnalysis() {
        print("🛑 Cancelling image analysis...")
        isCancelled = true
        currentAnalysisTask?.cancel()
        currentAnalysisTask = nil
        
        // Reset state
        analysisState = .idle
        progress = AnalysisProgress(percent: 0, message: "")
        
        print("✅ Analysis cancelled")
    }
    
    @MainActor
    private func performConcurrentAnalysis(image: UIImage) async {
        let startTime = CFAbsoluteTimeGetCurrent()
        
        // Check for cancellation
        guard !isCancelled else {
            print("🚫 Analysis cancelled during initialization")
            return
        }
        
        // Step 1: Create optimized thumbnail for analysis
        updateProgress(5, "📱 Preparing image for analysis...")
        guard let thumbnail = createOptimizedThumbnail(from: image, targetLongEdge: 1024) else {
            analysisState = .failed(AnalysisError.invalidImage)
            return
        }
        
        // Step 2: Concurrent analysis using TaskGroup
        updateProgress(15, "🔄 Starting concurrent image analysis...")
        
        // Check for cancellation before starting concurrent tasks
        guard !isCancelled else {
            print("🚫 Analysis cancelled before concurrent processing")
            return
        }
        
        // Launch all concurrent tasks with detailed progress updates
        async let histogramTask = analyzeHistogramConcurrent(thumbnail)
        async let angleTask = analyzeAngleConcurrent(thumbnail)
        async let leadingLinesTask = analyzeLeadingLinesConcurrent(thumbnail)
        async let saliencyTask = analyzeSaliencyConcurrent(thumbnail)
        
        // Update progress during concurrent processing
        updateProgress(25, "📊 Analyzing image histogram and contrast...")
        updateProgress(35, "📐 Detecting angles and horizon lines...")
        updateProgress(45, "📍 Finding leading lines and edges...")
        updateProgress(55, "🎯 Identifying salient regions...")
        
        // Wait for all concurrent tasks to complete
        let (histogramData, angleAnalysis, leadingLinesAnalysis, salientRegions) = await (
            histogramTask,
            angleTask,
            leadingLinesTask,
            saliencyTask
        )
        
        // Check for cancellation after concurrent tasks
        guard !isCancelled else {
            print("🚫 Analysis cancelled after concurrent processing")
            return
        }
        
        updateProgress(70, "🎨 Matching composition rules...")
        
        // Step 3: Process results and create final analysis
        let result = await processConcurrentResults(
            image: image,
            histogramData: histogramData,
            angleAnalysis: angleAnalysis,
            leadingLinesAnalysis: leadingLinesAnalysis,
            salientRegions: salientRegions
        )
        
        let processingTime = CFAbsoluteTimeGetCurrent() - startTime
        let timeString = formatProcessingTime(processingTime)
        
        // Check for cancellation before finalizing
        guard !isCancelled else {
            print("🚫 Analysis cancelled before finalization")
            return
        }
        
        // Update to 100% completion
        updateProgress(100, "✅ Analysis complete!")
        
        // Brief delay to show completion before transitioning to results
        try? await Task.sleep(nanoseconds: 1_500_000_000) // 1.5 seconds
        
        // Final cancellation check
        guard !isCancelled else {
            print("🚫 Analysis cancelled during finalization")
            return
        }
        
        analysisState = .completed(result)
        
        print("✅ Concurrent analysis completed in \(timeString):")
        print("   - Primary composition: \(result.detectedRules.first?.rawValue ?? "Unknown")")
        print("   - Detected rules: \(result.detectedRules.count)")
        print("   - Overlay elements: \(result.overlayElements.count)")
    }
    
    // MARK: - Concurrent Analysis Tasks
    
    private func analyzeHistogramConcurrent(_ image: UIImage) async -> HistogramData {
        let startTime = CFAbsoluteTimeGetCurrent()
        let result = await imageProcessor.analyzeHistogram(image)
        let processingTime = CFAbsoluteTimeGetCurrent() - startTime
        print("📊 Histogram analysis completed in \(formatProcessingTime(processingTime)) - Contrast: \(result.distribution.description)")
        return result
    }
    
    private func analyzeAngleConcurrent(_ image: UIImage) async -> ImageAngleDetector.AngleAnalysis {
        let startTime = CFAbsoluteTimeGetCurrent()
        let result = await Task.detached(priority: .utility) {
            return self.angleDetector.analyzeImageAngle(image)
        }.value
        let processingTime = CFAbsoluteTimeGetCurrent() - startTime
        print("📐 Angle analysis completed in \(formatProcessingTime(processingTime)) - Dominant angle: \(String(format: "%.1f°", result.dominantAngle))")
        return result
    }
    
    private func analyzeLeadingLinesConcurrent(_ image: UIImage) async -> DynamicLeadingLinesDetector.LeadingLinesAnalysis {
        let startTime = CFAbsoluteTimeGetCurrent()
        let result = await leadingLinesDetector.detectLeadingLines(in: image)
        let processingTime = CFAbsoluteTimeGetCurrent() - startTime
        print("📍 Leading lines analysis completed in \(formatProcessingTime(processingTime)) - Found \(result.detectedLines.count) lines")
        return result
    }
    
    private func analyzeSaliencyConcurrent(_ image: UIImage) async -> [CGRect] {
        let startTime = CFAbsoluteTimeGetCurrent()
        let result = await Task.detached(priority: .utility) {
            return self.imageProcessor.detectSalientRegions(image)
        }.value
        let processingTime = CFAbsoluteTimeGetCurrent() - startTime
        print("🎯 Saliency analysis completed in \(formatProcessingTime(processingTime)) - Found \(result.count) salient regions")
        return result
    }
    
    // MARK: - Optimized Thumbnail Creation
    
    private func createOptimizedThumbnail(from image: UIImage, targetLongEdge: CGFloat) -> UIImage? {
        let maxSide = max(image.size.width, image.size.height)
        let scale = targetLongEdge / maxSide
        
        // If image is already smaller than target, return as-is
        if scale >= 1 { return image }
        
        let size = CGSize(width: image.size.width * scale, height: image.size.height * scale)
        
        // Use UIGraphicsImageRenderer for better performance
        let renderer = UIGraphicsImageRenderer(size: size)
        return renderer.image { context in
            image.draw(in: CGRect(origin: .zero, size: size))
        }
    }
    
    // MARK: - Result Processing
    
    private func processConcurrentResults(
        image: UIImage,
        histogramData: HistogramData,
        angleAnalysis: ImageAngleDetector.AngleAnalysis,
        leadingLinesAnalysis: DynamicLeadingLinesDetector.LeadingLinesAnalysis,
        salientRegions: [CGRect]
    ) async -> CompositionAnalysisResult {
        
        let startTime = CFAbsoluteTimeGetCurrent()
        
        // Use dynamic composition matcher with pre-processed data
        let dynamicRecommendation = await Task.detached(priority: .utility) {
            return await self.dynamicMatcher.analyzeAndMatchComposition(image: image)
        }.value
        
        // Extract Vision framework observations
        let faceObservations = faceDetectionRequest?.results as? [VNFaceObservation] ?? []
        let contourObservations = extractContours()
        let rectangleObservations = rectangleDetectionRequest?.results as? [VNRectangleObservation] ?? []
        
        // Convert to overlay elements and suggestions
        var overlayElements: [OverlayElement] = []
        var detectedRules: [CompositionRule] = []
        var confidence: [CompositionRule: Float] = [:]
        var suggestions: [CompositionSuggestion] = []
        
        let maxElements = 20
        
        // Process dynamic matches
        for match in dynamicRecommendation.matches {
            detectedRules.append(match.rule)
            confidence[match.rule] = match.confidence
            
            // Add grid lines
            for line in match.dynamicLines.prefix(maxElements) {
                guard line.type == .grid else { continue }
                overlayElements.append(.gridLine(
                    start: line.start,
                    end: line.end,
                    type: .ruleOfThirds
                ))
            }
            
            // Add suggestions
            suggestions.append(CompositionSuggestion(
                rule: match.rule,
                message: match.recommendation,
                improvementTip: match.improvementSuggestion
            ))
        }
        
        // Add dynamic grid lines
        let imageSize = image.size
        for vLine in dynamicRecommendation.dynamicGrid.verticalLines {
            overlayElements.append(.gridLine(
                start: CGPoint(x: vLine, y: 0),
                end: CGPoint(x: vLine, y: imageSize.height),
                type: .ruleOfThirds
            ))
        }
        
        for hLine in dynamicRecommendation.dynamicGrid.horizontalLines {
            overlayElements.append(.gridLine(
                start: CGPoint(x: 0, y: hLine),
                end: CGPoint(x: imageSize.width, y: hLine),
                type: .ruleOfThirds
            ))
        }
        
        // Add intersection points
        let maxIntersectionPoints = 8
        for point in dynamicRecommendation.dynamicGrid.intersectionPoints.prefix(maxIntersectionPoints) {
            overlayElements.append(.hotspot(
                center: point,
                radius: 15,
                label: ""
            ))
        }
        
        // Add adjustment suggestions
        for adjustment in dynamicRecommendation.suggestedAdjustments {
            suggestions.append(CompositionSuggestion(
                rule: dynamicRecommendation.primaryComposition,
                message: adjustment.description,
                improvementTip: "This adjustment will improve your composition score from \(String(format: "%.0f%%", dynamicRecommendation.overallScore * 100))"
            ))
        }
        
        // Fallback if no rules detected
        if detectedRules.isEmpty {
            detectedRules.append(.ruleOfThirds)
            confidence[.ruleOfThirds] = 0.3
            suggestions.append(CompositionSuggestion(
                rule: .ruleOfThirds,
                message: "Consider using basic composition rules to improve your photo.",
                improvementTip: "Start with the rule of thirds by placing key elements at grid intersections."
            ))
        }
        
        // Remove hotspots to focus on grid-based composition
        overlayElements = overlayElements.filter { element in
            if case .hotspot = element { return false }
            return true
        }
        
        let processingTime = CFAbsoluteTimeGetCurrent() - startTime
        print("🎯 Result processing completed in \(formatProcessingTime(processingTime))")
        print("✅ Concurrent analysis completed:")
        print("   - Primary composition: \(dynamicRecommendation.primaryComposition)")
        print("   - Detected rules: \(detectedRules.count)")
        print("   - Overall score: \(String(format: "%.0f%%", dynamicRecommendation.overallScore * 100))")
        print("   - Overlay elements: \(overlayElements.count)")
        print("   - Suggestions: \(suggestions.count)")
        
        return CompositionAnalysisResult(
            detectedRules: detectedRules,
            confidence: confidence,
            suggestions: suggestions,
            overlayElements: overlayElements,
            faceObservations: faceObservations,
            contourObservations: contourObservations,
            rectangleObservations: rectangleObservations
        )
    }
    
    // MARK: - Progress Updates
    
    private func updateProgress(_ percent: Double, _ message: String) {
        progress = AnalysisProgress(percent: percent, message: message)
    }
    
    // MARK: - Processing Time Formatting
    
    private func formatProcessingTime(_ time: CFAbsoluteTime) -> String {
        if time < 1.0 {
            return String(format: "%.0fms", time * 1000)
        } else if time < 60.0 {
            return String(format: "%.1fsec", time)
        } else {
            let minutes = Int(time / 60)
            let seconds = Int(time.truncatingRemainder(dividingBy: 60))
            return "\(minutes)m \(seconds)s"
        }
    }
    

    

    
    private func mapLineTypeToGridType(_ lineType: DynamicCompositionMatcher.DynamicLine.LineType) -> OverlayElement.GridType {
        switch lineType {
        case .grid, .horizon:
            return .ruleOfThirds
        case .diagonal:
            return .diagonal
        case .leading, .framing:
            return .ruleOfThirds // Default mapping
        }
    }
    
    // MARK: - Simulator Fallback Analysis
    
    private func processSimulatorFallbackAnalysis(for image: UIImage) {
        print("🎭 Using dynamic analysis for simulator...")
        
        // The simulator fallback is now handled by the concurrent analysis
        // The dynamic components already have fallback mechanisms built-in
        // No additional processing needed as the main analyzeImage method handles all cases
    }
    
    // MARK: - Rule Analysis Methods
    
    private func analyzeRuleOfThirds(faces: [VNFaceObservation], imageSize: CGSize) -> (isDetected: Bool, confidence: Float, overlayElements: [OverlayElement], suggestions: [CompositionSuggestion]) {
        var overlayElements: [OverlayElement] = []
        var suggestions: [CompositionSuggestion] = []
        var totalConfidence: Float = 0
        var detectionCount = 0
        
        let thirdX = imageSize.width / 3
        let thirdY = imageSize.height / 3
        let tolerance: CGFloat = min(imageSize.width, imageSize.height) * 0.1
        
        // Check faces against rule of thirds points
        for face in faces {
            let faceCenterX = face.boundingBox.midX * imageSize.width
            let faceCenterY = (1 - face.boundingBox.midY) * imageSize.height
            
            // Check proximity to thirds intersections
            let intersectionPoints = [
                CGPoint(x: thirdX, y: thirdY),
                CGPoint(x: thirdX * 2, y: thirdY),
                CGPoint(x: thirdX, y: thirdY * 2),
                CGPoint(x: thirdX * 2, y: thirdY * 2)
            ]
            
            for point in intersectionPoints {
                let distance = hypot(faceCenterX - point.x, faceCenterY - point.y)
                if distance < tolerance {
                    detectionCount += 1
                    totalConfidence += Float(1 - distance / tolerance)
                    
                    overlayElements.append(.hotspot(
                        center: CGPoint(x: faceCenterX, y: faceCenterY),
                        radius: 20,
                        label: "Subject on thirds"
                    ))
                    
                    suggestions.append(CompositionSuggestion(
                        rule: .ruleOfThirds,
                        message: "Great job! Your subject is positioned on the rule of thirds.",
                        improvementTip: "Try different intersection points for varied compositions."
                    ))
                    break
                }
            }
            
            // Add face bounding box
            let faceRect = CGRect(
                x: face.boundingBox.minX * imageSize.width,
                y: (1 - face.boundingBox.maxY) * imageSize.height,
                width: face.boundingBox.width * imageSize.width,
                height: face.boundingBox.height * imageSize.height
            )
            overlayElements.append(.boundingBox(rect: faceRect, label: "Face", color: "blue"))
        }
        
        let isDetected = detectionCount > 0
        let avgConfidence = detectionCount > 0 ? totalConfidence / Float(detectionCount) : 0
        
        if !isDetected && faces.count > 0 {
            suggestions.append(CompositionSuggestion(
                rule: .ruleOfThirds,
                message: "Try positioning your subject on the rule of thirds grid.",
                improvementTip: "Move your subject away from the center to one of the intersection points."
            ))
        }
        
        return (isDetected, avgConfidence, overlayElements, suggestions)
    }
    
    private func analyzeLeadingLines(contours: [VNContour], imageSize: CGSize) -> (isDetected: Bool, confidence: Float, overlayElements: [OverlayElement], suggestions: [CompositionSuggestion]) {
        var overlayElements: [OverlayElement] = []
        var suggestions: [CompositionSuggestion] = []
        var leadingLineCount = 0
        var totalConfidence: Float = 0
        
        print("🔍 Analyzing \(contours.count) contours for leading lines...")
        
        for contour in contours {
            // Convert contour path to points array
            var points: [CGPoint] = []
            
            if contour.pointCount > 10 {
                let path = contour.normalizedPath
                
                // Extract points from CGPath
                path.applyWithBlock { elementPointer in
                    let element = elementPointer.pointee
                    let elementType = element.type
                    let elementPoints = element.points
                    
                    switch elementType {
                    case .moveToPoint, .addLineToPoint:
                        let point = elementPoints.pointee
                            let transformedPoint = CGPoint(
                                x: point.x * imageSize.width,
                                y: (1 - point.y) * imageSize.height
                            )
                            points.append(transformedPoint)
                    case .addQuadCurveToPoint:
                        // Add the end point of quad curve
                        let endPoint = elementPoints.advanced(by: 1).pointee
                            let transformedPoint = CGPoint(
                                x: endPoint.x * imageSize.width,
                                y: (1 - endPoint.y) * imageSize.height
                            )
                            points.append(transformedPoint)
                    case .addCurveToPoint:
                        // Add the end point of cubic curve
                        let endPoint = elementPoints.advanced(by: 2).pointee
                            let transformedPoint = CGPoint(
                                x: endPoint.x * imageSize.width,
                                y: (1 - endPoint.y) * imageSize.height
                            )
                            points.append(transformedPoint)
                    case .closeSubpath:
                        break
                    @unknown default:
                        break
                    }
                }
            }
            
            guard points.count >= 2 else { continue }
            
            // Calculate line properties
            let lineLength = calculateLineLength(points: points)
            let straightness = calculateStraightness(points: points)
            
            print("📏 Contour: \(points.count) points, length: \(lineLength), straightness: \(straightness)")
            
            // More lenient filter for potential leading lines
            if lineLength > min(imageSize.width, imageSize.height) * 0.2 && straightness > 0.6 {
                leadingLineCount += 1
                totalConfidence += straightness
                
                overlayElements.append(.contourPath(points: points, label: "Leading Line"))
                
                // Determine line direction
                let angle = calculateLineAngle(start: points.first!, end: points.last!)
                let isDiagonal = abs(angle) > 15 && abs(angle) < 75
                
                print("✅ Leading line detected: angle \(angle)°, diagonal: \(isDiagonal)")
                
                if isDiagonal {
                    suggestions.append(CompositionSuggestion(
                        rule: .leadingLines,
                        message: "Nice diagonal leading line detected!",
                        improvementTip: "Diagonal lines add dynamic energy to your composition."
                    ))
                } else {
                    suggestions.append(CompositionSuggestion(
                        rule: .leadingLines,
                        message: "Leading line detected in your landscape!",
                        improvementTip: "This line helps guide the viewer's eye through your composition."
                    ))
                }
            }
        }
        
        // Fallback: Add example leading lines for landscape photos even if none detected
        if leadingLineCount == 0 {
            // Add some example leading lines that might work well in landscapes
            let possibleLines = [
                (start: CGPoint(x: 0, y: imageSize.height * 0.8), end: CGPoint(x: imageSize.width * 0.7, y: imageSize.height * 0.3)),
                (start: CGPoint(x: imageSize.width * 0.3, y: imageSize.height), end: CGPoint(x: imageSize.width * 0.7, y: imageSize.height * 0.4))
            ]
            
            for (index, line) in possibleLines.enumerated() {
                overlayElements.append(.arrow(
                    start: line.start,
                    end: line.end,
                    label: "Potential Leading Line \(index + 1)"
                ))
            }
            
            suggestions.append(CompositionSuggestion(
                rule: .leadingLines,
                message: "Look for natural leading lines in your landscape.",
                improvementTip: "Rock formations, waterfall edges, or cliff lines can guide the viewer's eye through your composition."
            ))
            
            leadingLineCount = 1 // Mark as detected for fallback
            totalConfidence = 0.4
        }
        
        let isDetected = leadingLineCount > 0
        let avgConfidence = leadingLineCount > 0 ? totalConfidence / Float(leadingLineCount) : 0
        
        print("🎯 Leading lines analysis: detected=\(isDetected), confidence=\(avgConfidence)")
        
        return (isDetected, avgConfidence, overlayElements, suggestions)
    }
    
    private func analyzeSymmetry(faces: [VNFaceObservation], rectangles: [VNRectangleObservation], imageSize: CGSize) -> (isDetected: Bool, confidence: Float, overlayElements: [OverlayElement], suggestions: [CompositionSuggestion]) {
        var overlayElements: [OverlayElement] = []
        var suggestions: [CompositionSuggestion] = []
        var symmetryConfidence: Float = 0
        
        // Check vertical symmetry
        let centerX = imageSize.width / 2
        let tolerance = imageSize.width * 0.1
        
        // Check if faces are centered
        for face in faces {
            let faceCenterX = face.boundingBox.midX * imageSize.width
            let distanceFromCenter = abs(faceCenterX - centerX)
            
            if distanceFromCenter < tolerance {
                symmetryConfidence = 1 - Float(distanceFromCenter / tolerance)
                
                overlayElements.append(.gridLine(
                    start: CGPoint(x: centerX, y: 0),
                    end: CGPoint(x: centerX, y: imageSize.height),
                    type: .ruleOfThirds
                ))
                
                suggestions.append(CompositionSuggestion(
                    rule: .symmetry,
                    message: "Good use of central composition!",
                    improvementTip: "Central composition works well for portraits and symmetrical subjects."
                ))
            }
        }
        
        let isDetected = symmetryConfidence > 0.5
        
        if !isDetected && (faces.count > 0 || rectangles.count > 0) {
            suggestions.append(CompositionSuggestion(
                rule: .symmetry,
                message: "Consider using symmetry for a balanced composition.",
                improvementTip: "Center your subject or look for naturally symmetrical scenes."
            ))
        }
        
        return (isDetected, symmetryConfidence, overlayElements, suggestions)
    }
    
    // MARK: - Helper Methods
    
    private func extractContours() -> [VNContour] {
        guard let contourObservation = contourDetectionRequest?.results?.first as? VNContoursObservation else {
            return []
        }
        
        var allContours: [VNContour] = []
        
        // Extract top-level contours
        let topLevelContours = contourObservation.topLevelContours
        
        for contour in topLevelContours {
            // Add contours with sufficient points
            if contour.pointCount > 10 {
                allContours.append(contour)
            }
            
            // Also check child contours
            extractChildContours(from: contour, into: &allContours)
        }
        
        return allContours
    }
    
    private func extractChildContours(from contour: VNContour, into allContours: inout [VNContour]) {
        for childContour in contour.childContours {
            if childContour.pointCount > 10 {
                allContours.append(childContour)
            }
            extractChildContours(from: childContour, into: &allContours)
        }
    }
    
    private func createRuleOfThirdsGrid(imageSize: CGSize) -> [OverlayElement] {
        var elements: [OverlayElement] = []
        
        let thirdX = imageSize.width / 3
        let thirdY = imageSize.height / 3
        
        // Vertical lines
        elements.append(.gridLine(
            start: CGPoint(x: thirdX, y: 0),
            end: CGPoint(x: thirdX, y: imageSize.height),
            type: .ruleOfThirds
        ))
        elements.append(.gridLine(
            start: CGPoint(x: thirdX * 2, y: 0),
            end: CGPoint(x: thirdX * 2, y: imageSize.height),
            type: .ruleOfThirds
        ))
        
        // Horizontal lines
        elements.append(.gridLine(
            start: CGPoint(x: 0, y: thirdY),
            end: CGPoint(x: imageSize.width, y: thirdY),
            type: .ruleOfThirds
        ))
        elements.append(.gridLine(
            start: CGPoint(x: 0, y: thirdY * 2),
            end: CGPoint(x: imageSize.width, y: thirdY * 2),
            type: .ruleOfThirds
        ))
        
        return elements
    }
    
    private func calculateLineLength(points: [CGPoint]) -> CGFloat {
        guard let first = points.first, let last = points.last else { return 0 }
        return hypot(last.x - first.x, last.y - first.y)
    }
    
    private func calculateStraightness(points: [CGPoint]) -> Float {
        guard points.count >= 2, let first = points.first, let last = points.last else { return 0 }
        
        let directDistance = hypot(last.x - first.x, last.y - first.y)
        
        var totalDistance: CGFloat = 0
        for i in 1..<points.count {
            totalDistance += hypot(points[i].x - points[i-1].x, points[i].y - points[i-1].y)
        }
        
        return Float(directDistance / totalDistance)
    }
    
    private func calculateLineAngle(start: CGPoint, end: CGPoint) -> CGFloat {
        let dx = end.x - start.x
        let dy = end.y - start.y
        return atan2(dy, dx) * 180 / .pi
    }
    
    private func addLandscapeCompositionIndicators(imageSize: CGSize, overlayElements: inout [OverlayElement]) {
        let thirdX = imageSize.width / 3
        let thirdY = imageSize.height / 3
        
        // Add suggestion hotspots at rule of thirds intersections
        let intersectionPoints = [
            CGPoint(x: thirdX, y: thirdY),
            CGPoint(x: thirdX * 2, y: thirdY),
            CGPoint(x: thirdX, y: thirdY * 2),
            CGPoint(x: thirdX * 2, y: thirdY * 2)
        ]
        
        for (index, point) in intersectionPoints.enumerated() {
            overlayElements.append(.hotspot(
                center: point,
                radius: 15,
                label: "Focal Point \(index + 1)"
            ))
        }
        
        // Add suggestion for horizon placement
        overlayElements.append(.arrow(
            start: CGPoint(x: 0, y: thirdY),
            end: CGPoint(x: imageSize.width * 0.3, y: thirdY),
            label: "Upper horizon"
        ))
        
        overlayElements.append(.arrow(
            start: CGPoint(x: 0, y: thirdY * 2),
            end: CGPoint(x: imageSize.width * 0.3, y: thirdY * 2),
            label: "Lower horizon"
        ))
    }
}

// Deduplicate hotspots with similar centers (within 10px)
func dedupHotspots(_ elements: [OverlayElement]) -> [OverlayElement] {
    var seenKeys = Set<String>()
    var result: [OverlayElement] = []
    let bucketSize: CGFloat = 10.0
    
    for element in elements {
        switch element {
        case .hotspot(let center, let radius, let label):
            let key = "\(Int(center.x / bucketSize))_\(Int(center.y / bucketSize))"
            if !seenKeys.contains(key) {
                seenKeys.insert(key)
                result.append(.hotspot(center: center, radius: radius, label: label))
            }
        default:
            result.append(element)
        }
    }
    return result
}

// MARK: - Error Types
enum AnalysisError: LocalizedError {
    case invalidImage
    case processingFailed
    case simulatorLimitation
    
    var errorDescription: String? {
        switch self {
        case .invalidImage:
            return "Unable to process the image. Please try another photo."
        case .processingFailed:
            return "Failed to analyze the image composition."
        case .simulatorLimitation:
            return "Vision framework requires a physical device. Please test on an iPhone or iPad for full functionality."
        }
    }
} 
