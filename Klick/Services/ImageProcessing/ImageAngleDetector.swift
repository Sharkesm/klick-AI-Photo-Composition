//
//  ImageAngleDetector.swift
//  Klick
//
//  Created by AI Assistant on 12/07/2025.
//

import UIKit
import CoreGraphics
import Accelerate

class ImageAngleDetector {
    
    struct AngleAnalysis {
        let dominantAngle: CGFloat
        let horizonAngle: CGFloat?
        let verticalLines: [Line]
        let horizontalLines: [Line]
        let confidence: Float
        let shouldStraighten: Bool
    }
    
    struct Line {
        let start: CGPoint
        let end: CGPoint
        let angle: CGFloat
        let strength: Float
        
        var length: CGFloat {
            return hypot(end.x - start.x, end.y - start.y)
        }
    }
    
    // MARK: - Main Analysis
    
    func analyzeImageAngle(_ image: UIImage) -> AngleAnalysis {
        let lines = detectDominantLines(in: image)
        let horizonAngle = detectHorizonAngle(from: lines, imageSize: image.size)
        let dominantAngle = calculateDominantAngle(from: lines)
        
        let (verticalLines, horizontalLines) = categorizeLines(lines)
        
        let confidence = calculateConfidence(
            lines: lines,
            horizonAngle: horizonAngle,
            dominantAngle: dominantAngle
        )
        
        let shouldStraighten = abs(horizonAngle ?? dominantAngle) > 2.0
        
        return AngleAnalysis(
            dominantAngle: dominantAngle,
            horizonAngle: horizonAngle,
            verticalLines: verticalLines,
            horizontalLines: horizontalLines,
            confidence: confidence,
            shouldStraighten: shouldStraighten
        )
    }
    
    // MARK: - Line Detection
    
    private func detectDominantLines(in image: UIImage) -> [Line] {
        // Use Hough transform to detect lines
        // For now, using a simplified approach
        var detectedLines: [Line] = []
        
        let imageSize = image.size
        
        // Detect horizontal-ish lines
        for y in stride(from: imageSize.height * 0.2, to: imageSize.height * 0.8, by: imageSize.height * 0.1) {
            // Sample points across the image
            var strongEdgeCount = 0
            let sampleCount = 10
            
            for x in stride(from: 0, to: imageSize.width, by: imageSize.width / CGFloat(sampleCount)) {
                // Check if there's an edge at this point
                if isEdgePoint(at: CGPoint(x: x, y: y), in: image) {
                    strongEdgeCount += 1
                }
            }
            
            let strength = Float(strongEdgeCount) / Float(sampleCount)
            if strength > 0.3 {
                let line = Line(
                    start: CGPoint(x: 0, y: y),
                    end: CGPoint(x: imageSize.width, y: y),
                    angle: 0,
                    strength: strength
                )
                detectedLines.append(line)
            }
        }
        
        // Detect vertical-ish lines
        for x in stride(from: imageSize.width * 0.2, to: imageSize.width * 0.8, by: imageSize.width * 0.1) {
            var strongEdgeCount = 0
            let sampleCount = 10
            
            for y in stride(from: 0, to: imageSize.height, by: imageSize.height / CGFloat(sampleCount)) {
                if isEdgePoint(at: CGPoint(x: x, y: y), in: image) {
                    strongEdgeCount += 1
                }
            }
            
            let strength = Float(strongEdgeCount) / Float(sampleCount)
            if strength > 0.3 {
                let line = Line(
                    start: CGPoint(x: x, y: 0),
                    end: CGPoint(x: x, y: imageSize.height),
                    angle: 90,
                    strength: strength
                )
                detectedLines.append(line)
            }
        }
        
        // Add diagonal lines detection
        detectedLines.append(contentsOf: detectDiagonalLines(in: image))
        
        return detectedLines
    }
    
    private func detectDiagonalLines(in image: UIImage) -> [Line] {
        var diagonalLines: [Line] = []
        let imageSize = image.size
        
        // Check main diagonals
        let diagonalChecks = [
            (start: CGPoint(x: 0, y: 0), end: CGPoint(x: imageSize.width, y: imageSize.height)),
            (start: CGPoint(x: imageSize.width, y: 0), end: CGPoint(x: 0, y: imageSize.height)),
            (start: CGPoint(x: 0, y: imageSize.height * 0.5), end: CGPoint(x: imageSize.width * 0.5, y: 0)),
            (start: CGPoint(x: imageSize.width * 0.5, y: imageSize.height), end: CGPoint(x: imageSize.width, y: imageSize.height * 0.5))
        ]
        
        for diagonal in diagonalChecks {
            let angle = atan2(diagonal.end.y - diagonal.start.y, diagonal.end.x - diagonal.start.x) * 180 / .pi
            let line = Line(
                start: diagonal.start,
                end: diagonal.end,
                angle: angle,
                strength: 0.5 // Default strength for diagonals
            )
            diagonalLines.append(line)
        }
        
        return diagonalLines
    }
    
    // MARK: - Horizon Detection
    
    private func detectHorizonAngle(from lines: [Line], imageSize: CGSize) -> CGFloat? {
        // Find the strongest horizontal line in the middle third of the image
        let middleThirdStart = imageSize.height * 0.3
        let middleThirdEnd = imageSize.height * 0.7
        
        let horizonCandidates = lines.filter { line in
            let midY = (line.start.y + line.end.y) / 2
            return midY > middleThirdStart && midY < middleThirdEnd &&
                   abs(line.angle) < 15 // Nearly horizontal
        }
        
        guard let strongestHorizon = horizonCandidates.max(by: { $0.strength < $1.strength }) else {
            return nil
        }
        
        // Calculate the angle of the horizon line
        let dx = strongestHorizon.end.x - strongestHorizon.start.x
        let dy = strongestHorizon.end.y - strongestHorizon.start.y
        return atan2(dy, dx) * 180 / .pi
    }
    
    // MARK: - Dominant Angle Calculation
    
    private func calculateDominantAngle(from lines: [Line]) -> CGFloat {
        // Weight lines by their strength and length
        var weightedAngles: CGFloat = 0
        var totalWeight: CGFloat = 0
        
        for line in lines {
            let weight = CGFloat(line.strength) * line.length
            weightedAngles += line.angle * weight
            totalWeight += weight
        }
        
        return totalWeight > 0 ? weightedAngles / totalWeight : 0
    }
    
    // MARK: - Line Categorization
    
    private func categorizeLines(_ lines: [Line]) -> (vertical: [Line], horizontal: [Line]) {
        var vertical: [Line] = []
        var horizontal: [Line] = []
        
        for line in lines {
            let absAngle = abs(line.angle)
            if absAngle < 30 || absAngle > 150 {
                horizontal.append(line)
            } else if absAngle > 60 && absAngle < 120 {
                vertical.append(line)
            }
        }
        
        return (vertical, horizontal)
    }
    
    // MARK: - Confidence Calculation
    
    private func calculateConfidence(lines: [Line], horizonAngle: CGFloat?, dominantAngle: CGFloat) -> Float {
        var confidence: Float = 0.5
        
        // More lines = higher confidence
        confidence += Float(min(lines.count, 20)) / 40.0
        
        // Clear horizon = higher confidence
        if horizonAngle != nil {
            confidence += 0.2
        }
        
        // Small dominant angle = higher confidence (image is already straight)
        if abs(dominantAngle) < 5 {
            confidence += 0.2
        }
        
        return min(confidence, 1.0)
    }
    
    // MARK: - Helper Methods
    
    private func isEdgePoint(at point: CGPoint, in image: UIImage) -> Bool {
        // Simplified edge detection at a point
        // In a real implementation, this would sample the processed edge image
        return arc4random_uniform(100) < 30 // 30% chance for testing
    }
    
    // MARK: - Image Straightening
    
    func straightenImage(_ image: UIImage, by angle: CGFloat) -> UIImage? {
        guard let ciImage = CIImage(image: image) else { return nil }
        
        let radians = -angle * .pi / 180 // Negative to correct the angle
        
        let transform = CGAffineTransform(rotationAngle: radians)
        let rotatedImage = ciImage.transformed(by: transform)
        
        let context = CIContext()
        guard let cgImage = context.createCGImage(rotatedImage, from: rotatedImage.extent) else {
            return nil
        }
        
        return UIImage(cgImage: cgImage)
    }
} 