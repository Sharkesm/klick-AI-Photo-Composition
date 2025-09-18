//
//  PresetButtonsView.swift
//  Klick
//
//  Created by Manase on 18/09/2025.
//
import SwiftUI

struct PresetButtonsView: View {
    let isProcessing: Bool
    let selectedFilter: PhotoFilter?
    let filterAdjustment: FilterAdjustment
    let onApplyPreset: (FilterAdjustment) -> Void
    
    var filterAdjustments: [FilterAdjustment] = [.subtle, .balanced, .strong]
    
    var body: some View {
        HStack(spacing: 10) {
            ForEach(filterAdjustments, id: \.id) { element in
                Button(action: {
                    onApplyPreset(element)
                }) {
                    Text(element.title)
                        .font(.footnote)
                        .foregroundColor((selectedFilter == nil) ? Color.white.opacity(0.8) : element.title == filterAdjustment.title ? .black : .white.opacity(0.8))
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(
                            (selectedFilter == nil) ? Color.white.opacity(0.1) : Color.white.opacity((element.title == filterAdjustment.title) ? 1 : 0.1)
                        )
                        .cornerRadius(12)
                }
                .disabled(isProcessing || selectedFilter == nil)
            }
        }
    }
}
