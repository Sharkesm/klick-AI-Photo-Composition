import SwiftUI

// MARK: - Bottom Controls View
struct BottomControlsView: View {
    let compositionManager: CompositionManager
    let hasCameraPermission: Bool
    let cameraLoading: Bool
    let onCapturePhoto: () -> Void
    let onShowCompositionPicker: () -> Void
    let onShowFrameSettings: () -> Void
    
    var body: some View {
        // Bottom controls - only show when camera is ready
        if hasCameraPermission && !cameraLoading {
            VStack {
                Spacer()
                
                HStack(spacing: 40) {
                    // Composition type selector button
                    Button(action: onShowCompositionPicker) {
                        Image(systemName: compositionManager.currentCompositionType.icon)
                            .font(.system(size: 22))
                            .foregroundColor(.white)
                            .frame(width: 60, height: 60)
                            .background(.ultraThinMaterial)
                            .clipShape(Circle())
                    }
                    
                    // Capture button
                    Button(action: onCapturePhoto) {
                        Circle()
                            .fill(Color.white)
                            .frame(width: 80, height: 80)
                            .overlay(
                                Circle()
                                    .stroke(Color.black, lineWidth: 4)
                                    .frame(width: 70, height: 70)
                            )
                    }
                    
                    // Settings button
                    Button(action: onShowFrameSettings) {
                        Image(systemName: "gear")
                            .font(.system(size: 22))
                            .foregroundColor(.white)
                            .frame(width: 60, height: 60)
                            .background(.ultraThinMaterial)
                            .clipShape(Circle())
                    }
                }
                .padding(.bottom, 50)
            }
            .transition(.move(edge: .bottom).combined(with: .opacity).combined(with: .scale(scale: 0.8)))
        }
    }
}

