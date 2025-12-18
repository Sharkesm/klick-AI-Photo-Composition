//
//  ShareScreenData.swift
//  Klick
//
//  Created on 2025-12-18.
//  Data model for composition share screen
//

import UIKit

// MARK: - Share Screen Data Model

/// Holds data for the composition achievement share screen
struct ShareScreenData: Identifiable {
    let id = UUID()
    let photo: UIImage
    let compositionTechnique: String
    let techniqueDescription: String
    
    init(
        photo: UIImage,
        compositionTechnique: String,
        techniqueDescription: String
    ) {
        self.photo = photo
        self.compositionTechnique = compositionTechnique
        self.techniqueDescription = techniqueDescription
        print("✅ ShareScreenData created - Composition: \(compositionTechnique)")
    }
}

