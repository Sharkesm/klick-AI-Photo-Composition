//
//  CapturedPhotoData.swift
//  Klick
//
//  Created by Manase on 17/12/2025.
//
import AVFoundation
import SwiftUI

// MARK: - Captured Photo Data Model

/// Holds captured photo data for item-based presentation
/// This ensures ImagePreviewView receives fresh, non-nil state values
struct CapturedPhotoData: Identifiable {
    let id = UUID()
    let processedImage: UIImage
    let rawImage: UIImage?
    let cameraQuality: CameraQuality
    let compositionType: String
    let compositionDescription: String
    
    init(
        processedImage: UIImage,
        rawImage: UIImage?,
        cameraQuality: CameraQuality,
        compositionType: String = "Rule of Thirds",
        compositionDescription: String = "You positioned your subject perfectly, creating a balanced composition."
    ) {
        self.processedImage = processedImage
        self.rawImage = rawImage
        self.cameraQuality = cameraQuality
        self.compositionType = compositionType
        self.compositionDescription = compositionDescription
    }
}
