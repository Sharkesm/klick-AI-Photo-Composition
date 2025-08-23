//
//  CompositionStyleControlView.swift
//  Klick
//
//  Created by Manase on 23/08/2025.
//

import SwiftUI

struct CompositionStyleControlView: View {
    
    @State var compositionStyle: CompositionType = .ruleOfThirds
    
    private let impactGenerator = UIImpactFeedbackGenerator(style: .light)
    
    private func backgroundForType(_ type: CompositionType) -> some ShapeStyle {
        compositionStyle == type ? AnyShapeStyle(.yellow) : AnyShapeStyle(.ultraThinMaterial)
    }
    
    var body: some View {
        HStack {
            ForEach(CompositionType.allCases, id: \.self) { type in
                Button {
                    impactGenerator.impactOccurred()
                    impactGenerator.prepare()
                    
                    withAnimation(.spring(response: 0.6, dampingFraction: 0.8, blendDuration: 0)) {
                        compositionStyle = type
                    }
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: type.icon)
                            .font(.system(size: 16))
                            .foregroundColor(compositionStyle == type ? Color.black : Color.white)
                            .scaleEffect(compositionStyle == type ? 1.1 : 1.0)
                        
                        if compositionStyle == type {
                            Text(type.displayName)
                                .font(.subheadline)
                                .foregroundColor(.black)
                                .lineLimit(nil)
                                .multilineTextAlignment(.leading)
                                .transition(.asymmetric(
                                    insertion: .move(edge: .leading).combined(with: .opacity),
                                    removal: .move(edge: .trailing).combined(with: .opacity)
                                ))
                        }
                    }
                    .animation(.spring(response: 0.5, dampingFraction: 0.7), value: compositionStyle)
                }
                .padding(.vertical, 10)
                .padding(.horizontal, 12)
                .background(backgroundForType(type))
                .clipShape(RoundedRectangle(cornerRadius: 100))
                .scaleEffect(compositionStyle == type ? 1.05 : 1.0)
                .animation(.spring(response: 0.4, dampingFraction: 0.8), value: compositionStyle)
            }
        }
    }
}

#Preview {
    CompositionStyleControlView()
}
