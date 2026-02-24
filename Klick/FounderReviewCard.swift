//
//  FounderReviewCard.swift
//  Klick
//
//  Created by Manase on 24/02/2026.
//

import SwiftUI

// MARK: - Founder Review Card

struct FounderReviewCard: View {
    @ObservedObject var reviewRequestService: ReviewRequestService
    
    private let cardBackground = Color(white: 0.13)
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Hero section — large "about me." with inset photo
            HStack(alignment: .bottom, spacing: 0) {
                VStack(alignment: .leading, spacing: 0) {
                    Text("Meet The")
                        .font(.system(size: 32, weight: .black, design: .rounded))
                        .foregroundColor(.white)
                    
                        Text("FOUNDER")
                            .font(.system(size: 38, weight: .black, design: .rounded))
                            .foregroundColor(.white)
                }
                
                Spacer()
            }
            .padding(.top, 28)
            .padding(.horizontal, 24)
            .padding(.bottom, 24)
            .overlay(alignment: .topTrailing) {
                Image(.founder)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 56, height: 56)
                    .clipShape(Circle())
                    .padding(24)
            }
            
            // Greeting
            Text("nice to meet you!")
                .font(.system(size: 22, weight: .bold, design: .rounded))
                .foregroundColor(.white)
                .padding(.horizontal, 24)
                .padding(.bottom, 16)
            
            // Message body
            Text("Hey, Manase here. I'm passionate about building thoughtful, privacy-first apps.\n\nI built this because I care about creating tools that are simple, beautiful, and actually useful. The goal is to help you make better decisions while taking the photo — not fixing it later.\n\nIf it's made your photos even a little better, I'd genuinely appreciate a review or a message.")
                .font(.system(size: 13.5, weight: .regular))
                .foregroundColor(.white.opacity(0.75))
                .lineSpacing(5)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.horizontal, 24)
                .padding(.bottom, 20)
            
            // Signature
            HStack {
                Spacer()
                Text("— manase")
                    .font(.system(size: 16, weight: .medium, design: .serif))
                    .italic()
                    .foregroundColor(.white.opacity(0.4))
                    .padding(.trailing, 24)
            }
            .padding(.bottom, 20)
            
            // Review button
            Button(action: {
                reviewRequestService.requestReviewManually()
            }) {
                HStack(spacing: 8) {
                    Image(systemName: "star.fill")
                        .font(.system(size: 13, weight: .semibold))
                    Text("Leave a Review")
                        .font(.system(size: 14, weight: .semibold))
                }
                .foregroundColor(.black)
                .frame(maxWidth: .infinity)
                .frame(height: 48)
                .background(
                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                        .fill(Color.yellow)
                )
            }
            .buttonStyle(PlainButtonStyle())
            .padding(.horizontal, 24)
            .padding(.bottom, 24)
        }
        .background(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(cardBackground)
        )
    }
}
