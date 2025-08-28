//
//  OnboardingStepNotifications.swift
//  viberanking
//
//  Created by AI Assistant on 2025/08/28.
//

import SwiftUI

struct OnboardingStepNotifications: View {
    let complete: () -> Void
    let back: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    Text("Turn on notifications, don’t miss your wins")
                        .font(.system(size: 20, weight: .semibold))

                    VStack(alignment: .leading, spacing: 8) {
                        HStack(spacing: 12) {
                            Rectangle().fill(LinearGradient(gradient: Gradient(colors: [.blue, .purple]), startPoint: .leading, endPoint: .trailing)).frame(width: 6)
                            Text("📈 Daily rank: Today your vibe outperformed 80% of women")
                        }
                        HStack(spacing: 12) {
                            Rectangle().fill(LinearGradient(gradient: Gradient(colors: [.blue, .purple]), startPoint: .leading, endPoint: .trailing)).frame(width: 6)
                            Text("🔄 Weekly recap: See how much you’ve grown compared to last week")
                        }
                        HStack(spacing: 12) {
                            Rectangle().fill(LinearGradient(gradient: Gradient(colors: [.blue, .purple]), startPoint: .leading, endPoint: .trailing)).frame(width: 6)
                            Text("✨ Personal insights to level up faster")
                        }
                    }

                    Text("開啟通知，別錯過每一次勝出")
                        .font(.system(size: 18, weight: .semibold))

                    VStack(alignment: .leading, spacing: 8) {
                        HStack(spacing: 12) {
                            Rectangle().fill(LinearGradient(gradient: Gradient(colors: [.blue, .purple]), startPoint: .leading, endPoint: .trailing)).frame(width: 6)
                            Text("📈 每日排名：今天你的 vibe 打敗了 80% 的女生")
                        }
                        HStack(spacing: 12) {
                            Rectangle().fill(LinearGradient(gradient: Gradient(colors: [.blue, .purple]), startPoint: .leading, endPoint: .trailing)).frame(width: 6)
                            Text("🔄 每週回顧：看到自己比上週又成長了多少")
                        }
                        HStack(spacing: 12) {
                            Rectangle().fill(LinearGradient(gradient: Gradient(colors: [.blue, .purple]), startPoint: .leading, endPoint: .trailing)).frame(width: 6)
                            Text("✨ 個人化洞察，讓你更快升級")
                        }
                    }
                }
                .padding(24)
            }

            HStack(spacing: 12) {
                Button(action: back) {
                    Text("Back")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(RoundedRectangle(cornerRadius: 12).stroke(Color.gray.opacity(0.3)))
                }

                Button(action: complete) {
                    Text("Enable Notifications")
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(RoundedRectangle(cornerRadius: 12).fill(LinearGradient(gradient: Gradient(colors: [.blue, .purple]), startPoint: .leading, endPoint: .trailing)))
                }
            }
            .padding(20)
        }
    }
}

#Preview {
    OnboardingStepNotifications(complete: {}, back: {})
}


