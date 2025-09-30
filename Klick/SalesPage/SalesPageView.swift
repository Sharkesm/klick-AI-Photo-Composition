//
//  SalesPageView.swift
//  Klick
//
//  Created by Manase on 30/09/2025.
//

import SwiftUI

struct SalesPageView: View {
    var body: some View {
        ZStack(alignment: .top) {
            coverImageView
        
            VStack(alignment: .leading, spacing: 30) {
                Spacer()
                headlineView
                subscriptionOfferView
                subscriptionButton
            }
            .padding(.horizontal, 40)
            .padding(.bottom, 28)
            .frame(maxWidth: .infinity)
            
            headerView
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .ignoresSafeArea()
        .background(Color.black)
        
    }
    
    
    private var coverImageView: some View {
        ZStack(alignment: .bottom) {
            Image(.rectangle12)
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(maxWidth: .infinity)
            
            LinearGradient(
                stops: [
                    .init(color: Color.clear, location: 0),
                    .init(color: Color.black.opacity(0.6), location: 0.3),
                    .init(color: Color.black.opacity(0.7), location: 0.6),
                    .init(color: Color.black, location: 1)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .frame(height: 200)
        }
        .frame(height: 260)
    }
    
    private var headerView: some View {
        HStack {
            Spacer()
            
            Button(action: {
                
            }) {
                Image(systemName: "xmark")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.white.opacity(0.7))
                    .frame(width: 32, height: 32)
                    .background(
                        Circle()
                            .fill(Color.white.opacity(0.1))
                    )
            }
        }
        .padding(.horizontal, 28)
        .padding(.top, 40)
    }
    
    private var headlineView: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("KlickPhoto")
                    .font(.system(size: 16, weight: .medium, design: .rounded))
                    .foregroundColor(.white)
                
                VStack {
                    Text("Pro")
                        .font(.system(size: 14, weight: .medium, design: .rounded))
                        .foregroundStyle(Color.white)
                        .padding(.vertical, 2)
                        .padding(.horizontal, 8)
                }
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.white.opacity(0.05))
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color.white.opacity(0.1), lineWidth: 1)
                        )
                )
            }
            
            Text("Go Pro with smart photo capture")
                .font(.system(size: 23, weight: .medium, design: .rounded))
                .foregroundColor(.white)
            
            Text("Unlock all unlimited color profiles, image enhancement, and exlcusive editing updates.")
                .font(.system(size: 16, weight: .light, design: .rounded))
                .foregroundColor(.white)
        }
        .padding(.horizontal, 16)
    }
    
    private var subscriptionOfferView: some View {
        HStack(spacing: 10) {
            SubscriptionOfferButton(content: .init(period: "Monthly", amount: 14.9, savedAmount: 0.0), isHighlighted: false)
            SubscriptionOfferButton(content: .init(period: "Yearly", amount: 99.9, savedAmount: 45), isHighlighted: true)
            SubscriptionOfferButton(content: .init(period: "Lifetime", amount: 249.9, savedAmount: 0.0), isHighlighted: false)
        }
    }
    
    private var subscriptionButton: some View {
        VStack(alignment: .center, spacing: 16) {
            Text("By tapping Continue, you will be charged, your subscription will auto-renew for the same price and package length until you cancel via App store settings, and you agree to our Terms.")
                .foregroundStyle(Color.white)
                .font(.system(size: 11, weight: .light))
                .multilineTextAlignment(.leading)
           
            Button(action: {
                
            }) {
                Text("Continue")
                    .font(.system(size: 18, weight: .semibold, design: .rounded))
                    .foregroundColor(.black)
                    .padding(.horizontal, 40)
                    .padding(.vertical, 16)
                    .frame(maxWidth: .infinity)
                    .background(
                        RoundedRectangle(cornerRadius: 30)
                            .fill(Color.white)
                    )
                    .shadow(color: .white.opacity(0.3), radius: 10, x: 0, y: 5)
            }
            .padding(.bottom, 10)
 
            HStack(spacing: 15) {
                Button {
                    
                } label: {
                    Text("Terms of Use")
                        .foregroundStyle(Color.white)
                        .font(.system(size: 11, weight: .medium))
                }
                
                Text("•")
                    .foregroundStyle(Color.white)
                    .font(.system(size: 11, weight: .medium))
                
                Button {
                    
                } label: {
                    Text("Privacy Policy")
                        .foregroundStyle(Color.white)
                        .font(.system(size: 11, weight: .medium))
                }
                
                Text("•")
                    .foregroundStyle(Color.white)
                    .font(.system(size: 11, weight: .medium))
                
                Button {
                    
                } label: {
                    Text("Restore")
                        .foregroundStyle(Color.white)
                        .font(.system(size: 11, weight: .medium))
                }
            }
        }
        .padding(.horizontal, 16)
    }
}


struct SubscriptionOfferButton: View {
    var content: Content
    var isHighlighted: Bool
    
    struct Content {
        var period: String
        var amount: Double
        var savedAmount: Double
    }
    
    var body: some View {
        Button {
            
        } label: {
            VStack(alignment: .leading) {
                Text(content.period)
                Spacer()
                Text("RM \(String(format: "%.1f", content.amount))")
                    .font(.system(size: 18, weight: .bold))
            }
            .foregroundStyle(Color.white)
            .padding(.vertical, 12)
        }
        .frame(width: 120, height: 120)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white.opacity(0.05))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(isHighlighted ? Color.yellow : Color.white.opacity(0.1), lineWidth: isHighlighted ? 2 : 1)
                )
        )
        .overlay(alignment: .topTrailing) {
            if content.savedAmount > 0 {
                RoundedRectangle(cornerRadius: 6)
                    .fill(Color.yellow)
                    .frame(width: 70, height: 20)
                    .overlay(alignment: .center) {
                        Text("\(String(format: "%.f", content.savedAmount))% OFF")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundStyle(Color.black)
                    }
                    .offset(x: 10, y: -10)
            }
        }
    }
}
#Preview {
    SalesPageView()
}
