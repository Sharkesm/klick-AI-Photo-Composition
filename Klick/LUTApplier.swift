import CoreImage
import UIKit
import Foundation

/// A class responsible for loading and applying .cube LUT files to images
class LUTApplier {
    private let context = CIContext(options: [
        .useSoftwareRenderer: false,
        .cacheIntermediates: true,
        .workingColorSpace: CGColorSpaceCreateDeviceRGB()
    ])
    
    // Cache for parsed LUT data to avoid re-parsing
    private var lutCache: [String: (NSData, Int)] = [:]
    
    /// Apply a LUT from a .cube file to a UIImage
    /// - Parameters:
    ///   - lutFileName: Name of the .cube file (without extension)
    ///   - image: The input image to apply the LUT to
    ///   - intensity: Blend intensity (0.0 = original, 1.0 = full LUT effect)
    /// - Returns: The filtered image, or nil if the operation fails
    func applyLUT(lutFileName: String, to image: UIImage, intensity: Float = 1.0) -> UIImage? {
        // Early return for no effect
        if intensity <= 0.0 {
            return image
        }
        
        guard let ciImage = CIImage(image: image) else {
            SVLogger.main.log(message: "Failed to create CIImage from UIImage", logLevel: .error)
            return nil
        }
        
        // Get LUT data (from cache or parse)
        guard let (cubeData, size) = getLUTData(fileName: lutFileName) else {
            SVLogger.main.log(message: "Failed to load LUT", info: lutFileName, logLevel: .error)
            return image
        }
        
        // Create and configure the CIColorCube filter
        guard let filter = CIFilter(name: "CIColorCube") else {
            SVLogger.main.log(message: "Failed to create CIColorCube filter", logLevel: .error)
            return image
        }
        
        filter.setValue(size, forKey: "inputCubeDimension")
        filter.setValue(cubeData, forKey: "inputCubeData")
        filter.setValue(ciImage, forKey: kCIInputImageKey)
        
        guard let lutOutput = filter.outputImage else {
            SVLogger.main.log(message: "Failed to get LUT filter output", logLevel: .error)
            return image
        }
        
        var finalOutput = lutOutput
        
        // Apply intensity blending if needed (more efficient approach)
        if intensity < 1.0 {
            // Use source over compositing for better performance
            guard let blendFilter = CIFilter(name: "CISourceOverCompositing") else {
                SVLogger.main.log(message: "Failed to create blend filter, using dissolve transition", logLevel: .error)
                // Fallback to dissolve transition
                if let dissolveFilter = CIFilter(name: "CIDissolveTransition") {
                    dissolveFilter.setValue(ciImage, forKey: kCIInputImageKey)
                    dissolveFilter.setValue(lutOutput, forKey: "inputTargetImage")
                    dissolveFilter.setValue(intensity, forKey: "inputTime")
                    finalOutput = dissolveFilter.outputImage ?? lutOutput
                }
                return convertToUIImage(finalOutput, fallback: image)
            }
            
            // Create a semi-transparent version of the LUT output
            guard let opacityFilter = CIFilter(name: "CIColorMatrix") else {
                return convertToUIImage(lutOutput, fallback: image)
            }
            
            opacityFilter.setValue(lutOutput, forKey: kCIInputImageKey)
            opacityFilter.setValue(CIVector(x: 1, y: 0, z: 0, w: 0), forKey: "inputRVector")
            opacityFilter.setValue(CIVector(x: 0, y: 1, z: 0, w: 0), forKey: "inputGVector")
            opacityFilter.setValue(CIVector(x: 0, y: 0, z: 1, w: 0), forKey: "inputBVector")
            opacityFilter.setValue(CIVector(x: 0, y: 0, z: 0, w: CGFloat(intensity)), forKey: "inputAVector")
            
            guard let transparentLUT = opacityFilter.outputImage else {
                return convertToUIImage(lutOutput, fallback: image)
            }
            
            blendFilter.setValue(ciImage, forKey: kCIInputBackgroundImageKey)
            blendFilter.setValue(transparentLUT, forKey: kCIInputImageKey)
            
            finalOutput = blendFilter.outputImage ?? lutOutput
        }
        
        return convertToUIImage(finalOutput, fallback: image)
    }
    
    /// Convert CIImage to UIImage with error handling
    private func convertToUIImage(_ ciImage: CIImage, fallback: UIImage) -> UIImage {
        guard let cgImage = context.createCGImage(ciImage, from: ciImage.extent) else {
            SVLogger.main.log(message: "Failed to create CGImage from filtered output", logLevel: .error)
            return fallback
        }
        
        return UIImage(cgImage: cgImage)
    }
    
    /// Get LUT data from cache or parse from file
    private func getLUTData(fileName: String) -> (NSData, Int)? {
        // Check cache first
        if let cachedData = lutCache[fileName] {
            return cachedData
        }
        
        // Load and parse the .cube file (try both uppercase and lowercase extensions)
        var url = Bundle.main.url(forResource: fileName, withExtension: "CUBE")
        if url == nil {
            url = Bundle.main.url(forResource: fileName, withExtension: "cube")
        }
        
        guard let fileURL = url, let data = try? Data(contentsOf: fileURL) else {
            SVLogger.main.log(message: "Failed to load .cube file", info: fileName, logLevel: .error)
            return nil
        }
        
        guard let parsedData = parseCubeFile(data: data) else {
            SVLogger.main.log(message: "Failed to parse .cube file", info: fileName, logLevel: .error)
            return nil
        }
        
        // Cache the parsed data
        lutCache[fileName] = parsedData
        return parsedData
    }
    
    /// Parse a .cube LUT file and extract the color data
    private func parseCubeFile(data: Data) -> (NSData, Int)? {
        guard let content = String(data: data, encoding: .utf8) else {
            SVLogger.main.log(message: "Failed to decode .cube file as UTF-8", logLevel: .error)
            return nil
        }
        
        var size = 0
        var cubeValues: [Float] = []
        
        let lines = content.components(separatedBy: .newlines)
        
        for line in lines {
            let clean = line.trimmingCharacters(in: .whitespaces)
            
            // Skip empty lines and comments
            if clean.isEmpty || clean.hasPrefix("#") {
                continue
            }
            
            // Parse LUT size
            if clean.hasPrefix("LUT_3D_SIZE") {
                let components = clean.components(separatedBy: " ")
                if components.count >= 2, let sizeValue = Int(components[1]) {
                    size = sizeValue
                }
                continue
            }
            
            // Skip other metadata lines
            if clean.hasPrefix("TITLE") || clean.hasPrefix("DOMAIN_MIN") || clean.hasPrefix("DOMAIN_MAX") {
                continue
            }
            
            // Parse RGB data lines
            let components = clean.split(separator: " ")
            if components.count >= 3 {
                if let r = Float(components[0]),
                   let g = Float(components[1]),
                   let b = Float(components[2]) {
                    // Core Image expects RGBA format
                    cubeValues.append(contentsOf: [r, g, b, 1.0])
                }
            }
        }
        
        // Validate the parsed data
        let expectedCount = size * size * size * 4 // RGBA
        guard size > 0, cubeValues.count == expectedCount else {
            SVLogger.main.log(message: "Invalid LUT data: size=\(size), values=\(cubeValues.count), expected=\(expectedCount)", logLevel: .error)
            return nil
        }
        
        let cubeData = NSData(bytes: cubeValues, length: cubeValues.count * MemoryLayout<Float>.size)
        return (cubeData, size)
    }
    
    /// Preload commonly used LUTs for better performance
    func preloadCommonLUTs() {
        let commonLUTs = [
            "Bourbon 64", "Teigen 28", "Pitaya 15", "Pasadena 21", "Lucky 64",
            "Neon 770", "Azrael 93", "Reeve 38", "Korben 214", "Chemical 168",
            "Clouseau 54", "Hyla 68", "Arabica 12", "Vireo 37", "Cobi 3",
            "Portra 800", "Golden Light", "Gold 200", "Elite Chrome", "Portrait 100",
            "Color 400"
        ]
        
        DispatchQueue.global(qos: .utility).async { [weak self] in
            for lutName in commonLUTs {
                _ = self?.getLUTData(fileName: lutName)
            }
        }
    }
    
    /// Clear the LUT cache to free memory
    func clearCache() {
        lutCache.removeAll()
    }
    
    /// Get cache statistics
    func getCacheInfo() -> (count: Int, estimatedMemoryMB: Double) {
        let count = lutCache.count
        let estimatedMemory = Double(count * 32 * 32 * 32 * 4 * 4) / (1024 * 1024) // Rough estimate for 32³ LUTs
        return (count, estimatedMemory)
    }
    
    /// Get available LUT file names from the bundle
    static func getAvailableLUTs() -> [String] {
        guard let bundlePath = Bundle.main.resourcePath else { return [] }
        let lutsPath = bundlePath + "/Luts"
        
        do {
            let files = try FileManager.default.contentsOfDirectory(atPath: lutsPath)
            return files.compactMap { fileName in
                if fileName.hasSuffix(".CUBE") {
                    return String(fileName.dropLast(5)) // Remove .CUBE extension
                } else if fileName.hasSuffix(".cube") {
                    return String(fileName.dropLast(5)) // Remove .cube extension
                }
                return nil
            }.sorted()
        } catch {
            SVLogger.main.log(message: "Failed to list LUT files", info: error.localizedDescription, logLevel: .error)
            return []
        }
    }
}
