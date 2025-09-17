import SwiftUI
import UIKit
import Social
import CoreImage
import Vision

// MARK: - Image Effect State
struct ImageEffectState {
    var backgroundBlur: BackgroundBlurEffect
    var filter: FilterEffect?
    
    struct BackgroundBlurEffect {
        var isEnabled: Bool = false
        var intensity: Float = 5.0 // 0-20 range
    }
    
    struct FilterEffect {
        var filter: PhotoFilter
        var adjustments: FilterAdjustment = .balanced
    }
    
    static let `default` = ImageEffectState(
        backgroundBlur: BackgroundBlurEffect(),
        filter: nil
    )
}

// MARK: - Image State History
struct ImageStateHistory {
    var currentState: ImageEffectState
    var previousState: ImageEffectState?
    var currentImage: UIImage?
    var previousImage: UIImage?
    
    var previousStateInfo: String {
        guard let filter = previousState?.filter else {
            return "Background Blur"
        }
        
        return filter.filter.displayName.uppercased()
    }
    
    mutating func saveCurrentState(effectState: ImageEffectState, processedImage: UIImage?) {
        // Save current as previous
        previousState = currentState
        previousImage = currentImage
        
        // Update current
        currentState = effectState
        currentImage = processedImage
    }
    
    var hasPreviousState: Bool {
        return previousState != nil && previousImage != nil
    }
    
    static let empty = ImageStateHistory(
        currentState: ImageEffectState.default,
        previousState: nil,
        currentImage: nil,
        previousImage: nil
    )
}

struct ImagePreviewView: View {
    @Binding var image: UIImage?
    let originalImage: UIImage?
    @Binding var isProcessing: Bool

    let onSave: () -> Void
    let onDiscard: () -> Void

    @State private var showingShareSheet = false

    // Unified effect state
    @State private var effectState = ImageEffectState.default
    @State private var processedImage: UIImage?
    @State private var stateHistory = ImageStateHistory.empty
    @State private var isShowingPreviousState = false
    
    // UI state
    @State private var selectedPack: FilterPack = .glow
    @State private var showingAdjustments = false
    @State private var showingBlurAdjustment = false
    @State private var filterPreviews: [String: UIImage] = [:]

    // Subject masking state
    @State private var hasPersonSegmentation = false

    // Performance optimization
    @State private var effectWorkItem: DispatchWorkItem?

    // Save options
    @State private var showingSaveOptions = false
    
    // Computed property for determining which image to display
    private var displayImage: UIImage? {
        if isShowingPreviousState {
            return stateHistory.previousImage ?? originalImage
        } else {
            return processedImage ?? originalImage
        }
    }
    
    var body: some View {
        GeometryReader { geo in
            VStack {
                ImageDisplayView(
                    image: displayImage,
                    isProcessing: isProcessing,
                    selectedFilter: effectState.filter?.filter
                )
                .frame(maxWidth: abs(geo.size.width - 24))
                .frame(height: geo.size.height * 0.75)
                .cornerRadius(22)
                .contentShape(RoundedRectangle(cornerRadius: 22))
                .overlay(alignment: .bottom, content: {
                    // Previous state indicator
                    Group {
                        if isShowingPreviousState && stateHistory.hasPreviousState {
                            VStack(alignment: .center, spacing: 12) {
                                Text("BEFORE")
                                    .font(.footnote)
                                    .fontWeight(.semibold)
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 6)
                                    .background(.ultraThinMaterial)
                                    .clipShape(RoundedRectangle(cornerRadius: 30))
                                
                                Text(stateHistory.previousStateInfo)
                                    .font(.caption.weight(.bold))
                                    .foregroundStyle(Color.white)
                            }
                            .padding(16)
                        }
                    }
                })
                .onTapGesture {
                    handleImageTap()
                }
                .overlay(alignment: .top) {
                    TopBarView(
                        showingAdjustments: $showingAdjustments,
                        showingBlurAdjustment: $showingBlurAdjustment,
                        selectedFilter: effectState.filter?.filter,
                        hasPersonSegmentation: hasPersonSegmentation,
                        onSave: overwriteOriginal,
                        onDiscard: onDiscard,
                        onToggleBlurAdjustment: {
                            toggleBlurAdjustment()
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
                                    effectState.filter = nil
                                    applyEffects()
                                }
                            )
                        }
                        
                        // Always show filter selection strip (blur adjustment removed)
                        FilterSelectionStripView(
                            selectedPack: selectedPack,
                            selectedFilter: effectState.filter?.filter,
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
                                blurIntensity: Binding(
                                    get: { effectState.backgroundBlur.intensity },
                                    set: { effectState.backgroundBlur.intensity = $0 }
                                ),
                                isProcessing: isProcessing,
                                onBlurChanged: { applyBlurPreset() },
                                onDebouncedBlurChanged: { applyEffects(debounce: true) }
                            )
                        }
                        
                        if effectState.filter != nil && showingAdjustments {
                            AdjustmentControlsView(
                                adjustments: Binding(
                                    get: { effectState.filter?.adjustments ?? .balanced },
                                    set: { 
                                        if effectState.filter != nil {
                                            effectState.filter!.adjustments = $0
                                        }
                                    }
                                ),
                                onAdjustmentChanged: { applyEffects() },
                                onDebouncedAdjustmentChanged: { applyEffects(debounce: true) }
                            )
                        }
                        
                        // Show preset buttons when filter is selected and not showing blur adjustment
                        if effectState.filter != nil && !showingBlurAdjustment {
                            PresetButtonsView(
                                isProcessing: isProcessing,
                                selectedFilter: effectState.filter?.filter,
                                filterAdjustment: effectState.filter?.adjustments ?? .balanced,
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
            // MEMORY OPTIMIZATION: Start editing session for this image
            if let originalImage = originalImage {
                BackgroundBlurManager.shared.startEditingSession(for: originalImage)
            }
            
            generateFilterPreviews()
            checkPersonSegmentationSupport()
            resetEffectState()
        }
        .onChange(of: originalImage) { _ in
            // Clear effect state and cache when image changes
            resetEffectState()
            generateFilterPreviews()
            checkPersonSegmentationSupport()
        }
        .onDisappear {
            // MEMORY OPTIMIZATION: End editing session when leaving the view
            BackgroundBlurManager.shared.endEditingSession(clearAll: true)
            
            // Clean up work items to prevent memory leaks
            effectWorkItem?.cancel()
            effectWorkItem = nil
        }
        .onChange(of: selectedPack) { _ in generateFilterPreviews() }
    }

    // MARK: - Sub-Views

    struct TopBarView: View {
        @Binding var showingAdjustments: Bool
        @Binding var showingBlurAdjustment: Bool
        let selectedFilter: PhotoFilter?
        let hasPersonSegmentation: Bool
        let onSave: () -> Void
        let onDiscard: () -> Void
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
                    withAnimation(.spring) {
                        showingBlurAdjustment.toggle()
                        if showingBlurAdjustment {
                            showingAdjustments = false
                        }
                        onToggleBlurAdjustment()
                    }
                }) {
                    Image(systemName: "person.fill.and.arrow.left.and.arrow.right")
                        .foregroundColor(hasPersonSegmentation ? showingBlurAdjustment ? .yellow : .white : .white.opacity(0.35))
                        .font(.system(size: 16, weight: .medium))
                        .frame(width: 32, height: 32)
                        .background(.ultraThinMaterial)
                        .clipShape(Circle())
                        .shadow(color: Color.black.opacity(0.25), radius: 10, x: 0, y: 6)
                }
                .disabled(!hasPersonSegmentation)

                // Filter Adjustments Button
                Button(action: {
                    if showingAdjustments {
                        withAnimation(.easeIn(duration: 0.35)) {
                            showingBlurAdjustment = false
                        }
                    }
                    
                    withAnimation(.spring) {
                        showingAdjustments.toggle()
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
        
        var body: some View {
            if let previewImage = image {
                Image(uiImage: previewImage)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .overlay(
                        Group {
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

    // MARK: - Effect Functions

    private func selectFilter(_ filter: PhotoFilter?) {
        // Save current state before making changes
        saveCurrentStateToHistory()
        
        withAnimation(.spring) {
            if let filter = filter {
                effectState.filter = ImageEffectState.FilterEffect(filter: filter, adjustments: .balanced)
            } else {
                effectState.filter = nil
            }
        }
        
        applyEffects()
    }

    private func applyEffects(debounce: Bool = false) {
        guard let originalImage = originalImage else { return }

        // Cancel previous work item for debouncing
        effectWorkItem?.cancel()

        let workItem = DispatchWorkItem {
            guard let workItem = self.effectWorkItem, !workItem.isCancelled else { return }

            DispatchQueue.main.async {
                self.isProcessing = true
            }

            var resultImage = originalImage
            
            // Apply background blur first if enabled
            if self.effectState.backgroundBlur.isEnabled && self.effectState.backgroundBlur.intensity > 0 && self.hasPersonSegmentation {
                if let blurredImage = BackgroundBlurManager.shared.applyBackgroundBlur(
                    to: resultImage,
                    blurIntensity: self.effectState.backgroundBlur.intensity,
                    useCache: !debounce // Use cache for non-debounced calls
                ) {
                    resultImage = blurredImage
                }
            }
            
            // Apply filter second if selected
            if let filterEffect = self.effectState.filter {
                if let filteredImage = FilterManager.shared.applyFilter(
                    filterEffect.filter,
                    to: resultImage,
                    adjustments: filterEffect.adjustments,
                    useCache: !debounce // Use cache for non-debounced calls
                ) {
                    resultImage = filteredImage
                }
            }

            DispatchQueue.main.async {
                guard let workItem = self.effectWorkItem, !workItem.isCancelled else { return }

                withAnimation(.easeInOut(duration: 0.3)) {
                    self.processedImage = resultImage
                    self.image = resultImage // Keep for compatibility
                    self.isProcessing = false
                }
            }
        }

        if debounce {
            // Debounce for 0.15 seconds for slider adjustments
            effectWorkItem = workItem
            DispatchQueue.global(qos: .userInitiated).asyncAfter(deadline: .now() + 0.15, execute: workItem)
        } else {
            // Apply immediately for selections
            effectWorkItem = workItem
            DispatchQueue.global(qos: .userInitiated).async(execute: workItem)
        }
    }

    private func applyPreset(_ preset: FilterAdjustment) {
        if effectState.filter != nil {
            // Save current state before applying preset
            saveCurrentStateToHistory()
            effectState.filter!.adjustments = preset
            applyEffects()
        }
    }
    
    private func applyBlurPreset() {
        // Save current state before applying blur preset
        saveCurrentStateToHistory()
        applyEffects()
    }

    
    private func toggleBlurAdjustment() {
        // Save current state before making changes
        if !effectState.backgroundBlur.isEnabled && showingBlurAdjustment {
            saveCurrentStateToHistory()
        }
        
        effectState.backgroundBlur.isEnabled = showingBlurAdjustment
        if showingBlurAdjustment {
            showingAdjustments = false
        }
        applyEffects()
    }
    
    // MARK: - Smart Tap Gesture Handling
    
    private func handleImageTap() {
        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
            // Scenario 3: If any adjustment controls are active, close them first
            if showingAdjustments || showingBlurAdjustment {
                showingAdjustments = false
                showingBlurAdjustment = false
                return
            }
            
            // Scenario 1 & 2: Smart previous state preview
            if stateHistory.hasPreviousState {
                togglePreviousStatePreview()
            }
        }
    }
    
    private func togglePreviousStatePreview() {
        if isShowingPreviousState {
            // Return to current state
            isShowingPreviousState = false
        } else {
            // Show previous state
            isShowingPreviousState = true
            
            // Auto-return to current state after 1.5 seconds
            DispatchQueue.main.asyncAfter(deadline: .now() + 3.5) {
                withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                    self.isShowingPreviousState = false
                }
            }
        }
    }
    
    // MARK: - State History Management
    
    private func saveCurrentStateToHistory() {
        // Only save if there's actually a change to track
        guard processedImage != nil else { return }
        
        stateHistory.saveCurrentState(effectState: effectState, processedImage: processedImage)
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
            
            // Apply background blur first if enabled
            if self.effectState.backgroundBlur.isEnabled && self.effectState.backgroundBlur.intensity > 0 && self.hasPersonSegmentation {
                if let blurredImage = BackgroundBlurManager.shared.applyBackgroundBlur(
                    to: finalImage, 
                    blurIntensity: self.effectState.backgroundBlur.intensity,
                    useCache: false // Don't use cache for final export
                ) {
                    finalImage = blurredImage
                }
            }
            
            // Apply filter second if selected
            if let filterEffect = self.effectState.filter {
                if let filteredImage = FilterManager.shared.applyFilter(
                    filterEffect.filter, 
                    to: finalImage, 
                    adjustments: filterEffect.adjustments, 
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
                    // MEMORY OPTIMIZATION: Clear all caches after successful save
                    BackgroundBlurManager.shared.endEditingSession(clearAll: true)
                    self.onSave()
                }
            }
        }
    }

    // MARK: - Effect State Functions
    
    private func resetEffectState() {
        // Reset all effect-related state
        effectState = ImageEffectState.default
        processedImage = nil
        stateHistory = ImageStateHistory.empty
        isShowingPreviousState = false
        hasPersonSegmentation = false
        
        // Reset UI state
        showingBlurAdjustment = false
        showingAdjustments = false
        
        // MEMORY OPTIMIZATION: End editing session to clear all caches
        BackgroundBlurManager.shared.endEditingSession(clearAll: true)
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
    
    // MARK: - Legacy Image Processing Functions (kept for compatibility)
    
    private func resetToOriginal() {
        guard let originalImage = originalImage else { return }
        
        withAnimation(.easeInOut(duration: 0.3)) {
            processedImage = originalImage
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

