import SwiftUI

// MARK: - Bottom Controls View
struct BottomControlsView: View {
    @ObservedObject var compositionManager: CompositionManager
    
    let hasCameraPermission: Bool
    let cameraLoading: Bool
    let onCapturePhoto: () -> Void
    let onShowCompositionPicker: () -> Void
    
    @State private var selectedIndex: Int = 1 // Default to second item (center framing)
    @State private var scrollPosition: Int? = 1 // Optional for scrollPosition binding
    @State private var isInitializing: Bool = true
    
    private let compositionTypes = CompositionType.allCases
    private let itemSpacing: CGFloat = 20
    private let sideItemWidth: CGFloat = 50
    private let centerItemWidth: CGFloat = 80
    
    var body: some View {
        // Bottom controls - only show when camera is ready
        if hasCameraPermission && !cameraLoading {
            // Composition Style Picker with Scroll (iOS 16 Compatible)
            VStack {
                ZStack {
                    // Scrollable composition items
                    ScrollViewReader { proxy in
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(alignment: .center, spacing: itemSpacing) {
                                ForEach(Array(compositionTypes.enumerated()), id: \.offset) { index, compositionType in
                                    CompositionStyleButton(
                                        compositionType: compositionType,
                                        onTap: {
                                            selectCompositionStyle(at: index, proxy: proxy)
                                        },
                                        onCapture: nil // No capture from scrolling items
                                    )
                                    .id(index)
                                }
                            }
                            .padding(.horizontal, UIScreen.main.bounds.width / 2 - sideItemWidth / 2)
                            .background(
                                // Invisible geometry reader to track scroll position
                                GeometryReader { geometry in
                                    Color.clear
                                        .preference(key: ScrollOffsetPreferenceKey.self,
                                                    value: geometry.frame(in: .named("scroll")).origin.x)
                                }
                            )
                        }
                        .scrollDisabled(true) // Disable finger scrolling
                        .coordinateSpace(name: "scroll")
                        .onPreferenceChange(ScrollOffsetPreferenceKey.self) { offset in
                            // Only track scroll changes after initial setup
                            if !isInitializing {
                                updateSelectedIndexFromOffset(offset, proxy: proxy)
                            }
                        }
                        .onAppear {
                            // Initialize composition manager with default selected type
                            let defaultType = compositionTypes[selectedIndex]
                            compositionManager.switchToCompositionType(defaultType)
                            
                            // Scroll to default center item on appear
                            proxy.scrollTo(selectedIndex, anchor: .center)
                                
                            // Enable scroll tracking after initial positioning
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
                                isInitializing = false
                            }
                        }
                        .onChange(of: compositionManager.currentCompositionType) { newType in
                            // Sync selectedIndex when composition changes externally (e.g., from swipe gesture)
                            if let newIndex = compositionTypes.firstIndex(of: newType),
                               newIndex != selectedIndex {
                                withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                                    selectedIndex = newIndex
                                    proxy.scrollTo(newIndex, anchor: .center)
                                }
                            }
                        }
                    }
                    
                    // Fixed center border overlay (always stays in center)
                    StickyCompositionBorder(
                        compositionType: compositionTypes[selectedIndex],
                        onCapture: onCapturePhoto
                    )
                }
                
                HStack {
                    Spacer()
                    Text(compositionTypes[selectedIndex].displayName)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(Color.white)
                        .padding(.vertical, 5)
                        .padding(.horizontal, 10)
                        .background(.ultraThinMaterial.blendMode(.lighten))
                        .clipShape(Capsule())
                        .animation(.easeInOut(duration: 0.3), value: selectedIndex)
                    Spacer()
                }
            }
         }
    }
    
    private func selectCompositionStyle(at index: Int, proxy: ScrollViewProxy) {
        // Track composition selected via tap
        let previousType = compositionTypes[selectedIndex]
        let selectedType = compositionTypes[index]
        
        if previousType != selectedType {
            HapticFeedback.selection.generate()
            
            Task {
                await EventTrackingManager.shared.trackCompositionSelected(
                    fromComposition: previousType,
                    toComposition: selectedType,
                    selectionMethod: .tap
                )
            }
        }
        
        withAnimation(.spring(response: 0.5, dampingFraction: 0.7, blendDuration: 0.2)) {
            selectedIndex = index
            
            // Scroll to center the selected item
            proxy.scrollTo(index, anchor: .center)
        }
        
        // Update composition type outside of animation block to ensure immediate update
        compositionManager.switchToCompositionType(selectedType)
        
        // Force a UI update by publishing on main queue
        DispatchQueue.main.async {
            // This ensures the overlay view reacts immediately to the change
            self.compositionManager.objectWillChange.send()
        }

        // Trigger composition picker callback after the selection animation settles
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.65) {
            onShowCompositionPicker()
        }
    }
    
    private func updateSelectedIndexFromOffset(_ offset: CGFloat, proxy: ScrollViewProxy) {
        // Calculate which item should be centered based on scroll position
        let totalItemWidth = sideItemWidth + itemSpacing
        let paddingOffset = UIScreen.main.bounds.width / 2 - sideItemWidth / 2
        let scrollPosition = -offset + paddingOffset
        let calculatedIndex = Int(round(scrollPosition / totalItemWidth))
        let newIndex = max(0, min(compositionTypes.count - 1, calculatedIndex))
        
        // Only update if the index actually changed to avoid unnecessary updates
        if newIndex != selectedIndex {
            // Track composition selected via scroll
            let previousType = compositionTypes[selectedIndex]
            let selectedType = compositionTypes[newIndex]
            
            Task {
                await EventTrackingManager.shared.trackCompositionSelected(
                    fromComposition: previousType,
                    toComposition: selectedType,
                    selectionMethod: .scroll
                )
            }
            
            DispatchQueue.main.async {
                self.selectedIndex = newIndex
                self.compositionManager.switchToCompositionType(selectedType)
                
                // Force UI update to ensure overlays react immediately
                self.compositionManager.objectWillChange.send()
            }
        }
    }
}

// MARK: - Composition Style Button
struct CompositionStyleButton: View {
    let compositionType: CompositionType
    let onTap: () -> Void
    let onCapture: (() -> Void)?
    
    var body: some View {
        Button(action: onTap) {
            // All items are now uniform (no special center styling)
            Image(systemName: compositionType.icon)
                .font(.system(size: 20, weight: .medium))
                .foregroundColor(.white)
                .frame(width: 60, height: 60)
                .padding(3)
                .background(.ultraThinMaterial.opacity(0.85))
                .clipShape(Circle())
                .scaleEffect(0.9)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Sticky Composition Border (Always Centered)
struct StickyCompositionBorder: View {
    let compositionType: CompositionType
    let onCapture: () -> Void
    
    var body: some View {
        Button(action: onCapture) {
            // Fixed center border that never moves
            Circle()
                .fill(Color.clear)
                .frame(width: 90, height: 90)
                .overlay(alignment: .center) {
                    Circle()
                        .stroke(Color.white, lineWidth: 4)
                        .frame(width: 80, height: 80)
                        .overlay(alignment: .center, content: {
                            Image(systemName: compositionType.icon)
                                .font(.system(size: 24))
                                .foregroundColor(.black)
                                .frame(width: 60, height: 60)
                                .padding(3)
                                .background(.yellow)
                                .clipShape(Circle())
                        })
                }
                .scaleEffect(1.0)
        }
        .buttonStyle(PlainButtonStyle())
        .animation(.spring(response: 0.4, dampingFraction: 0.8), value: compositionType)
    }
}

// MARK: - Scroll Offset Preference Key (iOS 16 Compatible)
struct ScrollOffsetPreferenceKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}
