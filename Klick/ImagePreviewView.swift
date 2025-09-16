import SwiftUI
import UIKit
import Social
import CoreImage
import Vision

struct ImagePreviewView: View {
    @Binding var image: UIImage?
    let originalImage: UIImage?
    @Binding var isProcessing: Bool

    let onSave: () -> Void
    let onDiscard: () -> Void

    @State private var showingShareSheet = false

    // Filter system state
    @State private var selectedPack: FilterPack = .glow
    @State private var selectedFilter: PhotoFilter?
    @State private var currentAdjustments = FilterAdjustment.balanced
    @State private var showingAdjustments = false
    @State private var filterPreviews: [String: UIImage] = [:]

    // Subject masking state
    @State private var showingSubjectMasking = false
    @State private var isMaskingProcessing = false
    @State private var hasPersonSegmentation = false
    @State private var maskedImage: UIImage?
    
    // Background blur state
    @State private var showingBlurAdjustment = false
    @State private var blurIntensity: Float = 10.0 // Default medium blur (0-20 range)
    @State private var isBlurProcessing = false
    @State private var blurredImage: UIImage?

    // Performance optimization
    @State private var adjustmentWorkItem: DispatchWorkItem?
    @State private var blurWorkItem: DispatchWorkItem?

    // Save options
    @State private var showingSaveOptions = false
    
    // Computed property for determining which image to display
    private var displayImage: UIImage? {
        if showingBlurAdjustment && blurredImage != nil {
            return blurredImage
        } else if showingSubjectMasking && maskedImage != nil {
            return maskedImage
        } else {
            return image
        }
    }
    
    var body: some View {
        GeometryReader { geo in
            VStack {
                ImageDisplayView(
                    image: displayImage,
                    isProcessing: isProcessing || isMaskingProcessing || isBlurProcessing,
                    selectedFilter: selectedFilter
                )
                .frame(maxWidth: abs(geo.size.width - 24))
                .frame(height: geo.size.height * 0.75)
                .cornerRadius(22)
                .contentShape(RoundedRectangle(cornerRadius: 22))
                .onTapGesture {
                    if showingAdjustments {
                        withAnimation(.spring) {
                            showingAdjustments = false
                        }
                    } else if showingBlurAdjustment {
                        // Toggle between blurred and original view
                        toggleBlurredView()
                    } else if showingSubjectMasking {
                        // Toggle between masked and original view
                        toggleMaskedView()
                    } else {
                        guard selectedFilter != nil else { return }
                        toggleOriginalFiltered()
                    }
                }
                .overlay(alignment: .top) {
                    TopBarView(
                        showingAdjustments: $showingAdjustments,
                        showingSubjectMasking: $showingSubjectMasking,
                        showingBlurAdjustment: $showingBlurAdjustment,
                        selectedFilter: selectedFilter,
                        hasPersonSegmentation: hasPersonSegmentation,
                        onSave: overwriteOriginal,
                        onDiscard: onDiscard,
                        onToggleSubjectMasking: {
                            applySubjectMasking()
                        },
                        onToggleBlurAdjustment: {
                            applyBackgroundBlur()
                        }
                    )
                    .padding(.horizontal, 12)
                }
                
                Spacer()
            }
            .padding(.horizontal, 12)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .overlay(alignment: .bottom) {
                VStack(spacing: 10) {
                    VStack(spacing: 10) {
                        // Show filter pack selector when not showing adjustments
                        if !showingAdjustments {
                            FilterPackSelectorView(
                                selectedPack: $selectedPack,
                                onPackSelected: { pack in
                                    selectedPack = pack
                                    selectedFilter = nil
                                }
                            )
                        }
                        
                        // Always show filter selection strip (blur adjustment removed)
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
                        if showingBlurAdjustment {
                            BlurAdjustmentControlsView(
                                blurIntensity: $blurIntensity,
                                isProcessing: isBlurProcessing,
                                onBlurChanged: { applyBackgroundBlur() },
                                onDebouncedBlurChanged: { applyBackgroundBlur(debounce: true) }
                            )
                        }
                        
                        if selectedFilter != nil && showingAdjustments {
                            AdjustmentControlsView(
                                adjustments: $currentAdjustments,
                                onAdjustmentChanged: { applyCurrentFilter() },
                                onDebouncedAdjustmentChanged: { applyCurrentFilter(debounce: true) }
                            )
                        }
                        
                        // Show preset buttons when filter is selected and not showing blur adjustment
                        if selectedFilter != nil && !showingBlurAdjustment {
                            PresetButtonsView(
                                isProcessing: isProcessing,
                                selectedFilter: selectedFilter,
                                filterAdjustment: currentAdjustments,
                                onApplyPreset: applyPreset
                            )
                        }
                    }
                }
                .background(.black.opacity(0.85))
            }
        }
        .background(Color.black)
        .onAppear {
            generateFilterPreviews()
            checkPersonSegmentationSupport()
            resetMaskingState()
        }
        .onChange(of: originalImage) { _ in
            // Clear masking state and cache when image changes
            resetMaskingState()
            generateFilterPreviews()
            checkPersonSegmentationSupport()
        }
        .onDisappear {
            // Clean up work items to prevent memory leaks
            adjustmentWorkItem?.cancel()
            blurWorkItem?.cancel()
            adjustmentWorkItem = nil
            blurWorkItem = nil
        }
        .onChange(of: selectedPack) { _ in generateFilterPreviews() }
    }

    // MARK: - Sub-Views

    struct TopBarView: View {
        @Binding var showingAdjustments: Bool
        @Binding var showingSubjectMasking: Bool
        @Binding var showingBlurAdjustment: Bool
        let selectedFilter: PhotoFilter?
        let hasPersonSegmentation: Bool
        let onSave: () -> Void
        let onDiscard: () -> Void
        let onToggleSubjectMasking: () -> Void
        let onToggleBlurAdjustment: () -> Void

        var body: some View {
            HStack {
                // Dismiss button
                Button(action: onDiscard) {
                    Image(systemName: "xmark")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.white)
                        .frame(width: 32, height: 32)
                        .background(.ultraThinMaterial)
                        .clipShape(Circle())
                        .shadow(color: Color.black.opacity(0.25), radius: 10, x: 0, y: 6)
                }

                Spacer()

                // Background Blur Button
                Button(action: {
                    guard !showingAdjustments && !showingSubjectMasking else { return }
                    withAnimation(.spring) {
                        showingBlurAdjustment.toggle()
                        if showingBlurAdjustment {
                            showingAdjustments = false
                            showingSubjectMasking = false
                        }
                        onToggleBlurAdjustment()
                    }
                }) {
                    Image(systemName: "camera.aperture")
                        .foregroundColor(hasPersonSegmentation ? .white : .white.opacity(0.35))
                        .font(.system(size: 16, weight: .medium))
                        .frame(width: 32, height: 32)
                        .background(.ultraThinMaterial)
                        .clipShape(Circle())
                        .shadow(color: Color.black.opacity(0.25), radius: 10, x: 0, y: 6)
                }
                .disabled(!hasPersonSegmentation)

                // Subject Masking Button
                Button(action: {
                    guard !showingAdjustments && !showingBlurAdjustment else { return }
                    withAnimation(.spring) {
                        showingSubjectMasking.toggle()
                        if showingSubjectMasking {
                            showingAdjustments = false
                            showingBlurAdjustment = false
                        }
                        onToggleSubjectMasking()
                    }
                }) {
                    Image(systemName: "person.fill.and.arrow.left.and.arrow.right")
                        .foregroundColor(hasPersonSegmentation ? .white : .white.opacity(0.35))
                        .font(.system(size: 16, weight: .medium))
                        .frame(width: 32, height: 32)
                        .background(.ultraThinMaterial)
                        .clipShape(Circle())
                        .shadow(color: Color.black.opacity(0.25), radius: 10, x: 0, y: 6)
                }
                .disabled(!hasPersonSegmentation)

                // Filter Adjustments Button
                Button(action: {
                    guard !showingSubjectMasking && !showingBlurAdjustment else { return }
                    withAnimation(.spring) {
                        showingAdjustments.toggle()
                        if showingAdjustments {
                            showingSubjectMasking = false
                            showingBlurAdjustment = false
                        }
                    }
                }) {
                    Image(systemName: "slider.horizontal.3")
                        .foregroundColor(selectedFilter != nil ? .white : .white.opacity(0.35))
                        .font(.system(size: 16, weight: .medium))
                        .frame(width: 32, height: 32)
                        .background(.ultraThinMaterial)
                        .clipShape(Circle())
                        .shadow(color: Color.black.opacity(0.25), radius: 10, x: 0, y: 6)
                }
                .disabled(selectedFilter == nil)
                
                // Save button
                Button(action: onSave) {
                    Text("Save")
                        .foregroundColor(.black)
                        .font(.system(size: 14, weight: .semibold))
                        .padding(.vertical, 6)
                        .padding(.horizontal, 16)
                        .background(.yellow)
                        .clipShape(RoundedRectangle(cornerRadius: 22))
                }

            }
            .padding(.vertical)
        }
    }

    struct ImageDisplayView: View {
        let image: UIImage?
        let isProcessing: Bool
        let selectedFilter: PhotoFilter?
        // let showingMaskPreview: Bool // DISABLED: Mask preview
        // let maskPreviewImage: UIImage? // DISABLED: Mask preview image
        
        var body: some View {
            if let previewImage = image {
                Image(uiImage: previewImage)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .overlay(
                        Group {
                            // DISABLED: Subject glow effect overlay
                            // if showingMaskPreview, let glowImage = maskPreviewImage {
                            //     Image(uiImage: glowImage)
                            //         .resizable()
                            //         .aspectRatio(contentMode: .fill)
                            //         .frame(maxWidth: .infinity, maxHeight: .infinity)
                            //         .opacity(showingMaskPreview ? 1.0 : 0.0)
                            //         .animation(.easeInOut(duration: 0.8), value: showingMaskPreview)
                            // }
                            
                            // Processing indicator
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
                .padding(.horizontal, 10)
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
                            .foregroundColor((selectedFilter == nil) ? Color.white.opacity(0.8) : element.title == filterAdjustment.title ? .black : .white.opacity(0.8))
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
                            .aspectRatio(contentMode: .fill)
                            .frame(width: 70, height: 80)
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                    } else {
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color.gray.opacity(0.3))
                            .frame(width: 70, height: 80)
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
                            .frame(width: 70, height: 80)
                    }
                }
            }
        }
    }

    struct BlurAdjustmentControlsView: View {
        @Binding var blurIntensity: Float
        let isProcessing: Bool
        let onBlurChanged: () -> Void
        let onDebouncedBlurChanged: () -> Void

        var body: some View {
            VStack(spacing: 16) {
                Text("Background Blur")
                    .font(.headline)
                    .foregroundColor(.white)

                VStack(spacing: 12) {
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Text("Blur Intensity")
                                .font(.subheadline)
                                .foregroundColor(.white)
                            Spacer()
                            Text(String(format: "%.0f", blurIntensity))
                                .font(.caption)
                                .foregroundColor(.gray)
                        }

                        Slider(value: Binding(get: { Double(blurIntensity) }, set: { blurIntensity = Float($0) }), in: 0...20, step: 0.05)
                            .accentColor(.white)
                            .disabled(isProcessing)
                            .onChange(of: blurIntensity) { _ in
                                onDebouncedBlurChanged()
                            }
                    }
                    
                    // Preset buttons for quick blur levels
                    HStack(spacing: 16) {
                        ForEach([("None", Float(0)), ("Light", Float(5)), ("Medium", Float(10)), ("Strong", Float(18))], id: \.0) { preset in
                            Button(action: {
                                blurIntensity = preset.1
                                onBlurChanged()
                            }) {
                                Text(preset.0)
                                    .font(.footnote)
                                    .foregroundColor(abs(blurIntensity - preset.1) < 0.5 ? .black : .white.opacity(0.8))
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(
                                        Color.white.opacity(abs(blurIntensity - preset.1) < 0.5 ? 1 : 0.1)
                                    )
                                    .cornerRadius(12)
                            }
                            .disabled(isProcessing)
                        }
                    }
                }
                .padding(.horizontal, 20)
            }
            .padding(.vertical, 20)
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
        withAnimation(.spring) {
            selectedFilter = filter
        }
        
        if filter != nil {
            // DISABLED: Reset blur when applying a filter
            // blurIntensity = 0.0
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

    private func overwriteOriginal() {
        guard let originalImage = originalImage else { return }

        isProcessing = true

        DispatchQueue.global(qos: .userInitiated).async {
            var finalImage = originalImage
            
            // First apply blur if it's active (blur intensity > 0)
            if self.blurIntensity > 0 && self.hasPersonSegmentation && self.showingBlurAdjustment {
                if let blurredImage = BackgroundBlurManager.shared.applyBackgroundBlur(
                    to: originalImage, 
                    blurIntensity: self.blurIntensity,
                    useCache: false // Don't use cache for final export
                ) {
                    finalImage = blurredImage
                }
            }
            
            // Then apply subject masking if it's active
            if self.showingSubjectMasking {
                if let maskedImage = BackgroundBlurManager.shared.applySubjectMasking(
                    to: finalImage,
                    useCache: false // Don't use cache for final export
                ) {
                    finalImage = maskedImage
                }
            }
            
            // Finally apply filter if one is selected
            if let filter = self.selectedFilter {
                if let filteredImage = FilterManager.shared.applyFilter(
                    filter, 
                    to: finalImage, 
                    adjustments: self.currentAdjustments, 
                    useCache: false // Don't use cache for final export
                ) {
                    finalImage = filteredImage
                }
            }
            
            // Export the final processed image (no watermark)
            let exportData = FilterManager.shared.exportImage(finalImage, withWatermark: false)

            DispatchQueue.main.async {
                self.isProcessing = false
                if exportData != nil {
                    self.onSave()
                }
            }
        }
    }

    // MARK: - Subject Masking Functions
    
    private func resetMaskingState() {
        // Reset all masking-related state
        showingSubjectMasking = false
        isMaskingProcessing = false
        maskedImage = nil
        hasPersonSegmentation = false
        
        // Reset blur state
        showingBlurAdjustment = false
        isBlurProcessing = false
        blurredImage = nil
        blurIntensity = 10.0
        
        // Clear any cached masks for the previous image to prevent wrong masks
        if let originalImage = originalImage {
            BackgroundBlurManager.shared.clearCacheForImage(originalImage)
        }
    }
    
    private func applySubjectMasking() {
        guard let originalImage = originalImage else { return }
        
        // Reset filter when applying masking
        if showingSubjectMasking && selectedFilter != nil {
            selectedFilter = nil
        }
        
        isMaskingProcessing = true
        
        DispatchQueue.global(qos: .userInitiated).async {
            let processedImage: UIImage?
            
            if self.showingSubjectMasking {
                // Apply subject masking - use cache but with improved hash
                processedImage = BackgroundBlurManager.shared.applySubjectMasking(
                    to: originalImage,
                    useCache: true
                )
            } else {
                // Return to original
                processedImage = originalImage
                // Clear the cached result when turning off masking
                BackgroundBlurManager.shared.clearCacheForImage(originalImage)
            }
            
            DispatchQueue.main.async {
                withAnimation(.easeInOut(duration: 0.3)) {
                    self.maskedImage = processedImage
                    self.isMaskingProcessing = false
                }
            }
        }
    }
    
    private func toggleMaskedView() {
        guard let originalImage = originalImage else { return }
        
        withAnimation(.easeInOut(duration: 0.3)) {
            if showingSubjectMasking {
                // Toggle between masked and original view
                if maskedImage != nil {
                    maskedImage = nil // Show original
                } else {
                    maskedImage = BackgroundBlurManager.shared.applySubjectMasking(to: originalImage, useCache: true)
                }
            }
        }
    }
    
    private func checkPersonSegmentationSupport() {
        hasPersonSegmentation = BackgroundBlurManager.shared.isPersonSegmentationSupported()
        
        // If supported and we have an original image, try to detect a person
        if hasPersonSegmentation, let originalImage = originalImage {
            DispatchQueue.global(qos: .userInitiated).async {
                // Create a small preview for faster person detection
                let testSize = CGSize(width: 200, height: 300)
                guard let smallImage = originalImage.resized(to: testSize) else { return }
                
                // Try to apply masking to test if person detection works
                let testResult = BackgroundBlurManager.shared.applySubjectMasking(
                    to: smallImage,
                    useCache: false // Don't cache test result to avoid interference
                )
                
                DispatchQueue.main.async {
                    // If masking was successfully applied and different from original, we detected a person
                    if let result = testResult {
                        // Compare the images more robustly
                        let originalData = smallImage.pngData()
                        let resultData = result.pngData()
                        self.hasPersonSegmentation = originalData != resultData
                    } else {
                        self.hasPersonSegmentation = false
                    }
                }
            }
        }
    }
    
    // MARK: - Background Blur Functions
    
    private func applyBackgroundBlur(debounce: Bool = false) {
        guard let originalImage = originalImage else { return }
        
        // Reset filter and masking when applying blur
        if showingBlurAdjustment && (selectedFilter != nil || showingSubjectMasking) {
            selectedFilter = nil
            showingSubjectMasking = false
            maskedImage = nil
        }
        
        // Cancel previous work item for debouncing
        blurWorkItem?.cancel()
        
        let workItem = DispatchWorkItem {
            guard let workItem = self.blurWorkItem, !workItem.isCancelled else { return }
            
            DispatchQueue.main.async {
                self.isBlurProcessing = true
            }
            
            // Use preview size for real-time updates or full resolution for preset buttons
            let processedImage: UIImage?
            if debounce {
                // Use smaller preview for slider updates with enhanced edges for higher blur
                let useEnhancedEdges = self.blurIntensity > 12.0
                processedImage = BackgroundBlurManager.shared.generateBlurPreview(
                    for: originalImage,
                    blurIntensity: self.blurIntensity,
                    previewSize: CGSize(width: 600, height: 800),
                    enhancedEdges: useEnhancedEdges
                )
            } else {
                // Use full resolution for preset buttons
                processedImage = BackgroundBlurManager.shared.applyBackgroundBlur(
                    to: originalImage,
                    blurIntensity: self.blurIntensity,
                    useCache: true
                )
            }
            
            DispatchQueue.main.async {
                guard let workItem = self.blurWorkItem, !workItem.isCancelled else { return }
                
                withAnimation(.easeInOut(duration: 0.3)) {
                    self.blurredImage = processedImage ?? originalImage
                    self.isBlurProcessing = false
                }
            }
        }
        
        if debounce {
            // Debounce for 0.15 seconds for more responsive feel
            blurWorkItem = workItem
            DispatchQueue.global(qos: .userInitiated).asyncAfter(deadline: .now() + 0.15, execute: workItem)
        } else {
            // Apply immediately for preset selection
            blurWorkItem = workItem
            DispatchQueue.global(qos: .userInitiated).async(execute: workItem)
        }
    }
    
    private func toggleBlurredView() {
        guard let originalImage = originalImage else { return }
        
        withAnimation(.easeInOut(duration: 0.3)) {
            if showingBlurAdjustment {
                // Toggle between blurred and original view
                if blurredImage != nil {
                    blurredImage = nil // Show original
                } else {
                    blurredImage = BackgroundBlurManager.shared.applyBackgroundBlur(to: originalImage, blurIntensity: blurIntensity, useCache: true)
                }
            }
        }
    }

    // MARK: - Background Blur Functions (DISABLED)
    
    /*
    private func generateSubjectGlow() {
        guard let originalImage = originalImage else { return }
        
        DispatchQueue.global(qos: .userInitiated).async {
            // Generate edge glow effect around detected subject
            if let glowImage = BackgroundBlurManager.shared.generateSubjectGlow(for: originalImage) {
                DispatchQueue.main.async {
                    withAnimation(.easeInOut(duration: 0.8)) {
                        self.maskPreviewImage = glowImage
                        self.showingMaskPreview = true
                    }
                    
                    // Auto-hide the glow effect after 2.5 seconds
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
                        withAnimation(.easeInOut(duration: 0.8)) {
                            self.showingMaskPreview = false
                        }
                    }
                }
            }
        }
    }
    
    private func checkPersonSegmentationSupport() {
        hasPersonSegmentation = BackgroundBlurManager.shared.isPersonSegmentationSupported()
        
        // If supported and we have an original image, try to detect a person
        if hasPersonSegmentation, let originalImage = originalImage {
            DispatchQueue.global(qos: .userInitiated).async {
                // Create a small preview for faster person detection
                let testSize = CGSize(width: 200, height: 300)
                guard let smallImage = originalImage.resized(to: testSize) else { return }
                
                // Try to apply a very light blur to test if person detection works
                let testResult = BackgroundBlurManager.shared.applyBackgroundBlur(
                    to: smallImage, 
                    blurIntensity: 1.0, 
                    useCache: false // Don't cache test result
                )
                
                DispatchQueue.main.async {
                    // If blur was successfully applied, we detected a person
                    self.hasPersonSegmentation = testResult != nil
                }
            }
        }
    }
    
    private func applyBackgroundBlur(debounce: Bool = false) {
        guard let originalImage = originalImage else { return }
        
        // Reset filter when applying blur (if blur intensity > 0)
        if blurIntensity > 0 && selectedFilter != nil {
            selectedFilter = nil
        }
        
        // Cancel previous work item for debouncing
        blurWorkItem?.cancel()
        
        let workItem = DispatchWorkItem {
            guard let workItem = self.blurWorkItem, !workItem.isCancelled else { return }
            
            DispatchQueue.main.async {
                self.isBlurProcessing = true
            }
            
            // Use preview size for real-time updates
            let previewImage: UIImage?
            if debounce {
                // Use smaller preview for slider updates
                previewImage = BackgroundBlurManager.shared.generateBlurPreview(
                    for: originalImage,
                    blurIntensity: self.blurIntensity,
                    previewSize: CGSize(width: 600, height: 800)
                )
            } else {
                // Use full resolution for preset buttons
                previewImage = BackgroundBlurManager.shared.applyBackgroundBlur(
                    to: originalImage,
                    blurIntensity: self.blurIntensity,
                    useCache: true
                )
            }
            
            DispatchQueue.main.async {
                guard let workItem = self.blurWorkItem, !workItem.isCancelled else { return }
                
                withAnimation(.easeInOut(duration: 0.3)) {
                    self.image = previewImage ?? originalImage
                    self.isBlurProcessing = false
                }
            }
        }
        
        if debounce {
            // Debounce for 0.15 seconds (reduced from 0.2) for more responsive feel
            blurWorkItem = workItem
            DispatchQueue.global(qos: .userInitiated).asyncAfter(deadline: .now() + 0.15, execute: workItem)
        } else {
            // Apply immediately for preset selection
            blurWorkItem = workItem
            DispatchQueue.global(qos: .userInitiated).async(execute: workItem)
        }
    }
    */

    // MARK: - Legacy Image Processing Functions (kept for compatibility)
    
    private func resetToOriginal() {
        guard let originalImage = originalImage else { return }
        
        withAnimation(.easeInOut(duration: 0.3)) {
            image = originalImage
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
        image: .constant(UIImage(resource: .rectangle10)),
        originalImage: UIImage(resource: .rectangle10),
        isProcessing: .constant(false),
        onSave: {},
        onDiscard: {}
    )
    .preferredColorScheme(.dark)
}
