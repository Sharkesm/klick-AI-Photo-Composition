//
//  FilterSelectionStripView.swift
//  Klick
//
//  Created by Manase on 18/09/2025.
//
import SwiftUI

struct FilterSelectionStripView: View {
    let selectedPack: FilterPack
    let selectedFilter: PhotoFilter?
    let filterPreviews: [String: UIImage]
    let originalImage: UIImage?
    let onFilterSelected: (PhotoFilter?) -> Void

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(alignment: .top, spacing: 12) {
                FilterButton(
                    filter: nil,
                    previewImage: originalImage,
                    isSelected: selectedFilter == nil,
                    action: { onFilterSelected(nil) }
                )

                ForEach(FilterManager.shared.filters(for: selectedPack)) { filter in
                    FilterButton(
                        filter: filter,
                        previewImage: filterPreviews[filter.id] ?? originalImage,
                        isSelected: selectedFilter?.id == filter.id,
                        action: { onFilterSelected(filter) }
                    )
                }
            }
            .padding(.vertical, 10)
            .padding(.horizontal, 10)
        }
    }
}
