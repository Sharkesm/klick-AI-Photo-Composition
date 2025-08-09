import SwiftUI

struct FaceHighlightOverlayView: View {
    let faceBoundingBox: CGRect?
    
    var body: some View {
        GeometryReader { geometry in
            if let boundingBox = faceBoundingBox {
                // Ensure the bounding box is within screen bounds
                let clampedBoundingBox = clampToGeometry(boundingBox, geometry: geometry)
                
                // Add padding to make rectangle slightly larger than face
                let padding: CGFloat = 20
                let paddedWidth = clampedBoundingBox.width + (padding * 2)
                let paddedHeight = clampedBoundingBox.height + (padding * 2)
                
                // Ensure padded rectangle stays within screen bounds
                let maxX = geometry.size.width - paddedWidth
                let maxY = geometry.size.height - paddedHeight
                let paddedX = max(0, min(maxX, clampedBoundingBox.origin.x - padding))
                let paddedY = max(0, min(maxY, clampedBoundingBox.origin.y - padding))
                
                // Create the final rectangle
                let finalRect = CGRect(
                    x: paddedX,
                    y: paddedY,
                    width: min(paddedWidth, geometry.size.width - paddedX),
                    height: min(paddedHeight, geometry.size.height - paddedY)
                )
                
                // Use ZStack to show both the rectangle and corner indicators
                ZStack {
                    // Main rectangle outline
                    Rectangle()
                        .stroke(Color.yellow, lineWidth: 1)
                        .frame(width: finalRect.width, height: finalRect.height)
                        .position(x: finalRect.midX, y: finalRect.midY)
                        .cornerRadius(4)
                    
                    // Corner indicators for better visibility
                    CornerIndicatorsView(rect: finalRect)
                }
                .animation(.easeInOut(duration: 0.2), value: boundingBox)
            }
        }
    }
    
    /// Clamps the bounding box to ensure it's within the geometry bounds
    private func clampToGeometry(_ rect: CGRect, geometry: GeometryProxy) -> CGRect {
        let minX = max(0, rect.origin.x)
        let minY = max(0, rect.origin.y)
        let maxX = min(geometry.size.width, rect.origin.x + rect.width)
        let maxY = min(geometry.size.height, rect.origin.y + rect.height)
        
        return CGRect(
            x: minX,
            y: minY,
            width: max(0, maxX - minX),
            height: max(0, maxY - minY)
        )
    }
}

/// Corner indicators for better visual feedback
struct CornerIndicatorsView: View {
    let rect: CGRect
    private let cornerSize: CGFloat = 15
    private let cornerThickness: CGFloat = 1
    
    var body: some View {
        let corners = [
            CGPoint(x: rect.minX, y: rect.minY), // Top-left
            CGPoint(x: rect.maxX, y: rect.minY), // Top-right
            CGPoint(x: rect.minX, y: rect.maxY), // Bottom-left
            CGPoint(x: rect.maxX, y: rect.maxY)  // Bottom-right
        ]
        
        ForEach(Array(corners.enumerated()), id: \.offset) { index, corner in
            CornerIndicator(
                position: corner,
                type: CornerType.allCases[index],
                size: cornerSize,
                thickness: cornerThickness
            )
        }
    }
}

/// Individual corner indicator
struct CornerIndicator: View {
    let position: CGPoint
    let type: CornerType
    let size: CGFloat
    let thickness: CGFloat
    
    var body: some View {
        Path { path in
            switch type {
            case .topLeft:
                // Top line
                path.move(to: CGPoint(x: position.x, y: position.y))
                path.addLine(to: CGPoint(x: position.x + size, y: position.y))
                // Left line
                path.move(to: CGPoint(x: position.x, y: position.y))
                path.addLine(to: CGPoint(x: position.x, y: position.y + size))
                
            case .topRight:
                // Top line
                path.move(to: CGPoint(x: position.x, y: position.y))
                path.addLine(to: CGPoint(x: position.x - size, y: position.y))
                // Right line
                path.move(to: CGPoint(x: position.x, y: position.y))
                path.addLine(to: CGPoint(x: position.x, y: position.y + size))
                
            case .bottomLeft:
                // Bottom line
                path.move(to: CGPoint(x: position.x, y: position.y))
                path.addLine(to: CGPoint(x: position.x + size, y: position.y))
                // Left line
                path.move(to: CGPoint(x: position.x, y: position.y))
                path.addLine(to: CGPoint(x: position.x, y: position.y - size))
                
            case .bottomRight:
                // Bottom line
                path.move(to: CGPoint(x: position.x, y: position.y))
                path.addLine(to: CGPoint(x: position.x - size, y: position.y))
                // Right line
                path.move(to: CGPoint(x: position.x, y: position.y))
                path.addLine(to: CGPoint(x: position.x, y: position.y - size))
            }
        }
        .stroke(Color.yellow, lineWidth: thickness)
    }
}

enum CornerType: CaseIterable {
    case topLeft, topRight, bottomLeft, bottomRight
} 
