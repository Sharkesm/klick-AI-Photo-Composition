import SwiftUI

struct FaceHighlightOverlayView: View {
    let faceBoundingBox: CGRect?
    
    var body: some View {
        GeometryReader { geometry in
            if let boundingBox = faceBoundingBox {
                // The bounding box is now in screen coordinates from the preview layer
                let x = boundingBox.origin.x
                let y = boundingBox.origin.y
                let width = boundingBox.width
                let height = boundingBox.height
                
                // Add padding to make rectangle slightly larger than face
                let padding: CGFloat = 20
                let paddedWidth = width + (padding * 2)
                let paddedHeight = height + (padding * 2)
                let paddedX = max(0, x - padding)
                let paddedY = max(0, y - padding)
                
                Rectangle()
                    .stroke(Color.green, lineWidth: 2)
                    .frame(width: paddedWidth, height: paddedHeight)
                    .position(x: paddedX + paddedWidth/2, y: paddedY + paddedHeight/2)
                    .cornerRadius(4)
                    .animation(.easeInOut(duration: 0.2), value: boundingBox)
            }
        }
    }
} 