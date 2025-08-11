import SwiftUI

// MARK: - Top Controls View
struct TopControlsView: View {
    @Binding var selectedCameraQuality: CameraQuality
    @Binding var selectedFlashMode: FlashMode
    @Binding var selectedZoomLevel: ZoomLevel
    let compositionManager: CompositionManager
    let hasCameraPermission: Bool
    let cameraLoading: Bool
    
    var body: some View {
        // Top controls - composition indicator, quality selector and flash control
        if hasCameraPermission && !cameraLoading {
            VStack(spacing: 6) {
                HStack(alignment: .top) {
                    // Camera quality selector (left)
                    CameraQualitySelector(selectedQuality: $selectedCameraQuality)
                    
                    Spacer()
                    
                    // Composition indicator (center)
                    CompositionIndicatorView(
                        compositionManager: compositionManager,
                        compositionType: compositionManager.currentCompositionType.displayName
                    )
                    
                    Spacer()
                    
                    FlashControl(selectedFlashMode: $selectedFlashMode)
                }
                .frame(alignment: .top)
                .padding(.top, 60)
                .padding(.horizontal, 20)
                
                HStack {
                    Spacer()
                    ZoomControlsView(selectedZoomLevel: $selectedZoomLevel)
                }
                .padding(.horizontal, 8)
                
                Spacer()
            }
            .ignoresSafeArea()
        }
    }
}
