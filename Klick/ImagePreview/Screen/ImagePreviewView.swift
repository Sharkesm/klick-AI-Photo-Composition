import SwiftUI
import UIKit
import Social
import CoreImage
import Vision

struct ImagePreviewView: View {
    @Binding var image: UIImage?
    let originalImage: UIImage?
    let rawImage: UIImage? // New: RAW image for Pro mode
    let cameraQuality: CameraQuality // New: Camera quality used for capture
    @Binding var isProcessing: Bool

    let onSave: () -> Void
    let onDiscard: () -> Void

    @State private var showingShareSheet = false

    // ProRaw toggle state
    @State private var selectedProcessingMode: ImageProcessingMode = .standard
    
    // Unified effect state
    @State private var effectState = ImageEffectState.default
    @State private var processedImage: UIImage?
    @State private var stateHistory = ImageStateHistory.empty
    @State private var isShowingPreviousState = false
    
    // UI state
    @State private var selectedPack: FilterPack = .glow
    @State private var showingAdjustments = false
    @State private var showingBlurAdjustment = false
    @State private var showingEffects = false
    @State private var filterPreviews: [String: UIImage] = [:]
    @State private var shouldShrinkImage: Bool = false
    
    // Subject masking state
    @State private var hasPersonSegmentation = false

    // Performance optimization
    @State private var effectWorkItem: DispatchWorkItem?

    // Save options
    @State private var showingSaveOptions = false
    
    // Onboarding state
    @AppStorage("hasSeenImagePreviewOnboarding") private var hasSeenImagePreviewOnboarding: Bool = false
    @State private var showOnboardingAnimation = false
    @State private var hasAppliedFirstFilter = false
    
    // Computed property for determining the base image to use for processing
    private var baseImage: UIImage? {
        switch selectedProcessingMode {
        case .standard:
            return originalImage
        case .proRaw:
            return rawImage ?? originalImage // Fallback to standard if no RAW available
        }
    }
    
    // Computed property for determining which image to display
    private var displayImage: UIImage? {
        if isShowingPreviousState {
            return baseImage
        } else {
            return processedImage ?? baseImage
        }
    }
    
    // Computed property for determining whether to show a pro-raw toggle
    private var shouldShowProRawToggle: Bool {
        let controlStates = (!showingAdjustments || showingBlurAdjustment || (!isShowingPreviousState && stateHistory.hasPreviousState))
        let qualityState = cameraQuality == .pro && rawImage != nil
        return controlStates && qualityState
    }
    
    var body: some View {
        GeometryReader { geo in
            VStack(spacing: 0) {
                // ProRaw Toggle at the top
                TopBarView(
                    selectedProcessingMode: $selectedProcessingMode,
                    showProRaw: shouldShowProRawToggle,
                    onProRawToggle: handleProcessingModeChange
                )
                .padding(.horizontal, 12)
                .padding(.vertical, 12)
                
                ImageDisplayView(
                    image: displayImage,
                    isProcessing: isProcessing,
                    selectedFilter: effectState.filter?.filter
                )
                .frame(maxWidth: abs(geo.size.width - 24))
                .frame(height: geo.size.height * 0.75)
                .cornerRadius(22)
                .contentShape(RoundedRectangle(cornerRadius: 22))
                .scaleEffect(shouldShrinkImage ? 0.9 : 1)
                .animation(.spring(response: 0.25, dampingFraction: 0.8, blendDuration: 0.15), value: shouldShrinkImage)
                .overlay(
                    Group {
                        if showOnboardingAnimation {
                            Color.black.opacity(0.6)
                                .animation(.easeInOut(duration: 0.3), value: showOnboardingAnimation)
                        }
                    }
                )
                .overlay(alignment: .center) {
                    if showOnboardingAnimation {
                        ImagePreviewOnboardingView(
                            isVisible: $showOnboardingAnimation,
                            onComplete: {
                                hasSeenImagePreviewOnboarding = true
                                showOnboardingAnimation = false
                            }
                        )
                        .zIndex(1000)
                    }
                }
                .overlay(alignment: .bottom, content: {
                    HStack {
                        // Previous state indicator
                        if isShowingPreviousState && stateHistory.hasPreviousState {
                            Text("BEFORE")
                                .font(.footnote)
                                .fontWeight(.semibold)
                                .foregroundColor(.white)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(.ultraThickMaterial)
                                .clipShape(RoundedRectangle(cornerRadius: 30))
                        }
                    }
                    .padding(16)
                })
                .onTapGesture {
                    handleImageTap()
                }
                .onLongPressGesture {
                    handleImageOriginalState()
                }
                
                Spacer()
            }
            .padding(.horizontal, 12)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .overlay(alignment: .bottom) {
                VStack(spacing: 10) {
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
                    }
                    
                    VStack(spacing: 10) {
                        // Show filter pack selector when not showing adjustments
                        if showingEffects {
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
                        
                        HStack(spacing: 26) {
                            Spacer()
                            
                            // Dismiss button
                            Button(action: onDiscard) {
                                Image(systemName: "xmark")
                                    .foregroundColor(Color.white)
                                    .font(.system(size: 16, weight: .medium))
                                    .frame(width: 30, height: 30)
                                    .padding(8)
                                    .background(.ultraThinMaterial)
                                    .clipShape(Circle())
                                    .shadow(color: Color.black.opacity(0.25), radius: 10, x: 0, y: 6)
                            }
                            
                            HStack {
                                // Effects Button
                                Button(action: {
                                    if showingBlurAdjustment || showingAdjustments {
                                        withAnimation(.easeIn(duration: 0.35)) {
                                            showingAdjustments = false
                                            showingBlurAdjustment = false
                                        }
                                    }
                                    
                                    if !shouldShrinkImage {
                                        shouldShrinkImage = true
                                    }
                                    
                                    withAnimation(.spring) {
                                        showingEffects.toggle()
                                    }
                                    
                                    if !showingEffects {
                                       shouldShrinkImage = false
                                    }
                                }) {
                                    Image(systemName: "wand.and.stars")
                                        .foregroundColor(effectState.filter == nil ? Color.white : .yellow)
                                        .font(.system(size: 16, weight: .medium))
                                        .frame(width: 30, height: 30)
                                        .padding(8)
                                        .clipShape(Circle())
                                        .shadow(color: Color.black.opacity(0.25), radius: 10, x: 0, y: 6)
                                }
                                
                                // Background Blur Button
                                Button(action: {
                                    if showingAdjustments || showingEffects {
                                        withAnimation(.easeIn(duration: 0.35)) {
                                            showingAdjustments = false
                                            showingEffects = false
                                        }
                                    }
                                    
                                    if !shouldShrinkImage {
                                        shouldShrinkImage = true
                                    }
                                    
                                    withAnimation(.spring) {
                                        showingBlurAdjustment.toggle()
                                        toggleBlurAdjustment()
                                    }
                                    
                                    if !showingBlurAdjustment {
                                       shouldShrinkImage = false
                                    }
                                }) {
                                    Image(systemName: "person.fill.and.arrow.left.and.arrow.right")
                                        .foregroundColor(hasPersonSegmentation ? effectState.backgroundBlur.isEnabled ? .yellow : .white : .white.opacity(0.35))
                                        .font(.system(size: 16, weight: .medium))
                                        .frame(width: 30, height: 30)
                                        .padding(8)
                                        .clipShape(Circle())
                                        .shadow(color: Color.black.opacity(0.25), radius: 10, x: 0, y: 6)
                                }
                                .disabled(!hasPersonSegmentation)
                                
                                // Filter Adjustments Button
                                Button(action: {
                                    if showingBlurAdjustment || showingEffects {
                                        withAnimation(.easeIn(duration: 0.35)) {
                                            showingBlurAdjustment = false
                                            showingEffects = false
                                        }
                                    }
                                    
                                    if !shouldShrinkImage {
                                        shouldShrinkImage = true
                                    }
                                    
                                    withAnimation(.spring) {
                                        showingAdjustments.toggle()
                                    }
                                    
                                    if !showingAdjustments {
                                       shouldShrinkImage = false
                                    }
                                }) {
                                    Image(systemName: "slider.horizontal.3")
                                        .foregroundColor(effectState.filter?.filter != nil ? .white : .white.opacity(0.35))
                                        .font(.system(size: 16, weight: .medium))
                                        .frame(width: 30, height: 30)
                                        .padding(8)
                                        .clipShape(Circle())
                                        .shadow(color: Color.black.opacity(0.25), radius: 10, x: 0, y: 6)
                                }
                                .disabled(effectState.filter?.filter == nil)
                            }
                            .padding(6)
                            .background(.ultraThinMaterial)
                            .clipShape(RoundedRectangle(cornerRadius: 100))
                            .shadow(color: Color.black.opacity(0.25), radius: 10, x: 0, y: 6)
                            
                            
                            // Save button
                            Button(action: onSaveChanges) {
                                Image(systemName: "checkmark")
                                    .foregroundColor(.black)
                                    .font(.system(size: 16, weight: .medium))
                                    .frame(width: 30, height: 30)
                                    .padding(8)
                                    .background(.yellow)
                                    .clipShape(Circle())
                                    .shadow(color: Color.black.opacity(0.25), radius: 10, x: 0, y: 6)
                            }
                            
                            Spacer()
                        }
                    }
                    .padding(.top, 0)
                    .padding(.horizontal, 12)
                }
                .background(.black.opacity(0.85))
                .padding(.vertical, 16)
            }
        }
        .background(Color.black)
        .onAppear {
            // Reset the state on appear
            resetEffectState()
            
            // Try to initialize with either baseImage or the bound image
            let imageToUse = baseImage ?? image
            if let imageToUse = imageToUse {
                BackgroundBlurManager.shared.startEditingSession(for: imageToUse)
                stateHistory.initializeWithOriginal(originalImage: imageToUse)
                generateFilterPreviews()
                checkPersonSegmentationSupport()
            }
        }
        .onChange(of: originalImage) { newValue in
            if let imageToUse = newValue ?? originalImage {
                // MEMORY OPTIMIZATION: Start editing session for this image
                BackgroundBlurManager.shared.startEditingSession(for: imageToUse)
                
                // Clear effect state and cache when image changes
                resetEffectState()
                
                // Initialize state history AFTER reset
                stateHistory.initializeWithOriginal(originalImage: imageToUse)
                
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
        .onChange(of: showingEffects) { _ in checkForOnboardingTrigger() }
        .onChange(of: showingBlurAdjustment) { _ in checkForOnboardingTrigger() }
        .onChange(of: showingAdjustments) { _ in checkForOnboardingTrigger() }
        .onChange(of: effectState.filter?.filter.id) { _ in markFirstFilterApplied() }
    }

    // MARK: - ProRaw Mode Handling
    
    private func handleProcessingModeChange(_ newMode: ImageProcessingMode) {
        // Save current state before switching modes
        saveCurrentStateToHistory()
        
        // Reset effects when switching modes to avoid confusion
        effectState = .default
        processedImage = nil
        
        // Apply effects with the new base image
        applyEffects()
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
                resetToOriginal()
                return
            }
        }
        
        applyEffects()
    }

    private func applyEffects(debounce: Bool = false) {
        guard let currentBaseImage = baseImage else { return }

        // Cancel previous work item for debouncing
        effectWorkItem?.cancel()

        let workItem = DispatchWorkItem {
            guard let workItem = self.effectWorkItem, !workItem.isCancelled else { return }

            DispatchQueue.main.async {
                self.isProcessing = true
            }

            var resultImage = currentBaseImage
            
            // Apply background blur first if enabled
            if self.effectState.backgroundBlur.isEnabled && self.effectState.backgroundBlur.intensity > 0 && self.hasPersonSegmentation {
                if let blurredImage = BackgroundBlurManager.shared.applyBackgroundBlur(
                    to: resultImage,
                    blurIntensity: self.effectState.backgroundBlur.intensity,
                    useCache: !debounce // Use cache for non-debounced calls
                ) {
                    resultImage = blurredImage
                }
            } else {
                resultImage = currentBaseImage
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
        
        applyEffects()
    }
    
    // MARK: - Smart Tap Gesture Handling
    
    private func handleImageTap() {
        // Hide previous state label incase it's ON during an operation
        if isShowingPreviousState {
            isShowingPreviousState = false
        }
        
        // Scenario 3: If any adjustment controls are active, close them first
        if showingAdjustments || showingBlurAdjustment || showingEffects {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                showingAdjustments = false
                showingBlurAdjustment = false
                showingEffects = false
                shouldShrinkImage = false
            }
        }
    }
    
    private func handleImageOriginalState() {
        HapticFeedback.light.generate()
        
        withAnimation(.easeInOut) {
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
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                    self.isShowingPreviousState = false
                }
            }
        }
    }
    
    // MARK: - State History Management
    
    private func saveCurrentStateToHistory() {
        guard let currentBaseImage = baseImage else { return }
        
        // Determine the correct baseline based on the type of change
        let previousStateDescription = determineCorrectBaseline()
        
        // Use the current displayed image (processed or base)
        let currentDisplayedImage = processedImage ?? currentBaseImage
        
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
        guard let imageToUse = baseImage ?? image else { return }

        DispatchQueue.global(qos: .userInitiated).async {
            var newPreviews: [String: UIImage] = [:]

            for filter in FilterManager.shared.filters(for: selectedPack) {
                if let preview = FilterManager.shared.generateFilterPreview(filter, for: imageToUse) {
                    newPreviews[filter.id] = preview
                }
            }

            DispatchQueue.main.async {
                filterPreviews = newPreviews
            }
        }
    }

    private func onSaveChanges() {
        guard let currentBaseImage = baseImage else { return }

        isProcessing = true

        DispatchQueue.global(qos: .userInitiated).async {
            var finalImage = currentBaseImage
            
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
        effectState = .default
        processedImage = nil
        stateHistory = .empty
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
        
        // If supported and we have a base image, try to detect a person
        if hasPersonSegmentation, let currentBaseImage = baseImage {
            DispatchQueue.global(qos: .userInitiated).async {
                // Create a small preview for faster person detection
                let testSize = CGSize(width: 200, height: 300)
                guard let smallImage = currentBaseImage.resized(to: testSize) else { return }
                
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
        guard let currentBaseImage = baseImage else { return }
        
        effectState = .default
        stateHistory = .empty
        
        withAnimation(.easeInOut(duration: 0.3)) {
            processedImage = currentBaseImage
            image = currentBaseImage
        }
    }
    
    // MARK: - Onboarding Logic

    private func checkForOnboardingTrigger() {
        guard !hasSeenImagePreviewOnboarding && hasAppliedFirstFilter else { return }
        
        // Check if all control views are now dismissed
        let allControlsDismissed = !showingEffects && !showingBlurAdjustment && !showingAdjustments
        
        if allControlsDismissed {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
                withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                    showOnboardingAnimation = true
                }
            }
        }
    }

    private func markFirstFilterApplied() {
        if !hasAppliedFirstFilter && effectState.filter != nil {
            hasAppliedFirstFilter = true
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
        rawImage: nil, // No RAW for preview
        cameraQuality: .standard,
        isProcessing: .constant(false),
        onSave: {},
        onDiscard: {}
    )
    .preferredColorScheme(.dark)
}

