import SwiftUI

// MARK: - Top Controls View
struct TopControlsView: View {
    @Binding var selectedCameraQuality: CameraQuality
    @Binding var selectedFlashMode: FlashMode
    @Binding var selectedZoomLevel: ZoomLevel
    @Binding var showFrameSettings: Bool
    @Binding var showCompositionPractice: Bool
    
    let compositionManager: CompositionManager
    let hasCameraPermission: Bool
    let cameraLoading: Bool
    
    var body: some View {
        // Top controls - composition indicator, quality selector and flash control
        if hasCameraPermission && !cameraLoading {
             VStack(spacing: 6) {
                 HStack(alignment: .top) {
                     Button(action: {
                         withAnimation(.easeInOut(duration: 0.3)) {
                             showFrameSettings = true
                         }
                     }) {
                         Image(systemName: "gear")
                             .font(.system(size: 15, weight: .semibold))
                             .foregroundColor(.white)
                     }
                     .frame(width: 42, height: 42)
                     .background(Color.black.opacity(0.5))
                     .clipShape(Capsule())
                     
                     Spacer()
                     VStack {
                         CameraQualitySelectorView(selectedQuality: $selectedCameraQuality)
                         FlashControlView(selectedFlashMode: $selectedFlashMode)
                         ZoomControlsView(selectedZoomLevel: $selectedZoomLevel)
                         CompositionStylePracticeControl(showCompositionPractice: $showCompositionPractice)
                     }
                 }
                 .padding(.horizontal, 20)
                
                Spacer()
            }
        }
    }
}
