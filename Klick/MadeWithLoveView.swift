//
//  MadeWithLoveView.swift
//  Klick
//
//  Created by Manase on 09/08/2025.
//
import SwiftUI

struct MadeWithLoveView: View {
    var location: String? = nil
    var fontSize: CGFloat = 14
    var textColor: Color = .white.opacity(0.8)
    
    @State private var isPulsing = false

    var body: some View {
        HStack(spacing: 4) {
            Text("Made with")
            Text("❤️")
                .scaleEffect(isPulsing ? 1.0 : 0.85)
                .animation(
                    Animation.easeInOut(duration: 0.8)
                        .repeatForever(autoreverses: true),
                    value: isPulsing
                )
            
            if let location = location {
                Text("in \(location)")
            }
        }
        .font(.system(size: fontSize, weight: .medium, design: .default))
        .foregroundColor(textColor)
        .padding(.vertical, 8)
        .frame(maxWidth: .infinity)
        .onAppear {
            isPulsing = true
        }
    }
}
