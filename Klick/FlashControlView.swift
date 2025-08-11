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
struct FlashControl: View {
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
                }
            }
        }) {
            VStack(spacing: 4) {
                Image(systemName: selectedFlashMode.iconName)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(selectedFlashMode.captureColor)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(Color.black.opacity(0.5))
            .clipShape(Capsule())
            .scaleEffect(showFlashChange ? 1.1 : 1.0)
        }
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

