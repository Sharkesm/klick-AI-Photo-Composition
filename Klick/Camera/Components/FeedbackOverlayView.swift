import SwiftUI

// MARK: - Feedback Overlay View
struct FeedbackOverlayView: View {
    let showFeedback: Bool
    let feedbackMessage: String?
    let feedbackIcon: String?
    let hasCameraPermission: Bool
    let cameraLoading: Bool
    let isCompositionAnalysisEnabled: Bool
    
    var body: some View {
        if hasCameraPermission && !cameraLoading && isCompositionAnalysisEnabled {
            if showFeedback, let message = feedbackMessage {
                HStack(spacing: 8) {
                    // System image icon with translucent background
                    Image(systemName: feedbackIcon ?? "questionmark.circle")
                        .font(.title2)
                        .foregroundColor(.white)
                        .frame(width: 32, height: 32)
                        .background(.ultraThinMaterial)
                        .clipShape(Circle())
                        
                    // Feedback message
                    Text(message)
                        .font(.headline)
                        .foregroundColor(.white)
                        .padding(.vertical, 12)
                }
                .padding(.horizontal, 8)
                .padding(.trailing, 4)
                .background(.ultraThinMaterial)
                .cornerRadius(25)
                .scaleEffect(showFeedback ? 1.0 : 0.01)
                .opacity(showFeedback ? 1.0 : 0.0)
                .animation(.spring, value: showFeedback)
            }
        }
    }
}

