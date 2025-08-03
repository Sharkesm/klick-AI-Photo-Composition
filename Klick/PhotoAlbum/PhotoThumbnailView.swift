//
//  PhotoThumbnailView.swift
//  Klick
//
//  Created by Manase on 03/08/2025.
//
import SwiftUI

struct PhotoThumbnailView: View {
    let photo: CapturedPhoto
    let isSelectionMode: Bool
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            ZStack {
                Image(uiImage: photo.thumbnail)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(minHeight: 120)
                    .clipped()
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.white.opacity(0.3), lineWidth: 1)
                    )
                
                // Selection circle overlay
                if isSelectionMode {
                    VStack {
                        HStack {
                            ZStack {
                                Circle()
                                    .fill(isSelected ? Color.white : Color.clear)
                                    .frame(width: 18, height: 18)
                                    .overlay(
                                        Circle()
                                            .stroke(Color.white, lineWidth: 2)
                                            .frame(width: 18, height: 18)
                                    )
                                
                                if isSelected {
                                    Image(systemName: "checkmark")
                                        .font(.system(size: 10, weight: .bold))
                                        .foregroundColor(.black)
                                }
                            }
                            .padding(.leading, 8)
                            .padding(.top, 8)
                            
                            Spacer()
                        }
                        
                        Spacer()
                    }
                }
            }
        }
        .buttonStyle(PlainButtonStyle())
    }
}
