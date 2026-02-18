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
    @ObservedObject var featureManager: FeatureManager
    let onFilterSelected: (PhotoFilter?) -> Void
    let onShowSalesPage: ((PaywallSource) -> Void)? // Optional callback to show sales page with source
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(alignment: .top, spacing: 12) {
                FilterButton(
                    filter: nil,
                    previewImage: originalImage,
                    isSelected: selectedFilter == nil,
                    isLocked: false,
                    action: { onFilterSelected(nil) }
                )

                ForEach(FilterManager.shared.filters(for: selectedPack), id: \.id) { filter in
                    FilterButton(
                        filter: filter,
                        previewImage: filterPreviews[filter.id] ?? originalImage,
                        isSelected: selectedFilter?.id == filter.id,
                        isLocked: !featureManager.canUseFilter(id: filter.id, pack: selectedPack),
                        action: {
                            // If filter is locked, show sales page; otherwise select filter
                            if !featureManager.canUseFilter(id: filter.id, pack: selectedPack) {
                                onShowSalesPage?(.imagePreviewPremiumFilter)
                            } else {
                                onFilterSelected(filter)
                            }
                        }
                    )
                }
            }
            .padding(.vertical, 10)
            .padding(.horizontal, 10)
        }
    }
}
