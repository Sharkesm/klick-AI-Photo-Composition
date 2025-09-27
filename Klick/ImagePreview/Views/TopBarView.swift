//
//  TopBarView.swift
//  Klick
//
//  Created by Manase on 18/09/2025.
//
import SwiftUI

struct TopBarView: View {
    @Binding var selectedProcessingMode: ImageProcessingMode
    let showProRaw: Bool
    let onProRawToggle: (ImageProcessingMode) -> Void
    
    var body: some View {
        HStack {
            Spacer()

            // ProRaw Toggle at the top
            if showProRaw  {
                ProRawToggleView(
                    selectedMode: $selectedProcessingMode,
                    onModeChanged: onProRawToggle
                )
            } else {
                Text("Preview")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.black)
                    .padding(.vertical, 6)
                    .padding(.horizontal, 12)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(.white)
                    )
            }
            
            Spacer()
        }
        .padding(.vertical)
    }
}
