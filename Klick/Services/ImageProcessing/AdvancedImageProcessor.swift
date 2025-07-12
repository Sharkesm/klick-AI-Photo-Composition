//
//  AdvancedImageProcessor.swift
//  Klick
//
//  Created by AI Assistant on 12/07/2025.
//

import UIKit
import CoreImage
import Accelerate

class AdvancedImageProcessor {
    
    private let context = CIContext()
    private var processedImageCache: [String: UIImage] = [:]
    
    // MARK: - Grayscale Conversion
    
    func convertToGrayscale(_ image: UIImage) -> UIImage? {
        let cacheKey = "grayscale_\(image.hashValue)"
        if let cached = processedImageCache[cacheKey] {
            return cached
        }
        
        guard let ciImage = CIImage(image: image) else { return nil }
        
        let filter = CIFilter(name: "CIPhotoEffectMono")
        filter?.setValue(ciImage, forKey: kCIInputImageKey)
        
        guard let outputImage = filter?.outputImage,
              let cgImage = context.createCGImage(outputImage, from: outputImage.extent) else {
            return nil
        }
        
        let result = UIImage(cgImage: cgImage)
        processedImageCache[cacheKey] = result
        return result
    }
    
    // MARK: - Edge Detection
    
    func detectEdges(_ image: UIImage, threshold: Float = 0.1) -> UIImage? {
        let cacheKey = "edges_\(image.hashValue)_\(threshold)"
        if let cached = processedImageCache[cacheKey] {
            return cached
        }
        
        guard let ciImage = CIImage(image: image) else { return nil }
        
        // Apply Gaussian blur first to reduce noise
        let blurFilter = CIFilter(name: "CIGaussianBlur")
        blurFilter?.setValue(ciImage, forKey: kCIInputImageKey)
        blurFilter?.setValue(1.0, forKey: kCIInputRadiusKey)
        
        // Apply edge detection
        let edgeFilter = CIFilter(name: "CIEdges")
        edgeFilter?.setValue(blurFilter?.outputImage, forKey: kCIInputImageKey)
        edgeFilter?.setValue(threshold * 10, forKey: kCIInputIntensityKey)
        
        guard let outputImage = edgeFilter?.outputImage,
              let cgImage = context.createCGImage(outputImage, from: outputImage.extent) else {
            return nil
        }
        
        let result = UIImage(cgImage: cgImage)
        processedImageCache[cacheKey] = result
        return result
    }
    
    // MARK: - Sobel Edge Detection
    
    func applySobelFilter(_ image: UIImage) async -> (horizontal: UIImage?, vertical: UIImage?, magnitude: UIImage?) {
        let cacheKey = "sobel_\(image.hashValue)"
        if let cachedHorizontal = processedImageCache["\(cacheKey)_h"],
           let cachedVertical = processedImageCache["\(cacheKey)_v"],
           let cachedMagnitude = processedImageCache["\(cacheKey)_m"] {
            return (cachedHorizontal, cachedVertical, cachedMagnitude)
        }
        
        guard let ciImage = CIImage(image: image) else { return (nil, nil, nil) }
        
        // Convert to grayscale first
        let grayscaleFilter = CIFilter(name: "CIPhotoEffectMono")
        grayscaleFilter?.setValue(ciImage, forKey: kCIInputImageKey)
        guard let grayscaleImage = grayscaleFilter?.outputImage else { return (nil, nil, nil) }
        
        // Process Sobel kernels concurrently
        let horizontalKernel = CIFilter(name: "CIConvolution3X3")
        horizontalKernel?.setValue(grayscaleImage, forKey: kCIInputImageKey)
        horizontalKernel?.setValue(CIVector(values: [
            -1, 0, 1,
            -2, 0, 2,
            -1, 0, 1
        ], count: 9), forKey: "inputWeights")
        
        let verticalKernel = CIFilter(name: "CIConvolution3X3")
        verticalKernel?.setValue(grayscaleImage, forKey: kCIInputImageKey)
        verticalKernel?.setValue(CIVector(values: [
            -1, -2, -1,
             0,  0,  0,
             1,  2,  1
        ], count: 9), forKey: "inputWeights")
        
        // Process horizontal and vertical edges concurrently
        async let horizontalTask = processHorizontalEdges(horizontalKernel, cacheKey: cacheKey)
        async let verticalTask = processVerticalEdges(verticalKernel, cacheKey: cacheKey)
        
        let (horizontal, vertical) = await (horizontalTask, verticalTask)
        
        // Process magnitude after horizontal and vertical are complete
        var magnitudeImage: UIImage?
        if let hOutput = horizontalKernel?.outputImage,
           let vOutput = verticalKernel?.outputImage {
            magnitudeImage = await processMagnitude(hOutput: hOutput, vOutput: vOutput, cacheKey: cacheKey)
        }
        
        return (horizontal, vertical, magnitudeImage)
    }
    
    // Synchronous version for backward compatibility
    func applySobelFilterSync(_ image: UIImage) -> (horizontal: UIImage?, vertical: UIImage?, magnitude: UIImage?) {
        let cacheKey = "sobel_\(image.hashValue)"
        if let cachedHorizontal = processedImageCache["\(cacheKey)_h"],
           let cachedVertical = processedImageCache["\(cacheKey)_v"],
           let cachedMagnitude = processedImageCache["\(cacheKey)_m"] {
            return (cachedHorizontal, cachedVertical, cachedMagnitude)
        }
        
        guard let ciImage = CIImage(image: image) else { return (nil, nil, nil) }
        
        // Convert to grayscale first
        let grayscaleFilter = CIFilter(name: "CIPhotoEffectMono")
        grayscaleFilter?.setValue(ciImage, forKey: kCIInputImageKey)
        guard let grayscaleImage = grayscaleFilter?.outputImage else { return (nil, nil, nil) }
        
        // Sobel horizontal kernel
        let horizontalKernel = CIFilter(name: "CIConvolution3X3")
        horizontalKernel?.setValue(grayscaleImage, forKey: kCIInputImageKey)
        horizontalKernel?.setValue(CIVector(values: [
            -1, 0, 1,
            -2, 0, 2,
            -1, 0, 1
        ], count: 9), forKey: "inputWeights")
        
        // Sobel vertical kernel
        let verticalKernel = CIFilter(name: "CIConvolution3X3")
        verticalKernel?.setValue(grayscaleImage, forKey: kCIInputImageKey)
        verticalKernel?.setValue(CIVector(values: [
            -1, -2, -1,
             0,  0,  0,
             1,  2,  1
        ], count: 9), forKey: "inputWeights")
        
        var horizontalImage: UIImage?
        var verticalImage: UIImage?
        var magnitudeImage: UIImage?
        
        // Process horizontal edges
        if let hOutput = horizontalKernel?.outputImage,
           let cgImage = context.createCGImage(hOutput, from: hOutput.extent) {
            horizontalImage = UIImage(cgImage: cgImage)
            processedImageCache["\(cacheKey)_h"] = horizontalImage
        }
        
        // Process vertical edges
        if let vOutput = verticalKernel?.outputImage,
           let cgImage = context.createCGImage(vOutput, from: vOutput.extent) {
            verticalImage = UIImage(cgImage: cgImage)
            processedImageCache["\(cacheKey)_v"] = verticalImage
        }
        
        // Calculate magnitude
        if let hOutput = horizontalKernel?.outputImage,
           let vOutput = verticalKernel?.outputImage {
            // Combine horizontal and vertical edges
            let addFilter = CIFilter(name: "CIAdditionCompositing")
            addFilter?.setValue(hOutput, forKey: kCIInputImageKey)
            addFilter?.setValue(vOutput, forKey: kCIInputBackgroundImageKey)
            
            if let magOutput = addFilter?.outputImage,
               let cgImage = context.createCGImage(magOutput, from: magOutput.extent) {
                magnitudeImage = UIImage(cgImage: cgImage)
                processedImageCache["\(cacheKey)_m"] = magnitudeImage
            }
        }
        
        return (horizontalImage, verticalImage, magnitudeImage)
    }
    
    // MARK: - Concurrent Sobel Processing
    
    private func processHorizontalEdges(_ kernel: CIFilter?, cacheKey: String) async -> UIImage? {
        guard let hOutput = kernel?.outputImage,
              let cgImage = context.createCGImage(hOutput, from: hOutput.extent) else {
            return nil
        }
        let image = UIImage(cgImage: cgImage)
        processedImageCache["\(cacheKey)_h"] = image
        return image
    }
    
    private func processVerticalEdges(_ kernel: CIFilter?, cacheKey: String) async -> UIImage? {
        guard let vOutput = kernel?.outputImage,
              let cgImage = context.createCGImage(vOutput, from: vOutput.extent) else {
            return nil
        }
        let image = UIImage(cgImage: cgImage)
        processedImageCache["\(cacheKey)_v"] = image
        return image
    }
    
    private func processMagnitude(hOutput: CIImage, vOutput: CIImage, cacheKey: String) async -> UIImage? {
        // Combine horizontal and vertical edges
        let addFilter = CIFilter(name: "CIAdditionCompositing")
        addFilter?.setValue(hOutput, forKey: kCIInputImageKey)
        addFilter?.setValue(vOutput, forKey: kCIInputBackgroundImageKey)
        
        guard let magOutput = addFilter?.outputImage,
              let cgImage = context.createCGImage(magOutput, from: magOutput.extent) else {
            return nil
        }
        let image = UIImage(cgImage: cgImage)
        processedImageCache["\(cacheKey)_m"] = image
        return image
    }
    
    // MARK: - Histogram Analysis
    
    func analyzeHistogram(_ image: UIImage) async -> HistogramData {
        guard let cgImage = image.cgImage else {
            return HistogramData(brightness: [], distribution: .normal, averageBrightness: 0.5)
        }
        
        let width = cgImage.width
        let height = cgImage.height
        
        // Create grayscale bitmap context
        let colorSpace = CGColorSpaceCreateDeviceGray()
        let bitmapInfo = CGImageAlphaInfo.none.rawValue
        
        guard let context = CGContext(data: nil,
                                      width: width,
                                      height: height,
                                      bitsPerComponent: 8,
                                      bytesPerRow: width,
                                      space: colorSpace,
                                      bitmapInfo: bitmapInfo) else {
            return HistogramData(brightness: [], distribution: .normal, averageBrightness: 0.5)
        }
        
        context.draw(cgImage, in: CGRect(x: 0, y: 0, width: width, height: height))
        
        guard let pixelData = context.data else {
            return HistogramData(brightness: [], distribution: .normal, averageBrightness: 0.5)
        }
        
        let data = pixelData.bindMemory(to: UInt8.self, capacity: width * height)
        
        // Use concurrent processing for histogram calculation
        return await analyzeHistogramConcurrent(data: data, width: width, height: height)
    }
    
    // Synchronous version for backward compatibility
    func analyzeHistogramSync(_ image: UIImage) -> HistogramData {
        guard let cgImage = image.cgImage else {
            return HistogramData(brightness: [], distribution: .normal, averageBrightness: 0.5)
        }
        
        let width = cgImage.width
        let height = cgImage.height
        
        // Create grayscale bitmap context
        let colorSpace = CGColorSpaceCreateDeviceGray()
        let bitmapInfo = CGImageAlphaInfo.none.rawValue
        
        guard let context = CGContext(data: nil,
                                      width: width,
                                      height: height,
                                      bitsPerComponent: 8,
                                      bytesPerRow: width,
                                      space: colorSpace,
                                      bitmapInfo: bitmapInfo) else {
            return HistogramData(brightness: [], distribution: .normal, averageBrightness: 0.5)
        }
        
        context.draw(cgImage, in: CGRect(x: 0, y: 0, width: width, height: height))
        
        guard let pixelData = context.data else {
            return HistogramData(brightness: [], distribution: .normal, averageBrightness: 0.5)
        }
        
        let data = pixelData.bindMemory(to: UInt8.self, capacity: width * height)
        
        // Calculate histogram directly (synchronous version)
        var histogram = [Int](repeating: 0, count: 256)
        var totalBrightness: Int = 0
        
        let pixelCount = width * height
        for i in 0..<pixelCount {
            let brightness = Int(data[i])
            histogram[brightness] += 1
            totalBrightness += brightness
        }
        
        let averageBrightness = Float(totalBrightness) / Float(pixelCount) / 255.0
        let distribution = determineDistribution(histogram: histogram, totalPixels: pixelCount)
        
        return HistogramData(
            brightness: histogram,
            distribution: distribution,
            averageBrightness: averageBrightness
        )
    }
    
    private func analyzeHistogramConcurrent(data: UnsafePointer<UInt8>, width: Int, height: Int) async -> HistogramData {
        let pixelCount = width * height
        
        // Split the image into chunks for concurrent processing
        let chunkSize = pixelCount / ProcessInfo.processInfo.activeProcessorCount
        let chunks = stride(from: 0, to: pixelCount, by: chunkSize).map { start in
            min(start + chunkSize, pixelCount)
        }
        
        // Process chunks concurrently
        let chunkResults = await withTaskGroup(of: (histogram: [Int], totalBrightness: Int).self) { group in
            for (index, end) in chunks.enumerated() {
                let start = index * chunkSize
                group.addTask {
                    return self.processHistogramChunk(data: data, start: start, end: end)
                }
            }
            
            var results: [(histogram: [Int], totalBrightness: Int)] = []
            for await result in group {
                results.append(result)
            }
            return results
        }
        
        // Combine results
        var combinedHistogram = [Int](repeating: 0, count: 256)
        var totalBrightness: Int = 0
        
        for result in chunkResults {
            for (index, count) in result.histogram.enumerated() {
                combinedHistogram[index] += count
            }
            totalBrightness += result.totalBrightness
        }
        
        let averageBrightness = Float(totalBrightness) / Float(pixelCount) / 255.0
        let distribution = determineDistribution(histogram: combinedHistogram, totalPixels: pixelCount)
        
        return HistogramData(
            brightness: combinedHistogram,
            distribution: distribution,
            averageBrightness: averageBrightness
        )
    }
    
    private func processHistogramChunk(data: UnsafePointer<UInt8>, start: Int, end: Int) -> (histogram: [Int], totalBrightness: Int) {
        var histogram = [Int](repeating: 0, count: 256)
        var totalBrightness: Int = 0
        
        for i in start..<end {
            let brightness = Int(data[i])
            histogram[brightness] += 1
            totalBrightness += brightness
        }
        
        return (histogram: histogram, totalBrightness: totalBrightness)
    }
    
    private func determineDistribution(histogram: [Int], totalPixels: Int) -> BrightnessDistribution {
        let lowThird = histogram[0..<85].reduce(0, +)
        let midThird = histogram[85..<170].reduce(0, +)
        let highThird = histogram[170..<256].reduce(0, +)
        
        let lowRatio = Float(lowThird) / Float(totalPixels)
        let midRatio = Float(midThird) / Float(totalPixels)
        let highRatio = Float(highThird) / Float(totalPixels)
        
        if lowRatio > 0.5 {
            return .underexposed
        } else if highRatio > 0.5 {
            return .overexposed
        } else if midRatio > 0.6 {
            return .normal
        } else {
            return .highContrast
        }
    }
    
    // MARK: - Contrast Enhancement
    
    func enhanceContrast(_ image: UIImage, amount: Float = 1.5) -> UIImage? {
        let cacheKey = "contrast_\(image.hashValue)_\(amount)"
        if let cached = processedImageCache[cacheKey] {
            return cached
        }
        
        guard let ciImage = CIImage(image: image) else { return nil }
        
        let filter = CIFilter(name: "CIColorControls")
        filter?.setValue(ciImage, forKey: kCIInputImageKey)
        filter?.setValue(amount, forKey: kCIInputContrastKey)
        filter?.setValue(1.0, forKey: kCIInputSaturationKey)
        filter?.setValue(0.0, forKey: kCIInputBrightnessKey)
        
        guard let outputImage = filter?.outputImage,
              let cgImage = context.createCGImage(outputImage, from: outputImage.extent) else {
            return nil
        }
        
        let result = UIImage(cgImage: cgImage)
        processedImageCache[cacheKey] = result
        return result
    }
    
    // MARK: - Saliency Detection
    
    func detectSalientRegions(_ image: UIImage) -> [CGRect] {
        guard let ciImage = CIImage(image: image) else { return [] }
        
        // Use a simple approach: detect high contrast regions
        let contrastFilter = CIFilter(name: "CIColorControls")
        contrastFilter?.setValue(ciImage, forKey: kCIInputImageKey)
        contrastFilter?.setValue(2.0, forKey: kCIInputContrastKey)
        
        // Apply threshold to find bright regions
        let thresholdFilter = CIFilter(name: "CIColorThreshold")
        thresholdFilter?.setValue(contrastFilter?.outputImage, forKey: kCIInputImageKey)
        thresholdFilter?.setValue(0.5, forKey: "inputThreshold")
        
        // For now, return placeholder regions
        // In a real implementation, we'd analyze the threshold output
        let imageSize = image.size
        return [
            CGRect(x: imageSize.width * 0.3, y: imageSize.height * 0.3,
                   width: imageSize.width * 0.4, height: imageSize.height * 0.4)
        ]
    }
    
    // MARK: - Cache Management
    
    func clearCache() {
        processedImageCache.removeAll()
    }
}

// MARK: - Supporting Types

struct HistogramData {
    let brightness: [Int]
    let distribution: BrightnessDistribution
    let averageBrightness: Float
}

enum BrightnessDistribution {
    case underexposed
    case normal
    case overexposed
    case highContrast
    
    var description: String {
        switch self {
        case .underexposed: return "Underexposed"
        case .normal: return "Normal"
        case .overexposed: return "Overexposed"
        case .highContrast: return "High Contrast"
        }
    }
} 
