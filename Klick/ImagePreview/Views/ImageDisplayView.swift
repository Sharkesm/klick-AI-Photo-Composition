//
//  ImageDisplayView.swift
//  Klick
//
//  Created by Manase on 18/09/2025.
//
import SwiftUI

struct ImageDisplayView: View {
    let image: UIImage?
    let isProcessing: Bool
    let selectedFilter: PhotoFilter?
    
    var body: some View {
        if let previewImage = image {
            Image(uiImage: previewImage)
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .overlay(
                    Group {
                        // Processing indicator
                        if isProcessing {
                            ZStack {
                                Color.black.opacity(0.3)
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                    .scaleEffect(0.8)
                            }
                        }
                    }
                )
                .animation(.easeInOut(duration: 0.3), value: isProcessing)
        } else {
            Rectangle()
                .fill(Color.gray.opacity(0.3))
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .overlay(
                    Text("No Image")
                        .foregroundColor(.gray)
                )
        }
    }
}
