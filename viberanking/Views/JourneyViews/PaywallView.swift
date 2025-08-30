//
//  PaywallView.swift
//  viberanking
//
//  Created by Kiro on 2025/08/09.
//

import SwiftUI

struct PaywallView: View {
    @Binding var isPresented: Bool
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
                            
                            Text("解鎖 AI 風格建議")
                                .font(.largeTitle)
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                                .multilineTextAlignment(.center)
                            
                            Text("讓 AI 為你量身打造專屬風格方案")
                                .font(.subheadline)
                                .foregroundColor(.gray)
                                .multilineTextAlignment(.center)
                        }
                        .padding(.top, 40)
                        
                        // Features
                        VStack(spacing: 20) {
                            FeatureRow(
                                icon: "brain.head.profile",
                                title: "專業風格分析",
                                description: "深度分析你的風格特點和潛力"
                            )
                            
                            FeatureRow(
                                icon: "tshirt.fill",
                                title: "個人化穿搭建議",
                                description: "根據你的體型和喜好推薦搭配"
                            )
                            
                            FeatureRow(
                                icon: "paintpalette.fill",
                                title: "色彩搭配推薦",
                                description: "找到最適合你的顏色組合"
                            )
                            
                            FeatureRow(
                                icon: "chart.line.uptrend.xyaxis",
                                title: "風格趨勢預測",
                                description: "掌握最新時尚趨勢和發展方向"
                            )
                        }
                        .padding(.horizontal, 20)
                        
                        // Pricing
                        VStack(spacing: 16) {
                            Text("選擇方案")
                                .font(.headline)
                                .foregroundColor(.white)
                            
                            VStack(spacing: 12) {
                                PricingCard(
                                    title: "AI 風格建議",
                                    price: "$10.00",
                                    period: "一次性購買",
                                    features: [
                                        "完整風格分析報告",
                                        "個人化建議方案",
                                        "永久訪問權限"
                                    ],
                                    isSelected: selectedPlan == 0,
                                    action: { selectedPlan = 0 }
                                )
                            }
                        }
                        .padding(.horizontal, 20)
                        
                        // Purchase Button
                        Button(action: {
                            // Handle purchase
                            purchaseAIFeatures()
                        }) {
                            HStack {
                                Image(systemName: "crown.fill")
                                Text("立即解鎖 - $10.00")
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
                            Text("購買即表示同意我們的服務條款")
                                .font(.caption)
                                .foregroundColor(.gray)
                                .multilineTextAlignment(.center)
                            
                            HStack(spacing: 16) {
                                Button("隱私政策") {
                                    // Handle privacy policy
                                }
                                .font(.caption)
                                .foregroundColor(.blue)
                                
                                Button("服務條款") {
                                    // Handle terms
                                }
                                .font(.caption)
                                .foregroundColor(.blue)
                                
                                Button("恢復購買") {
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
                    Button("關閉") {
                        isPresented = false
                    }
                    .foregroundColor(.white)
                }
            }
        }
    }
    
    private func purchaseAIFeatures() {
        // TODO: Implement Apple In-App Purchase
        // For now, just close the paywall
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
    PaywallView(isPresented: .constant(true))
}