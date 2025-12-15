//
//  StorageFullAlert.swift
//  Klick
//
//  Alert shown when storage limit is reached
//

import SwiftUI

// General upgrade prompt for any context
struct UpgradePromptAlert: View {
    let context: FeatureManager.UpgradeContext
    @Binding var isPresented: Bool
    let onUpgrade: () -> Void
    
    private var title: String {
        switch context {
        case .photoLimit:
            return "Free Photo Limit Reached"
        case .advancedComposition:
            return "Pro Feature"
        case .premiumFilter:
            return "Premium Filter"
        case .filterAdjustments:
            return "Pro Feature"
        case .batchDelete:
            return "Pro Feature"
        case .hideOverlays:
            return "Pro Feature"
        // REMOVED: Watermark feature temporarily disabled
        // case .watermarkRemoval:
        //     return "Remove Watermark"
        case .proCameraQuality:
            return "Pro Camera Quality"
        }
    }
    
    private var message: String {
        switch context {
        case .photoLimit:
            return "You've reached the free tier limit of \(FeatureManager.shared.maxFreePhotos) photos. Upgrade to Pro for unlimited storage."
        case .advancedComposition:
            return "This composition technique is available in Pro. Upgrade to unlock all composition styles."
        case .premiumFilter:
            return "This filter is part of our Pro collection. Upgrade to access all 29 professional filters."
        case .filterAdjustments:
            return "Filter adjustments are available in Pro. Upgrade to fine-tune intensity, brightness, and warmth."
        case .batchDelete:
            return "Batch delete is a Pro feature. Upgrade to delete multiple photos at once."
        case .hideOverlays:
            return "Hide overlays is a Pro feature. Upgrade to toggle overlay visibility."
        // REMOVED: Watermark feature temporarily disabled
        // case .watermarkRemoval:
        //     return "All photos in the free tier include a watermark. Upgrade to Pro to remove watermarks."
        case .proCameraQuality:
            return "Pro camera quality with RAW capture is available in Pro. Upgrade for maximum image quality."
        }
    }
    
    private var icon: String {
        switch context {
        case .photoLimit:
            return "photo.stack.fill"
        case .advancedComposition:
            return "square.grid.3x3"
        case .premiumFilter:
            return "camera.filters"
        case .filterAdjustments:
            return "slider.horizontal.3"
        case .batchDelete:
            return "trash.fill"
        case .hideOverlays:
            return "eye.slash.fill"
        // REMOVED: Watermark feature temporarily disabled
        // case .watermarkRemoval:
        //     return "drop.triangle.fill"
        case .proCameraQuality:
            return "camera.aperture"
        }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            
            // Alert card
            VStack(spacing: 20) {
                // Icon
                Image(systemName: icon)
                    .font(.system(size: 22, weight: .medium))
                    .foregroundColor(.white)
                    .frame(width: 48, height: 48)
                    .background(
                        Circle()
                            .fill(Color.white.opacity(0.1))
                    )
                
                // Title
                Text(title)
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(.primary)
                
                // Message
                Text(message)
                    .font(.system(size: 15))
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 8)
                
                // Upgrade button
                Button(action: {
                    isPresented = false
                    onUpgrade()
                }) {
                    HStack(spacing: 8) {
                        Image(systemName: "crown.fill")
                            .font(.system(size: 16, weight: .semibold))
                        
                        Text("Upgrade to Pro")
                            .font(.system(size: 17, weight: .semibold))
                    }
                    .padding(.horizontal, 32)
                    .padding(.vertical, 16)
                    .foregroundColor(.black)
                    .background(
                        RoundedRectangle(cornerRadius: 25)
                            .fill(Color.yellow)
                    )
                    .shadow(color: .black.opacity(0.2), radius: 10, x: 0, y: 5)
                }
                
                // Dismiss button
                Button(action: {
                    withAnimation {
                        isPresented = false
                    }
                }) {
                    Text("Maybe Later")
                        .font(.system(size: 15, weight: .medium))
                        .foregroundColor(.secondary)
                }
                .padding(.bottom, 8)
            }
            .padding(24)
            .background(.black)
        }
    }
}

#Preview {
    ZStack {
        Color.black.ignoresSafeArea()
        
        UpgradePromptAlert(
            context: .filterAdjustments,
            isPresented: .constant(true),
            onUpgrade: {}
        )
    }
}

