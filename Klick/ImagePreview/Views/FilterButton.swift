//
//  FilterButton.swift
//  Klick
//
//  Created by Manase on 18/09/2025.
//
import SwiftUI

struct FilterButton: View {
    let filter: PhotoFilter?
    let previewImage: UIImage?
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            ZStack(alignment: .bottom) {
                if let preview = previewImage {
                    Image(uiImage: preview)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 70, height: 80)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                } else {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.gray.opacity(0.3))
                        .frame(width: 70, height: 80)
                        .overlay(
                            Image(systemName: "photo")
                                .foregroundColor(.gray)
                        )
                }
                
                LinearGradient(
                    stops: [
                        .init(color: Color.clear, location: 0),
                        .init(color: Color.black.opacity(0.3), location: 0.3),
                        .init(color: Color.black.opacity(0.7), location: 0.6),
                        .init(color: Color.black, location: 1)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .frame(height: 30)
                .overlay(alignment: .bottom) {
                    Text(filter?.name ?? "Normal")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .scaleEffect(0.92)
                        .foregroundColor(Color.white.opacity(0.85))
                        .lineLimit(1)
                        .frame(maxWidth: .infinity)
                        .multilineTextAlignment(.center)
                        .padding(.bottom, 5)
                }
                .clipShape(RoundedRectangle(cornerRadius: 8))
            }
            .overlay {
                if isSelected {
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.yellow, lineWidth: 3)
                        .frame(width: 70, height: 80)
                }
            }
        }
    }
}
