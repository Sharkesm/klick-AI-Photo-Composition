import SwiftUI
import UIKit
import Social
import CoreImage

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
        ZStack(alignment: .top) {
            Color.black.ignoresSafeArea()
            
            GeometryReader { geo in
                VStack {
                    TopBarView(
                        showingAdjustments: $showingAdjustments,
                        selectedFilter: selectedFilter,
                        onDiscard: onDiscard
                    )
                    
                    ImageDisplayView(
                        image: image,
                        isProcessing: isProcessing,
                        selectedFilter: selectedFilter,
                        onToggleOriginalFiltered: toggleOriginalFiltered
                    )
                    .frame(height: geo.size.height * 0.64)
                    .cornerRadius(12)
                    .padding(.horizontal, 12)
                    
                    Spacer()
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .overlay(alignment: .bottom) {
                    VStack(spacing: 10) {
                        VStack(spacing: 10) {
                            if !showingAdjustments {
                                FilterPackSelectorView(
                                    selectedPack: $selectedPack,
                                    onPackSelected: { pack in
                                        selectedPack = pack
                                        selectedFilter = nil
                                    }
                                )
                            }
                            
                            FilterSelectionStripView(
                                selectedPack: selectedPack,
                                selectedFilter: selectedFilter,
                                filterPreviews: filterPreviews,
                                originalImage: originalImage,
                                onFilterSelected: selectFilter
                            )
                        }
                        .padding(.top, 16)
                        .padding(.horizontal, 12)
                        
                        VStack(spacing: 16) {
                            if showingAdjustments && selectedFilter != nil {
                                AdjustmentControlsView(
                                    adjustments: $currentAdjustments,
                                    onAdjustmentChanged: { applyCurrentFilter() },
                                    onDebouncedAdjustmentChanged: { applyCurrentFilter(debounce: true) }
                                )
                            }
                            
                            PresetButtonsView(
                                isProcessing: isProcessing,
                                selectedFilter: selectedFilter,
                                filterAdjustment: currentAdjustments,
                                onApplyPreset: applyPreset
                            )
                        }
                    }
                    .background(.ultraThinMaterial)
                }
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
                    .padding(.vertical, 8)
                    .padding(.horizontal, 12)
                    .background(.ultraThinMaterial)
                    .mask(RoundedRectangle(cornerRadius: 16))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(.white.opacity(0.12), lineWidth: 1)
                    )
                    .shadow(color: Color.black.opacity(0.25), radius: 10, x: 0, y: 6)
                    .padding()

                Spacer()

                Button(action: {
                    withAnimation(.spring) {
                        showingAdjustments.toggle()
                    }
                }) {
                    Image(systemName: "slider.horizontal.3")
                        .font(.title2)
                        .foregroundColor(selectedFilter != nil ? .white : .gray)
                        .frame(width: 44, height: 44)
                }
                .disabled(selectedFilter == nil)
            }
        }
    }

    struct ImageDisplayView: View {
        let image: UIImage?
        let isProcessing: Bool
        let selectedFilter: PhotoFilter?
        let onToggleOriginalFiltered: () -> Void
        
        var body: some View {
            if let previewImage = image {
                Image(uiImage: previewImage)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .overlay(
                        Group {
                            if isProcessing {
                                ZStack {
                                    Color.black.opacity(0.3)
                                    ProgressView()
                                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                        .scaleEffect(0.8)
                                }
                            }
                        }
                    )
                    .overlay(content: {
                        if selectedFilter != nil {
                            Color.clear
                                .contentShape(Rectangle())
                                .onTapGesture(perform: onToggleOriginalFiltered)
                        }
                    })
                    .animation(.easeInOut(duration: 0.3), value: isProcessing)
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
            }
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
                HStack(alignment: .top, spacing: 12) {
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
                .padding(.vertical, 10)
            }
        }
    }

    struct PresetButtonsView: View {
        let isProcessing: Bool
        let selectedFilter: PhotoFilter?
        let filterAdjustment: FilterAdjustment
        let onApplyPreset: (FilterAdjustment) -> Void
        
        var filterAdjustments: [FilterAdjustment] = [.subtle, .balanced, .strong]
        
        var body: some View {
            HStack(spacing: 10) {
                ForEach(filterAdjustments, id: \.id) { element in
                    Button(action: {
                        onApplyPreset(element)
                    }) {
                        Text(element.title)
                            .font(.footnote)
                            .foregroundColor((selectedFilter == nil) ? Color.white.opacity(0.35) : element.title == filterAdjustment.title ? .black : .white.opacity(0.8))
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(
                                (selectedFilter == nil) ? Color.white.opacity(0.1) : Color.white.opacity((element.title == filterAdjustment.title) ? 1 : 0.1)
                            )
                            .cornerRadius(12)
                    }
                    .disabled(isProcessing || selectedFilter == nil)
                }
            }
        }
    }

    // MARK: - Filter Helper Views

    struct FilterPackButton: View {
        let pack: FilterPack
        let isSelected: Bool
        let action: () -> Void

        var body: some View {
            Button(action: {
                withAnimation(.spring) {
                    action()
                }
            }) {
                Text(pack.rawValue)
                    .font(.subheadline)
                    .foregroundColor(isSelected ? .black : .white)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(
                        RoundedRectangle(cornerRadius: 20)
                            .fill(isSelected ? Color.yellow : Color.white.opacity(0.1))
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
                ZStack(alignment: .bottom) {
                    if let preview = previewImage {
                        Image(uiImage: preview)
                            .resizable()
                            .frame(width: 60, height: 80)
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                    } else {
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color.gray.opacity(0.3))
                            .frame(width: 60, height: 80)
                            .overlay(
                                Image(systemName: "photo")
                                    .foregroundColor(.gray)
                            )
                    }
                    
                    LinearGradient(
                        stops: [
                            .init(color: Color.clear, location: 0),
                            .init(color: Color.black.opacity(0.3), location: 0.3),
                            .init(color: Color.black.opacity(0.7), location: 0.6),
                            .init(color: Color.black, location: 1)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                    .frame(height: 30)
                    .overlay(alignment: .bottom) {
                        Text(filter?.name ?? "Normal")
                            .font(.caption)
                            .fontWeight(.semibold)
                            .scaleEffect(0.92)
                            .foregroundColor(Color.white.opacity(0.85))
                            .lineLimit(1)
                            .frame(maxWidth: .infinity)
                            .multilineTextAlignment(.center)
                            .padding(.bottom, 5)
                    }
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                }
                .overlay {
                    if isSelected {
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.yellow, lineWidth: 3)
                            .frame(width: 60, height: 80)
                    }
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
        image: .constant(UIImage(resource: .perspective1)),
        originalImage: UIImage(resource: .perspective1),
        isProcessing: .constant(false),
        onSave: {},
        onDiscard: {}
    )
    .preferredColorScheme(.dark)
}
