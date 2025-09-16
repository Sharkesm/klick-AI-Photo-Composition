//
//  FilterPack.swift
//  Klick
//
//  Created by Manase on 07/09/2025.
//
import UIKit
import CoreImage
import CoreImage.CIFilterBuiltins

// MARK: - Filter System

enum FilterPack: String, CaseIterable {
    case glow = "😍 Glow Pack"
    case cine = "🍿 Cine Pack"
    case aesthetic = "🌹 Aesthetic Pack"
}

struct PhotoFilter: Identifiable, Hashable {
    let id: String
    let name: String
    let tagline: String
    let pack: FilterPack
    let scenario: String
    let previewImageName: String?
    let filterType: CIFilterType
    let parameters: [String: Any]

    var displayName: String {
        "\(id) - \(name)"
    }

    static func == (lhs: PhotoFilter, rhs: PhotoFilter) -> Bool {
        lhs.id == rhs.id
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}

enum CIFilterType {
    case builtIn(String) // CIFilter name
    case customLUT(String) // LUT file name
    case none // Original image
}

struct FilterAdjustment {
    var id: String = UUID().uuidString
    var title: String
    var intensity: Double = 0.6 // 0-1
    var brightness: Double = 0.0 // -0.2 to 0.2
    var warmth: Double = 0.0 // -0.2 to 0.2
    
    static let subtle = FilterAdjustment(title: "Subtle", intensity: 0.3, brightness: 0.0, warmth: 0.0)
    static let balanced = FilterAdjustment(title: "Balanced", intensity: 0.6, brightness: 0.0, warmth: 0.0)
    static let strong = FilterAdjustment(title: "Strong", intensity: 0.9, brightness: 0.0, warmth: 0.0)
}

// MARK: - Filter Definitions

class FilterManager {
    static let shared = FilterManager()

    // Performance optimizations
    private let context = CIContext(options: [
        .useSoftwareRenderer: false,
        .cacheIntermediates: true,
        .workingColorSpace: CGColorSpaceCreateDeviceRGB()
    ])
    private var filterCache = NSCache<NSString, UIImage>()
    private let lutApplier = LUTApplier()
    
    private init() {
        // Configure cache limits
        filterCache.countLimit = 50 // Limit to 50 cached filter results
        filterCache.totalCostLimit = 100 * 1024 * 1024 // 100MB limit
        
        // Preload common LUTs for better performance
        lutApplier.preloadCommonLUTs()
    }

    let allFilters: [PhotoFilter] = [
        // 🌞 The Glow Pack - "Main Character Energy"
        PhotoFilter(
            id: "GH1",
            name: "Goddess",
            tagline: "Golden Hour Goddess - Main character energy, activated ✨",
            pack: .glow,
            scenario: "Beach walks, rooftop evenings",
            previewImageName: nil,
            filterType: .customLUT("Bourbon 64"),
            parameters: [:]
        ),
        PhotoFilter(
            id: "SV1",
            name: "Slay",
            tagline: "Sunset Slay - Serving golden hour perfection 🌅",
            pack: .glow,
            scenario: "Travel, couples at dusk",
            previewImageName: nil,
            filterType: .customLUT("Teigen 28"),
            parameters: [:]
        ),
        PhotoFilter(
            id: "PS1",
            name: "Peachy",
            tagline: "Peach Perfect - Your selfie's glow-up bestie 🍑",
            pack: .glow,
            scenario: "Selfies, beauty/lifestyle posts",
            previewImageName: nil,
            filterType: .customLUT("Pitaya 15"),
            parameters: [:]
        ),
        PhotoFilter(
            id: "WS1",
            name: "Cali",
            tagline: "California Dreaming - West coast golden vibes 🌴",
            pack: .glow,
            scenario: "Outdoor portraits, vacation shots",
            previewImageName: nil,
            filterType: .customLUT("Pasadena 21"),
            parameters: [:]
        ),
        PhotoFilter(
            id: "LK1",
            name: "Lucky",
            tagline: "Lucky Charm - Good vibes only energy 🍀",
            pack: .glow,
            scenario: "Happy moments, celebrations",
            previewImageName: nil,
            filterType: .customLUT("Lucky 64"),
            parameters: [:]
        ),
        PhotoFilter(
            id: "GL1",
            name: "Midas",
            tagline: "Midas Touch - Everything you touch turns gold ✋",
            pack: .glow,
            scenario: "Portraits, landscapes, everyday moments",
            previewImageName: nil,
            filterType: .customLUT("Golden Light"),
            parameters: [:]
        ),
        PhotoFilter(
            id: "G200",
            name: "Vintage",
            tagline: "Vintage Vibes - Nostalgic film aesthetic 📸",
            pack: .glow,
            scenario: "Vintage-inspired photography, warm lighting",
            previewImageName: nil,
            filterType: .customLUT("Gold 200"),
            parameters: [:]
        ),

        // 🎬 The Cine Pack - "Movie Star Moments"
        PhotoFilter(
            id: "CT1",
            name: "Neon",
            tagline: "Neon Nights - Hollywood blockbuster energy 🌃",
            pack: .cine,
            scenario: "Urban, night portraits",
            previewImageName: nil,
            filterType: .customLUT("Neon 770"),
            parameters: [:]
        ),
        PhotoFilter(
            id: "MN1",
            name: "Academia",
            tagline: "Dark Academia - Mysterious intellectual vibes 🖤",
            pack: .cine,
            scenario: "Studio, dramatic headshots",
            previewImageName: nil,
            filterType: .customLUT("Azrael 93"),
            parameters: [:]
        ),
        PhotoFilter(
            id: "R9",
            name: "Rewind",
            tagline: "Retro Rewind - Y2K throwback aesthetic ⏪",
            pack: .cine,
            scenario: "Lifestyle, retro outfits",
            previewImageName: nil,
            filterType: .customLUT("Reeve 38"),
            parameters: [:]
        ),
        PhotoFilter(
            id: "KB1",
            name: "Noir",
            tagline: "Film Noir - Classic cinema magic 🎭",
            pack: .cine,
            scenario: "Portrait photography, artistic shots",
            previewImageName: nil,
            filterType: .customLUT("Korben 214"),
            parameters: [:]
        ),
        PhotoFilter(
            id: "CH1",
            name: "Edge",
            tagline: "Urban Edge - Street style with attitude 🏙️",
            pack: .cine,
            scenario: "Urban exploration, street photography",
            previewImageName: nil,
            filterType: .customLUT("Chemical 168"),
            parameters: [:]
        ),
        PhotoFilter(
            id: "FD1",
            name: "Fade",
            tagline: "Vintage Film - Old school cool vibes 🎞️",
            pack: .cine,
            scenario: "Nostalgic moments, artistic portraits",
            previewImageName: nil,
            filterType: .customLUT("Faded 47"),
            parameters: [:]
        ),
        PhotoFilter(
            id: "P800",
            name: "Portra",
            tagline: "Portrait Pro - Professional photographer approved 📷",
            pack: .cine,
            scenario: "Portrait photography, natural lighting",
            previewImageName: nil,
            filterType: .customLUT("Portra 800"),
            parameters: [:]
        ),
        PhotoFilter(
            id: "CF1",
            name: "Coastal",
            tagline: "Beach Babe - Coastal goddess mode 🏖️",
            pack: .cine,
            scenario: "Color grading, film emulation",
            previewImageName: nil,
            filterType: .customLUT("Coastal Film"),
            parameters: [:]
        ),
        PhotoFilter(
            id: "EC1",
            name: "Chrome",
            tagline: "Chrome Dreams - Futuristic vibes activated 💎",
            pack: .cine,
            scenario: "Professional photography, vibrant colors",
            previewImageName: nil,
            filterType: .customLUT("Elite Chrome"),
            parameters: [:]
        ),
        PhotoFilter(
            id: "C400",
            name: "Color",
            tagline: "Film Fresh - That authentic film look 🎨",
            pack: .cine,
            scenario: "Film emulation, sharp details, natural portraits",
            previewImageName: nil,
            filterType: .customLUT("Color 400"),
            parameters: [:]
        ),

        // 💫 The Aesthetic Pack - "Soft Girl/Boy Energy"
        PhotoFilter(
            id: "CW1",
            name: "Clean",
            tagline: "Clean Girl - Effortless minimalist vibes 🤍",
            pack: .aesthetic,
            scenario: "Fashion, minimalist portraits",
            previewImageName: nil,
            filterType: .customLUT("Clouseau 54"),
            parameters: [:]
        ),
        PhotoFilter(
            id: "DP1",
            name: "Dreamy",
            tagline: "Dreamy Soft - Living in a cloud aesthetic ☁️",
            pack: .aesthetic,
            scenario: "Fun lifestyle, creative reels",
            previewImageName: nil,
            filterType: .customLUT("Hyla 68"),
            parameters: [:]
        ),
        PhotoFilter(
            id: "MM1",
            name: "Mocha",
            tagline: "Coffee Shop - Cozy café main character ☕",
            pack: .aesthetic,
            scenario: "Cafés, reading, cozy indoors",
            previewImageName: nil,
            filterType: .customLUT("Arabica 12"),
            parameters: [:]
        ),
        PhotoFilter(
            id: "VR1",
            name: "Angel",
            tagline: "Angel Glow - Heavenly soft energy 👼",
            pack: .aesthetic,
            scenario: "Romantic portraits, soft lighting",
            previewImageName: nil,
            filterType: .customLUT("Vireo 37"),
            parameters: [:]
        ),
        PhotoFilter(
            id: "CB1",
            name: "Fresh",
            tagline: "Fresh Face - Natural beauty enhanced 😊",
            pack: .aesthetic,
            scenario: "Contemporary lifestyle, social media",
            previewImageName: nil,
            filterType: .customLUT("Cobi 3"),
            parameters: [:]
        ),
        PhotoFilter(
            id: "ML1",
            name: "Charm",
            tagline: "Vintage Charm - Retro cuteness overload 💕",
            pack: .aesthetic,
            scenario: "Vintage-inspired shoots, creative content",
            previewImageName: nil,
            filterType: .customLUT("Milo 5"),
            parameters: [:]
        ),
        PhotoFilter(
            id: "CR100",
            name: "Beachy",
            tagline: "Beach Vibes - Endless summer energy 🌊",
            pack: .aesthetic,
            scenario: "Beach photography, creative projects",
            previewImageName: nil,
            filterType: .customLUT("Creatives 100"),
            parameters: [:]
        ),
        PhotoFilter(
            id: "P100",
            name: "Softie",
            tagline: "Soft Focus - Dreamy portrait perfection 🌸",
            pack: .aesthetic,
            scenario: "Portrait photography, soft lighting",
            previewImageName: nil,
            filterType: .customLUT("Portrait 100"),
            parameters: [:]
        ),
        
        // Bonus Filters - Popular LUTs
        PhotoFilter(
            id: "DJ1",
            name: "Midnight",
            tagline: "Midnight Mood - After dark energy 🌙",
            pack: .cine,
            scenario: "Night photography, moody portraits",
            previewImageName: nil,
            filterType: .customLUT("Django 25"),
            parameters: [:]
        ),
        PhotoFilter(
            id: "FS1",
            name: "Fusion",
            tagline: "Color Pop - Vibrant energy unleashed 🎨",
            pack: .aesthetic,
            scenario: "Creative content, bold looks",
            previewImageName: nil,
            filterType: .customLUT("Fusion 88"),
            parameters: [:]
        ),
        PhotoFilter(
            id: "SP1",
            name: "Sprocket",
            tagline: "Film Burn - Authentic film texture 🔥",
            pack: .cine,
            scenario: "Artistic photography, texture lovers",
            previewImageName: nil,
            filterType: .customLUT("Sprocket 231"),
            parameters: [:]
        )
    ]

    func filters(for pack: FilterPack) -> [PhotoFilter] {
        allFilters.filter { $0.pack == pack }
    }

    func applyFilter(_ filter: PhotoFilter, to image: UIImage, adjustments: FilterAdjustment = .balanced, useCache: Bool = true) -> UIImage? {
        // Create cache key
        let cacheKey = "\(filter.id)_\(adjustments.intensity)_\(adjustments.brightness)_\(adjustments.warmth)_\(image.hash)" as NSString

        // Check cache first
        if useCache, let cachedImage = filterCache.object(forKey: cacheKey) {
            return cachedImage
        }

        var resultImage: UIImage?

        // Apply base filter
        switch filter.filterType {
        case .builtIn(let filterName):
            // Legacy support for built-in filters (if needed)
            guard let ciImage = CIImage(image: image) else { return image }
            var processedImage = ciImage
            
            if let ciFilter = CIFilter(name: filterName) {
                ciFilter.setValue(processedImage, forKey: kCIInputImageKey)
                if let output = ciFilter.outputImage {
                    processedImage = output
                }
            }
            
            // Apply adjustments
            processedImage = applyAdjustments(adjustments, to: processedImage)
            
            guard let cgImage = context.createCGImage(processedImage, from: processedImage.extent) else {
                return image
            }
            
            resultImage = UIImage(cgImage: cgImage)
            
        case .customLUT(let lutName):
            // Apply LUT with intensity from adjustments
            resultImage = lutApplier.applyLUT(
                lutFileName: lutName,
                to: image,
                intensity: Float(adjustments.intensity)
            )
            
            // Apply additional adjustments (brightness and warmth) if needed
            if let lutResult = resultImage,
               (adjustments.brightness != 0 || adjustments.warmth != 0) {
                guard let ciImage = CIImage(image: lutResult) else { return lutResult }
                let adjustedImage = applyBrightnessAndWarmth(adjustments, to: ciImage)
                
                guard let cgImage = context.createCGImage(adjustedImage, from: adjustedImage.extent) else {
                    return lutResult
                }
                
                resultImage = UIImage(cgImage: cgImage)
            }
            
        case .none:
            return image
        }

        // Use the original image as fallback
        let finalResult = resultImage ?? image

        // Cache the result
        if useCache {
            filterCache.setObject(finalResult, forKey: cacheKey)
        }

        return finalResult
    }

    func generateFilterPreview(_ filter: PhotoFilter, for image: UIImage, size: CGSize = CGSize(width: 60, height: 60)) -> UIImage? {
        // Create a smaller version for preview
        let previewImage = image.resized(to: size) ?? image
        return applyFilter(filter, to: previewImage, adjustments: .balanced, useCache: true)
    }

    func exportImage(_ image: UIImage, withWatermark: Bool = true, quality: CGFloat = 0.9) -> Data? {
        return image.jpegData(compressionQuality: quality)
    }

    private func applyAdjustments(_ adjustments: FilterAdjustment, to ciImage: CIImage) -> CIImage {
        var processedImage = ciImage

        // Brightness adjustment
        if adjustments.brightness != 0 {
            let brightnessFilter = CIFilter.colorControls()
            brightnessFilter.inputImage = processedImage
            brightnessFilter.brightness = Float(adjustments.brightness)
            if let output = brightnessFilter.outputImage {
                processedImage = output
            }
        }

        // Temperature adjustment (warmth)
        if adjustments.warmth != 0 {
            let temperatureFilter = CIFilter.temperatureAndTint()
            temperatureFilter.inputImage = processedImage
            temperatureFilter.neutral = CIVector(x: 6500, y: 0)
            temperatureFilter.targetNeutral = CIVector(x: 6500 * (1 + adjustments.warmth), y: 0)
            if let output = temperatureFilter.outputImage {
                processedImage = output
            }
        }

        // Intensity adjustment (opacity blend with original)
        if adjustments.intensity < 1.0 {
            let blendFilter = CIFilter.dissolveTransition()
            blendFilter.inputImage = ciImage
            blendFilter.targetImage = processedImage
            blendFilter.time = Float(adjustments.intensity)
            if let output = blendFilter.outputImage {
                processedImage = output
            }
        }

        return processedImage
    }
    
    /// Apply only brightness and warmth adjustments (used for LUT post-processing)
    private func applyBrightnessAndWarmth(_ adjustments: FilterAdjustment, to ciImage: CIImage) -> CIImage {
        var processedImage = ciImage

        // Brightness adjustment
        if adjustments.brightness != 0 {
            let brightnessFilter = CIFilter.colorControls()
            brightnessFilter.inputImage = processedImage
            brightnessFilter.brightness = Float(adjustments.brightness)
            if let output = brightnessFilter.outputImage {
                processedImage = output
            }
        }

        // Temperature adjustment (warmth)
        if adjustments.warmth != 0 {
            let temperatureFilter = CIFilter.temperatureAndTint()
            temperatureFilter.inputImage = processedImage
            temperatureFilter.neutral = CIVector(x: 6500, y: 0)
            temperatureFilter.targetNeutral = CIVector(x: 6500 * (1 + adjustments.warmth), y: 0)
            if let output = temperatureFilter.outputImage {
                processedImage = output
            }
        }

        return processedImage
    }
    
    /// Clear all caches to free memory (call when receiving memory warnings)
    func clearAllCaches() {
        filterCache.removeAllObjects()
        lutApplier.clearCache()
        print("🗑️ All filter caches cleared")
    }
    
    /// Get memory usage information
    func getMemoryInfo() -> String {
        let filterCacheCount = filterCache.countLimit
        let lutInfo = lutApplier.getCacheInfo()
        return "Filter Cache: \(filterCacheCount) items, LUT Cache: \(lutInfo.count) items (~\(String(format: "%.1f", lutInfo.estimatedMemoryMB))MB)"
    }
}
