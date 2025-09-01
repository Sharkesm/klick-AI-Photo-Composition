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
                 HStack {
                     Spacer()
                     VStack {
                         CameraQualitySelector(selectedQuality: $selectedCameraQuality)
                         FlashControl(selectedFlashMode: $selectedFlashMode)
                         ZoomControlsView(selectedZoomLevel: $selectedZoomLevel)
                     }
                 }
                 .padding(.horizontal, 20)
                
                Spacer()
            }
        }
    }
}
