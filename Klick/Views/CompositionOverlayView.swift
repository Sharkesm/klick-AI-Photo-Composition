//
//  CompositionOverlayView.swift
//  Klick
//
//  Created by AI Assistant on 12/07/2025.
//

import SwiftUI

struct CompositionOverlayView: View {
    let imageSize: CGSize
    let analysisResult: CompositionAnalysisResult
    @State private var showOverlay = false
    @State private var animateGrid = false
    @State private var animateBoundingBoxes = false
    @State private var animateContours = false
    @State private var showBlackWhite = false
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Always show rule of thirds grid
                if showOverlay {
                    RuleOfThirdsGridView(
                        containerSize: geometry.size,
                        imageSize: imageSize
                    )
                    .opacity(animateGrid ? 0.8 : 0)
                    .animation(.easeInOut(duration: 0.8), value: animateGrid)
                    .onAppear {
                        animateGrid = true
                    }
                }
                
                // Prioritize and conditionally render elements
                let prioritizedElements = analysisResult.overlayElements.compactMap { element -> OverlayElement? in
                    switch element {
                    case .gridLine: // Keep all grid lines
                        return element
                    default:
                        return nil // Skip everything else
                    }
                }

                // Render prioritized elements
                ForEach(prioritizedElements.indices, id: \.self) { index in
                    drawOverlayElement(
                        prioritizedElements[index],
                        in: geometry.size,
                        originalSize: imageSize
                    )
                    .animation(
                        .spring(response: 0.6, dampingFraction: 0.8)
                            .delay(Double(index) * 0.05),
                        value: showOverlay
                    )
                }
                
                // Composition summary and controls
                VStack {
                    HStack {
                        // Composition detection summary
                        if showOverlay && !analysisResult.detectedRules.isEmpty {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Detected:")
                                    .font(.caption)
                                    .foregroundColor(.white)
                                    .fontWeight(.semibold)
                                
                                ForEach(analysisResult.detectedRules.prefix(3), id: \.self) { rule in
                                    HStack {
                                        Image(systemName: rule.icon)
                                            .font(.caption2)
                                            .foregroundColor(.yellow)
                                        Text(rule.rawValue)
                                            .font(.caption2)
                                            .foregroundColor(.white)
                                    }
                                }
                            }
                            .padding(8)
                            .background(Color.black.opacity(0.7))
                            .cornerRadius(8)
                        }
                        
                        Spacer()
                    }
                    .padding()
                    .padding(.top, 150)
                    Spacer()
                }
            }
            .onAppear {
                withAnimation(.easeInOut(duration: 0.5)) {
                    showOverlay = true
                }
            }
        }
    }
    
    @ViewBuilder
    private func drawOverlayElement(_ element: OverlayElement, in size: CGSize, originalSize: CGSize) -> some View {
        let scaleX = size.width / originalSize.width
        let scaleY = size.height / originalSize.height
        
        switch element {
        case .gridLine(let start, let end, let type):
            Path { path in
                path.move(to: CGPoint(x: start.x * scaleX, y: start.y * scaleY))
                path.addLine(to: CGPoint(x: end.x * scaleX, y: end.y * scaleY))
            }
            .stroke(gridLineColor(for: type), lineWidth: gridLineWidth(for: type))
            .opacity(animateGrid ? 0.8 : 0)
            .animation(.easeInOut(duration: 0.8), value: animateGrid)
            .onAppear {
                animateGrid = true
            }
            
        case .boundingBox(let rect, let label, let color):
            ZStack(alignment: .topLeading) {
                Rectangle()
                    .stroke(Color(color), lineWidth: 2)
                    .frame(
                        width: rect.width * scaleX,
                        height: rect.height * scaleY
                    )
                    .position(
                        x: (rect.minX + rect.width/2) * scaleX,
                        y: (rect.minY + rect.height/2) * scaleY
                    )
                
                Text(label)
                    .font(.caption)
                    .foregroundColor(.white)
                    .padding(4)
                    .background(Color(color).opacity(0.8))
                    .cornerRadius(4)
                    .position(x: rect.minX * scaleX, y: rect.minY * scaleY)
            }
            .opacity(animateBoundingBoxes ? 1 : 0)
            .scaleEffect(animateBoundingBoxes ? 1 : 0.8)
            .animation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.3), value: animateBoundingBoxes)
            .onAppear {
                animateBoundingBoxes = true
            }
            
        case .contourPath(let points, let label):
            Path { path in
                guard let first = points.first else { return }
                path.move(to: CGPoint(x: first.x * scaleX, y: first.y * scaleY))
                for point in points.dropFirst() {
                    path.addLine(to: CGPoint(x: point.x * scaleX, y: point.y * scaleY))
                }
            }
            .stroke(Color.green, lineWidth: 2)
            .opacity(animateContours ? 0.7 : 0)
            .animation(.easeInOut(duration: 1.0).delay(0.5), value: animateContours)
            .onAppear {
                animateContours = true
            }
            
        case .hotspot(let center, let radius, let label):
            ZStack {
                Circle()
                    .fill(Color.yellow.opacity(0.3))
                    .frame(width: radius * 2, height: radius * 2)
                    .overlay(
                        Circle()
                            .stroke(Color.yellow, lineWidth: 2)
                    )
                    .position(x: center.x * scaleX, y: center.y * scaleY)
                
                if !label.isEmpty {
                    Text(label)
                        .font(.caption2)
                        .foregroundColor(.white)
                        .padding(4)
                        .background(Color.black.opacity(0.7))
                        .cornerRadius(4)
                        .position(x: center.x * scaleX, y: (center.y * scaleY) - radius - 20)
                }
            }
            .opacity(showOverlay ? 1 : 0)
            .scaleEffect(showOverlay ? 1 : 0.5)
            .animation(.spring(response: 0.5, dampingFraction: 0.7).delay(0.2), value: showOverlay)
            
        case .arrow(let start, let end, let label):
            ZStack {
                ArrowShape(start: CGPoint(x: start.x * scaleX, y: start.y * scaleY),
                          end: CGPoint(x: end.x * scaleX, y: end.y * scaleY))
                    .stroke(Color.orange, lineWidth: 3)
                
                if !label.isEmpty {
                    Text(label)
                        .font(.caption)
                        .foregroundColor(.white)
                        .padding(4)
                        .background(Color.orange.opacity(0.8))
                        .cornerRadius(4)
                        .position(
                            x: ((start.x + end.x) / 2) * scaleX,
                            y: ((start.y + end.y) / 2) * scaleY
                        )
                }
            }
            .opacity(showOverlay ? 0.8 : 0)
            .animation(.easeInOut(duration: 0.8).delay(0.4), value: showOverlay)
        }
    }
    
    private func gridLineColor(for type: OverlayElement.GridType) -> Color {
        switch type {
        case .ruleOfThirds:
            return Color.white.opacity(0.8)
        case .goldenRatio:
            return Color.yellow.opacity(0.7)
        case .diagonal:
            return Color.purple.opacity(0.7)
        }
    }
    
    private func gridLineWidth(for type: OverlayElement.GridType) -> CGFloat {
        switch type {
        case .ruleOfThirds:
            return 1.5
        case .goldenRatio:
            return 2.0
        case .diagonal:
            return 1.0
        }
    }
}

// MARK: - Arrow Shape
struct ArrowShape: Shape {
    let start: CGPoint
    let end: CGPoint
    
    func path(in rect: CGRect) -> Path {
        var path = Path()
        
        // Draw line
        path.move(to: start)
        path.addLine(to: end)
        
        // Calculate arrow head
        let angle = atan2(end.y - start.y, end.x - start.x)
        let arrowLength: CGFloat = 15
        let arrowAngle: CGFloat = .pi / 6
        
        let arrowPoint1 = CGPoint(
            x: end.x - arrowLength * cos(angle - arrowAngle),
            y: end.y - arrowLength * sin(angle - arrowAngle)
        )
        
        let arrowPoint2 = CGPoint(
            x: end.x - arrowLength * cos(angle + arrowAngle),
            y: end.y - arrowLength * sin(angle + arrowAngle)
        )
        
        // Draw arrow head
        path.move(to: arrowPoint1)
        path.addLine(to: end)
        path.addLine(to: arrowPoint2)
        
        return path
    }
}

// MARK: - Rule of Thirds Grid View
struct RuleOfThirdsGridView: View {
    let containerSize: CGSize
    let imageSize: CGSize
    
    var body: some View {
        let scaleX = containerSize.width / imageSize.width
        let scaleY = containerSize.height / imageSize.height
        let scale = min(scaleX, scaleY)
        
        let displayWidth = imageSize.width * scale
        let displayHeight = imageSize.height * scale
        
        let offsetX = (containerSize.width - displayWidth) / 2
        let offsetY = (containerSize.height - displayHeight) / 2
        
        let thirdX = displayWidth / 3
        let thirdY = displayHeight / 3
        
        Path { path in
            // Vertical lines
            path.move(to: CGPoint(x: offsetX + thirdX, y: offsetY))
            path.addLine(to: CGPoint(x: offsetX + thirdX, y: offsetY + displayHeight))
            path.move(to: CGPoint(x: offsetX + thirdX * 2, y: offsetY))
            path.addLine(to: CGPoint(x: offsetX + thirdX * 2, y: offsetY + displayHeight))
            
            // Horizontal lines
            path.move(to: CGPoint(x: offsetX, y: offsetY + thirdY))
            path.addLine(to: CGPoint(x: offsetX + displayWidth, y: offsetY + thirdY))
            path.move(to: CGPoint(x: offsetX, y: offsetY + thirdY * 2))
            path.addLine(to: CGPoint(x: offsetX + displayWidth, y: offsetY + thirdY * 2))
        }
        .stroke(Color.white.opacity(0.8), lineWidth: 2)
    }
}

// MARK: - Black & White Filter View Modifier
struct BlackWhiteModifier: ViewModifier {
    let isActive: Bool
    
    func body(content: Content) -> some View {
        if isActive {
            content
                .colorMultiply(.gray)
                .contrast(1.2)
        } else {
            content
        }
    }
} 
