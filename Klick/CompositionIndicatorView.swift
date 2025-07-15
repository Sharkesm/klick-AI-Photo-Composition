import SwiftUI

struct CompositionIndicatorView: View {
    let compositionType: String
    
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "squareshape.split.2x2.dotted")
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.white)
            
            Text(compositionType)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.white)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(Color.black.opacity(0.6))
        .clipShape(Capsule())
        .padding(.leading, 20)
        .padding(.top, 60) // Account for safe area
    }
}

#Preview {
    ZStack {
        Color.black
        CompositionIndicatorView(compositionType: "Rule of Thirds")
    }
} 
