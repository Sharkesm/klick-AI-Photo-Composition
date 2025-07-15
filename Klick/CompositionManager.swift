import SwiftUI
import Vision
import Combine

// MARK: - Composition Manager

class CompositionManager: ObservableObject {
    @Published var currentCompositionType: CompositionType = .ruleOfThirds
    @Published var isEnabled = true
    @Published var lastResult: CompositionResult?
    
    // Available composition services
    private let ruleOfThirdsService = RuleOfThirdsService()
    private let centerFramingService = CenterFramingService()
    
    // Current active service
    private var currentService: CompositionService {
        switch currentCompositionType {
        case .ruleOfThirds:
            return ruleOfThirdsService
        case .centerFraming:
            return centerFramingService
        case .symmetry:
            return centerFramingService // Symmetry is handled within center framing
        }
    }
    
    // All available services
    var availableServices: [CompositionService] {
        [ruleOfThirdsService, centerFramingService]
    }
    
    // MARK: - Public Methods
    
    /// Evaluate composition for a detected subject
    /// - Parameters:
    ///   - observation: The detected subject (face or human)
    ///   - frameSize: The size of the camera frame
    ///   - pixelBuffer: The current frame's pixel buffer for advanced analysis
    /// - Returns: Composition result with feedback and overlay data
    func evaluate(observation: VNDetectedObjectObservation, frameSize: CGSize, pixelBuffer: CVPixelBuffer?) -> CompositionResult {
        guard isEnabled else {
            return CompositionResult(
                isWellComposed: false,
                feedbackMessage: "Composition analysis disabled",
                overlayElements: [],
                score: 0.0,
                compositionType: currentCompositionType
            )
        }
        
        let result = currentService.evaluate(
            observation: observation,
            frameSize: frameSize,
            pixelBuffer: pixelBuffer
        )
        
        lastResult = result
        return result
    }
    
    /// Get basic overlay elements for the current composition type (shown even without subject)
    func getBasicOverlays(frameSize: CGSize) -> [OverlayElement] {
        guard isEnabled else { return [] }
        
        switch currentCompositionType {
        case .ruleOfThirds:
            return [ruleOfThirdsService.createGridOverlay(frameSize: frameSize)]
        case .centerFraming, .symmetry:
            return [centerFramingService.createCenterCrosshair(frameSize: frameSize)]
        }
    }
    
    /// Switch to a different composition type
    /// - Parameter type: The new composition type to use
    func switchToCompositionType(_ type: CompositionType) {
        currentCompositionType = type
        lastResult = nil // Clear previous result when switching
    }
    
    /// Toggle composition analysis on/off
    func toggleEnabled() {
        isEnabled.toggle()
        if !isEnabled {
            lastResult = nil
        }
    }
    
    /// Get the current service name
    var currentServiceName: String {
        currentService.name
    }
    
    /// Get all available composition types
    var availableCompositionTypes: [CompositionType] {
        CompositionType.allCases
    }
    
    /// Check if a specific composition type is available
    /// - Parameter type: The composition type to check
    /// - Returns: Whether the composition type is available
    func isCompositionTypeAvailable(_ type: CompositionType) -> Bool {
        switch type {
        case .ruleOfThirds, .centerFraming, .symmetry:
            return true
        }
    }
    
    /// Get the best composition suggestion for the current frame
    /// - Parameters:
    ///   - observation: The detected subject
    ///   - frameSize: The frame size
    ///   - pixelBuffer: The pixel buffer for analysis
    /// - Returns: The composition type with the highest score
    func getBestCompositionSuggestion(
        observation: VNDetectedObjectObservation,
        frameSize: CGSize,
        pixelBuffer: CVPixelBuffer?
    ) -> CompositionType {
        var bestType = CompositionType.ruleOfThirds
        var bestScore = 0.0
        
        for service in availableServices {
            let result = service.evaluate(
                observation: observation,
                frameSize: frameSize,
                pixelBuffer: pixelBuffer
            )
            
            if result.score > bestScore {
                bestScore = result.score
                bestType = result.compositionType
            }
        }
        
        return bestType
    }
    
    /// Get composition scores for all available types
    /// - Parameters:
    ///   - observation: The detected subject
    ///   - frameSize: The frame size
    ///   - pixelBuffer: The pixel buffer for analysis
    /// - Returns: Dictionary of composition types and their scores
    func getAllCompositionScores(
        observation: VNDetectedObjectObservation,
        frameSize: CGSize,
        pixelBuffer: CVPixelBuffer?
    ) -> [CompositionType: Double] {
        var scores: [CompositionType: Double] = [:]
        
        for service in availableServices {
            let result = service.evaluate(
                observation: observation,
                frameSize: frameSize,
                pixelBuffer: pixelBuffer
            )
            scores[result.compositionType] = result.score
        }
        
        return scores
    }
} 