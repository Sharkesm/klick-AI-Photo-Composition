import SwiftUI
import AVFoundation

// MARK: - Zoom Level Enum
enum ZoomLevel: String, CaseIterable {
    case ultraWide
    case wide
    case telephoto2x
    case telephoto5x
    
    var displayName: String {
        return self.rawValue
    }
    
    var zoomFactor: CGFloat {
        switch self {
        case .ultraWide:
            return 0.5
        case .wide:
            return 1.0
        case .telephoto2x:
            return 2.0
        case .telephoto5x:
            return 5.0
        }
    }
    
    var zoomLabel: String {
        switch self {
        case .ultraWide:
            return ".5"
        case .wide:
            return "1"
        case .telephoto2x:
            return "2"
        case .telephoto5x:
            return "5"
        }
    }
    
    var deviceType: AVCaptureDevice.DeviceType {
        switch self {
        case .ultraWide:
            return .builtInUltraWideCamera
        case .wide:
            return .builtInWideAngleCamera
        case .telephoto2x, .telephoto5x:
            return .builtInTelephotoCamera
        }
    }
    
    var isAvailable: Bool {
        let discoverySession = AVCaptureDevice.DiscoverySession(
            deviceTypes: [deviceType],
            mediaType: .video,
            position: .back
        )
        return !discoverySession.devices.isEmpty
    }
    
    // Get the best available device for this zoom level
    static func getAvailableZoomLevels() -> [ZoomLevel] {
        return allCases.filter { $0.isAvailable }
    }
}

// MARK: - Zoom Controls View
struct ZoomControlsView: View {
    @Binding var selectedZoomLevel: ZoomLevel
    @State private var showZoomChange = false
    @State private var isRevealed = false
    
    let impactFeedback = UIImpactFeedbackGenerator(style: .light)
    
    var body: some View {
        ZStack {
            // Morphing Container - starts as capsule like FlashControl, expands to rounded rectangle
            RoundedRectangle(
                cornerRadius: isRevealed ? 25 : 50,
                style: .continuous
            )
            .fill(Color.black.opacity(isRevealed ? 0.4 : 0.5))
            .background(.ultraThinMaterial.opacity(isRevealed ? 0.1 : 0))
            .frame(
                width: isRevealed ? 46 : 40,
                height: isRevealed ? CGFloat(ZoomLevel.getAvailableZoomLevels().count * 44) : 40
            )
            .animation(.spring(response: 0.5, dampingFraction: 0.8), value: isRevealed)
            
            VStack(spacing: isRevealed ? 6 : 0) {
                // Default button that transforms into the first zoom option
                Button {
                    if isRevealed {
                        isRevealed = false
                    } else {
                        withAnimation(.spring(response: 0.4, dampingFraction: 0.8, blendDuration: 0)) {
                            isRevealed.toggle()
                        }
                        impactFeedback.impactOccurred()
                        impactFeedback.prepare()
                    }
                } label: {
                    HStack(spacing: 4) {
                        if isRevealed {
                            Image(systemName: "x.circle.fill")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(.white)
                        } else {
                            Text("\(selectedZoomLevel.zoomLabel)x")
                                .font(.system(size: isRevealed ? 16 : 14, weight: .medium))
                                .foregroundColor(isRevealed ? (selectedZoomLevel == ZoomLevel.getAvailableZoomLevels().first ? .yellow : .white) : .white)
                                .padding(.top, 6)
                        }
                    }
                    .padding(.horizontal, isRevealed ? 0 : 12)
                    .padding(.vertical, isRevealed ? 0 : 8)
                    .background(Color.clear)
                    .clipShape(Circle())
                    .scaleEffect(isRevealed && selectedZoomLevel == ZoomLevel.getAvailableZoomLevels().first ? 1.1 : 0.95)
                    .shadow(color: isRevealed && selectedZoomLevel == ZoomLevel.getAvailableZoomLevels().first ? .yellow.opacity(0.3) : .clear, radius: 4)
                }
                .animation(.spring(response: 0.4, dampingFraction: 0.8), value: isRevealed)
                .animation(.spring(response: 0.4, dampingFraction: 0.8), value: selectedZoomLevel)
                .padding(.bottom, 6)
                
                // Additional zoom options that appear when expanded
                if isRevealed {
                    ForEach(Array(ZoomLevel.getAvailableZoomLevels().enumerated()), id: \.element) { index, zoomLevel in
                        Button(action: {
                            // Add haptic feedback
                            impactFeedback.impactOccurred()
                            impactFeedback.prepare()
                            
                            withAnimation(.easeInOut(duration: 0.3)) {
                                selectedZoomLevel = zoomLevel
                                showZoomChange = true
                            }
                            
                            // Collapse after selection with slight delay
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.9)) {
                                    isRevealed = false
                                }
                            }
                        }) {
                            Text(zoomLevel.zoomLabel)
                                .font(.system(size: selectedZoomLevel == zoomLevel ? 14 : 11, weight: .medium))
                                .foregroundColor(selectedZoomLevel == zoomLevel ? .yellow : .white)
                                .padding(.horizontal, selectedZoomLevel == zoomLevel ? 12 : 10)
                                .padding(.vertical, selectedZoomLevel == zoomLevel ? 8 : 6)
                                .background(Color.black.opacity(selectedZoomLevel == zoomLevel ? 0.8 : 0.6))
                                .clipShape(Circle())
                                .scaleEffect(selectedZoomLevel == zoomLevel ? 1.0 : 0.9)
                                .shadow(color: selectedZoomLevel == zoomLevel ? .yellow.opacity(0.3) : .clear, radius: 4)
                        }
                        .transition(.asymmetric(
                            insertion: .scale(scale: 0.1).combined(with: .opacity).combined(with: .move(edge: .top)),
                            removal: .scale(scale: 0.1).combined(with: .opacity).combined(with: .move(edge: .top))
                        ))
                        .animation(.spring(response: 0.4, dampingFraction: 0.8).delay(Double(index + 1) * 0.08), value: isRevealed)
                        .animation(.spring(response: 0.3, dampingFraction: 0.8), value: selectedZoomLevel)
                    }
                }
            }
            .padding(.horizontal, isRevealed ? 16 : 12)
            .padding(.vertical, 8)
            .onChange(of: showZoomChange) { newValue in
                if newValue {
                    // Reset animation state
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                        withAnimation(.easeOut(duration: 0.1)) {
                            showZoomChange = false
                        }
                    }
                }
            }
        }
        .onTapGesture {
            // Tap outside to collapse
            if isRevealed {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.9)) {
                    isRevealed = false
                }
            }
        }
    }
}

