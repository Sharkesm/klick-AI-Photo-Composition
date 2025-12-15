//
//  PhotoCounterBadge.swift
//  Klick
//
//  Photo counter badge for free tier users
//

import SwiftUI

struct PhotoCounterBadge: View {
    @ObservedObject var featureManager: FeatureManager
    @Binding var showSalesPage: Bool
    
    var remainingPhotos: Int {
        featureManager.maxFreePhotos - featureManager.capturedPhotoCount
    }
    
    
    var body: some View {
        // Only show for free users
        if !featureManager.isPro {
            Button {
                showSalesPage = true
            } label: {
                Text("\(remainingPhotos)")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)
            }
            .frame(width: 42, height: 42)
            .background(Color.black.opacity(0.5))
            .clipShape(Capsule())
        }
    }
}
