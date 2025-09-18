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

                    Slider(value: Binding(get: { Double(blurIntensity) }, set: { blurIntensity = Float($0) }), in: 0...20, step: 0.05)
                        .accentColor(.white)
                        .disabled(isProcessing)
                        .onChange(of: blurIntensity) { _ in
                            onDebouncedBlurChanged()
                        }
                }
                
                // Preset buttons for quick blur levels
                HStack(spacing: 16) {
                    ForEach([("None", Float(0)), ("Light", Float(5)), ("Medium", Float(10)), ("Strong", Float(18))], id: \.0) { preset in
                        Button(action: {
                            blurIntensity = preset.1
                            onBlurChanged()
                        }) {
                            Text(preset.0)
                                .font(.footnote)
                                .foregroundColor(abs(blurIntensity - preset.1) < 0.5 ? .black : .white.opacity(0.8))
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(
                                    Color.white.opacity(abs(blurIntensity - preset.1) < 0.5 ? 1 : 0.1)
                                )
                                .cornerRadius(12)
                        }
                        .disabled(isProcessing)
                    }
                }
            }
            .padding(.horizontal, 20)
        }
        .padding(.vertical, 20)
    }
}
