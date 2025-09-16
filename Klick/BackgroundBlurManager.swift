//
//  BackgroundBlurManager.swift
//  Klick
//
//  Created by Manase on 15/09/2025.
//

import UIKit
import Vision
import CoreImage
import CoreImage.CIFilterBuiltins

class BackgroundBlurManager {
    static let shared = BackgroundBlurManager()
    
    // MARK: - Subject Masking functionality
    // Core Image context for processing - reuse for better performance
    private let context: CIContext = {
        // Use Metal for better performance if available
        if let metalDevice = MTLCreateSystemDefaultDevice() {
            return CIContext(mtlDevice: metalDevice, options: [
                .cacheIntermediates: true,
                .workingColorSpace: CGColorSpaceCreateDeviceRGB(),
                .outputPremultiplied: true,
                .useSoftwareRenderer: false
            ])
        } else {
            // Fallback to CPU renderer
            return CIContext(options: [
                .useSoftwareRenderer: false,
                .cacheIntermediates: true,
                .workingColorSpace: CGColorSpaceCreateDeviceRGB()
            ])
        }
    }()
    
    // Cache for segmentation masks to avoid reprocessing
    private let maskCache = NSCache<NSString, CIImage>()
    
    // Queue for image processing to avoid blocking main thread
    private let processingQueue = DispatchQueue(label: "com.klick.subjectmasking", qos: .userInitiated)
    
    private init() {
        setupCaches()
        
        // Listen for memory warnings
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleMemoryWarning),
            name: UIApplication.didReceiveMemoryWarningNotification,
            object: nil
        )
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    private func setupCaches() {
        // Configure cache limits for masks only
        maskCache.countLimit = 5 // Keep it small - masks are large
        maskCache.totalCostLimit = 20 * 1024 * 1024 // 20MB for masks
        
        // Set eviction delegate to track cache behavior
        maskCache.evictsObjectsWithDiscardedContent = true
    }
    
    @objc private func handleMemoryWarning() {
        print("⚠️ Memory warning received - clearing subject masking caches")
        clearAllCaches()
    }
    
    // MARK: - Public Interface - Subject Masking
    
    /// Apply subject masking to an image with person segmentation
    /// - Parameters:
    ///   - image: Original image
    ///   - useCache: Whether to use cached results for performance
    /// - Returns: Image with subject masked in white, or original image if segmentation fails
    func applySubjectMasking(to image: UIImage, useCache: Bool = true) -> UIImage? {
        // Create cache key using image size and content hash for better accuracy
        let imageIdentifier = "\(image.size.width)x\(image.size.height)_\(image.contentHash)"
        _ = "\(imageIdentifier)_masked" as NSString
        
        // Use autoreleasepool to manage memory better
        return autoreleasepool { () -> UIImage? in
            guard let ciImage = CIImage(image: image) else {
                return image
            }
            
            // Get or generate segmentation mask
            let maskCacheKey = imageIdentifier as NSString
            var maskImage: CIImage?
            
            if useCache, let cachedMask = maskCache.object(forKey: maskCacheKey) {
                maskImage = cachedMask
            } else {
                maskImage = generatePersonSegmentationMask(for: ciImage)
                if let mask = maskImage, useCache {
                    // Calculate approximate memory cost for the mask
                    let maskCost = Int(ciImage.extent.width * ciImage.extent.height * 4) // Approximate bytes
                    maskCache.setObject(mask, forKey: maskCacheKey, cost: maskCost)
                }
            }
            
            // If no mask was generated, return original image
            guard let mask = maskImage else {
                return image
            }
            
            // Apply white masking to the subject
            let maskedImage = applyWhiteSubjectMask(to: ciImage, mask: mask)
            
            // Convert back to UIImage with proper memory management
            guard let cgImage = context.createCGImage(maskedImage, from: maskedImage.extent) else {
                return image
            }
            
            return UIImage(cgImage: cgImage, scale: image.scale, orientation: image.imageOrientation)
        }
    }
    
    
    /// Check if person segmentation is available on this device
    /// - Returns: True if segmentation is supported
    func isPersonSegmentationSupported() -> Bool {
        return VNGeneratePersonSegmentationRequest.supportedRevisions.contains(VNGeneratePersonSegmentationRequestRevision1)
    }
    
    
    // MARK: - Private Methods
    
    /// Generate person segmentation mask using Vision framework
    private func generatePersonSegmentationMask(for ciImage: CIImage) -> CIImage? {
        // Create a fresh request to ensure clean state
        let request = VNGeneratePersonSegmentationRequest()
        request.qualityLevel = .balanced
        request.outputPixelFormat = kCVPixelFormatType_OneComponent8
        
        let handler = VNImageRequestHandler(ciImage: ciImage, options: [:])
        
        do {
            try handler.perform([request])
            
            guard let result = request.results?.first else {
                print("⚠️ Person segmentation failed - no mask generated")
                return nil
            }
            
            // Convert pixel buffer to CIImage
            let maskImage = CIImage(cvPixelBuffer: result.pixelBuffer)
            
            // Mask generated successfully
            
            // The mask needs to be scaled to match the original image size
            let scaleX = ciImage.extent.width / maskImage.extent.width
            let scaleY = ciImage.extent.height / maskImage.extent.height
            
            // Use transform for efficient scaling
            let scaledMask = maskImage.transformed(by: CGAffineTransform(scaleX: scaleX, y: scaleY))
            
            return scaledMask
            
        } catch {
            return nil
        }
    }
    
    /// Apply white masking to the subject while keeping background untouched
    private func applyWhiteSubjectMask(to image: CIImage, mask: CIImage) -> CIImage {
        let originalExtent = image.extent
        let adjustedMask = mask.cropped(to: originalExtent)
        
        // Create white color for the subject
        let whiteColor = CIImage(color: CIColor(red: 1.0, green: 1.0, blue: 1.0, alpha: 1.0))
            .cropped(to: originalExtent)
        
        // Apply the mask blending - white for subject (where mask is white), original background (where mask is black)
        let blendFilter = CIFilter.blendWithMask()
        blendFilter.inputImage = whiteColor // White for subject areas (where mask is white)
        blendFilter.backgroundImage = image // Original image for background areas (where mask is black)
        blendFilter.maskImage = adjustedMask // The segmentation mask
        
        guard let maskedImage = blendFilter.outputImage else {
            return image
        }
        
        return maskedImage.cropped(to: originalExtent)
    }
    
    /// Apply blur effect using the segmentation mask
    private func applyBlurEffect(to image: CIImage, mask: CIImage, blurIntensity: Float) -> CIImage {
        // If blur intensity is 0, return original image
        guard blurIntensity > 0 else { return image }
        
        // Store the original image extent to maintain dimensions
        let originalExtent = image.extent
        
        // Use clamp to prevent edge artifacts during blur
        let clampFilter = CIFilter.affineClamp()
        clampFilter.inputImage = image
        clampFilter.transform = CGAffineTransform.identity
        
        guard let clampedImage = clampFilter.outputImage else {
            return image
        }
        
        // Apply Gaussian blur to the clamped image
        let blurFilter = CIFilter.gaussianBlur()
        blurFilter.inputImage = clampedImage
        blurFilter.radius = blurIntensity
        
        guard let blurredImageRaw = blurFilter.outputImage else {
            return image
        }
        
        // Crop the blurred image back to original dimensions
        let blurredImage = blurredImageRaw.cropped(to: originalExtent)
        
        // Ensure mask dimensions match the original image
        let adjustedMask = mask.cropped(to: originalExtent)
        
        // Apply streamlined mask refinement for optimal background blur
        let refinedMask = refineMaskForBackgroundBlur(adjustedMask, originalExtent: originalExtent, blurIntensity: blurIntensity)
        
        // Apply optimized mask blending for perfect subject protection
        let blendFilter = CIFilter.blendWithMask()
        blendFilter.inputImage = image // Sharp subject (white mask areas)
        blendFilter.backgroundImage = blurredImage // Blurred background (black mask areas)
        blendFilter.maskImage = refinedMask // Refined mask with soft edges
        
        guard let finalImage = blendFilter.outputImage else {
            return image
        }
        
        return finalImage.cropped(to: originalExtent)
    }
    
    /// Streamlined 3-step mask refinement for optimal subject protection and background blur
    /// Adaptive mask refinement for background blur
    /// Expands + softens subject edges proportionally to image size and blur intensity
    private func refineMaskForBackgroundBlur(
        _ mask: CIImage,
        originalExtent: CGRect,
        blurIntensity: Float
    ) -> CIImage {
        var refinedMask = mask.cropped(to: originalExtent)
        
        // Normalize intensity into 0–1 range for adaptive scaling
        let normalizedIntensity = min(max(blurIntensity / 20.0, 0), 1)
        
        // Scale factors based on image resolution
        let baseScale = Float(max(originalExtent.width, originalExtent.height) / 1000.0)
        
        // Step 1: Expand subject edges
        let expansionRadius = 2.0 * baseScale + (3.0 * normalizedIntensity * baseScale)
        let expandFilter = CIFilter.morphologyMaximum()
        expandFilter.inputImage = refinedMask
        expandFilter.radius = Float(expansionRadius)
        
        if let expandedMask = expandFilter.outputImage {
            refinedMask = expandedMask.cropped(to: originalExtent)
        }
        
        // Step 2: Feather edges (soft transition between subject and background)
        let featherRadius = 2.0 * baseScale + (6.0 * normalizedIntensity * baseScale)
        let softenFilter = CIFilter.gaussianBlur()
        softenFilter.inputImage = refinedMask
        softenFilter.radius = Float(featherRadius)
        
        if let softenedMask = softenFilter.outputImage {
            refinedMask = softenedMask.cropped(to: originalExtent)
        }
        
        // Step 3: Adjust mask contrast for clean separation
        let contrastBoost = 1.2 + (0.3 * normalizedIntensity) // stronger separation at high blur
        let brightnessBoost = 0.05 + (0.1 * normalizedIntensity)
        
        let contrastFilter = CIFilter.colorControls()
        contrastFilter.inputImage = refinedMask
        contrastFilter.contrast = Float(contrastBoost)
        contrastFilter.brightness = Float(brightnessBoost)
        
        if let optimizedMask = contrastFilter.outputImage {
            refinedMask = optimizedMask.cropped(to: originalExtent)
        }
        
        return refinedMask
    }

    
    /// Create subtle edge glow effect around the subject
    private func createSubjectEdgeGlow(mask: CIImage, originalImage: CIImage) -> CIImage {
        let originalExtent = originalImage.extent
        let adjustedMask = mask.cropped(to: originalExtent)
        
        // Step 1: Create edge detection from mask
        let edgeFilter = CIFilter.morphologyGradient()
        edgeFilter.inputImage = adjustedMask
        edgeFilter.radius = 3.0 // Width of edge detection
        
        guard let edgeMask = edgeFilter.outputImage?.cropped(to: originalExtent) else {
            return originalImage
        }
        
        // Step 2: Create soft glow effect
        let glowFilter = CIFilter.gaussianBlur()
        glowFilter.inputImage = edgeMask
        glowFilter.radius = 8.0 // Soft glow spread
        
        guard let glowMask = glowFilter.outputImage?.cropped(to: originalExtent) else {
            return originalImage
        }
        
        // Step 3: Create golden glow color
        let glowColor = CIImage(color: CIColor(red: 1.0, green: 0.9, blue: 0.6, alpha: 0.4))
            .cropped(to: originalExtent)
        
        // Step 4: Apply glow color using the glow mask
        let coloredGlow = CIFilter.multiplyCompositing()
        coloredGlow.inputImage = glowColor
        coloredGlow.backgroundImage = glowMask
        
        guard let finalGlow = coloredGlow.outputImage else {
            return originalImage
        }
        
        // Step 5: Blend glow with original image
        let blendFilter = CIFilter.screenBlendMode()
        blendFilter.inputImage = originalImage
        blendFilter.backgroundImage = finalGlow
        
        guard let glowedImage = blendFilter.outputImage else {
            return originalImage
        }
        
        return glowedImage.cropped(to: originalExtent)
    }
    
    
    // MARK: - Cache Management
    
    /// Clear all caches to free memory
    func clearAllCaches() {
        maskCache.removeAllObjects()
        print("🗑️ Subject masking caches cleared")
    }
    
    /// Clear cache for a specific image to force regeneration
    func clearCacheForImage(_ image: UIImage) {
        let imageIdentifier = "\(image.size.width)x\(image.size.height)_\(image.contentHash)"
        let maskCacheKey = imageIdentifier as NSString
        maskCache.removeObject(forKey: maskCacheKey)
        print("🗑️ Cleared cache for specific image")
    }
    
    /// Get cache information for debugging
    func getCacheInfo() -> (maskCount: Int, estimatedMemoryMB: Double) {
        // NSCache doesn't provide direct count access, so we track approximately
        let estimatedMemoryMB = Double(maskCache.totalCostLimit) / (1024 * 1024)
        
        return (maskCount: maskCache.countLimit, estimatedMemoryMB: estimatedMemoryMB)
    }
    
    /// Preload segmentation for an image (useful for preparing next image)
    func preloadSegmentation(for image: UIImage) {
        processingQueue.async { [weak self] in
            guard let self = self,
                  let ciImage = CIImage(image: image) else { return }
            
            let imageIdentifier = "\(image.size.width)x\(image.size.height)_\(image.contentHash)"
            let maskCacheKey = imageIdentifier as NSString
            
            // Only generate if not already cached
            if self.maskCache.object(forKey: maskCacheKey) == nil {
                _ = self.generatePersonSegmentationMask(for: ciImage)
            }
        }
    }
}

// MARK: - UIImage Extensions for Background Blur

extension UIImage {
    /// Robust content hash that samples actual pixel data for unique identification
    var contentHash: Int {
        var hasher = Hasher()
        hasher.combine(size.width)
        hasher.combine(size.height)
        hasher.combine(scale)
        
        // Sample actual pixel content for better uniqueness
        if let cgImage = self.cgImage {
            hasher.combine(cgImage.width)
            hasher.combine(cgImage.height)
            hasher.combine(cgImage.bitsPerComponent)
            
            // Sample pixels from different regions of the image for content-based hashing
            let width = cgImage.width
            let height = cgImage.height
            
            if width > 0 && height > 0 {
                // Create a small context to sample pixels
                let bytesPerPixel = 4
                let bytesPerRow = width * bytesPerPixel
                let bufferSize = bytesPerRow * height
                
                guard let colorSpace = CGColorSpace(name: CGColorSpace.sRGB),
                      let context = CGContext(
                        data: nil,
                        width: width,
                        height: height,
                        bitsPerComponent: 8,
                        bytesPerRow: bytesPerRow,
                        space: colorSpace,
                        bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
                      ) else {
                    // Fallback to basic hash if pixel sampling fails
                    if let providerData = cgImage.dataProvider?.data {
                        hasher.combine(CFDataGetLength(providerData))
                    }
                    return hasher.finalize()
                }
                
                context.draw(cgImage, in: CGRect(x: 0, y: 0, width: width, height: height))
                
                guard let data = context.data else {
                    if let providerData = cgImage.dataProvider?.data {
                        hasher.combine(CFDataGetLength(providerData))
                    }
                    return hasher.finalize()
                }
                
                let buffer = data.assumingMemoryBound(to: UInt8.self)
                
                // Sample pixels from 9 strategic points (corners, edges, center)
                let samplePoints = [
                    (0, 0),                           // Top-left
                    (width/2, 0),                     // Top-center
                    (width-1, 0),                     // Top-right
                    (0, height/2),                    // Middle-left
                    (width/2, height/2),              // Center
                    (width-1, height/2),              // Middle-right
                    (0, height-1),                    // Bottom-left
                    (width/2, height-1),              // Bottom-center
                    (width-1, height-1)              // Bottom-right
                ]
                
                for (x, y) in samplePoints {
                    let pixelIndex = (y * width + x) * bytesPerPixel
                    if pixelIndex + 3 < bufferSize {
                        // Sample RGBA values
                        hasher.combine(buffer[pixelIndex])     // R
                        hasher.combine(buffer[pixelIndex + 1]) // G
                        hasher.combine(buffer[pixelIndex + 2]) // B
                        hasher.combine(buffer[pixelIndex + 3]) // A
                    }
                }
            }
        }
        
        return hasher.finalize()
    }
    
    /// Optimized resizing with quality options
    func resized(to targetSize: CGSize, quality: CGInterpolationQuality = .high) -> UIImage? {
        let renderer = UIGraphicsImageRenderer(size: targetSize, format: UIGraphicsImageRendererFormat.preferred())
        
        return renderer.image { context in
            context.cgContext.interpolationQuality = quality
            self.draw(in: CGRect(origin: .zero, size: targetSize))
        }
    }
}
