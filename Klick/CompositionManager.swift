import SwiftUI
import Vision
import Combine

// MARK: - Composition Manager

class CompositionManager: ObservableObject {
    @Published var currentCompositionType: CompositionType = .ruleOfThirds
    @Published var isEnabled = true
    @Published var lastResult: EnhancedCompositionResult?
    
    // Available composition services
    private let ruleOfThirdsService = RuleOfThirdsService()
    private let centerFramingService = CenterFramingService()
    private let symmetryService = SymmetryService()
    
    // Current active service
    private var currentService: CompositionService {
        switch currentCompositionType {
        case .ruleOfThirds:
            return ruleOfThirdsService
        case .centerFraming:
            return centerFramingService
        case .symmetry:
            return symmetryService
        }
    }
    
    // All available services
    var availableServices: [CompositionService] {
        [ruleOfThirdsService, centerFramingService, symmetryService]
    }
    
    // MARK: - Public Methods
    
    /// Evaluate composition for a detected subject
    /// - Parameters:
    ///   - observation: The detected subject (face or human)
    ///   - frameSize: The size of the camera frame
    ///   - pixelBuffer: The current frame's pixel buffer for advanced analysis
    /// - Returns: Enhanced composition result with context and suggestions
    func evaluate(observation: VNDetectedObjectObservation, frameSize: CGSize, pixelBuffer: CVPixelBuffer?) -> EnhancedCompositionResult {
        guard isEnabled else {
            let context = CompositionContextAnalyzer.analyzeContext(observation: observation, frameSize: frameSize)
            let disabledFeedback = CompositionFeedback(
                label: "pause.circle",
                suggestion: "Analysis disabled",
                compositionLevel: 4,
                color: .white
            )
            return EnhancedCompositionResult(
                composition: currentCompositionType.rawValue,
                score: 0.0,
                status: .needsAdjustment,
                suggestion: "Analysis disabled",
                context: context,
                overlayElements: [],
                feedbackIcon: "pause.circle",
                feedback: disabledFeedback, achievementContext: "Mhhh, curious how your composition scored? Enable live feedback to find out next time."
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
        case .centerFraming:
            return [centerFramingService.createCenterCrosshair(frameSize: frameSize)]
        case .symmetry:
            return [symmetryService.createSymmetryLine(frameSize: frameSize)]
        }
    }
    
    /// Switch to a different composition type
    /// - Parameter type: The new composition type to use
    /// - Note: Allows switching to any composition type for UI purposes.
    ///   Actual capture blocking is handled in ContentView.capturePhoto()
    func switchToCompositionType(_ type: CompositionType) {
        // Allow switching to any composition type - capture will be gated separately
        currentCompositionType = type
        lastResult = nil // Clear previous result when switching
        print("📐 Composition switched to: \(type.displayName)")
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
                bestType = CompositionType(rawValue: result.composition) ?? .ruleOfThirds
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
            if let compositionType = CompositionType(rawValue: result.composition) {
                scores[compositionType] = result.score
            }
        }
        
        return scores
    }
    
    /// Get JSON representation of the last composition result
    /// - Returns: JSON string matching the required format
    func getLastResultAsJSON() -> String? {
        return lastResult?.toJSONString()
    }
    
    /// Get JSON dictionary of the last composition result
    /// - Returns: JSON-compatible dictionary
    func getLastResultAsJSONDict() -> [String: Any]? {
        return lastResult?.toJSON()
    }
} 
