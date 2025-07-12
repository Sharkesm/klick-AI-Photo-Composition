//
//  CompositionModels.swift
//  Klick
//
//  Created by AI Assistant on 12/07/2025.
//

import Foundation
import CoreGraphics
import Vision

// MARK: - Composition Rules
enum CompositionRule: String, CaseIterable {
    case ruleOfThirds = "Rule of Thirds"
    case leadingLines = "Leading Lines"
    case symmetry = "Symmetry"
    case framing = "Framing"
    case goldenRatio = "Golden Ratio"
    case diagonals = "Diagonals"
    case patterns = "Patterns"
    case fillTheFrame = "Fill the Frame"
    
    var description: String {
        switch self {
        case .ruleOfThirds:
            return "Place key elements along lines dividing the image into thirds or at their intersections for a balanced composition."
        case .leadingLines:
            return "Use natural lines to guide the viewer's eye toward your subject or through the image."
        case .symmetry:
            return "Create balance by arranging elements equally on both sides of the image."
        case .framing:
            return "Use foreground elements to frame your subject and add depth."
        case .goldenRatio:
            return "Position elements along the golden spiral for naturally pleasing proportions."
        case .diagonals:
            return "Use diagonal lines to create dynamic tension and movement."
        case .patterns:
            return "Look for repeating elements to create visual rhythm."
        case .fillTheFrame:
            return "Get close to your subject to eliminate distractions and create impact."
        }
    }
    
    var icon: String {
        switch self {
        case .ruleOfThirds: return "grid"
        case .leadingLines: return "arrow.up.right"
        case .symmetry: return "square.on.square"
        case .framing: return "rectangle.inset.filled"
        case .goldenRatio: return "spiral"
        case .diagonals: return "slash.circle"
        case .patterns: return "square.grid.3x3"
        case .fillTheFrame: return "viewfinder"
        }
    }
}

// MARK: - Analysis Results
struct CompositionAnalysisResult {
    let detectedRules: [CompositionRule]
    let confidence: [CompositionRule: Float]
    let suggestions: [CompositionSuggestion]
    let overlayElements: [OverlayElement]
    let faceObservations: [VNFaceObservation]
    let contourObservations: [VNContour]
    let rectangleObservations: [VNRectangleObservation]
}

struct CompositionSuggestion {
    let rule: CompositionRule
    let message: String
    let improvementTip: String
}

// MARK: - Overlay Elements
enum OverlayElement {
    case gridLine(start: CGPoint, end: CGPoint, type: GridType)
    case boundingBox(rect: CGRect, label: String, color: String)
    case contourPath(points: [CGPoint], label: String)
    case hotspot(center: CGPoint, radius: CGFloat, label: String)
    case arrow(start: CGPoint, end: CGPoint, label: String)
    
    enum GridType {
        case ruleOfThirds
        case goldenRatio
        case diagonal
    }
}

// MARK: - Image Analysis State
enum AnalysisState {
    case idle
    case analyzing
    case completed(CompositionAnalysisResult)
    case failed(Error)
}

// MARK: - Composition Strength
enum CompositionStrength: String {
    case strong = "Strong"
    case moderate = "Moderate"
    case weak = "Weak"
    case notDetected = "Not Detected"
    
    var color: String {
        switch self {
        case .strong: return "green"
        case .moderate: return "yellow"
        case .weak: return "orange"
        case .notDetected: return "gray"
        }
    }
}

// MARK: - Educational Content
struct CompositionLesson {
    let rule: CompositionRule
    let title: String
    let overview: String
    let examples: [String]
    let exercises: [String]
    let tips: [String]
} 