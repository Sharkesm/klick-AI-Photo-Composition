//
//  FilterPackSelectorView.swift
//  Klick
//
//  Created by Manase on 18/09/2025.
//
import SwiftUI

struct FilterPackSelectorView: View {
    @Binding var selectedPack: FilterPack
    let onPackSelected: (FilterPack) -> Void

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(FilterPack.allCases, id: \.self) { pack in
                    FilterPackButton(
                        pack: pack,
                        isSelected: selectedPack == pack,
                        action: { onPackSelected(pack) }
                    )
                }
            }
        }
    }
}
