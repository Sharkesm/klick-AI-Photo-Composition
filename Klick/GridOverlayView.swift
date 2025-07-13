import SwiftUI

struct GridOverlayView: View {
    let isVisible: Bool
    
    var body: some View {
        GeometryReader { geometry in
            if isVisible {
                Canvas { context, size in
                    let width = size.width
                    let height = size.height
                    
                    // Calculate third positions
                    let thirdX1 = width / 3
                    let thirdX2 = width * 2 / 3
                    let thirdY1 = height / 3
                    let thirdY2 = height * 2 / 3
                    
                    // Create path for grid lines
                    var path = Path()
                    
                    // Vertical lines
                    path.move(to: CGPoint(x: thirdX1, y: 0))
                    path.addLine(to: CGPoint(x: thirdX1, y: height))
                    
                    path.move(to: CGPoint(x: thirdX2, y: 0))
                    path.addLine(to: CGPoint(x: thirdX2, y: height))
                    
                    // Horizontal lines
                    path.move(to: CGPoint(x: 0, y: thirdY1))
                    path.addLine(to: CGPoint(x: width, y: thirdY1))
                    
                    path.move(to: CGPoint(x: 0, y: thirdY2))
                    path.addLine(to: CGPoint(x: width, y: thirdY2))
                    
                    // Draw the grid
                    context.stroke(path, with: .color(.white.opacity(0.6)), lineWidth: 1)
                }
                .animation(.easeInOut(duration: 0.3), value: isVisible)
            }
        }
    }
} 