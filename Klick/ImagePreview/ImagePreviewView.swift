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
                                    // Save current state before changing pack (which clears filter)
                                    // Only save if we currently have a filter applied
                                    if effectState.filter != nil {
                                        saveCurrentStateToHistory()
                                    }
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
            // Reset the state on appear
            resetEffectState()
            
            // Try to initialize with either originalImage or the bound image
            let imageToUse = originalImage ?? image
            if let imageToUse = imageToUse {
                BackgroundBlurManager.shared.startEditingSession(for: imageToUse)
                stateHistory.initializeWithOriginal(originalImage: imageToUse)
                generateFilterPreviews()
                checkPersonSegmentationSupport()
            }
        }
        .onChange(of: originalImage) { newValue in
            if let originalImage = newValue ?? originalImage {
                // MEMORY OPTIMIZATION: Start editing session for this image
                BackgroundBlurManager.shared.startEditingSession(for: originalImage)
                
                // Clear effect state and cache when image changes
                resetEffectState()
                
                // Initialize state history AFTER reset
                stateHistory.initializeWithOriginal(originalImage: originalImage)
                
                generateFilterPreviews()
                checkPersonSegmentationSupport()
            } else {
                // Just reset state if image becomes nil
                resetEffectState()
            }
        }
        .onChange(of: image) { newValue in
            // If we don't have state history initialized yet and we get an image, use it
            if !stateHistory.isInitialized, let imageToUse = newValue ?? originalImage {
                BackgroundBlurManager.shared.startEditingSession(for: imageToUse)
                stateHistory.initializeWithOriginal(originalImage: imageToUse)
                generateFilterPreviews()
                checkPersonSegmentationSupport()
            }
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

    // MARK: - Effect Functions

    private func selectFilter(_ filter: PhotoFilter?) {        
        withAnimation(.spring) {
            if let filter = filter {
                // Always save state when applying any filter (styling choice)
                // This ensures we can compare current filter vs baseline (original or blur)
                effectState.filter = ImageEffectState.FilterEffect(filter: filter, adjustments: .balanced)
                saveCurrentStateToHistory()
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
            // Always save state before applying filter preset (styling choice refinement)
            saveCurrentStateToHistory()
            effectState.filter!.adjustments = preset
            applyEffects()
        }
    }
    
    private func applyBlurPreset() {
        // Always save state before applying blur preset (structural change)
        saveCurrentStateToHistory()
        applyEffects()
    }

    private func toggleBlurAdjustment() {
        if showingBlurAdjustment {
            showingAdjustments = false
        }
        
        // Always save state when toggling blur (structural change)
        // This creates a new baseline for future comparisons
        if showingBlurAdjustment {
            // We're about to enable blur - always save current state
            saveCurrentStateToHistory()
            effectState.backgroundBlur.isEnabled = true
        } else {
            // We're disabling blur - also save state
            saveCurrentStateToHistory()
            effectState.backgroundBlur.isEnabled = false
        }
        
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
            // Allow preview if there are actual effects applied (even for first effect)
            let currentStateDescription = getCurrentStateDescription(effectState)
            if currentStateDescription != "ORIGINAL" {
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
            
            // Log the history state access
            if stateHistory.hasPreviousState {
                let currentStateDescription = getCurrentStateDescription(effectState)
                let previousStateDescription = stateHistory.previousState != nil ? 
                    getCurrentStateDescription(stateHistory.previousState!) : "ORIGINAL"
                
                print("------ Image History State --------")
                print("")
                print("Current State: \(currentStateDescription)")
                print("Previous State: \(previousStateDescription)")
                print("")
                print("-----------------------------------")
            }
            
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
        guard let originalImage = originalImage else { return }
        
        // Determine the correct baseline based on the type of change
        let previousStateDescription = determineCorrectBaseline()
        
        // Use the current displayed image (processed or original)
        let currentDisplayedImage = processedImage ?? originalImage
        
        // Save the new state to history
        stateHistory.saveCurrentState(effectState: effectState, processedImage: currentDisplayedImage)
        
        // Only log meaningful transitions (when there's an actual effect applied)
        let currentStateDescription = getCurrentStateDescription(effectState)
        if currentStateDescription != "ORIGINAL" {
            print("------ Image Change State --------")
            print("")
            print("Current State: \(currentStateDescription)")
            print("Previous State: \(previousStateDescription)")
            print("")
            print("-----------------------------------")
        }
    }
    
    private func determineCorrectBaseline() -> String {
        // Check if we have blur active in current state
        let currentHasBlur = effectState.backgroundBlur.isEnabled && effectState.backgroundBlur.intensity > 0
        
        // Check if we had blur in previous state
        let previousHadBlur = stateHistory.previousState?.backgroundBlur.isEnabled == true && 
                             (stateHistory.previousState?.backgroundBlur.intensity ?? 0) > 0
        
        // Styling Choice Rule: For filter-only changes, always compare to original
        if !currentHasBlur && !previousHadBlur {
            // Pure filter changes always compare to original
            return "ORIGINAL"
        }
        
        // Structural Change Rule: When blur is involved, use the immediate previous state
        if let previousState = stateHistory.previousState {
            return getCurrentStateDescription(previousState)
        }
        
        // Fallback to original if no previous state
        return "ORIGINAL"
    }
    
    private func getCurrentStateDescription(_ state: ImageEffectState) -> String {
        let hasBlur = state.backgroundBlur.isEnabled && state.backgroundBlur.intensity > 0
        let hasFilter = state.filter != nil
        
        if hasBlur && hasFilter {
            return "\(state.filter!.filter.name.uppercased()) + BLUR (\(String(format: "%.0f", state.backgroundBlur.intensity)))"
        } else if hasFilter {
            return state.filter!.filter.name.uppercased()
        } else if hasBlur {
            return "BACKGROUND BLUR (\(String(format: "%.0f", state.backgroundBlur.intensity)))"
        } else {
            return "ORIGINAL"
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

