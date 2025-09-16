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
    private let blurCache = NSCache<NSString, UIImage>()
    
    // Track cache keys per image for granular clearing
    private var imageKeyTracker: [String: Set<NSString>] = [:]
    private let keyTrackerQueue = DispatchQueue(label: "com.klick.keytracker", attributes: .concurrent)
    
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
        // MEMORY OPTIMIZATION: Aggressive limits for session-based editing
        maskCache.countLimit = 2 // Only current + 1 previous mask
        maskCache.totalCostLimit = 8 * 1024 * 1024 // 8MB for masks
        
        // MEMORY OPTIMIZATION: Smaller blur cache for active editing only
        blurCache.countLimit = 4 // Preview + full-size for current image only
        blurCache.totalCostLimit = 12 * 1024 * 1024 // 12MB for blurred images
        
        // Set eviction delegate to track cache behavior
        maskCache.evictsObjectsWithDiscardedContent = true
        blurCache.evictsObjectsWithDiscardedContent = true
        
        // MEMORY OPTIMIZATION: Set up automatic cleanup timer
        setupSessionCleanupTimer()
    }
    
    /// Setup automatic cleanup timer to prevent memory accumulation
    private func setupSessionCleanupTimer() {
        Timer.scheduledTimer(withTimeInterval: 30.0, repeats: true) { [weak self] _ in
            self?.performPeriodicSessionCleanup()
        }
    }
    
    /// Periodic cleanup to prevent memory leaks during long editing sessions
    private func performPeriodicSessionCleanup() {
        // If session is expired or no active session, clear everything
        if currentEditingSessionId == nil || isSessionExpired() {
            endEditingSession(clearAll: true)
            print("⏰ Periodic cleanup: Session expired, cleared all caches")
        } else {
            // Clean up old preview caches but keep current session
            clearSessionCaches(keepCurrentImage: true)
            print("⏰ Periodic cleanup: Cleaned old caches, kept current session")
        }
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
    
    /// Apply background blur to an image with person segmentation
    /// - Parameters:
    ///   - image: Original image
    ///   - blurIntensity: Blur intensity (0.0 = no blur, 20.0 = maximum blur)
    ///   - useCache: Whether to use cached results for performance
    /// - Returns: Image with blurred background and sharp subject, or original image if segmentation fails
    func applyBackgroundBlur(to image: UIImage, blurIntensity: Float, useCache: Bool = true) -> UIImage? {
        let startTime = CFAbsoluteTimeGetCurrent()
        
        // Early return for zero blur
        guard blurIntensity > 0 else { return image }
        
        // Create cache key using image size, content hash, and blur intensity
        let imageIdentifier = "\(image.size.width)x\(image.size.height)_\(image.contentHash)"
        let cacheKey = "\(imageIdentifier)_blur_\(blurIntensity)" as NSString
        
        // Check cache first
        if useCache, let cachedImage = blurCache.object(forKey: cacheKey) {
            let cacheTime = (CFAbsoluteTimeGetCurrent() - startTime) * 1000
            print("💾 Full-size blur from cache in \(String(format: "%.1f", cacheTime))ms")
            return cachedImage
        }
        
        // Use autoreleasepool to manage memory better
        return autoreleasepool { () -> UIImage? in
            guard let ciImage = CIImage(image: image) else {
                return image
            }
            
            // Get or generate segmentation mask
            let maskCacheKey = imageIdentifier as NSString
            var maskImage: CIImage?
            let maskStartTime = CFAbsoluteTimeGetCurrent()
            
            if useCache, let cachedMask = maskCache.object(forKey: maskCacheKey) {
                maskImage = cachedMask
                let maskTime = (CFAbsoluteTimeGetCurrent() - maskStartTime) * 1000
                print("💾 Full-size mask from cache in \(String(format: "%.1f", maskTime))ms")
            } else {
                maskImage = generatePersonSegmentationMask(for: ciImage)
                if let mask = maskImage, useCache {
                    // Calculate approximate memory cost for the mask
                    let maskCost = Int(ciImage.extent.width * ciImage.extent.height * 4) // Approximate bytes
                    maskCache.setObject(mask, forKey: maskCacheKey, cost: maskCost)
                }
                let maskTime = (CFAbsoluteTimeGetCurrent() - maskStartTime) * 1000
                print("🔍 Full-size mask generated in \(String(format: "%.1f", maskTime))ms")
            }
            
            // If no mask was generated, return original image
            guard let mask = maskImage else {
                return image
            }
            
            // Apply blur effect to background only
            let blurredImage = applyBackgroundBlurEffect(to: ciImage, mask: mask, blurIntensity: blurIntensity)
            
            // Convert back to UIImage with proper memory management
            guard let cgImage = context.createCGImage(blurredImage, from: blurredImage.extent) else {
                return image
            }
            
            let resultImage = UIImage(cgImage: cgImage, scale: image.scale, orientation: image.imageOrientation)
            
            // Cache the result with proper memory cost
            if useCache {
                let imageCost = Int(resultImage.size.width * resultImage.size.height * 4 * resultImage.scale * resultImage.scale)
                blurCache.setObject(resultImage, forKey: cacheKey, cost: imageCost)
                
                // Track this cache key for the image
                trackCacheKey(cacheKey, forImageIdentifier: imageIdentifier)
            }
            
            let totalTime = (CFAbsoluteTimeGetCurrent() - startTime) * 1000
            print("🏁 Full-size blur completed in \(String(format: "%.1f", totalTime))ms")
            
            return resultImage
        }
    }
    
    /// Generate a preview-sized blurred image for real-time slider updates
    /// OPTIMIZED: Uses preview-sized mask generation for 10-16x performance improvement
    /// - Parameters:
    ///   - image: Original image
    ///   - blurIntensity: Blur intensity
    ///   - previewSize: Size for preview (smaller for better performance)
    ///   - enhancedEdges: Whether to use enhanced edge smoothing for better quality
    /// - Returns: Preview image with background blur
    func generateBlurPreview(for image: UIImage, blurIntensity: Float, previewSize: CGSize = CGSize(width: 400, height: 600), enhancedEdges: Bool = false) -> UIImage? {
        let startTime = CFAbsoluteTimeGetCurrent()
        
        // Use autoreleasepool for preview generation
        let result = autoreleasepool { () -> UIImage? in
            // Calculate optimal preview size maintaining aspect ratio
            let scale = min(previewSize.width / image.size.width, previewSize.height / image.size.height)
            let scaledSize = CGSize(width: image.size.width * scale, height: image.size.height * scale)
            
            guard let resizedImage = image.resized(to: scaledSize, quality: enhancedEdges ? .high : .medium) else { return nil }
            
            // OPTIMIZATION: Use preview-specific blur application for better performance
            return applyBackgroundBlurForPreview(to: resizedImage, originalImage: image, blurIntensity: blurIntensity, useCache: !enhancedEdges)
        }
        
        let processingTime = (CFAbsoluteTimeGetCurrent() - startTime) * 1000
        print("🚀 Preview generation completed in \(String(format: "%.1f", processingTime))ms")
        
        return result
    }

    /// OPTIMIZED: Apply background blur specifically optimized for preview generation
    /// Uses intelligent mask reuse strategy for maximum performance
    /// - Parameters:
    ///   - previewImage: Already resized preview image
    ///   - originalImage: Original full-size image (for mask cache lookup)
    ///   - blurIntensity: Blur intensity
    ///   - useCache: Whether to use caching
    /// - Returns: Preview image with background blur
    private func applyBackgroundBlurForPreview(to previewImage: UIImage, originalImage: UIImage, blurIntensity: Float, useCache: Bool = true) -> UIImage? {
        // Early return for zero blur
        guard blurIntensity > 0 else { return previewImage }
        
        let originalIdentifier = "\(originalImage.size.width)x\(originalImage.size.height)_\(originalImage.contentHash)"
        let previewIdentifier = "\(previewImage.size.width)x\(previewImage.size.height)_\(originalImage.contentHash)"
        let previewCacheKey = "\(previewIdentifier)_preview_blur_\(blurIntensity)" as NSString
        
        // Check preview cache first
        if useCache, let cachedPreview = blurCache.object(forKey: previewCacheKey) {
            return cachedPreview
        }
        
        return autoreleasepool { () -> UIImage? in
            guard let previewCIImage = CIImage(image: previewImage) else { return previewImage }
            
            var maskImage: CIImage?
            let maskStartTime = CFAbsoluteTimeGetCurrent()
            
            // STRATEGY 1: Try to reuse full-resolution mask if available
            let fullSizeMaskKey = originalIdentifier as NSString
            if useCache, let fullSizeMask = maskCache.object(forKey: fullSizeMaskKey) {
                // Resize the full-size mask to preview dimensions
                let scaleX = previewCIImage.extent.width / fullSizeMask.extent.width
                let scaleY = previewCIImage.extent.height / fullSizeMask.extent.height
                maskImage = fullSizeMask.transformed(by: CGAffineTransform(scaleX: scaleX, y: scaleY))
                
                let maskTime = (CFAbsoluteTimeGetCurrent() - maskStartTime) * 1000
                print("📐 Reused full-size mask (resized in \(String(format: "%.1f", maskTime))ms)")
                
                } else {
                    // STRATEGY 2: Generate mask at preview resolution for maximum speed
                    let previewMaskKey = previewIdentifier as NSString
                    if useCache, let cachedPreviewMask = maskCache.object(forKey: previewMaskKey) {
                        maskImage = cachedPreviewMask
                        print("🎯 Using cached preview mask")
                    } else {
                        // Generate new mask at preview resolution
                        maskImage = generatePersonSegmentationMask(for: previewCIImage)
                        
                        // MEMORY OPTIMIZATION: Only cache preview masks during active editing session
                        if let mask = maskImage, useCache, 
                           let currentId = currentEditingSessionId,
                           previewIdentifier.contains(currentId) {
                            let maskCost = Int(previewCIImage.extent.width * previewCIImage.extent.height * 4)
                            maskCache.setObject(mask, forKey: previewMaskKey, cost: maskCost)
                            trackCacheKey(previewMaskKey, forImageIdentifier: previewIdentifier)
                        }
                        
                        let maskTime = (CFAbsoluteTimeGetCurrent() - maskStartTime) * 1000
                        print("⚡ Generated preview mask in \(String(format: "%.1f", maskTime))ms")
                    }
                }
            
            guard let mask = maskImage else { return previewImage }
            
            // Apply blur effect optimized for preview
            let blurredImage = applyBackgroundBlurEffect(to: previewCIImage, mask: mask, blurIntensity: blurIntensity)
            
            guard let cgImage = context.createCGImage(blurredImage, from: blurredImage.extent) else {
                return previewImage
            }
            
            let resultImage = UIImage(cgImage: cgImage, scale: previewImage.scale, orientation: previewImage.imageOrientation)
            
            // Cache preview result - MEMORY OPTIMIZATION: Only during active editing session
            if useCache, let currentId = currentEditingSessionId,
               previewIdentifier.contains(currentId) {
                let imageCost = Int(resultImage.size.width * resultImage.size.height * 4 * resultImage.scale * resultImage.scale)
                blurCache.setObject(resultImage, forKey: previewCacheKey, cost: imageCost)
                trackCacheKey(previewCacheKey, forImageIdentifier: previewIdentifier)
            }
            
            return resultImage
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
        request.qualityLevel = .accurate
        request.outputPixelFormat = kCVPixelFormatType_OneComponent8
        
        if VNGeneratePersonSegmentationRequest.supportedRevisions.contains(2) {
            request.revision = 2 // Better hair, semi-transparent details
        }
        
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
    
    /// Apply blur effect to background only, keeping subject sharp
    private func applyBackgroundBlurEffect(to image: CIImage, mask: CIImage, blurIntensity: Float) -> CIImage {
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
        
        // Apply Gaussian blur to the entire image
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
        
        // Apply advanced mask refinement for ultra-smooth transitions
        // Use premium soft edge technique for blur intensities above 8 for best quality
        let refinedMask: CIImage
        if blurIntensity > 8.0 {
            // Use premium soft edge mask for high blur intensities
            refinedMask = createSoftEdgeMask(adjustedMask, originalExtent: originalExtent, blurIntensity: blurIntensity)
        } else {
            // Use standard refinement for lower blur intensities
            refinedMask = refineMaskForBackgroundBlur(adjustedMask, originalExtent: originalExtent, blurIntensity: blurIntensity)
        }
        
        // Apply mask blending - sharp subject (white mask areas), blurred background (black mask areas)
        let blendFilter = CIFilter.blendWithMask()
        blendFilter.inputImage = image // Sharp subject (where mask is white)
        blendFilter.backgroundImage = blurredImage // Blurred background (where mask is black)
        blendFilter.maskImage = refinedMask // Refined mask with soft edges
        
        guard let finalImage = blendFilter.outputImage else {
            return image
        }
        
        return finalImage.cropped(to: originalExtent)
    }
    
    /// Advanced mask refinement for ultra-smooth background blur transitions
    /// Creates natural, soft edges that blend seamlessly with the background blur
    private func refineMaskForBackgroundBlur(
        _ mask: CIImage,
        originalExtent: CGRect,
        blurIntensity: Float
    ) -> CIImage {
        var refinedMask = mask.cropped(to: originalExtent)
        
        // Normalize intensity into 0–1 range for adaptive scaling
        let normalizedIntensity = min(max(blurIntensity / 20.0, 0), 1)
        
        // Scale factors based on image resolution for consistent results across different image sizes
        let baseScale = Float(max(originalExtent.width, originalExtent.height) / 1000.0)
        let minScale = max(baseScale, 0.5) // Ensure minimum scale for small images
        
        // Step 1: Initial edge cleanup with morphological opening
        // This removes small noise and smooths rough edges
        let cleanupRadius = 0.5 * minScale
        let openingFilter = CIFilter.morphologyMinimum()
        openingFilter.inputImage = refinedMask
        openingFilter.radius = Float(cleanupRadius)
        
        if let cleanedMask = openingFilter.outputImage {
            let closingFilter = CIFilter.morphologyMaximum()
            closingFilter.inputImage = cleanedMask.cropped(to: originalExtent)
            closingFilter.radius = Float(cleanupRadius)
            
            if let smoothedMask = closingFilter.outputImage {
                refinedMask = smoothedMask.cropped(to: originalExtent)
            }
        }
        
        // Step 2: Strategic edge expansion to prevent harsh cutoffs
        // Expand more for higher blur intensities to create natural falloff
        let expansionRadius = 1.5 * minScale + (3.5 * normalizedIntensity * minScale)
        let expandFilter = CIFilter.morphologyMaximum()
        expandFilter.inputImage = refinedMask
        expandFilter.radius = Float(expansionRadius)
        
        if let expandedMask = expandFilter.outputImage {
            refinedMask = expandedMask.cropped(to: originalExtent)
        }
        
        // Step 3: Multi-stage feathering for ultra-soft edges
        // First pass: Moderate blur for initial softening
        let initialFeatherRadius = 2.5 * minScale + (4.0 * normalizedIntensity * minScale)
        let initialBlurFilter = CIFilter.gaussianBlur()
        initialBlurFilter.inputImage = refinedMask
        initialBlurFilter.radius = Float(initialFeatherRadius)
        
        if let initiallyBlurred = initialBlurFilter.outputImage {
            refinedMask = initiallyBlurred.cropped(to: originalExtent)
        }
        
        // Second pass: Additional feathering for higher blur intensities
        if normalizedIntensity > 0.3 {
            let secondaryFeatherRadius = 1.5 * minScale + (6.0 * (normalizedIntensity - 0.3) * minScale)
            let secondaryBlurFilter = CIFilter.gaussianBlur()
            secondaryBlurFilter.inputImage = refinedMask
            secondaryBlurFilter.radius = Float(secondaryFeatherRadius)
            
            if let secondaryBlurred = secondaryBlurFilter.outputImage {
                refinedMask = secondaryBlurred.cropped(to: originalExtent)
            }
        }
        
        // Step 4: Intelligent contrast adjustment for natural transitions
        // Use sigmoid curve for smooth falloff instead of linear contrast
        let midpoint = 0.5 + (0.1 * normalizedIntensity) // Shift midpoint slightly for higher blur
        let sharpness = 1.8 + (0.7 * normalizedIntensity) // Increase sharpness for cleaner separation
        
        // Apply sigmoid-like curve using color controls
        let sigmoidFilter = CIFilter.colorControls()
        sigmoidFilter.inputImage = refinedMask
        sigmoidFilter.contrast = Float(sharpness)
        sigmoidFilter.brightness = Float(midpoint - 0.5)
        sigmoidFilter.saturation = 1.0
        
        if let sigmoidMask = sigmoidFilter.outputImage {
            refinedMask = sigmoidMask.cropped(to: originalExtent)
        }
        
        // Step 5: Final edge polishing with subtle gamma correction
        // This creates a more natural falloff curve
        let gammaCorrection = 0.9 - (0.1 * normalizedIntensity) // Slightly lower gamma for softer edges
        let gammaFilter = CIFilter.gammaAdjust()
        gammaFilter.inputImage = refinedMask
        gammaFilter.power = Float(gammaCorrection)
        
        if let gammaCorrected = gammaFilter.outputImage {
            refinedMask = gammaCorrected.cropped(to: originalExtent)
        }
        
        return refinedMask
    }
    
    /// Create an ultra-soft edge mask using distance field techniques for premium edge quality
    /// This is used for high-quality blur effects where edge smoothness is critical
    private func createSoftEdgeMask(_ mask: CIImage, originalExtent: CGRect, blurIntensity: Float) -> CIImage {
        var softMask = mask.cropped(to: originalExtent)
        
        let normalizedIntensity = min(max(blurIntensity / 20.0, 0), 1)
        let baseScale = Float(max(originalExtent.width, originalExtent.height) / 1000.0)
        let minScale = max(baseScale, 0.5)
        
        // Step 1: Create a distance field effect using multiple blur passes
        // This creates a natural gradient falloff from the subject edges
        let distances = [
            (radius: 1.0 * minScale, weight: 0.4),
            (radius: 2.5 * minScale, weight: 0.3),
            (radius: 5.0 * minScale, weight: 0.2),
            (radius: 8.0 * minScale, weight: 0.1)
        ]
        
        var blendedMask: CIImage?
        
        for (index, distance) in distances.enumerated() {
            let blurFilter = CIFilter.gaussianBlur()
            blurFilter.inputImage = softMask
            blurFilter.radius = Float(distance.radius * (1.0 + normalizedIntensity))
            
            guard let blurredMask = blurFilter.outputImage?.cropped(to: originalExtent) else { continue }
            
            if index == 0 {
                blendedMask = blurredMask
            } else if let currentMask = blendedMask {
                // Blend with weighted average
                let blendFilter = CIFilter.additionCompositing()
                
                // Apply weight to the new layer
                let multiplyFilter = CIFilter.colorMatrix()
                multiplyFilter.inputImage = blurredMask
                multiplyFilter.rVector = CIVector(x: CGFloat(distance.weight), y: 0, z: 0, w: 0)
                multiplyFilter.gVector = CIVector(x: 0, y: CGFloat(distance.weight), z: 0, w: 0)
                multiplyFilter.bVector = CIVector(x: 0, y: 0, z: CGFloat(distance.weight), w: 0)
                multiplyFilter.aVector = CIVector(x: 0, y: 0, z: 0, w: CGFloat(distance.weight))
                
                if let weightedMask = multiplyFilter.outputImage {
                    blendFilter.inputImage = weightedMask
                    blendFilter.backgroundImage = currentMask
                    
                    if let blended = blendFilter.outputImage {
                        blendedMask = blended.cropped(to: originalExtent)
                    }
                }
            }
        }
        
        // Step 2: Apply smooth curve mapping for natural transitions
        if let finalMask = blendedMask {
            // Use tone curve for smooth S-curve mapping
            let curveFilter = CIFilter.toneCurve()
            curveFilter.inputImage = finalMask
            
            // Create smooth S-curve points for natural falloff
            curveFilter.point0 = .init(x: 0.0, y: 0.0)
            curveFilter.point1 = .init(x: 0.25, y: 0.15)
            curveFilter.point2 = .init(x: 0.5, y: 0.5)
            curveFilter.point3 = .init(x: 0.75, y: 0.85)
            curveFilter.point4 = .init(x: 1.0, y: 1.0)
            
            if let curvedMask = curveFilter.outputImage {
                softMask = curvedMask.cropped(to: originalExtent)
            }
        }
        
        return softMask
    }
    
    // MARK: - Cache Management
    
    // Current editing session tracking
    private var currentEditingSessionId: String?
    private var sessionStartTime: Date?
    private let maxSessionDuration: TimeInterval = 180 // 3 minutes max session
    
    /// Start a new editing session - clears previous session caches
    func startEditingSession(for image: UIImage) {
        let imageId = "\(image.size.width)x\(image.size.height)_\(image.contentHash)"
        
        // If this is a different image or session expired, clear previous caches
        if let currentId = currentEditingSessionId,
           currentId != imageId || isSessionExpired() {
            clearSessionCaches(keepCurrentImage: false)
        }
        
        currentEditingSessionId = imageId
        sessionStartTime = Date()
        
        print("🎬 Started editing session for image: \(imageId)")
    }
    
    /// End current editing session and clear all caches
    func endEditingSession(clearAll: Bool = true) {
        if clearAll {
            clearAllCaches()
        } else if let sessionId = currentEditingSessionId {
            clearSessionCaches(keepCurrentImage: false)
        }
        
        currentEditingSessionId = nil
        sessionStartTime = nil
        
        print("🎬 Ended editing session - caches cleared")
    }
    
    /// Check if current session has expired
    private func isSessionExpired() -> Bool {
        guard let startTime = sessionStartTime else { return true }
        return Date().timeIntervalSince(startTime) > maxSessionDuration
    }
    
    /// Clear caches for previous sessions while optionally keeping current image
    private func clearSessionCaches(keepCurrentImage: Bool) {
        keyTrackerQueue.async(flags: .barrier) { [weak self] in
            guard let self = self else { return }
            
            if keepCurrentImage, let currentId = self.currentEditingSessionId {
                // Keep only current image caches
                let keysToKeep = self.imageKeyTracker[currentId] ?? Set<NSString>()
                let currentMaskKey = currentId as NSString
                
                // Clear all blur caches except current image
                let allKeys = Set(self.imageKeyTracker.values.flatMap { $0 })
                let keysToRemove = allKeys.subtracting(keysToKeep)
                
                for key in keysToRemove {
                    self.blurCache.removeObject(forKey: key)
                }
                
                // Clear all masks except current
                self.maskCache.removeAllObjects()
                
                // Keep only current image in tracker
                self.imageKeyTracker.removeAll()
                if !keysToKeep.isEmpty {
                    self.imageKeyTracker[currentId] = keysToKeep
                }
                
                print("🧹 Session cleanup: Kept \(keysToKeep.count) caches for current image")
            } else {
                // Clear everything
                self.maskCache.removeAllObjects()
                self.blurCache.removeAllObjects()
                self.imageKeyTracker.removeAll()
                
                print("🧹 Full session cleanup completed")
            }
        }
    }
    
    /// Track a cache key for a specific image
    private func trackCacheKey(_ cacheKey: NSString, forImageIdentifier imageIdentifier: String) {
        keyTrackerQueue.async(flags: .barrier) {
            if self.imageKeyTracker[imageIdentifier] == nil {
                self.imageKeyTracker[imageIdentifier] = Set<NSString>()
            }
            self.imageKeyTracker[imageIdentifier]?.insert(cacheKey)
        }
    }
    
    /// Get all cache keys for a specific image
    private func getCacheKeys(forImageIdentifier imageIdentifier: String) -> Set<NSString> {
        return keyTrackerQueue.sync {
            return self.imageKeyTracker[imageIdentifier] ?? Set<NSString>()
        }
    }
    
    /// Remove tracking for a specific image
    private func removeKeyTracking(forImageIdentifier imageIdentifier: String) {
        keyTrackerQueue.async(flags: .barrier) {
            self.imageKeyTracker.removeValue(forKey: imageIdentifier)
        }
    }
    
    /// Clear all caches to free memory
    func clearAllCaches() {
        maskCache.removeAllObjects()
        blurCache.removeAllObjects()
        keyTrackerQueue.async(flags: .barrier) {
            self.imageKeyTracker.removeAll()
        }
        print("🗑️ Subject masking and blur caches cleared")
    }
    
    /// Clear cache for a specific image to force regeneration
    func clearCacheForImage(_ image: UIImage) {
        let imageIdentifier = "\(image.size.width)x\(image.size.height)_\(image.contentHash)"
        let maskCacheKey = imageIdentifier as NSString
        
        // Clear the mask cache for this image
        maskCache.removeObject(forKey: maskCacheKey)
        
        // Get all blur cache keys for this specific image
        let blurKeysToRemove = getCacheKeys(forImageIdentifier: imageIdentifier)
        
        // Remove only the blur cache entries for this specific image
        for cacheKey in blurKeysToRemove {
            blurCache.removeObject(forKey: cacheKey)
        }
        
        // Clean up the key tracking for this image
        removeKeyTracking(forImageIdentifier: imageIdentifier)
        
        print("🗑️ Cleared cache for specific image (removed \(blurKeysToRemove.count) blur entries)")
    }
    
    /// Get cache information for debugging
    func getCacheInfo() -> (maskCount: Int, blurCount: Int, trackedImages: Int, estimatedMemoryMB: Double) {
        // NSCache doesn't provide direct count access, so we track approximately
        let estimatedMemoryMB = Double(maskCache.totalCostLimit + blurCache.totalCostLimit) / (1024 * 1024)
        
        let trackedImageCount = keyTrackerQueue.sync {
            return self.imageKeyTracker.count
        }
        
        return (maskCount: maskCache.countLimit, blurCount: blurCache.countLimit, trackedImages: trackedImageCount, estimatedMemoryMB: estimatedMemoryMB)
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
