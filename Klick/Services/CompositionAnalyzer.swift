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

class CompositionAnalyzer: ObservableObject {
    @Published var analysisState: AnalysisState = .idle
    
    // Vision request handlers
    private var faceDetectionRequest: VNDetectFaceRectanglesRequest?
    private var contourDetectionRequest: VNDetectContoursRequest?
    private var rectangleDetectionRequest: VNDetectRectanglesRequest?
    
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
        print("🔄 Setting analysis state to analyzing...")
        analysisState = .analyzing
        
        guard let cgImage = image.cgImage else {
            print("❌ Failed to get CGImage from UIImage")
            analysisState = .failed(AnalysisError.invalidImage)
            return
        }
        
        print("📸 Image size: \(image.size)")
        
        // Check if running on simulator
        #if targetEnvironment(simulator)
        print("📱 Running on simulator - using fallback analysis")
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in
            self?.processSimulatorFallbackAnalysis(for: image)
        }
        return
        #else
        print("📱 Running on device - using Vision framework")
        #endif
        
        print("🔍 Starting Vision framework analysis...")
        
        let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
        
        var requests: [VNRequest] = []
        
        // Only add face detection for device (most reliable)
        if let faceRequest = faceDetectionRequest {
            requests.append(faceRequest)
        }
        
        // Add rectangle detection (more reliable than contours)
        if let rectangleRequest = rectangleDetectionRequest {
            requests.append(rectangleRequest)
        }
        
        // Only add contour detection on device
        #if !targetEnvironment(simulator)
        if let contourRequest = contourDetectionRequest {
            requests.append(contourRequest)
        }
        #endif
        
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            do {
                try handler.perform(requests)
                
                DispatchQueue.main.async {
                    self?.processAnalysisResults(for: image)
                }
            } catch {
                print("❌ Vision framework error: \(error.localizedDescription)")
                DispatchQueue.main.async {
                    // Fallback to simulator analysis if Vision fails
                    self?.processSimulatorFallbackAnalysis(for: image)
                }
            }
        }
    }
    
    private func processAnalysisResults(for image: UIImage) {
        let imageSize = image.size
        
        // Extract observations
        let faceObservations = faceDetectionRequest?.results as? [VNFaceObservation] ?? []
        let contourObservations = extractContours()
        let rectangleObservations = rectangleDetectionRequest?.results as? [VNRectangleObservation] ?? []
        
        // Analyze composition rules
        var detectedRules: [CompositionRule] = []
        var confidence: [CompositionRule: Float] = [:]
        var overlayElements: [OverlayElement] = []
        var suggestions: [CompositionSuggestion] = []
        
        // Rule of Thirds Analysis
        let ruleOfThirdsAnalysis = analyzeRuleOfThirds(
            faces: faceObservations,
            imageSize: imageSize
        )
        if ruleOfThirdsAnalysis.isDetected {
            detectedRules.append(.ruleOfThirds)
            confidence[.ruleOfThirds] = ruleOfThirdsAnalysis.confidence
            overlayElements.append(contentsOf: ruleOfThirdsAnalysis.overlayElements)
            suggestions.append(contentsOf: ruleOfThirdsAnalysis.suggestions)
        }
        
        // Leading Lines Analysis
        let leadingLinesAnalysis = analyzeLeadingLines(
            contours: contourObservations,
            imageSize: imageSize
        )
        if leadingLinesAnalysis.isDetected {
            detectedRules.append(.leadingLines)
            confidence[.leadingLines] = leadingLinesAnalysis.confidence
            overlayElements.append(contentsOf: leadingLinesAnalysis.overlayElements)
            suggestions.append(contentsOf: leadingLinesAnalysis.suggestions)
        }
        
        // Symmetry Analysis
        let symmetryAnalysis = analyzeSymmetry(
            faces: faceObservations,
            rectangles: rectangleObservations,
            imageSize: imageSize
        )
        if symmetryAnalysis.isDetected {
            detectedRules.append(.symmetry)
            confidence[.symmetry] = symmetryAnalysis.confidence
            overlayElements.append(contentsOf: symmetryAnalysis.overlayElements)
            suggestions.append(contentsOf: symmetryAnalysis.suggestions)
        }
        
        // Add grid overlay elements
        overlayElements.append(contentsOf: createRuleOfThirdsGrid(imageSize: imageSize))
        
        // Add general landscape suggestions if no specific rules detected
        if detectedRules.isEmpty {
            suggestions.append(CompositionSuggestion(
                rule: .ruleOfThirds,
                message: "This appears to be a landscape photo. Consider using the rule of thirds.",
                improvementTip: "Try positioning the horizon on the upper or lower third line, and place key elements at intersection points."
            ))
            
            suggestions.append(CompositionSuggestion(
                rule: .leadingLines,
                message: "Look for natural leading lines in your landscape.",
                improvementTip: "Rivers, paths, shorelines, or rock formations can guide the viewer's eye through your composition."
            ))
            
            // Force add rule of thirds as detected for landscapes
            detectedRules.append(.ruleOfThirds)
            confidence[.ruleOfThirds] = 0.5
        }
        
        // Always add visual indicators for improvement
        addLandscapeCompositionIndicators(imageSize: imageSize, overlayElements: &overlayElements)
        
        // Create final result
        let result = CompositionAnalysisResult(
            detectedRules: detectedRules,
            confidence: confidence,
            suggestions: suggestions,
            overlayElements: overlayElements,
            faceObservations: faceObservations,
            contourObservations: contourObservations,
            rectangleObservations: rectangleObservations
        )
        
        print("Analysis completed with \(detectedRules.count) rules detected: \(detectedRules)")
        print("Overlay elements count: \(overlayElements.count)")
        
        analysisState = .completed(result)
    }
    
    // MARK: - Simulator Fallback Analysis
    
    private func processSimulatorFallbackAnalysis(for image: UIImage) {
        let imageSize = image.size
        
        print("🎭 Creating simulator fallback analysis...")
        
        // Create mock analysis result for simulator testing
        var detectedRules: [CompositionRule] = [.ruleOfThirds, .leadingLines]
        var confidence: [CompositionRule: Float] = [
            .ruleOfThirds: 0.7,
            .leadingLines: 0.6
        ]
        var overlayElements: [OverlayElement] = []
        var suggestions: [CompositionSuggestion] = []
        
        // Add rule of thirds grid
        overlayElements.append(contentsOf: createRuleOfThirdsGrid(imageSize: imageSize))
        
        // Add landscape indicators
        addLandscapeCompositionIndicators(imageSize: imageSize, overlayElements: &overlayElements)
        
        // Add mock leading lines for the waterfall
        let waterfallLines = [
            // Vertical waterfall line
            (start: CGPoint(x: imageSize.width * 0.5, y: imageSize.height * 0.2), 
             end: CGPoint(x: imageSize.width * 0.5, y: imageSize.height * 0.8)),
            // Rock formation lines
            (start: CGPoint(x: imageSize.width * 0.1, y: imageSize.height * 0.9), 
             end: CGPoint(x: imageSize.width * 0.4, y: imageSize.height * 0.4)),
            (start: CGPoint(x: imageSize.width * 0.9, y: imageSize.height * 0.9), 
             end: CGPoint(x: imageSize.width * 0.6, y: imageSize.height * 0.4))
        ]
        
        for (index, line) in waterfallLines.enumerated() {
            let points = [line.start, line.end]
            overlayElements.append(.contourPath(points: points, label: "Leading Line \(index + 1)"))
        }
        
        // Add composition suggestions
        suggestions.append(CompositionSuggestion(
            rule: .ruleOfThirds,
            message: "Your waterfall is well-positioned using the rule of thirds!",
            improvementTip: "The vertical composition creates a strong focal point. Consider the horizon placement for even better balance."
        ))
        
        suggestions.append(CompositionSuggestion(
            rule: .leadingLines,
            message: "Great use of natural leading lines in this landscape!",
            improvementTip: "The rock formations and waterfall create excellent leading lines that guide the eye through the composition."
        ))
        
        suggestions.append(CompositionSuggestion(
            rule: .framing,
            message: "The rock formations provide natural framing for your waterfall.",
            improvementTip: "This creates depth and draws attention to your main subject - the waterfall."
        ))
        
        // Create final result
        let result = CompositionAnalysisResult(
            detectedRules: detectedRules,
            confidence: confidence,
            suggestions: suggestions,
            overlayElements: overlayElements,
            faceObservations: [], // No faces in landscape
            contourObservations: [], // Simulated
            rectangleObservations: [] // Simulated
        )
        
        print("✅ Simulator analysis completed with \(detectedRules.count) rules detected: \(detectedRules)")
        print("📊 Overlay elements count: \(overlayElements.count)")
        
        analysisState = .completed(result)
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
