import SwiftUI

// MARK: - Bottom Controls View
struct BottomControlsView: View {
    let compositionManager: CompositionManager
    let hasCameraPermission: Bool
    let cameraLoading: Bool
    let onCapturePhoto: () -> Void
    let onShowCompositionPicker: () -> Void
    
    var body: some View {
        // Bottom controls - only show when camera is ready
        if hasCameraPermission && !cameraLoading {
            VStack {
                Spacer()
                
                HStack(alignment: .center, spacing: 30) {
                    
                    // Left-side icon (smaller size)
                    Button(action: {
                        // Do nothing
                    }) {
                        Image(systemName: CompositionType.centerFraming.icon)
                            .font(.system(size: 20))
                            .foregroundColor(.white)
                            .frame(width: 50, height: 50)
                            .padding(3)
                            .background(.ultraThinMaterial.opacity(0.65))
                            .clipShape(Circle())
                    }
                    
                    // Center Icon
                    Button(action: onCapturePhoto) {
                        Circle()
                            .fill(Color.clear)
                            .frame(width: 80, height: 80)
                            .overlay(alignment: .center) {
                                Circle()
                                    .stroke(Color.white, lineWidth: 4)
                                    .frame(width: 70, height: 70)
                                    .overlay(alignment: .center, content: {
                                        Image(systemName: CompositionType.centerFraming.icon)
                                            .font(.system(size: 24))
                                            .foregroundColor(.black)
                                            .frame(width: 50, height: 50)
                                            .padding(3)
                                            .background(.yellow)
                                            .clipShape(Circle())
                                    })
                            }
                    }

                    // Right-side icon (smaller size)
                    Button(action: {
                        // Do nothing
                    }) {
                        Image(systemName: CompositionType.symmetry.icon)
                            .font(.system(size: 20))
                            .foregroundColor(.white)
                            .frame(width: 50, height: 50)
                            .padding(3)
                            .background(.ultraThinMaterial.opacity(0.65))
                            .clipShape(Circle())
                    }
                }
                .overlay(alignment: .bottom) {
                    Text("Capture")
                        .font(.system(size: 12))
                        .foregroundStyle(Color.white)
                        .padding(.vertical, 5)
                        .padding(.horizontal, 10)
                        .background(.ultraThinMaterial.blendMode(.lighten))
                        .clipShape(Capsule())
                        .offset(y: 30)
                }
            }
            .transition(
                .move(edge: .bottom)
                .combined(with: .opacity)
                .combined(with: .scale(scale: 0.8))
            )
        }
    }
}


#Preview {
    BottomControlsView(compositionManager: .init(), hasCameraPermission: true, cameraLoading: false, onCapturePhoto: {}, onShowCompositionPicker: {})
}
