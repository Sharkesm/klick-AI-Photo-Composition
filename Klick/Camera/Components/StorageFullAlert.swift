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
        case .lastFreePhoto:
            return "Last Free Photo!"
        case .advancedComposition:
            return "Pro Feature"
        case .premiumFilter:
            return "Premium Filter"
        case .filterAdjustments:
            return "Pro Feature"
        case .backgroundBlur:
            return "Pro Feature"
        case .portraitPractices:
            return "Pro Feature"
        case .liveFeedback:
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
        case .lastFreePhoto:
            return "This is your last free photo! After this, Live Feedback and premium features will be disabled unless you upgrade to Pro. Continue to capture and enjoy unlimited access with Pro!"
        case .advancedComposition:
            return "This composition technique is available in Pro. Upgrade to unlock all composition styles."
        case .premiumFilter:
            return "This filter is part of our Pro collection. Upgrade to access all 29 professional filters."
        case .filterAdjustments:
            return "Filter adjustments are available in Pro. Upgrade to fine-tune intensity, brightness, and warmth."
        case .backgroundBlur:
            return "Background blur is a Pro feature. Upgrade to create stunning portraits with professional depth-of-field effects."
        case .portraitPractices:
            return "Advanced portrait practices are available in Pro. Upgrade to unlock Expression, Angles, Framing, and Styling guides."
        case .liveFeedback:
            return "Live Feedback messages are available in Pro. Upgrade to get real-time AI coaching and directional guidance while shooting."
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
        case .lastFreePhoto:
            return "exclamationmark.triangle.fill"
        case .advancedComposition:
            return "square.grid.3x3"
        case .premiumFilter:
            return "camera.filters"
        case .filterAdjustments:
            return "slider.horizontal.3"
        case .backgroundBlur:
            return "person.fill.and.arrow.left.and.arrow.right"
        case .portraitPractices:
            return "graduationcap.fill"
        case .liveFeedback:
            return "message.badge.fill"
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
                    .font(.system(size: 24, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                
                // Message
                Text(message)
                    .font(.system(size: 15))
                    .foregroundColor(.white.opacity(0.8))
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
                        .font(.system(size: 16, weight: .medium, design: .rounded))
                        .foregroundColor(.white.opacity(0.6))
                }
                .padding(.bottom, 8)
            }
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

