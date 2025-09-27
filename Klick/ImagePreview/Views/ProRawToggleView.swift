//
//  ProRawToggleView.swift
//  Klick
//
//  Created by Manase on 27/09/2025.
//

import SwiftUI

enum ImageProcessingMode: String, CaseIterable {
    case standard = "Standard"
    case proRaw = "ProRaw"
    
    var displayName: String {
        return self.rawValue
    }
}

struct ProRawToggleView: View {
    @Binding var selectedMode: ImageProcessingMode
    let onModeChanged: (ImageProcessingMode) -> Void
    
    var body: some View {
        HStack(spacing: 0) {
            ForEach(ImageProcessingMode.allCases, id: \.self) { mode in
                Button(action: {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        selectedMode = mode
                        onModeChanged(mode)
                    }
                }) {
                    Text(mode.displayName)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(selectedMode == mode ? .black : .white)
                        .padding(.vertical, 6)
                        .padding(.horizontal, 12)
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(selectedMode == mode ? .white : .clear)
                        )
                }
            }
        }
        .padding(2)
        .background(
            RoundedRectangle(cornerRadius: 18)
                .fill(.ultraThinMaterial)
                .shadow(color: Color.black.opacity(0.15), radius: 8, x: 0, y: 4)
        )
        .transition(.scale.combined(with: .opacity))
    }
}
