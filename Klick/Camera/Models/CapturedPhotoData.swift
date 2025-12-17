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
    
    init(processedImage: UIImage, rawImage: UIImage?, cameraQuality: CameraQuality) {
        self.processedImage = processedImage
        self.rawImage = rawImage
        self.cameraQuality = cameraQuality
        print("✅ CapturedPhotoData created - Processed: ✓, RAW: \(rawImage != nil ? "✓" : "✗"), Quality: \(cameraQuality)")
    }
}
