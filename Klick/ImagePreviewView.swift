import SwiftUI
import UIKit
import Social
import CoreImage
import CoreImage.CIFilterBuiltins

// MARK: - Filter System

enum FilterPack: String, CaseIterable {
    case glow = "🌞 The Glow Pack"
    case cine = "🎬 The Cine Pack"
    case aesthetic = "💫 The Aesthetic Pack"
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
    var intensity: Double = 0.6 // 0-1
    var brightness: Double = 0.0 // -0.2 to 0.2
    var warmth: Double = 0.0 // -0.2 to 0.2

    static let subtle = FilterAdjustment(intensity: 0.3, brightness: 0.0, warmth: 0.0)
    static let balanced = FilterAdjustment(intensity: 0.6, brightness: 0.0, warmth: 0.0)
    static let strong = FilterAdjustment(intensity: 0.9, brightness: 0.0, warmth: 0.0)
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
        // 🌞 The Glow Pack
        PhotoFilter(
            id: "GH1",
            name: "Golden Hour Glow",
            tagline: "Mimic golden-hour magic",
            pack: .glow,
            scenario: "Beach walks, rooftop evenings",
            previewImageName: nil,
            filterType: .customLUT("Bourbon 64"),
            parameters: [:]
        ),
        PhotoFilter(
            id: "SV1",
            name: "Sunset Vibe",
            tagline: "Paint your portraits with sunset skies",
            pack: .glow,
            scenario: "Travel, couples at dusk",
            previewImageName: nil,
            filterType: .customLUT("Teigen 28"),
            parameters: [:]
        ),
        PhotoFilter(
            id: "PS1",
            name: "Peach Skin",
            tagline: "Your selfie's best friend",
            pack: .glow,
            scenario: "Selfies, beauty/lifestyle posts",
            previewImageName: nil,
            filterType: .customLUT("Pitaya 15"),
            parameters: [:]
        ),
        PhotoFilter(
            id: "WS1",
            name: "Warm Summer",
            tagline: "Endless summer vibes",
            pack: .glow,
            scenario: "Outdoor portraits, vacation shots",
            previewImageName: nil,
            filterType: .customLUT("Pasadena 21"),
            parameters: [:]
        ),
        PhotoFilter(
            id: "LK1",
            name: "Lucky Charm",
            tagline: "Bright and cheerful",
            pack: .glow,
            scenario: "Happy moments, celebrations",
            previewImageName: nil,
            filterType: .customLUT("Lucky 64"),
            parameters: [:]
        ),
        PhotoFilter(
            id: "GL1",
            name: "Golden Light",
            tagline: "Warm tones and rich colors",
            pack: .glow,
            scenario: "Portraits, landscapes, everyday moments",
            previewImageName: nil,
            filterType: .customLUT("Golden Light"),
            parameters: [:]
        ),
        PhotoFilter(
            id: "G200",
            name: "Gold 200",
            tagline: "Warmth and nostalgia of Kodak's rich hues",
            pack: .glow,
            scenario: "Vintage-inspired photography, warm lighting",
            previewImageName: nil,
            filterType: .customLUT("Gold 200"),
            parameters: [:]
        ),

        // 🎬 The Cine Pack
        PhotoFilter(
            id: "CT1",
            name: "Cinematic Teal",
            tagline: "Bring Hollywood to your portraits",
            pack: .cine,
            scenario: "Urban, night portraits",
            previewImageName: nil,
            filterType: .customLUT("Neon 770"),
            parameters: [:]
        ),
        PhotoFilter(
            id: "MN1",
            name: "Matte Noir",
            tagline: "Moody. Timeless. Powerful",
            pack: .cine,
            scenario: "Studio, dramatic headshots",
            previewImageName: nil,
            filterType: .customLUT("Azrael 93"),
            parameters: [:]
        ),
        PhotoFilter(
            id: "R9",
            name: "Retro 90s",
            tagline: "Throwback to vintage vibes",
            pack: .cine,
            scenario: "Lifestyle, retro outfits",
            previewImageName: nil,
            filterType: .customLUT("Reeve 38"),
            parameters: [:]
        ),
        PhotoFilter(
            id: "KB1",
            name: "Korben Classic",
            tagline: "Timeless cinematic look",
            pack: .cine,
            scenario: "Portrait photography, artistic shots",
            previewImageName: nil,
            filterType: .customLUT("Korben 214"),
            parameters: [:]
        ),
        PhotoFilter(
            id: "CH1",
            name: "Chemical Wash",
            tagline: "Edgy industrial vibes",
            pack: .cine,
            scenario: "Urban exploration, street photography",
            previewImageName: nil,
            filterType: .customLUT("Chemical 168"),
            parameters: [:]
        ),
        PhotoFilter(
            id: "FD1",
            name: "Faded Film",
            tagline: "Vintage film aesthetic",
            pack: .cine,
            scenario: "Nostalgic moments, artistic portraits",
            previewImageName: nil,
            filterType: .customLUT("Faded 47"),
            parameters: [:]
        ),
        PhotoFilter(
            id: "P800",
            name: "Portra 800",
            tagline: "Classic film with neutral skin tones",
            pack: .cine,
            scenario: "Portrait photography, natural lighting",
            previewImageName: nil,
            filterType: .customLUT("Portra 800"),
            parameters: [:]
        ),
        PhotoFilter(
            id: "CF1",
            name: "Coastal Film",
            tagline: "Gold 200 film characteristics",
            pack: .cine,
            scenario: "Color grading, film emulation",
            previewImageName: nil,
            filterType: .customLUT("Coastal Film"),
            parameters: [:]
        ),
        PhotoFilter(
            id: "EC1",
            name: "Elite Chrome",
            tagline: "Iconic vibrancy of Kodak Elite Chrome",
            pack: .cine,
            scenario: "Professional photography, vibrant colors",
            previewImageName: nil,
            filterType: .customLUT("Elite Chrome"),
            parameters: [:]
        ),
        PhotoFilter(
            id: "C400",
            name: "Color 400",
            tagline: "Rich, bright colors with natural skin tones",
            pack: .cine,
            scenario: "Film emulation, sharp details, natural portraits",
            previewImageName: nil,
            filterType: .customLUT("Color 400"),
            parameters: [:]
        ),

        // 💫 The Aesthetic Pack
        PhotoFilter(
            id: "CW1",
            name: "Clean White",
            tagline: "Sharp, stylish, and Instagram-ready",
            pack: .aesthetic,
            scenario: "Fashion, minimalist portraits",
            previewImageName: nil,
            filterType: .customLUT("Clouseau 54"),
            parameters: [:]
        ),
        PhotoFilter(
            id: "DP1",
            name: "Dreamy Pastel",
            tagline: "Soft tones for dreamy feeds",
            pack: .aesthetic,
            scenario: "Fun lifestyle, creative reels",
            previewImageName: nil,
            filterType: .customLUT("Hyla 68"),
            parameters: [:]
        ),
        PhotoFilter(
            id: "MM1",
            name: "Mocha Mood",
            tagline: "Warmth that feels like home",
            pack: .aesthetic,
            scenario: "Cafés, reading, cozy indoors",
            previewImageName: nil,
            filterType: .customLUT("Arabica 12"),
            parameters: [:]
        ),
        PhotoFilter(
            id: "VR1",
            name: "Vireo Soft",
            tagline: "Gentle and ethereal",
            pack: .aesthetic,
            scenario: "Romantic portraits, soft lighting",
            previewImageName: nil,
            filterType: .customLUT("Vireo 37"),
            parameters: [:]
        ),
        PhotoFilter(
            id: "CB1",
            name: "Cobi Fresh",
            tagline: "Clean and modern",
            pack: .aesthetic,
            scenario: "Contemporary lifestyle, social media",
            previewImageName: nil,
            filterType: .customLUT("Cobi 3"),
            parameters: [:]
        ),
        PhotoFilter(
            id: "ML1",
            name: "Milo Vintage",
            tagline: "Retro charm with modern appeal",
            pack: .aesthetic,
            scenario: "Vintage-inspired shoots, creative content",
            previewImageName: nil,
            filterType: .customLUT("Milo 5"),
            parameters: [:]
        ),
        PhotoFilter(
            id: "CR100",
            name: "Creatives 100",
            tagline: "Beautiful cinematic beach vibes",
            pack: .aesthetic,
            scenario: "Beach photography, creative projects",
            previewImageName: nil,
            filterType: .customLUT("Creatives 100"),
            parameters: [:]
        ),
        PhotoFilter(
            id: "P100",
            name: "Portrait 100",
            tagline: "Soft and beautiful film look",
            pack: .aesthetic,
            scenario: "Portrait photography, soft lighting",
            previewImageName: nil,
            filterType: .customLUT("Portrait 100"),
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

    func addWatermark(to image: UIImage, text: String = "KlickPhoto") -> UIImage? {
        let renderer = UIGraphicsImageRenderer(size: image.size)

        return renderer.image { context in
            // Draw original image
            image.draw(in: CGRect(origin: .zero, size: image.size))

            // Configure watermark text
            let attributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 16, weight: .medium),
                .foregroundColor: UIColor.white.withAlphaComponent(0.7)
            ]

            let attributedString = NSAttributedString(string: text, attributes: attributes)
            let textSize = attributedString.size()

            // Position watermark in bottom right corner with padding
            let padding: CGFloat = 20
            let textRect = CGRect(
                x: image.size.width - textSize.width - padding,
                y: image.size.height - textSize.height - padding,
                width: textSize.width,
                height: textSize.height
            )

            // Draw semi-transparent background for better readability
            let backgroundRect = textRect.insetBy(dx: -8, dy: -4)
            let backgroundPath = UIBezierPath(roundedRect: backgroundRect, cornerRadius: 4)
            UIColor.black.withAlphaComponent(0.3).setFill()
            backgroundPath.fill()

            // Draw watermark text
            attributedString.draw(in: textRect)
        }
    }

    func exportImage(_ image: UIImage, withWatermark: Bool = true, quality: CGFloat = 0.9) -> Data? {
        let exportImage = withWatermark ? (addWatermark(to: image) ?? image) : image
        return exportImage.jpegData(compressionQuality: quality)
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

struct ImagePreviewView: View {
    @Binding var image: UIImage?
    let originalImage: UIImage?
    @Binding var isProcessing: Bool

    let onSave: () -> Void
    let onDiscard: () -> Void

    @State private var showingShareSheet = false
    @State private var showingInstagramAlert = false

    // Filter system state
    @State private var selectedPack: FilterPack = .glow
    @State private var selectedFilter: PhotoFilter?
    @State private var currentAdjustments = FilterAdjustment.balanced
    @State private var showingAdjustments = false
    @State private var filterPreviews: [String: UIImage] = [:]

    // Performance optimization
    @State private var adjustmentWorkItem: DispatchWorkItem?

    // Save options
    @State private var showingSaveOptions = false
    @State private var isProUser = false // TODO: Connect to subscription system
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            VStack(spacing: 0) {
                TopBarView(
                    showingAdjustments: $showingAdjustments,
                    selectedFilter: selectedFilter,
                    onDiscard: onDiscard
                )
                
                Spacer()
                
                ImageDisplayView(
                    image: image,
                    isProcessing: isProcessing,
                    selectedFilter: selectedFilter,
                    onToggleOriginalFiltered: toggleOriginalFiltered
                )
                
                FilterPackSelectorView(
                    selectedPack: $selectedPack,
                    onPackSelected: { pack in selectedPack = pack }
                )
                
                FilterSelectionStripView(
                    selectedPack: selectedPack,
                    selectedFilter: selectedFilter,
                    filterPreviews: filterPreviews,
                    originalImage: originalImage,
                    onFilterSelected: selectFilter
                )
                
                if showingAdjustments && selectedFilter != nil {
                    AdjustmentControlsView(
                        adjustments: $currentAdjustments,
                        onAdjustmentChanged: { applyCurrentFilter() },
                        onDebouncedAdjustmentChanged: { applyCurrentFilter(debounce: true) }
                    )
                    .transition(.move(edge: .bottom))
                    .background(Color.black.opacity(0.95))
                }
                
                ActionButtonsView(
                    isProcessing: isProcessing,
                    selectedFilter: selectedFilter,
                    onReset: resetToOriginal,
                    onApplyPreset: applyPreset,
                    onInstagramShare: shareToInstagramStories,
                    onDiscard: onDiscard,
                    onSave: { showingSaveOptions = true }
                )
            }
        }
        .onAppear(perform: generateFilterPreviews)
        .onChange(of: selectedPack) { _ in generateFilterPreviews() }
        .alert("Instagram Not Available", isPresented: $showingInstagramAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text("Instagram is not installed on this device or Instagram Stories sharing is not available.")
        }
        .alert("Save Options", isPresented: $showingSaveOptions) {
            Button("Save as Copy", role: .none, action: saveAsCopy)
            Button("Overwrite Original", role: .destructive, action: overwriteOriginal)
            Button("Cancel", role: .cancel) { }
        } message: {
            if isProUser {
                Text("Choose how to save your edited photo.")
            } else {
                Text("Choose how to save your edited photo.\n\nFree users get watermarks on exports. Upgrade to Pro for watermark-free exports!")
            }
        }
    }

    // MARK: - Sub-Views

    struct TopBarView: View {
        @Binding var showingAdjustments: Bool
        let selectedFilter: PhotoFilter?
        let onDiscard: () -> Void

        var body: some View {
            HStack {
                Button(action: onDiscard) {
                    Image(systemName: "xmark")
                        .font(.title2)
                        .foregroundColor(.white)
                        .frame(width: 44, height: 44)
                }

                Spacer()

                Text("Preview")
                    .font(.headline)
                    .foregroundColor(.white)

                Spacer()

                Button(action: { showingAdjustments.toggle() }) {
                    Image(systemName: "slider.horizontal.3")
                        .font(.title2)
                        .foregroundColor(selectedFilter != nil ? .white : .gray)
                        .frame(width: 44, height: 44)
                }
                .disabled(selectedFilter == nil)
            }
            .padding(.horizontal, 20)
            .padding(.top, 10)
        }
    }

    struct ImageDisplayView: View {
        let image: UIImage?
        let isProcessing: Bool
        let selectedFilter: PhotoFilter?
        let onToggleOriginalFiltered: () -> Void

        var body: some View {
            Group {
                if let previewImage = image {
                    ZStack {
                        Image(uiImage: previewImage)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                            .clipped()
                            .overlay(
                                Group {
                                    if isProcessing {
                                        ZStack {
                                            Color.black.opacity(0.3)
                                            ProgressView()
                                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                                .scaleEffect(1.5)
                                        }
                                    }
                                }
                            )
                            .animation(.easeInOut(duration: 0.3), value: isProcessing)

                        if selectedFilter != nil {
                            Color.clear
                                .contentShape(Rectangle())
                                .onTapGesture(perform: onToggleOriginalFiltered)
                        }
                    }
                } else {
                    Rectangle()
                        .fill(Color.gray.opacity(0.3))
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .overlay(
                            Text("No Image")
                                .foregroundColor(.gray)
                        )
                }
            }
        }
    }

    struct FilterPackSelectorView: View {
        @Binding var selectedPack: FilterPack
        let onPackSelected: (FilterPack) -> Void

        var body: some View {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(FilterPack.allCases, id: \.self) { pack in
                        FilterPackButton(
                            pack: pack,
                            isSelected: selectedPack == pack,
                            action: { onPackSelected(pack) }
                        )
                    }
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 10)
            }
            .background(Color.black.opacity(0.8))
        }
    }

    struct FilterSelectionStripView: View {
        let selectedPack: FilterPack
        let selectedFilter: PhotoFilter?
        let filterPreviews: [String: UIImage]
        let originalImage: UIImage?
        let onFilterSelected: (PhotoFilter?) -> Void

        var body: some View {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    FilterButton(
                        filter: nil,
                        previewImage: originalImage,
                        isSelected: selectedFilter == nil,
                        action: { onFilterSelected(nil) }
                    )

                    ForEach(FilterManager.shared.filters(for: selectedPack)) { filter in
                        FilterButton(
                            filter: filter,
                            previewImage: filterPreviews[filter.id] ?? originalImage,
                            isSelected: selectedFilter?.id == filter.id,
                            action: { onFilterSelected(filter) }
                        )
                    }
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 10)
            }
            .background(Color.black.opacity(0.9))
        }
    }

    struct ActionButtonsView: View {
        let isProcessing: Bool
        let selectedFilter: PhotoFilter?
        let onReset: () -> Void
        let onApplyPreset: (FilterAdjustment) -> Void
        let onInstagramShare: () -> Void
        let onDiscard: () -> Void
        let onSave: () -> Void

        var body: some View {
            VStack(spacing: 20) {
                HStack(spacing: 20) {
                    Button(action: onReset) {
                        VStack(spacing: 8) {
                            ZStack {
                                Circle()
                                    .fill(Color.white.opacity(0.1))
                                    .frame(width: 60, height: 60)

                                Image(systemName: "arrow.counterclockwise")
                                    .font(.title2)
                                    .foregroundColor(.white)
                            }

                            Text("Reset")
                                .font(.caption)
                                .foregroundColor(.white)
                        }
                    }
                    .disabled(isProcessing)

                    PresetButtonsView(
                        isProcessing: isProcessing,
                        selectedFilter: selectedFilter,
                        onApplyPreset: onApplyPreset
                    )

                    Button(action: onInstagramShare) {
                        VStack(spacing: 8) {
                            ZStack {
                                Circle()
                                    .fill(Color.white.opacity(0.1))
                                    .frame(width: 60, height: 60)

                                Image(systemName: "camera.circle")
                                    .font(.title2)
                                    .foregroundColor(.white)
                            }

                            Text("Stories")
                                .font(.caption)
                                .foregroundColor(.white)
                        }
                    }
                    .disabled(isProcessing)
                }

                HStack(spacing: 15) {
                    Button(action: onDiscard) {
                        Text("Discard")
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 50)
                            .background(Color.red.opacity(0.8))
                            .cornerRadius(25)
                    }
                    .disabled(isProcessing)

                    Button(action: onSave) {
                        Text("Save Photo")
                            .font(.headline)
                            .foregroundColor(.black)
                            .frame(maxWidth: .infinity)
                            .frame(height: 50)
                            .background(Color.white)
                            .cornerRadius(25)
                    }
                    .disabled(isProcessing)
                }
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 40)
        }
    }

    struct PresetButtonsView: View {
        let isProcessing: Bool
        let selectedFilter: PhotoFilter?
        let onApplyPreset: (FilterAdjustment) -> Void

        var body: some View {
            HStack(spacing: 10) {
                Button(action: { onApplyPreset(.subtle) }) {
                    Text("Subtle")
                        .font(.caption2)
                        .foregroundColor(.white.opacity(0.8))
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.white.opacity(0.1))
                        .cornerRadius(12)
                }
                .disabled(isProcessing || selectedFilter == nil)

                Button(action: { onApplyPreset(.balanced) }) {
                    Text("Balanced")
                        .font(.caption2)
                        .foregroundColor(.white.opacity(0.8))
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.white.opacity(0.1))
                        .cornerRadius(12)
                }
                .disabled(isProcessing || selectedFilter == nil)

                Button(action: { onApplyPreset(.strong) }) {
                    Text("Strong")
                        .font(.caption2)
                        .foregroundColor(.white.opacity(0.8))
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.white.opacity(0.1))
                        .cornerRadius(12)
                }
                .disabled(isProcessing || selectedFilter == nil)
            }
        }
    }

    // MARK: - Filter Helper Views

    struct FilterPackButton: View {
        let pack: FilterPack
        let isSelected: Bool
        let action: () -> Void

        var body: some View {
            Button(action: action) {
                Text(pack.rawValue)
                    .font(.subheadline)
                    .foregroundColor(isSelected ? .white : .gray)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(
                        RoundedRectangle(cornerRadius: 20)
                            .fill(isSelected ? Color.white.opacity(0.2) : Color.clear)
                    )
            }
        }
    }

    struct FilterButton: View {
        let filter: PhotoFilter?
        let previewImage: UIImage?
        let isSelected: Bool
        let action: () -> Void

        var body: some View {
            Button(action: action) {
                VStack(spacing: 8) {
                    ZStack {
                        if let preview = previewImage {
                            Image(uiImage: preview)
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(width: 60, height: 60)
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                        } else {
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color.gray.opacity(0.3))
                                .frame(width: 60, height: 60)
                                .overlay(
                                    Image(systemName: "photo")
                                        .foregroundColor(.gray)
                                )
                        }

                        if isSelected {
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.white, lineWidth: 3)
                                .frame(width: 60, height: 60)
                        }
                    }

                    Text(filter?.name ?? "Original")
                        .font(.caption)
                        .foregroundColor(.white)
                        .lineLimit(1)
                        .frame(width: 70)
                }
            }
        }
    }

    struct AdjustmentControlsView: View {
        @Binding var adjustments: FilterAdjustment
        let onAdjustmentChanged: () -> Void
        let onDebouncedAdjustmentChanged: () -> Void

        var body: some View {
            VStack(spacing: 16) {
                Text("Adjustments")
                    .font(.headline)
                    .foregroundColor(.white)

                VStack(spacing: 12) {
                    // Intensity
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Text("Intensity")
                                .font(.subheadline)
                                .foregroundColor(.white)
                            Spacer()
                            Text(String(format: "%.0f%%", adjustments.intensity * 100))
                                .font(.caption)
                                .foregroundColor(.gray)
                        }

                        Slider(value: $adjustments.intensity, in: 0...1, step: 0.01)
                            .accentColor(.white)
                            .onChange(of: adjustments.intensity) { _ in
                                onDebouncedAdjustmentChanged()
                            }
                    }

                    // Brightness
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Text("Brightness")
                                .font(.subheadline)
                                .foregroundColor(.white)
                            Spacer()
                            Text(String(format: "%+.0f", adjustments.brightness * 100))
                                .font(.caption)
                                .foregroundColor(.gray)
                        }

                        Slider(value: $adjustments.brightness, in: -0.2...0.2, step: 0.01)
                            .accentColor(.white)
                            .onChange(of: adjustments.brightness) { _ in
                                onDebouncedAdjustmentChanged()
                            }
                    }

                    // Warmth
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Text("Warmth")
                                .font(.subheadline)
                                .foregroundColor(.white)
                            Spacer()
                            Text(String(format: "%+.0f", adjustments.warmth * 100))
                                .font(.caption)
                                .foregroundColor(.gray)
                        }

                        Slider(value: $adjustments.warmth, in: -0.2...0.2, step: 0.01)
                            .accentColor(.white)
                            .onChange(of: adjustments.warmth) { _ in
                                onDebouncedAdjustmentChanged()
                            }
                    }
                }
                .padding(.horizontal, 20)
            }
            .padding(.vertical, 20)
        }
    }

    // MARK: - Filter Functions

    private func selectFilter(_ filter: PhotoFilter?) {
        selectedFilter = filter
        showingAdjustments = false

        if filter != nil {
            currentAdjustments = .balanced
            applyCurrentFilter()
        } else {
            resetToOriginal()
        }
    }

    private func applyCurrentFilter(debounce: Bool = false) {
        guard let filter = selectedFilter, let originalImage = originalImage else { return }

        // Cancel previous work item for debouncing
        adjustmentWorkItem?.cancel()

        let workItem = DispatchWorkItem {
            guard !self.adjustmentWorkItem!.isCancelled else { return }

            DispatchQueue.main.async {
                self.isProcessing = true
            }

            let filteredImage = FilterManager.shared.applyFilter(filter, to: originalImage, adjustments: self.currentAdjustments)

            DispatchQueue.main.async {
                guard let workItem = self.adjustmentWorkItem, !workItem.isCancelled else { return }

                withAnimation(.easeInOut(duration: 0.3)) {
                    self.image = filteredImage
                    self.isProcessing = false
                }
            }
        }

        if debounce {
            // Debounce for 0.1 seconds to prevent too many filter applications
            adjustmentWorkItem = workItem
            DispatchQueue.global(qos: .userInitiated).asyncAfter(deadline: .now() + 0.1, execute: workItem)
        } else {
            // Apply immediately for filter selection
            adjustmentWorkItem = workItem
            DispatchQueue.global(qos: .userInitiated).async(execute: workItem)
        }
    }

    private func applyPreset(_ preset: FilterAdjustment) {
        currentAdjustments = preset
        applyCurrentFilter()
    }

    private func toggleOriginalFiltered() {
        if let filteredImage = image, let originalImage = originalImage {
            // Simple toggle between original and filtered
            if filteredImage.pngData() == originalImage.pngData() {
                applyCurrentFilter()
            } else {
                withAnimation(.easeInOut(duration: 0.3)) {
                    image = originalImage
                }
            }
        }
    }

    private func generateFilterPreviews() {
        guard let originalImage = originalImage else { return }

        DispatchQueue.global(qos: .userInitiated).async {
            var newPreviews: [String: UIImage] = [:]

            for filter in FilterManager.shared.filters(for: selectedPack) {
                if let preview = FilterManager.shared.generateFilterPreview(filter, for: originalImage) {
                    newPreviews[filter.id] = preview
                }
            }

            DispatchQueue.main.async {
                filterPreviews = newPreviews
            }
        }
    }

    private func saveAsCopy() {
        guard let imageToSave = image else { return }

        isProcessing = true

        DispatchQueue.global(qos: .userInitiated).async {
            // For free users, add watermark; Pro users get clean exports
            let exportData = FilterManager.shared.exportImage(imageToSave, withWatermark: !isProUser)

            DispatchQueue.main.async {
                isProcessing = false
                if exportData != nil {
                    onSave()
                }
            }
        }
    }

    private func overwriteOriginal() {
        guard let imageToSave = image else { return }

        isProcessing = true

        DispatchQueue.global(qos: .userInitiated).async {
            // Overwrite always uses the clean version (no watermark)
            let exportData = FilterManager.shared.exportImage(imageToSave, withWatermark: false)

            DispatchQueue.main.async {
                isProcessing = false
                if exportData != nil {
                    onSave()
                }
            }
        }
    }

    // MARK: - Legacy Image Processing Functions (kept for compatibility)
    
    private func resetToOriginal() {
        guard let originalImage = originalImage else { return }
        
        withAnimation(.easeInOut(duration: 0.3)) {
            image = originalImage
        }
    }
    
    private func shareToInstagramStories() {
        guard let imageToShare = image else { return }
        
        // Check if Instagram is installed
        guard let instagramURL = URL(string: "instagram-stories://share"), UIApplication.shared.canOpenURL(instagramURL) else {
            showingInstagramAlert = true
            return
        }
        
        // Convert image to data
        guard let imageData = imageToShare.jpegData(compressionQuality: 0.9) else {
            print("Failed to convert image to data")
            return
        }
        
        // Create pasteboard items for Instagram Stories
        let pasteboardItems: [String: Any] = [
            "com.instagram.sharedSticker.stickerImage": imageData,
            "com.instagram.sharedSticker.backgroundTopColor": "#000000",
            "com.instagram.sharedSticker.backgroundBottomColor": "#000000"
        ]
        
        // Set pasteboard data
        UIPasteboard.general.setItems([pasteboardItems], options: [.expirationDate: Date().addingTimeInterval(60 * 5)])
        
        // Open Instagram Stories
        UIApplication.shared.open(instagramURL, options: [:]) { success in
            if success {
                print("✅ Successfully opened Instagram Stories")
            } else {
                print("❌ Failed to open Instagram Stories")
                DispatchQueue.main.async {
                    showingInstagramAlert = true
                }
            }
        }
    }
}

// MARK: - UIImage Extensions

extension UIImage {
    func toGrayscale() -> UIImage? {
        guard let cgImage = self.cgImage else { return nil }

        let colorSpace = CGColorSpaceCreateDeviceGray()
        let width = cgImage.width
        let height = cgImage.height

        guard let context = CGContext(
            data: nil,
            width: width,
            height: height,
            bitsPerComponent: 8,
            bytesPerRow: 0,
            space: colorSpace,
            bitmapInfo: CGImageAlphaInfo.none.rawValue
        ) else { return nil }

        context.draw(cgImage, in: CGRect(x: 0, y: 0, width: width, height: height))

        guard let grayscaleCGImage = context.makeImage() else { return nil }

        return UIImage(cgImage: grayscaleCGImage)
    }

    func resized(to size: CGSize) -> UIImage? {
        let renderer = UIGraphicsImageRenderer(size: size)
        return renderer.image { _ in
            self.draw(in: CGRect(origin: .zero, size: size))
        }
    }
}

#Preview {
    ImagePreviewView(
        image: .constant(UIImage(systemName: "photo")),
        originalImage: UIImage(systemName: "photo"),
        isProcessing: .constant(false),
        onSave: {},
        onDiscard: {}
    )
    .preferredColorScheme(.dark)
}
