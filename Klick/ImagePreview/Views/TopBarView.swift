//
//  TopBarView.swift
//  Klick
//
//  Created by Manase on 18/09/2025.
//
import SwiftUI

struct TopBarView: View {
    @Binding var showingAdjustments: Bool
    @Binding var showingBlurAdjustment: Bool
    let selectedFilter: PhotoFilter?
    let hasPersonSegmentation: Bool
    let onSave: () -> Void
    let onDiscard: () -> Void
    let onToggleBlurAdjustment: () -> Void

    var body: some View {
        HStack {
            // Dismiss button
            Button(action: onDiscard) {
                Image(systemName: "xmark")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.white)
                    .frame(width: 32, height: 32)
                    .background(.ultraThinMaterial)
                    .clipShape(Circle())
                    .shadow(color: Color.black.opacity(0.25), radius: 10, x: 0, y: 6)
            }

            Spacer()

            // Background Blur Button
            Button(action: {
                withAnimation(.spring) {
                    showingBlurAdjustment.toggle()
                    onToggleBlurAdjustment()
                }
            }) {
                Image(systemName: "person.fill.and.arrow.left.and.arrow.right")
                    .foregroundColor(hasPersonSegmentation ? showingBlurAdjustment ? .yellow : .white : .white.opacity(0.35))
                    .font(.system(size: 16, weight: .medium))
                    .frame(width: 32, height: 32)
                    .background(.ultraThinMaterial)
                    .clipShape(Circle())
                    .shadow(color: Color.black.opacity(0.25), radius: 10, x: 0, y: 6)
            }
            .disabled(!hasPersonSegmentation)

            // Filter Adjustments Button
            Button(action: {
                if showingAdjustments {
                    withAnimation(.easeIn(duration: 0.35)) {
                        showingBlurAdjustment = false
                    }
                }
                
                withAnimation(.spring) {
                    showingAdjustments.toggle()
                }
            }) {
                Image(systemName: "slider.horizontal.3")
                    .foregroundColor(selectedFilter != nil ? .white : .white.opacity(0.35))
                    .font(.system(size: 16, weight: .medium))
                    .frame(width: 32, height: 32)
                    .background(.ultraThinMaterial)
                    .clipShape(Circle())
                    .shadow(color: Color.black.opacity(0.25), radius: 10, x: 0, y: 6)
            }
            .disabled(selectedFilter == nil)
            
            // Save button
            Button(action: onSave) {
                Text("Save")
                    .foregroundColor(.black)
                    .font(.system(size: 14, weight: .semibold))
                    .padding(.vertical, 6)
                    .padding(.horizontal, 16)
                    .background(.yellow)
                    .clipShape(RoundedRectangle(cornerRadius: 22))
            }

        }
        .padding(.vertical)
    }
}
