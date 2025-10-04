//
//  PaywallView.swift
//  viberanking
//
//  Created by Kiro on 2025/08/09.
//

import SwiftUI

struct PaywallView: View {
    @Binding var isPresented: Bool
    let onPurchased: (() -> Void)?
    @State private var selectedPlan = 0
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.black.ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 32) {
                        // Header
                        VStack(spacing: 16) {
                            Image(systemName: "sparkles")
                                .font(.system(size: 60))
                                .foregroundColor(.purple)
                            
                            Text("paywall.title".localized)
                                .font(.largeTitle)
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                                .multilineTextAlignment(.center)
                            
                            Text("paywall.subtitle".localized)
                                .font(.subheadline)
                                .foregroundColor(.gray)
                                .multilineTextAlignment(.center)
                        }
                        .padding(.top, 40)
                        
                        // Features
                        VStack(spacing: 20) {
                            FeatureRow(
                                icon: "brain.head.profile",
                                title: "paywall.feature.professional_analysis.title".localized,
                                description: "paywall.feature.professional_analysis.description".localized
                            )
                            
                            FeatureRow(
                                icon: "tshirt.fill",
                                title: "paywall.feature.outfit_suggestions.title".localized,
                                description: "paywall.feature.outfit_suggestions.description".localized
                            )
                            
                            FeatureRow(
                                icon: "paintpalette.fill",
                                title: "paywall.feature.color_recommendations.title".localized,
                                description: "paywall.feature.color_recommendations.description".localized
                            )
                            
                            FeatureRow(
                                icon: "chart.line.uptrend.xyaxis",
                                title: "paywall.feature.trend_prediction.title".localized,
                                description: "paywall.feature.trend_prediction.description".localized
                            )
                        }
                        .padding(.horizontal, 20)
                        
                        // Pricing
                        VStack(spacing: 16) {
                            Text("paywall.choose_plan".localized)
                                .font(.headline)
                                .foregroundColor(.white)
                            
                            VStack(spacing: 12) {
                                PricingCard(
                                    title: "paywall.ai_style_suggestions".localized,
                                    price: "$10.00",
                                    period: "paywall.one_time_purchase".localized,
                                    features: [
                                        "paywall.feature.complete_report".localized,
                                        "paywall.feature.personalized_plan".localized,
                                        "paywall.feature.permanent_access".localized
                                    ],
                                    isSelected: selectedPlan == 0,
                                    action: { selectedPlan = 0 }
                                )
                            }
                        }
                        .padding(.horizontal, 20)
                        
                        // Purchase Button
                        Button(action: {
                            // Handle purchase (mock)
                            purchaseAIFeatures()
                        }) {
                            HStack {
                                Image(systemName: "crown.fill")
                                Text("paywall.unlock_now".localized)
                                    .fontWeight(.semibold)
                            }
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 56)
                            .background(
                                LinearGradient(
                                    colors: [.purple, .pink],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .cornerRadius(16)
                        }
                        .padding(.horizontal, 20)
                        
                        // Terms
                        VStack(spacing: 8) {
                            Text("paywall.terms_agreement".localized)
                                .font(.caption)
                                .foregroundColor(.gray)
                                .multilineTextAlignment(.center)
                            
                            HStack(spacing: 16) {
                                Button("paywall.privacy_policy".localized) {
                                    // Handle privacy policy
                                }
                                .font(.caption)
                                .foregroundColor(.blue)
                                
                                Button("paywall.terms_of_service".localized) {
                                    // Handle terms
                                }
                                .font(.caption)
                                .foregroundColor(.blue)
                                
                                Button("paywall.restore_purchase".localized) {
                                    // Handle restore
                                }
                                .font(.caption)
                                .foregroundColor(.blue)
                            }
                        }
                        .padding(.bottom, 40)
                    }
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("paywall.close".localized) {
                        isPresented = false
                    }
                    .foregroundColor(.white)
                }
            }
        }
    }
    
    private func purchaseAIFeatures() {
        // TODO: Implement Apple In-App Purchase (StoreKit)
        // Mock purchase success
        onPurchased?()
        isPresented = false
    }
}

struct FeatureRow: View {
    let icon: String
    let title: String
    let description: String
    
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 24))
                .foregroundColor(.purple)
                .frame(width: 32, height: 32)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                    .foregroundColor(.white)
                
                Text(description)
                    .font(.subheadline)
                    .foregroundColor(.gray)
            }
            
            Spacer()
        }
    }
}

struct PricingCard: View {
    let title: String
    let price: String
    let period: String
    let features: [String]
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(title)
                            .font(.headline)
                            .foregroundColor(.white)
                        
                        Text(period)
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                    
                    Spacer()
                    
                    Text(price)
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.purple)
                }
                
                VStack(alignment: .leading, spacing: 8) {
                    ForEach(features, id: \.self) { feature in
                        HStack {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.green)
                                .font(.caption)
                            
                            Text(feature)
                                .font(.caption)
                                .foregroundColor(.gray)
                        }
                    }
                }
            }
            .padding(20)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.gray.opacity(0.1))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(isSelected ? Color.purple : Color.gray.opacity(0.3), lineWidth: isSelected ? 2 : 1)
                    )
            )
        }
    }
}

#Preview {
    PaywallView(isPresented: .constant(true), onPurchased: {})
}