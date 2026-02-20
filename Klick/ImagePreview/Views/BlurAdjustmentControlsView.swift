//
//  BlurAdjustmentControlsView.swift
//  Klick
//
//  Created by Manase on 18/09/2025.
//
import SwiftUI

struct BlurAdjustmentControlsView: View {
    @Binding var blurIntensity: Float
    let isProcessing: Bool
    let onBlurChanged: () -> Void
    let onDebouncedBlurChanged: () -> Void

    var body: some View {
        VStack(spacing: 16) {
            Text("Background Blur")
                .font(.headline)
                .foregroundColor(.white)

            VStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text("Blur Intensity")
                            .font(.subheadline)
                            .foregroundColor(.white)
                        Spacer()
                        Text(String(format: "%.0f", blurIntensity))
                            .font(.caption)
                            .foregroundColor(.gray)
                    }

                    Slider(value: $blurIntensity, in: 0...20, step: 1.0) {
                        
                    } onEditingChanged: { editing in
                        guard !editing else { return }
                        onDebouncedBlurChanged()
                    }
                    .accentColor(.white)
                    .disabled(isProcessing)
                }
            }
            .padding(.horizontal, 20)
        }
        .padding(.vertical, 20)
    }
}
