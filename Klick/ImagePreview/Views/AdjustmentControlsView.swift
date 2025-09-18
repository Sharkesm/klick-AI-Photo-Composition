//
//  AdjustmentControlsView.swift
//  Klick
//
//  Created by Manase on 18/09/2025.
//

import SwiftUI

struct AdjustmentControlsView: View {
    @Binding var adjustments: FilterAdjustment
    let onAdjustmentChanged: () -> Void
    let onDebouncedAdjustmentChanged: () -> Void

    var body: some View {
        VStack(spacing: 16) {
            Text("Adjustments")
                .font(.headline)
                .foregroundColor(.white)

            VStack(spacing: 12) {
                // Intensity
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text("Intensity")
                            .font(.subheadline)
                            .foregroundColor(.white)
                        Spacer()
                        Text(String(format: "%.0f%%", adjustments.intensity * 100))
                            .font(.caption)
                            .foregroundColor(.gray)
                    }

                    Slider(value: $adjustments.intensity, in: 0...1, step: 0.01)
                        .accentColor(.white)
                        .onChange(of: adjustments.intensity) { _ in
                            onDebouncedAdjustmentChanged()
                        }
                }

                // Brightness
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text("Brightness")
                            .font(.subheadline)
                            .foregroundColor(.white)
                        Spacer()
                        Text(String(format: "%+.0f", adjustments.brightness * 100))
                            .font(.caption)
                            .foregroundColor(.gray)
                    }

                    Slider(value: $adjustments.brightness, in: -0.2...0.2, step: 0.01)
                        .accentColor(.white)
                        .onChange(of: adjustments.brightness) { _ in
                            onDebouncedAdjustmentChanged()
                        }
                }

                // Warmth
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text("Warmth")
                            .font(.subheadline)
                            .foregroundColor(.white)
                        Spacer()
                        Text(String(format: "%+.0f", adjustments.warmth * 100))
                            .font(.caption)
                            .foregroundColor(.gray)
                    }

                    Slider(value: $adjustments.warmth, in: -0.2...0.2, step: 0.01)
                        .accentColor(.white)
                        .onChange(of: adjustments.warmth) { _ in
                            onDebouncedAdjustmentChanged()
                        }
                }
            }
            .padding(.horizontal, 20)
        }
        .padding(.vertical, 20)
    }
}
