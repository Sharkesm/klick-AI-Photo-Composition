//
//  DynamicCompositionMatcher.swift
//  Klick
//
//  Created by AI Assistant on 12/07/2025.
//

import UIKit
import CoreGraphics

class DynamicCompositionMatcher {
    
    struct CompositionMatch {
        let rule: CompositionRule
        let confidence: Float
        let dynamicPoints: [CGPoint]
        let dynamicLines: [DynamicLine]
        let recommendation: String
        let improvementSuggestion: String
    }
    
    struct DynamicLine {
        let start: CGPoint
        let end: CGPoint
        let type: LineType
        let label: String
        
        enum LineType {
            case grid
            case leading
            case horizon
            case framing
            case diagonal
        }
    }
    
    struct CompositionRecommendation {
        let primaryComposition: CompositionRule
        let matches: [CompositionMatch]
        let dynamicGrid: DynamicGrid
        let suggestedAdjustments: [Adjustment]
        let overallScore: Float
    }
    
    struct DynamicGrid {
        let verticalLines: [CGFloat]  // X positions
        let horizontalLines: [CGFloat] // Y positions
        let intersectionPoints: [CGPoint]
        let type: GridType
        
        enum GridType {
            case ruleOfThirds
            case goldenRatio
            case dynamic
            case diagonal
        }
    }
    
    struct Adjustment {
        let type: AdjustmentType
        let description: String
        let visualGuide: CGRect?
        
        enum AdjustmentType {
            case reframe
            case rotate
            case moveSubject
            case changeAngle
        }
    }
    
    private let imageProcessor = AdvancedImageProcessor()
    private let angleDetector = ImageAngleDetector()
    private let leadingLinesDetector = DynamicLeadingLinesDetector()
    
    // MARK: - Main Matching
    
    func analyzeAndMatchComposition(image: UIImage) async -> CompositionRecommendation {
        print("🎨 Starting dynamic composition analysis...")
        
        // Step 1: Preprocess and analyze image
        let histogramData = await imageProcessor.analyzeHistogram(image)
        let angleAnalysis = angleDetector.analyzeImageAngle(image)
        let leadingLinesAnalysis = await leadingLinesDetector.detectLeadingLines(in: image)
        let salientRegions = imageProcessor.detectSalientRegions(image)
        
        print("📊 Histogram: \(histogramData.distribution.description)")
        print("📐 Dominant angle: \(angleAnalysis.dominantAngle)°")
        print("📍 Leading lines found: \(leadingLinesAnalysis.detectedLines.count)")
        print("🎯 Salient regions: \(salientRegions.count)")
        
        // Step 2: Create dynamic grid based on detected features
        let dynamicGrid = createDynamicGrid(
            imageSize: image.size,
            angleAnalysis: angleAnalysis,
            leadingLines: leadingLinesAnalysis,
            salientRegions: salientRegions
        )
        
        // Step 3: Match compositions based on analysis
        var matches: [CompositionMatch] = []
        
        // Rule of Thirds matching
        if let ruleOfThirdsMatch = matchRuleOfThirds(
            dynamicGrid: dynamicGrid,
            salientRegions: salientRegions,
            imageSize: image.size
        ) {
            matches.append(ruleOfThirdsMatch)
        }
        
        // Leading Lines matching
        if let leadingLinesMatch = matchLeadingLines(
            leadingLinesAnalysis: leadingLinesAnalysis,
            imageSize: image.size
        ) {
            matches.append(leadingLinesMatch)
        }
        
        // Symmetry matching
        if let symmetryMatch = matchSymmetry(
            angleAnalysis: angleAnalysis,
            salientRegions: salientRegions,
            imageSize: image.size
        ) {
            matches.append(symmetryMatch)
        }
        
        // Framing matching
        if let framingMatch = matchFraming(
            histogram: histogramData,
            salientRegions: salientRegions,
            imageSize: image.size
        ) {
            matches.append(framingMatch)
        }
        
        // Diagonal matching
        if let diagonalMatch = matchDiagonals(
            leadingLines: leadingLinesAnalysis,
            angleAnalysis: angleAnalysis,
            imageSize: image.size
        ) {
            matches.append(diagonalMatch)
        }
        
        // Step 4: Determine primary composition
        let primaryComposition = determinePrimaryComposition(from: matches)
        
        // Step 5: Generate adjustments
        let adjustments = generateAdjustments(
            matches: matches,
            angleAnalysis: angleAnalysis,
            salientRegions: salientRegions,
            imageSize: image.size
        )
        
        // Step 6: Calculate overall score
        let overallScore = calculateOverallScore(matches: matches)
        
        return CompositionRecommendation(
            primaryComposition: primaryComposition,
            matches: matches,
            dynamicGrid: dynamicGrid,
            suggestedAdjustments: adjustments,
            overallScore: overallScore
        )
    }
    
    // MARK: - Dynamic Grid Creation
    
    private func createDynamicGrid(
        imageSize: CGSize,
        angleAnalysis: ImageAngleDetector.AngleAnalysis,
        leadingLines: DynamicLeadingLinesDetector.LeadingLinesAnalysis,
        salientRegions: [CGRect]
    ) -> DynamicGrid {
        
        // Start with rule of thirds as base
        var verticalLines: [CGFloat] = [
            imageSize.width / 3,
            imageSize.width * 2 / 3
        ]
        var horizontalLines: [CGFloat] = [
            imageSize.height / 3,
            imageSize.height * 2 / 3
        ]
        
        // Adjust based on horizon detection
        if let horizonAngle = angleAnalysis.horizonAngle {
            let horizonY = imageSize.height * 0.5 + tan(horizonAngle * .pi / 180) * imageSize.width / 2
            if horizonY > imageSize.height * 0.2 && horizonY < imageSize.height * 0.8 {
                // Replace nearest horizontal line with horizon
                if abs(horizonY - horizontalLines[0]) < abs(horizonY - horizontalLines[1]) {
                    horizontalLines[0] = horizonY
                } else {
                    horizontalLines[1] = horizonY
                }
            }
        }
        
        // Adjust based on strong vertical lines
        for line in angleAnalysis.verticalLines.prefix(2) {
            let lineX = (line.start.x + line.end.x) / 2
            if lineX > imageSize.width * 0.2 && lineX < imageSize.width * 0.8 {
                // Replace nearest vertical line
                if verticalLines.isEmpty {
                    verticalLines.append(lineX)
                } else if abs(lineX - verticalLines[0]) < abs(lineX - verticalLines.last!) {
                    verticalLines[0] = lineX
                } else {
                    verticalLines[verticalLines.count - 1] = lineX
                }
            }
        }
        
        // Calculate intersection points
        var intersectionPoints: [CGPoint] = []
        for vLine in verticalLines {
            for hLine in horizontalLines {
                intersectionPoints.append(CGPoint(x: vLine, y: hLine))
            }
        }
        
        // Add focal points from leading lines
        intersectionPoints.append(contentsOf: leadingLines.suggestedFocalPoints)
        
        let gridType: DynamicGrid.GridType = leadingLines.hasStrongLeadingLines ? .dynamic : .ruleOfThirds
        
        return DynamicGrid(
            verticalLines: verticalLines,
            horizontalLines: horizontalLines,
            intersectionPoints: intersectionPoints,
            type: gridType
        )
    }
    
    // MARK: - Composition Matching
    
    private func matchRuleOfThirds(
        dynamicGrid: DynamicGrid,
        salientRegions: [CGRect],
        imageSize: CGSize
    ) -> CompositionMatch? {
        
        var confidence: Float = 0
        var dynamicPoints: [CGPoint] = []
        var dynamicLines: [DynamicLine] = []
        
        // Check if salient regions align with grid intersections
        for region in salientRegions {
            let regionCenter = CGPoint(
                x: region.midX,
                y: region.midY
            )
            
            for point in dynamicGrid.intersectionPoints {
                let distance = hypot(regionCenter.x - point.x, regionCenter.y - point.y)
                let threshold = min(imageSize.width, imageSize.height) * 0.1
                
                if distance < threshold {
                    confidence += 0.3
                    dynamicPoints.append(point)
                }
            }
        }
        
        // Add grid lines
        for vLine in dynamicGrid.verticalLines {
            dynamicLines.append(DynamicLine(
                start: CGPoint(x: vLine, y: 0),
                end: CGPoint(x: vLine, y: imageSize.height),
                type: .grid,
                label: "Vertical Third"
            ))
        }
        
        for hLine in dynamicGrid.horizontalLines {
            dynamicLines.append(DynamicLine(
                start: CGPoint(x: 0, y: hLine),
                end: CGPoint(x: imageSize.width, y: hLine),
                type: .grid,
                label: "Horizontal Third"
            ))
        }
        
        confidence = min(confidence, 1.0)
        
        guard confidence > 0.2 else { return nil }
        
        return CompositionMatch(
            rule: .ruleOfThirds,
            confidence: confidence,
            dynamicPoints: dynamicPoints,
            dynamicLines: dynamicLines,
            recommendation: "Your image shows good use of the rule of thirds with subjects near key intersection points.",
            improvementSuggestion: "Try aligning your main subject more precisely with the grid intersections for stronger composition."
        )
    }
    
    private func matchLeadingLines(
        leadingLinesAnalysis: DynamicLeadingLinesDetector.LeadingLinesAnalysis,
        imageSize: CGSize
    ) -> CompositionMatch? {
        
        guard leadingLinesAnalysis.hasStrongLeadingLines else { return nil }
        
        var dynamicLines: [DynamicLine] = []
        var dynamicPoints: [CGPoint] = leadingLinesAnalysis.convergencePoints
        
        // Convert detected lines to dynamic lines
        for (index, line) in leadingLinesAnalysis.detectedLines.prefix(5).enumerated() {
            guard let start = line.points.first,
                  let end = line.points.last else { continue }
            
            dynamicLines.append(DynamicLine(
                start: start,
                end: end,
                type: .leading,
                label: "Leading Line \(index + 1)"
            ))
        }
        
        let confidence = min(Float(leadingLinesAnalysis.detectedLines.count) / 3.0, 1.0)
        
        return CompositionMatch(
            rule: .leadingLines,
            confidence: confidence,
            dynamicPoints: dynamicPoints,
            dynamicLines: dynamicLines,
            recommendation: "Strong leading lines detected that guide the viewer's eye through your composition.",
            improvementSuggestion: "Ensure your leading lines direct attention to your main subject or point of interest."
        )
    }
    
    private func matchSymmetry(
        angleAnalysis: ImageAngleDetector.AngleAnalysis,
        salientRegions: [CGRect],
        imageSize: CGSize
    ) -> CompositionMatch? {
        
        let centerX = imageSize.width / 2
        var confidence: Float = 0
        var dynamicLines: [DynamicLine] = []
        
        // Check vertical symmetry
        var leftWeight: CGFloat = 0
        var rightWeight: CGFloat = 0
        
        for region in salientRegions {
            if region.midX < centerX {
                leftWeight += region.width * region.height
            } else {
                rightWeight += region.width * region.height
            }
        }
        
        let balance = 1.0 - abs(leftWeight - rightWeight) / (leftWeight + rightWeight + 0.001)
        confidence = Float(balance)
        
        // Add center line
        dynamicLines.append(DynamicLine(
            start: CGPoint(x: centerX, y: 0),
            end: CGPoint(x: centerX, y: imageSize.height),
            type: .grid,
            label: "Center Line"
        ))
        
        guard confidence > 0.3 else { return nil }
        
        return CompositionMatch(
            rule: .symmetry,
            confidence: confidence,
            dynamicPoints: [CGPoint(x: centerX, y: imageSize.height / 2)],
            dynamicLines: dynamicLines,
            recommendation: "Your image shows \(confidence > 0.7 ? "strong" : "moderate") symmetrical balance.",
            improvementSuggestion: "Perfect symmetry can be powerful for architectural and portrait photography."
        )
    }
    
    private func matchFraming(
        histogram: HistogramData,
        salientRegions: [CGRect],
        imageSize: CGSize
    ) -> CompositionMatch? {
        
        // Check for dark edges that might indicate natural framing
        let edgeThickness = imageSize.width * 0.1
        var framingScore: Float = 0
        var dynamicLines: [DynamicLine] = []
        
        // Simple framing detection based on histogram
        if histogram.distribution == .highContrast {
            framingScore += 0.3
        }
        
        // Check if salient regions are centered with space around
        if let mainRegion = salientRegions.first {
            let marginRatio = min(
                mainRegion.minX / imageSize.width,
                mainRegion.minY / imageSize.height,
                (imageSize.width - mainRegion.maxX) / imageSize.width,
                (imageSize.height - mainRegion.maxY) / imageSize.height
            )
            
            if marginRatio > 0.1 {
                framingScore += Float(marginRatio)
                
                // Add framing lines
                dynamicLines.append(DynamicLine(
                    start: CGPoint(x: mainRegion.minX, y: mainRegion.minY),
                    end: CGPoint(x: mainRegion.maxX, y: mainRegion.minY),
                    type: .framing,
                    label: "Frame Top"
                ))
                dynamicLines.append(DynamicLine(
                    start: CGPoint(x: mainRegion.minX, y: mainRegion.maxY),
                    end: CGPoint(x: mainRegion.maxX, y: mainRegion.maxY),
                    type: .framing,
                    label: "Frame Bottom"
                ))
            }
        }
        
        guard framingScore > 0.3 else { return nil }
        
        return CompositionMatch(
            rule: .framing,
            confidence: framingScore,
            dynamicPoints: [],
            dynamicLines: dynamicLines,
            recommendation: "Natural framing elements detected in your composition.",
            improvementSuggestion: "Use darker foreground elements to create stronger framing and add depth."
        )
    }
    
    private func matchDiagonals(
        leadingLines: DynamicLeadingLinesDetector.LeadingLinesAnalysis,
        angleAnalysis: ImageAngleDetector.AngleAnalysis,
        imageSize: CGSize
    ) -> CompositionMatch? {
        
        var diagonalLines: [DynamicLine] = []
        var confidence: Float = 0
        
        // Check for diagonal leading lines
        for line in leadingLines.detectedLines {
            let absAngle = abs(line.angle)
            if absAngle > 20 && absAngle < 70 {
                confidence += line.strength * 0.5
                
                if let start = line.points.first,
                   let end = line.points.last {
                    diagonalLines.append(DynamicLine(
                        start: start,
                        end: end,
                        type: .diagonal,
                        label: "Diagonal"
                    ))
                }
            }
        }
        
        confidence = min(confidence, 1.0)
        guard confidence > 0.3 else { return nil }
        
        return CompositionMatch(
            rule: .diagonals,
            confidence: confidence,
            dynamicPoints: [],
            dynamicLines: diagonalLines,
            recommendation: "Dynamic diagonal lines add energy and movement to your composition.",
            improvementSuggestion: "Diagonal lines from bottom-left to top-right create a sense of growth and positivity."
        )
    }
    
    // MARK: - Helper Methods
    
    private func determinePrimaryComposition(from matches: [CompositionMatch]) -> CompositionRule {
        guard let bestMatch = matches.max(by: { $0.confidence < $1.confidence }) else {
            return .ruleOfThirds
        }
        return bestMatch.rule
    }
    
    private func generateAdjustments(
        matches: [CompositionMatch],
        angleAnalysis: ImageAngleDetector.AngleAnalysis,
        salientRegions: [CGRect],
        imageSize: CGSize
    ) -> [Adjustment] {
        
        var adjustments: [Adjustment] = []
        
        // Rotation adjustment
        if angleAnalysis.shouldStraighten {
            adjustments.append(Adjustment(
                type: .rotate,
                description: "Rotate image by \(String(format: "%.1f", -angleAnalysis.dominantAngle))° to straighten horizon",
                visualGuide: nil
            ))
        }
        
        // Reframing suggestion
        if let mainRegion = salientRegions.first {
            let centerOffset = CGPoint(
                x: mainRegion.midX - imageSize.width / 2,
                y: mainRegion.midY - imageSize.height / 2
            )
            
            if abs(centerOffset.x) > imageSize.width * 0.1 ||
               abs(centerOffset.y) > imageSize.height * 0.1 {
                adjustments.append(Adjustment(
                    type: .reframe,
                    description: "Consider reframing to better position your main subject",
                    visualGuide: mainRegion
                ))
            }
        }
        
        return adjustments
    }
    
    private func calculateOverallScore(matches: [CompositionMatch]) -> Float {
        guard !matches.isEmpty else { return 0.3 }
        
        let totalConfidence = matches.reduce(0) { $0 + $1.confidence }
        let averageConfidence = totalConfidence / Float(matches.count)
        
        // Bonus for multiple composition rules
        let diversityBonus = Float(matches.count) * 0.1
        
        return min(averageConfidence + diversityBonus, 1.0)
    }
} 
