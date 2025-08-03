//
//  AddPhotoCanvasView.swift
//  Klick
//
//  Created by Manase on 03/08/2025.
//
import SwiftUI

struct AddPhotoCanvasView: View {
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            ZStack {
                // Dotted rectangle background
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.clear)
                    .frame(minHeight: 120)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(
                                Color.black.opacity(0.4),
                                style: StrokeStyle(
                                    lineWidth: 2,
                                    lineCap: .round,
                                    dash: [8, 6]
                                )
                            )
                    )
                
                // Plus icon in circle
                ZStack {
                    Circle()
                        .fill(Color.black.opacity(0.1))
                        .frame(width: 40, height: 40)
                    
                    Image(systemName: "plus")
                        .font(.system(size: 20, weight: .medium))
                        .foregroundColor(.black.opacity(0.6))
                }
            }
        }
        .buttonStyle(PlainButtonStyle())
    }
}
