//
//  ImageStateHistory.swift
//  Klick
//
//  Created by Manase on 18/09/2025.
//
import SwiftUI

// MARK: - Image State History
struct ImageStateHistory {
    var currentState: ImageEffectState
    var previousState: ImageEffectState?
    var currentImage: UIImage?
    var previousImage: UIImage?
    var isInitialized: Bool = false
    
    var previousStateInfo: String {
        guard let previousState = previousState else {
            return "ORIGINAL"
        }
        
        // Check what effects were active in the previous state
        let hasBlur = previousState.backgroundBlur.isEnabled && previousState.backgroundBlur.intensity > 0
        let hasFilter = previousState.filter != nil
        
        if hasBlur && hasFilter {
            return "\(previousState.filter!.filter.name.uppercased()) + BLUR"
        } else if hasFilter {
            return previousState.filter!.filter.name.uppercased()
        } else if hasBlur {
            return "BACKGROUND BLUR"
        } else {
            return "ORIGINAL"
        }
    }
    
    mutating func initializeWithOriginal(originalImage: UIImage) {
        guard !isInitialized else { return }
        
        currentState = ImageEffectState.default
        currentImage = originalImage
        previousState = nil
        previousImage = nil
        isInitialized = true
    }
    
    mutating func saveCurrentState(effectState: ImageEffectState, processedImage: UIImage?) {
        // Save current as previous
        previousState = currentState
        previousImage = currentImage
        
        // Update current
        currentState = effectState
        currentImage = processedImage
    }
    
    var hasPreviousState: Bool {
        return isInitialized && previousImage != nil
    }
    
    static let empty = ImageStateHistory(
        currentState: ImageEffectState.default,
        previousState: nil,
        currentImage: nil,
        previousImage: nil,
        isInitialized: false
    )
}
