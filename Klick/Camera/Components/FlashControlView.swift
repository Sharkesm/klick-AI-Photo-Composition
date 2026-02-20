import SwiftUI
import AVFoundation

// MARK: - Flash Mode Enum
enum FlashMode: String, CaseIterable {
    case off = "off"
    case auto = "auto"
    case on = "on"
    
    var displayName: String {
        switch self {
        case .off:
            return "OFF"
        case .auto:
            return "AUTO"
        case .on:
            return "ON"
        }
    }
    
    var iconName: String {
        switch self {
        case .off:
            return "bolt.slash"
        case .auto:
            return "bolt.badge.a"
        case .on:
            return "bolt"
        }
    }
    
    var captureFlashMode: AVCaptureDevice.FlashMode {
        switch self {
        case .off:
            return .off
        case .auto:
            return .auto
        case .on:
            return .on
        }
    }
    
    var captureColor: Color {
        switch self {
        case .on:
            return .yellow
        default:
            return .white
        }
    }
}

// MARK: - Flash Control View
struct FlashControlView: View {
    @Binding var selectedFlashMode: FlashMode
    @State private var showFlashChange = false
    
    var body: some View {
        Button(action: {
            withAnimation(.easeInOut(duration: 0.2)) {
                showFlashChange = true
                
                // Cycle through flash modes
                let allCases = FlashMode.allCases
                if let currentIndex = allCases.firstIndex(of: selectedFlashMode) {
                    let nextIndex = (currentIndex + 1) % allCases.count
                    selectedFlashMode = allCases[nextIndex]
                    
                    // Track flash changed
                    Task {
                        let trackingFlashMode: TrackingFlashMode = {
                            switch selectedFlashMode {
                            case .off: return .off
                            case .auto: return .auto
                            case .on: return .on
                            }
                        }()
                        await EventTrackingManager.shared.trackFlashChanged(mode: trackingFlashMode)
                    }
                }
            }
        }) {
            Image(systemName: selectedFlashMode.iconName)
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(selectedFlashMode.captureColor)
                .scaleEffect(showFlashChange ? 1.0 : 0.95)
        }
        .frame(width: 42, height: 42)
        .background(Color.black.opacity(0.5))
        .clipShape(Capsule())
        .onChange(of: showFlashChange) { newValue in
            if newValue {
                // Reset scale after animation
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                    withAnimation(.easeOut(duration: 0.1)) {
                        showFlashChange = false
                    }
                }
            }
        }
    }
}

