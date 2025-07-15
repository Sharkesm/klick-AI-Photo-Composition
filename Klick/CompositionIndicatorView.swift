import SwiftUI

struct CompositionIndicatorView: View {
    @ObservedObject var compositionManager: CompositionManager
    let compositionType: String
    
    var body: some View {
        HStack(spacing: 0) {
            Spacer()
            HStack(spacing: 8) {
                Image(systemName: compositionManager.currentCompositionType.icon)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.white)
                
                Text(compositionType)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.white)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(Color.black)
            .clipShape(Capsule())
            Spacer()
        }
    }
}
