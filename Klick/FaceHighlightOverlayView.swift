import SwiftUI

struct FaceHighlightOverlayView: View {
    // MARK: - Properties
    let faceBoundingBox: CGRect?
    let isFaceDetected: Bool
    let recognitionConfidence: CGFloat
    
    // MARK: - Configuration
    let cornerLength: CGFloat
    let strokeWidth: CGFloat
    let glowColor: Color
    let pulseDuration: Double
    
    // MARK: - State
    @State private var glowIntensity: Double = 0.0
    
    // MARK: - Initializers
    /// Backward compatible initializer
    init(faceBoundingBox: CGRect?) {
        self.faceBoundingBox = faceBoundingBox
        self.isFaceDetected = faceBoundingBox != nil
        self.recognitionConfidence = faceBoundingBox != nil ? 0.8 : 0.0
        self.cornerLength = 48.0
        self.strokeWidth = 2.0
        self.glowColor = Color.yellow.opacity(0.8)
        self.pulseDuration = 2.0
    }
    
    /// Enhanced initializer with all parameters
    init(
        faceBoundingBox: CGRect?,
        isFaceDetected: Bool,
        recognitionConfidence: CGFloat,
        cornerLength: CGFloat = 48.0,
        strokeWidth: CGFloat = 2.0,
        glowColor: Color = Color.yellow.opacity(0.8),
        pulseDuration: Double = 2.0
    ) {
        self.faceBoundingBox = faceBoundingBox
        self.isFaceDetected = isFaceDetected
        self.recognitionConfidence = max(0.0, min(1.0, recognitionConfidence))
        self.cornerLength = cornerLength
        self.strokeWidth = strokeWidth
        self.glowColor = glowColor
        self.pulseDuration = pulseDuration
    }
    
    // MARK: - Computed Properties
    private var effectiveConfidence: CGFloat {
        max(0.0, min(1.0, recognitionConfidence))
    }
    
    
    private var glowOpacity: Double {
        isFaceDetected ? Double(effectiveConfidence) * 0.7 : 0.0
    }
    
    
    var body: some View {
        GeometryReader { geometry in
            if let boundingBox = faceBoundingBox {
                // Apply Y-axis correction for coordinate system alignment
                // Move the overlay DOWN to properly align with the face
                let layoutOffset: CGFloat = 40 // Move down by 40 points
                
                let correctedBoundingBox = CGRect(
                    x: boundingBox.origin.x,
                    y: boundingBox.origin.y + layoutOffset, // Subtract to move DOWN
                    width: boundingBox.width,
                    height: boundingBox.height
                )
                
                // Ensure the corrected bounding box is within screen bounds
                let clampedBoundingBox = clampToGeometry(correctedBoundingBox, geometry: geometry)
                
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
                
                // Enhanced ZStack with glow effects and animations
                ZStack {
                    // Glow effect layers (multiple for better blur effect)
                    if isFaceDetected && glowOpacity > 0 {
                        Group {
                            // Outer glow
                            CurvedCornerBracketsView(
                                rect: finalRect,
                                cornerLength: cornerLength,
                                strokeWidth: strokeWidth * 2,
                                color: glowColor.opacity(glowOpacity * 0.3)
                            )
                            .blur(radius: 8)
                            
                            // Mid glow
                            CurvedCornerBracketsView(
                                rect: finalRect,
                                cornerLength: cornerLength,
                                strokeWidth: strokeWidth * 1.5,
                                color: glowColor.opacity(glowOpacity * 0.5)
                            )
                            .blur(radius: 4)
                            
                            // Inner glow
                            CurvedCornerBracketsView(
                                rect: finalRect,
                                cornerLength: cornerLength,
                                strokeWidth: strokeWidth,
                                color: glowColor.opacity(glowOpacity * 0.8)
                            )
                            .blur(radius: 2)
                        }
                    }
                    
                    // Main curved corner brackets
                    CurvedCornerBracketsView(
                        rect: finalRect,
                        cornerLength: cornerLength,
                        strokeWidth: strokeWidth,
                        color: glowColor
                    )
                }
                .animation(.easeInOut(duration: 0.3), value: boundingBox)
                .animation(.easeInOut(duration: 0.5), value: isFaceDetected)
                .animation(.easeInOut(duration: 0.3), value: effectiveConfidence)
            }
        }
        .onChange(of: isFaceDetected) { detected in
            updateAnimations()
        }
        .onChange(of: effectiveConfidence) { _ in
            updateAnimations()
        }
        .onAppear {
            startAnimations()
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
    
    // MARK: - Animation Methods
    private func startAnimations() {
        // Initialize animations if needed
    }
    
    private func updateAnimations() {
        if isFaceDetected {
            // Smooth transition to target glow intensity
            withAnimation(.easeInOut(duration: 0.5)) {
                glowIntensity = Double(effectiveConfidence)
            }
        } else {
            // Fade out effects when no face detected
            withAnimation(.easeOut(duration: 0.8)) {
                glowIntensity = 0.0
            }
        }
    }
}

/// Enhanced curved corner brackets with smooth rounded edges
struct CurvedCornerBracketsView: View {
    let rect: CGRect
    let cornerLength: CGFloat
    let strokeWidth: CGFloat
    let color: Color
    
    var body: some View {
        let corners = [
            CGPoint(x: rect.minX, y: rect.minY), // Top-left
            CGPoint(x: rect.maxX, y: rect.minY), // Top-right
            CGPoint(x: rect.minX, y: rect.maxY), // Bottom-left
            CGPoint(x: rect.maxX, y: rect.maxY)  // Bottom-right
        ]
        
        ForEach(Array(corners.enumerated()), id: \.offset) { index, corner in
            CurvedCornerBracket(
                position: corner,
                type: CornerType.allCases[index],
                length: cornerLength,
                strokeWidth: strokeWidth,
                color: color
            )
        }
    }
}

/// Individual curved corner bracket with smooth rounded edges
struct CurvedCornerBracket: View {
    let position: CGPoint
    let type: CornerType
    let length: CGFloat
    let strokeWidth: CGFloat
    let color: Color
    
    var body: some View {
        Path { path in
            let cornerRadius: CGFloat = 8.0 // Smooth corner radius
            
            switch type {
            case .topLeft:
                // Horizontal line (top)
                path.move(to: CGPoint(x: position.x + cornerRadius, y: position.y))
                path.addLine(to: CGPoint(x: position.x + length, y: position.y))
                
                // Curved corner
                path.move(to: CGPoint(x: position.x + cornerRadius, y: position.y))
                path.addQuadCurve(
                    to: CGPoint(x: position.x, y: position.y + cornerRadius),
                    control: position
                )
                
                // Vertical line (left)
                path.addLine(to: CGPoint(x: position.x, y: position.y + length))
                
            case .topRight:
                // Horizontal line (top)
                path.move(to: CGPoint(x: position.x - cornerRadius, y: position.y))
                path.addLine(to: CGPoint(x: position.x - length, y: position.y))
                
                // Curved corner
                path.move(to: CGPoint(x: position.x - cornerRadius, y: position.y))
                path.addQuadCurve(
                    to: CGPoint(x: position.x, y: position.y + cornerRadius),
                    control: position
                )
                
                // Vertical line (right)
                path.addLine(to: CGPoint(x: position.x, y: position.y + length))
                
            case .bottomLeft:
                // Horizontal line (bottom)
                path.move(to: CGPoint(x: position.x + cornerRadius, y: position.y))
                path.addLine(to: CGPoint(x: position.x + length, y: position.y))
                
                // Curved corner
                path.move(to: CGPoint(x: position.x + cornerRadius, y: position.y))
                path.addQuadCurve(
                    to: CGPoint(x: position.x, y: position.y - cornerRadius),
                    control: position
                )
                
                // Vertical line (left)
                path.addLine(to: CGPoint(x: position.x, y: position.y - length))
                
            case .bottomRight:
                // Horizontal line (bottom)
                path.move(to: CGPoint(x: position.x - cornerRadius, y: position.y))
                path.addLine(to: CGPoint(x: position.x - length, y: position.y))
                
                // Curved corner
                path.move(to: CGPoint(x: position.x - cornerRadius, y: position.y))
                path.addQuadCurve(
                    to: CGPoint(x: position.x, y: position.y - cornerRadius),
                    control: position
                )
                
                // Vertical line (right)
                path.addLine(to: CGPoint(x: position.x, y: position.y - length))
            }
        }
        .stroke(color, style: StrokeStyle(lineWidth: strokeWidth, lineCap: .round, lineJoin: .round))
    }
}

enum CornerType: CaseIterable {
    case topLeft, topRight, bottomLeft, bottomRight
} 
