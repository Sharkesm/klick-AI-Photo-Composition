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
    
    // Separate debounce timers for visual updates and tracking
    @State private var visualUpdateTimer: Timer?
    @State private var trackingTimer: Timer?
    private let visualUpdateDelay: TimeInterval = 0.15 // Quick visual feedback
    private let trackingDelay: TimeInterval = 0.8 // Wait longer before tracking

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

                    Slider(value: $adjustments.intensity, in: 0...1, step: 0.01, onEditingChanged: { editing in
                        guard !editing else { return }
                        debouncedTrackingCall()
                        debouncedVisualUpdate()
                    })
                    .accentColor(.white)
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

                    Slider(value: $adjustments.brightness, in: -0.2...0.2, step: 0.01, onEditingChanged: { editing in
                        guard !editing else { return }
                        debouncedTrackingCall()
                        debouncedVisualUpdate()
                    })
                    .accentColor(.white)
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

                    Slider(value: $adjustments.warmth, in: -0.2...0.2, step: 0.01, onEditingChanged: { editing in
                        guard !editing else { return }
                        debouncedTrackingCall()
                        debouncedVisualUpdate()
                    })
                    .accentColor(.white)
                }
            }
            .padding(.horizontal, 20)
        }
        .padding(.vertical, 20)
    }
    
    // MARK: - Debounce Helpers
    
    /// Debounces visual updates to avoid janky scrolling while keeping UI responsive
    private func debouncedVisualUpdate() {
        // Cancel any existing timer
        visualUpdateTimer?.invalidate()
        
        // Create new timer for visual update (short delay for responsiveness)
        visualUpdateTimer = Timer.scheduledTimer(withTimeInterval: visualUpdateDelay, repeats: false) { _ in
            onAdjustmentChanged()
        }
    }
    
    /// Debounces the tracking call to only fire once user stops adjusting
    private func debouncedTrackingCall() {
        // Cancel any existing timer
        trackingTimer?.invalidate()
        
        // Create new timer that will fire after user stops adjusting (longer delay)
        trackingTimer = Timer.scheduledTimer(withTimeInterval: trackingDelay, repeats: false) { _ in
            onDebouncedAdjustmentChanged()
        }
    }
}
