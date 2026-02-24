import SwiftUI

struct HowItWorksButton: View {
    @Binding var showOnboarding: Bool
    
    var body: some View {
        Button(action: {
            Task {
                await EventTrackingManager.shared.trackCameraHowItWorksTapped()
            }
            showOnboarding = true
        }) {
            Image(systemName: "info.circle")
                .font(.system(size: 15, weight: .semibold))
                .foregroundColor(.white)
        }
        .frame(width: 42, height: 42)
        .background(Color.black.opacity(0.5))
        .clipShape(Capsule())
    }
}
