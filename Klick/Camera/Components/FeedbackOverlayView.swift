import SwiftUI

// MARK: - Feedback Overlay View
struct FeedbackOverlayView: View {
    let showFeedback: Bool
    let hasCameraPermission: Bool
    let cameraLoading: Bool
    let isCompositionAnalysisEnabled: Bool
    let feedback: CompositionFeedback?
    
    var body: some View {
        if hasCameraPermission && !cameraLoading && isCompositionAnalysisEnabled {
            if showFeedback, let feedback = feedback {
                HStack(spacing: 8) {
                    // System image icon with translucent background - using color from feedback model
                    Image(systemName: feedback.label)
                        .font(.title2)
                        .foregroundColor(feedback.color)
                        .frame(width: 32, height: 32)
                        .background(.ultraThinMaterial)
                        .clipShape(Circle())
                        
                    // Feedback message
                    Text(feedback.suggestion)
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

