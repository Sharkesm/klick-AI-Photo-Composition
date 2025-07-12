//
//  DynamicLeadingLinesDetector.swift
//  Klick
//
//  Created by AI Assistant on 12/07/2025.
//

import UIKit
import CoreGraphics

class DynamicLeadingLinesDetector {
    
    struct LeadingLine {
        let points: [CGPoint]
        let strength: Float
        let angle: CGFloat
        let type: LineType
        let convergencePoint: CGPoint?
        
        enum LineType {
            case diagonal
            case vertical
            case horizontal
            case curved
            case converging
        }
    }
    
    struct LeadingLinesAnalysis {
        let detectedLines: [LeadingLine]
        let convergencePoints: [CGPoint]
        let dominantDirection: CGVector
        let hasStrongLeadingLines: Bool
        let suggestedFocalPoints: [CGPoint]
    }
    
    private let imageProcessor = AdvancedImageProcessor()
    
    // MARK: - Main Detection
    
    func detectLeadingLines(in image: UIImage) async -> LeadingLinesAnalysis {
        // Step 1: Preprocess image (use cached versions if available)
        guard let grayscaleImage = imageProcessor.convertToGrayscale(image),
              let enhancedImage = imageProcessor.enhanceContrast(grayscaleImage, amount: 1.8) else {
            return LeadingLinesAnalysis(
                detectedLines: [],
                convergencePoints: [],
                dominantDirection: .zero,
                hasStrongLeadingLines: false,
                suggestedFocalPoints: []
            )
        }
        
        // Step 2: Detect edges (use cached Sobel results)
        let edgeResults = await imageProcessor.applySobelFilter(enhancedImage)
        
        // Step 3: Extract line segments from edges concurrently
        var detectedLines: [LeadingLine] = []
        
        // Process all edge types concurrently if available
        async let horizontalLines = extractLines(from: edgeResults.horizontal, orientation: .horizontal)
        async let verticalLines = extractLines(from: edgeResults.vertical, orientation: .vertical)
        async let diagonalLines = extractDiagonalLines(from: edgeResults.magnitude)
        
        let (horizontal, vertical, diagonal) = await (horizontalLines, verticalLines, diagonalLines)
        detectedLines.append(contentsOf: horizontal)
        detectedLines.append(contentsOf: vertical)
        detectedLines.append(contentsOf: diagonal)
        
        // Step 4: Find convergence points
        let convergencePoints = findConvergencePoints(from: detectedLines)
        
        // Step 5: Calculate dominant direction
        let dominantDirection = calculateDominantDirection(from: detectedLines)
        
        // Step 6: Identify focal points
        let suggestedFocalPoints = identifyFocalPoints(
            lines: detectedLines,
            convergencePoints: convergencePoints,
            imageSize: image.size
        )
        
        // Step 7: Determine if strong leading lines exist
        let hasStrongLeadingLines = detectedLines.contains { $0.strength > 0.7 }
        
        return LeadingLinesAnalysis(
            detectedLines: detectedLines,
            convergencePoints: convergencePoints,
            dominantDirection: dominantDirection,
            hasStrongLeadingLines: hasStrongLeadingLines,
            suggestedFocalPoints: suggestedFocalPoints
        )
    }
    
    // MARK: - Line Extraction
    
    private func extractLines(from edgeImage: UIImage?, orientation: Orientation) async -> [LeadingLine] {
        guard let edgeImage = edgeImage else { return [] }
        
        let imageSize = edgeImage.size
        let scanInterval: CGFloat = 20
        
        switch orientation {
        case .horizontal:
            return await extractHorizontalLinesConcurrent(edgeImage: edgeImage, imageSize: imageSize, scanInterval: scanInterval)
        case .vertical:
            return await extractVerticalLinesConcurrent(edgeImage: edgeImage, imageSize: imageSize, scanInterval: scanInterval)
        case .diagonal:
            return []
        }
    }
    
    private func extractHorizontalLinesConcurrent(edgeImage: UIImage, imageSize: CGSize, scanInterval: CGFloat) async -> [LeadingLine] {
        let scanLines = stride(from: scanInterval, to: imageSize.height - scanInterval, by: scanInterval)
        let scanArray = Array(scanLines)
        
        // Process scan lines concurrently
        let lines = await withTaskGroup(of: LeadingLine?.self) { group in
            for y in scanArray {
                group.addTask {
                    let linePoints = self.scanHorizontalLine(at: y, in: edgeImage)
                    return self.createLeadingLine(from: linePoints, orientation: .horizontal)
                }
            }
            
            var results: [LeadingLine] = []
            for await line in group {
                if let line = line {
                    results.append(line)
                }
            }
            return results
        }
        
        return lines
    }
    
    private func extractVerticalLinesConcurrent(edgeImage: UIImage, imageSize: CGSize, scanInterval: CGFloat) async -> [LeadingLine] {
        let scanLines = stride(from: scanInterval, to: imageSize.width - scanInterval, by: scanInterval)
        let scanArray = Array(scanLines)
        
        // Process scan lines concurrently
        let lines = await withTaskGroup(of: LeadingLine?.self) { group in
            for x in scanArray {
                group.addTask {
                    let linePoints = self.scanVerticalLine(at: x, in: edgeImage)
                    return self.createLeadingLine(from: linePoints, orientation: .vertical)
                }
            }
            
            var results: [LeadingLine] = []
            for await line in group {
                if let line = line {
                    results.append(line)
                }
            }
            return results
        }
        
        return lines
    }
    
    private func extractDiagonalLines(from edgeImage: UIImage?) async -> [LeadingLine] {
        guard let edgeImage = edgeImage else { return [] }
        
        let imageSize = edgeImage.size
        let edgeMargin: CGFloat = 50
        
        // Prepare starting points for concurrent processing
        var topEdgePoints: [CGPoint] = []
        var leftEdgePoints: [CGPoint] = []
        
        // Top edge to right edge
        for startX in stride(from: edgeMargin, to: imageSize.width - edgeMargin, by: 50) {
            topEdgePoints.append(CGPoint(x: startX, y: 0))
        }
        
        // Left edge to bottom edge
        for startY in stride(from: edgeMargin, to: imageSize.height - edgeMargin, by: 50) {
            leftEdgePoints.append(CGPoint(x: 0, y: startY))
        }
        
        // Process diagonal lines concurrently
        let lines = await withTaskGroup(of: LeadingLine?.self) { group in
            // Add top edge tasks
            for point in topEdgePoints {
                group.addTask {
                    let points = self.traceDiagonalLine(
                        from: point,
                        direction: CGVector(dx: 1, dy: 1),
                        in: edgeImage
                    )
                    return self.createLeadingLine(from: points, orientation: .diagonal)
                }
            }
            
            // Add left edge tasks
            for point in leftEdgePoints {
                group.addTask {
                    let points = self.traceDiagonalLine(
                        from: point,
                        direction: CGVector(dx: 1, dy: 1),
                        in: edgeImage
                    )
                    return self.createLeadingLine(from: points, orientation: .diagonal)
                }
            }
            
            var results: [LeadingLine] = []
            for await line in group {
                if let line = line {
                    results.append(line)
                }
            }
            return results
        }
        
        return lines
    }
    
    // MARK: - Line Scanning
    
    private func scanHorizontalLine(at y: CGFloat, in image: UIImage) -> [CGPoint] {
        var points: [CGPoint] = []
        let width = image.size.width
        
        // Simplified: Create sample points along horizontal line
        for x in stride(from: 0, to: width, by: 10) {
            points.append(CGPoint(x: x, y: y))
        }
        
        return points
    }
    
    private func scanVerticalLine(at x: CGFloat, in image: UIImage) -> [CGPoint] {
        var points: [CGPoint] = []
        let height = image.size.height
        
        // Simplified: Create sample points along vertical line
        for y in stride(from: 0, to: height, by: 10) {
            points.append(CGPoint(x: x, y: y))
        }
        
        return points
    }
    
    private func traceDiagonalLine(from start: CGPoint, direction: CGVector, in image: UIImage) -> [CGPoint] {
        var points: [CGPoint] = []
        let imageSize = image.size
        
        var current = start
        let step: CGFloat = 10
        
        while current.x >= 0 && current.x < imageSize.width &&
              current.y >= 0 && current.y < imageSize.height {
            points.append(current)
            current.x += direction.dx * step
            current.y += direction.dy * step
        }
        
        return points
    }
    
    // MARK: - Line Creation
    
    private func createLeadingLine(from points: [CGPoint], orientation: Orientation) -> LeadingLine? {
        guard points.count > 5 else { return nil }
        
        let angle = calculateLineAngle(from: points)
        let strength = calculateLineStrength(points: points)
        let type = determineLineType(angle: angle, points: points)
        let convergencePoint = findLineConvergence(points: points)
        
        return LeadingLine(
            points: points,
            strength: strength,
            angle: angle,
            type: type,
            convergencePoint: convergencePoint
        )
    }
    
    private func calculateLineAngle(from points: [CGPoint]) -> CGFloat {
        guard let first = points.first, let last = points.last else { return 0 }
        return atan2(last.y - first.y, last.x - first.x) * 180 / .pi
    }
    
    private func calculateLineStrength(points: [CGPoint]) -> Float {
        // Calculate based on length and continuity
        guard let first = points.first, let last = points.last else { return 0 }
        let length = hypot(last.x - first.x, last.y - first.y)
        
        // Normalize strength based on expected image dimensions
        let normalizedStrength = Float(length / 1000.0)
        return min(normalizedStrength, 1.0)
    }
    
    private func determineLineType(angle: CGFloat, points: [CGPoint]) -> LeadingLine.LineType {
        let absAngle = abs(angle)
        
        if absAngle < 15 || absAngle > 165 {
            return .horizontal
        } else if absAngle > 75 && absAngle < 105 {
            return .vertical
        } else if isCurved(points: points) {
            return .curved
        } else {
            return .diagonal
        }
    }
    
    private func isCurved(points: [CGPoint]) -> Bool {
        guard points.count > 10 else { return false }
        
        // Check if points deviate from a straight line
        guard let first = points.first, let last = points.last else { return false }
        
        let directDistance = hypot(last.x - first.x, last.y - first.y)
        var pathDistance: CGFloat = 0
        
        for i in 1..<points.count {
            pathDistance += hypot(points[i].x - points[i-1].x, points[i].y - points[i-1].y)
        }
        
        // If path is significantly longer than direct distance, it's curved
        return pathDistance > directDistance * 1.1
    }
    
    private func findLineConvergence(points: [CGPoint]) -> CGPoint? {
        // Extend the line and see where it converges
        guard points.count >= 2,
              let first = points.first,
              let last = points.last else { return nil }
        
        let dx = last.x - first.x
        let dy = last.y - first.y
        
        // Extend the line by 2x its length
        let extendedPoint = CGPoint(
            x: last.x + dx * 2,
            y: last.y + dy * 2
        )
        
        return extendedPoint
    }
    
    // MARK: - Convergence Analysis
    
    private func findConvergencePoints(from lines: [LeadingLine]) -> [CGPoint] {
        var convergencePoints: [CGPoint] = []
        
        // Find intersections between lines
        for i in 0..<lines.count {
            for j in (i+1)..<lines.count {
                if let intersection = findIntersection(line1: lines[i], line2: lines[j]) {
                    convergencePoints.append(intersection)
                }
            }
        }
        
        // Cluster nearby convergence points
        return clusterPoints(convergencePoints, threshold: 50)
    }
    
    private func findIntersection(line1: LeadingLine, line2: LeadingLine) -> CGPoint? {
        guard let start1 = line1.points.first, let end1 = line1.points.last,
              let start2 = line2.points.first, let end2 = line2.points.last else {
            return nil
        }
        
        // Line intersection formula
        let x1 = start1.x, y1 = start1.y
        let x2 = end1.x, y2 = end1.y
        let x3 = start2.x, y3 = start2.y
        let x4 = end2.x, y4 = end2.y
        
        let denominator = (x1 - x2) * (y3 - y4) - (y1 - y2) * (x3 - x4)
        
        guard abs(denominator) > 0.001 else { return nil } // Parallel lines
        
        let t = ((x1 - x3) * (y3 - y4) - (y1 - y3) * (x3 - x4)) / denominator
        
        // Check if intersection is within reasonable bounds
        guard t >= -1 && t <= 2 else { return nil }
        
        let intersectionX = x1 + t * (x2 - x1)
        let intersectionY = y1 + t * (y2 - y1)
        
        return CGPoint(x: intersectionX, y: intersectionY)
    }
    
    private func clusterPoints(_ points: [CGPoint], threshold: CGFloat) -> [CGPoint] {
        guard !points.isEmpty else { return [] }
        
        var clusters: [[CGPoint]] = []
        
        for point in points {
            var addedToCluster = false
            
            for i in 0..<clusters.count {
                let clusterCenter = calculateCenter(of: clusters[i])
                let distance = hypot(point.x - clusterCenter.x, point.y - clusterCenter.y)
                
                if distance < threshold {
                    clusters[i].append(point)
                    addedToCluster = true
                    break
                }
            }
            
            if !addedToCluster {
                clusters.append([point])
            }
        }
        
        return clusters.map { calculateCenter(of: $0) }
    }
    
    private func calculateCenter(of points: [CGPoint]) -> CGPoint {
        guard !points.isEmpty else { return .zero }
        
        let sumX = points.reduce(0) { $0 + $1.x }
        let sumY = points.reduce(0) { $0 + $1.y }
        
        return CGPoint(
            x: sumX / CGFloat(points.count),
            y: sumY / CGFloat(points.count)
        )
    }
    
    // MARK: - Direction Analysis
    
    private func calculateDominantDirection(from lines: [LeadingLine]) -> CGVector {
        var totalDx: CGFloat = 0
        var totalDy: CGFloat = 0
        var totalWeight: CGFloat = 0
        
        for line in lines {
            guard let first = line.points.first,
                  let last = line.points.last else { continue }
            
            let dx = last.x - first.x
            let dy = last.y - first.y
            let weight = CGFloat(line.strength)
            
            totalDx += dx * weight
            totalDy += dy * weight
            totalWeight += weight
        }
        
        guard totalWeight > 0 else { return .zero }
        
        return CGVector(
            dx: totalDx / totalWeight,
            dy: totalDy / totalWeight
        )
    }
    
    // MARK: - Focal Point Identification
    
    private func identifyFocalPoints(lines: [LeadingLine], convergencePoints: [CGPoint], imageSize: CGSize) -> [CGPoint] {
        var focalPoints: [CGPoint] = []
        
        // Add convergence points that are within or near the image bounds
        let margin = imageSize.width * 0.2
        for point in convergencePoints {
            if point.x >= -margin && point.x <= imageSize.width + margin &&
               point.y >= -margin && point.y <= imageSize.height + margin {
                focalPoints.append(point)
            }
        }
        
        // Add rule of thirds intersections as potential focal points
        let thirdX = imageSize.width / 3
        let thirdY = imageSize.height / 3
        
        focalPoints.append(contentsOf: [
            CGPoint(x: thirdX, y: thirdY),
            CGPoint(x: thirdX * 2, y: thirdY),
            CGPoint(x: thirdX, y: thirdY * 2),
            CGPoint(x: thirdX * 2, y: thirdY * 2)
        ])
        
        // Remove duplicates and cluster nearby points
        return clusterPoints(focalPoints, threshold: 50)
    }
}

// MARK: - Supporting Types

private enum Orientation {
    case horizontal
    case vertical
    case diagonal
} 
