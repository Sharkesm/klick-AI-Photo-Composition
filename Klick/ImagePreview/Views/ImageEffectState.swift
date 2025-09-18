//
//  ImageEffectState.swift
//  Klick
//
//  Created by Manase on 18/09/2025.
//

import Foundation

// MARK: - Image Effect State
struct ImageEffectState {
    var backgroundBlur: BackgroundBlurEffect
    var filter: FilterEffect?
    
    struct BackgroundBlurEffect {
        var isEnabled: Bool = false
        var intensity: Float = 5.0 // 0-20 range
    }
    
    struct FilterEffect {
        var filter: PhotoFilter
        var adjustments: FilterAdjustment = .balanced
    }
    
    static let `default` = ImageEffectState(
        backgroundBlur: BackgroundBlurEffect(),
        filter: nil
    )
}
