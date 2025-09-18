//
//  FilterPackButton.swift
//  Klick
//
//  Created by Manase on 18/09/2025.
//
import SwiftUI

struct FilterPackButton: View {
    let pack: FilterPack
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: {
            withAnimation(.spring) {
                action()
            }
        }) {
            Text(pack.rawValue)
                .font(.subheadline)
                .foregroundColor(isSelected ? .black : .white)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(
                    RoundedRectangle(cornerRadius: 20)
                        .fill(isSelected ? Color.yellow : Color.white.opacity(0.1))
                )
        }
    }
}
