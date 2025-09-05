import SwiftUI

// MARK: - Composition Overlays View
struct CompositionOverlaysView: View {
    @ObservedObject var compositionManager: CompositionManager
    let hasCameraPermission: Bool
    let cameraLoading: Bool
    let isCompositionAnalysisEnabled: Bool
    let areOverlaysHidden: Bool
    
    var body: some View {
        // Composition overlay - only show when camera is ready, analysis is enabled, and overlays are not hidden
        if hasCameraPermission && !cameraLoading && compositionManager.isEnabled && isCompositionAnalysisEnabled && !areOverlaysHidden {
            GeometryReader { geometry in
                // Always show basic overlays (grid, crosshair, etc.)
                ForEach(Array(compositionManager.getBasicOverlays(frameSize: geometry.size).enumerated()), id: \.offset) { index, element in
                    element.path
                        .stroke(element.color.opacity(element.opacity), lineWidth: element.lineWidth)
                        .animation(.easeInOut(duration: 0.3), value: compositionManager.currentCompositionType)
                }
                
                // Show subject-specific overlays when available
                if let result = compositionManager.lastResult {
                    ForEach(Array(result.overlayElements.enumerated()), id: \.offset) { index, element in
                        element.path
                            .stroke(element.color.opacity(element.opacity), lineWidth: element.lineWidth)
                            .animation(.easeInOut(duration: 0.3), value: compositionManager.currentCompositionType)
                    }
                }
            }
            .ignoresSafeArea()
            .transition(.opacity)
            .animation(.easeInOut(duration: 0.3), value: compositionManager.currentCompositionType)
        }
    }
}

