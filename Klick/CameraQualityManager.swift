import SwiftUI
import AVFoundation

// MARK: - Camera Quality Enum
enum CameraQuality: String, CaseIterable {
    case hd720p = "hd720p"
    case hd1080p = "hd1080p"
    case uhd4K = "uhd4K"
    
    var sessionPreset: AVCaptureSession.Preset {
        switch self {
        case .hd720p:
            return .hd1280x720
        case .hd1080p:
            return .hd1920x1080
        case .uhd4K:
            return .hd4K3840x2160
        }
    }
    
    var displayName: String {
        switch self {
        case .hd720p:
            return "HD"
        case .hd1080p:
            return "HD+"
        case .uhd4K:
            return "4K"
        }
    }
}

// MARK: - Camera Quality Selector View
struct CameraQualitySelector: View {
    @Binding var selectedQuality: CameraQuality
    @State private var showQualityPicker = false
    
    var body: some View {
        Button(action: {
            withAnimation(.easeInOut(duration: 0.2)) {
                showQualityPicker = true
        
                // Cycle through quality options
                let allCases = CameraQuality.allCases
                if let currentIndex = allCases.firstIndex(of: selectedQuality) {
                    let nextIndex = (currentIndex + 1) % allCases.count
                    selectedQuality = allCases[nextIndex]
                }
            }
        }) {
            Text(selectedQuality.displayName)
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(.white)
        }
        .frame(width: 42, height: 42)
        .background(Color.black.opacity(0.5))
        .clipShape(Capsule())
    }
}
