import SwiftUI

// MARK: - Composition Overlay View

struct CompositionOverlayView: View {
    let compositionResult: CompositionResult?
    let isVisible: Bool
    
    var body: some View {
        GeometryReader { geometry in
            if isVisible, let result = compositionResult {
                ForEach(Array(result.overlayElements.enumerated()), id: \.offset) { index, element in
                    element.path
                        .stroke(
                            element.color.opacity(element.opacity),
                            lineWidth: element.lineWidth
                        )
                        .animation(.easeInOut(duration: 0.3), value: result.compositionType)
                        .transition(.opacity)
                }
            }
        }
    }
}

// MARK: - Center Framing Overlay View

struct CenterFramingOverlayView: View {
    let frameSize: CGSize
    let isVisible: Bool
    let showSymmetryLine: Bool
    let isSymmetrical: Bool
    
    var body: some View {
        GeometryReader { geometry in
            if isVisible {
                ZStack {
                    // Center crosshair
                    CrosshairView(
                        center: CGPoint(
                            x: geometry.size.width / 2,
                            y: geometry.size.height / 2
                        ),
                        size: 30,
                        color: .white,
                        opacity: 0.8
                    )
                    
                    // Symmetry line (if enabled)
                    if showSymmetryLine {
                        SymmetryLineView(
                            frameSize: geometry.size,
                            isSymmetrical: isSymmetrical
                        )
                    }
                }
                .animation(.easeInOut(duration: 0.3), value: isVisible)
                .transition(.opacity)
            }
        }
    }
}

// MARK: - Symmetry Overlay View

struct SymmetryOverlayView: View {
    let frameSize: CGSize
    let isVisible: Bool
    let symmetryType: SymmetryType
    let isSymmetrical: Bool
    
    enum SymmetryType {
        case vertical
        case horizontal
        case both
    }
    
    var body: some View {
        GeometryReader { geometry in
            if isVisible {
                ZStack {
                    // Vertical symmetry line
                    if symmetryType == .vertical || symmetryType == .both {
                        VerticalSymmetryLine(
                            frameSize: geometry.size,
                            isSymmetrical: isSymmetrical
                        )
                    }
                    
                    // Horizontal symmetry line
                    if symmetryType == .horizontal || symmetryType == .both {
                        HorizontalSymmetryLine(
                            frameSize: geometry.size,
                            isSymmetrical: isSymmetrical
                        )
                    }
                }
                .animation(.easeInOut(duration: 0.3), value: isVisible)
                .transition(.opacity)
            }
        }
    }
}

// MARK: - Supporting Views

private struct CrosshairView: View {
    let center: CGPoint
    let size: CGFloat
    let color: Color
    let opacity: Double
    
    var body: some View {
        Path { path in
            // Horizontal line
            path.move(to: CGPoint(x: center.x - size, y: center.y))
            path.addLine(to: CGPoint(x: center.x + size, y: center.y))
            
            // Vertical line
            path.move(to: CGPoint(x: center.x, y: center.y - size))
            path.addLine(to: CGPoint(x: center.x, y: center.y + size))
        }
        .stroke(color.opacity(opacity), lineWidth: 2)
    }
}

private struct SymmetryLineView: View {
    let frameSize: CGSize
    let isSymmetrical: Bool
    
    var body: some View {
        Path { path in
            let centerX = frameSize.width / 2
            
            // Vertical symmetry line
            path.move(to: CGPoint(x: centerX, y: 0))
            path.addLine(to: CGPoint(x: centerX, y: frameSize.height))
        }
        .stroke(
            (isSymmetrical ? Color.green : Color.yellow).opacity(0.4),
            lineWidth: 1
        )
    }
}

private struct VerticalSymmetryLine: View {
    let frameSize: CGSize
    let isSymmetrical: Bool
    
    var body: some View {
        Path { path in
            let centerX = frameSize.width / 2
            
            // Main vertical line
            path.move(to: CGPoint(x: centerX, y: 0))
            path.addLine(to: CGPoint(x: centerX, y: frameSize.height))
        }
        .stroke(
            (isSymmetrical ? Color.green : Color.yellow).opacity(0.6),
            style: StrokeStyle(lineWidth: 2, dash: [5, 5])
        )
        
        // Add symmetry indicators
        if isSymmetrical {
            HStack {
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        Image(systemName: "arrow.left")
                            .foregroundColor(.green)
                            .font(.caption)
                        Spacer()
                    }
                    Spacer()
                }
                
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        Image(systemName: "arrow.right")
                            .foregroundColor(.green)
                            .font(.caption)
                        Spacer()
                    }
                    Spacer()
                }
            }
            .opacity(0.8)
        }
    }
}

private struct HorizontalSymmetryLine: View {
    let frameSize: CGSize
    let isSymmetrical: Bool
    
    var body: some View {
        Path { path in
            let centerY = frameSize.height / 2
            
            // Main horizontal line
            path.move(to: CGPoint(x: 0, y: centerY))
            path.addLine(to: CGPoint(x: frameSize.width, y: centerY))
        }
        .stroke(
            (isSymmetrical ? Color.green : Color.yellow).opacity(0.6),
            style: StrokeStyle(lineWidth: 2, dash: [5, 5])
        )
        
        // Add symmetry indicators
        if isSymmetrical {
            VStack {
                HStack {
                    Spacer()
                    VStack {
                        Spacer()
                        Image(systemName: "arrow.up")
                            .foregroundColor(.green)
                            .font(.caption)
                        Spacer()
                    }
                    Spacer()
                }
                
                HStack {
                    Spacer()
                    VStack {
                        Spacer()
                        Image(systemName: "arrow.down")
                            .foregroundColor(.green)
                            .font(.caption)
                        Spacer()
                    }
                    Spacer()
                }
            }
            .opacity(0.8)
        }
    }
}

// MARK: - Enhanced Grid Overlay View

struct EnhancedGridOverlayView: View {
    let isVisible: Bool
    let compositionType: CompositionType
    
    var body: some View {
        GeometryReader { geometry in
            if isVisible {
                switch compositionType {
                case .ruleOfThirds:
                    RuleOfThirdsGridView(frameSize: geometry.size)
                case .centerFraming:
                    CenterFramingOverlayView(
                        frameSize: geometry.size,
                        isVisible: true,
                        showSymmetryLine: false,
                        isSymmetrical: false
                    )
                case .symmetry:
                    SymmetryOverlayView(
                        frameSize: geometry.size,
                        isVisible: true,
                        symmetryType: .vertical,
                        isSymmetrical: false
                    )
                }
            }
        }
    }
}

private struct RuleOfThirdsGridView: View {
    let frameSize: CGSize
    
    var body: some View {
        Path { path in
            let width = frameSize.width
            let height = frameSize.height
            
            // Calculate third positions
            let thirdX1 = width / 3
            let thirdX2 = width * 2 / 3
            let thirdY1 = height / 3
            let thirdY2 = height * 2 / 3
            
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
        }
        .stroke(Color.white.opacity(0.6), lineWidth: 1)
    }
}

#Preview {
    ZStack {
        Color.black
        
        CompositionOverlayView(
            compositionResult: CompositionResult(
                isWellComposed: true,
                feedbackMessage: "✅ Balanced symmetry achieved!",
                overlayElements: [],
                score: 0.85,
                compositionType: .centerFraming
            ),
            isVisible: true
        )
    }
} 