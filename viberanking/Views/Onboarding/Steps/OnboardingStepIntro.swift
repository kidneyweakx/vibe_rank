//
//  OnboardingStepIntro.swift
//  viberanking
//
//  Created by AI Assistant on 2025/08/28.
//

import SwiftUI

struct OnboardingStepIntro: View {
    let next: () -> Void

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Backed by Data. Powered by Real People.")
                        .font(.system(size: 28, weight: .bold))
                        .multilineTextAlignment(.leading)

                    englishSubheadline
                        .font(.system(size: 16))
                        .foregroundColor(.secondary)
                        .fixedSize(horizontal: false, vertical: true)

                    Text("Vibe Rank captures your full presence—makeup, hairstyle, outfit, body, and overall energy. Every detail matters, and every day is a chance to level up your vibe.")
                        .font(.system(size: 15))
                        .foregroundColor(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }

                VStack(alignment: .leading, spacing: 12) {
                    Text("數據為基礎．群體為驅動")
                        .font(.system(size: 24, weight: .bold))

                    chineseSubheadline
                        .font(.system(size: 15))
                        .foregroundColor(.secondary)
                        .fixedSize(horizontal: false, vertical: true)

                    Text("Vibe Rank 幫你映照完整的 vibe —— 妝容、髮型、穿搭、體態、狀態。每個細節都重要，而每天，你都能升級更好的自己。")
                        .font(.system(size: 14))
                        .foregroundColor(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Button(action: next) {
                    HStack {
                        Text("👉 Start Your Vibe Journey")
                            .font(.system(size: 18, weight: .semibold))
                        Spacer()
                        Image(systemName: "arrow.right")
                            .font(.system(size: 16, weight: .semibold))
                    }
                    .foregroundColor(.white)
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(LinearGradient(gradient: Gradient(colors: [.blue, .purple]), startPoint: .leading, endPoint: .trailing))
                    )
                }
                .buttonStyle(.plain)

                Button(action: next) {
                    HStack {
                        Text("👉 開始你的 Vibe 升級之旅")
                            .font(.system(size: 16, weight: .medium))
                        Spacer()
                        Image(systemName: "arrow.right")
                    }
                    .foregroundColor(.white)
                    .padding(.vertical, 12)
                }
                .buttonStyle(.plain)
            }
            .padding(24)
        }
    }
}

#if canImport(UIKit)
private extension OnboardingStepIntro {
    var englishSubheadline: Text {
        var s1 = AttributedString("Your vibe isn’t just what one friend thinks. It’s the ")
        var s2 = AttributedString("consensus of the crowd")
        s2.inlinePresentationIntent = .stronglyEmphasized
        var s3 = AttributedString(", refined by ")
        var s4 = AttributedString("AI insights")
        s4.inlinePresentationIntent = .stronglyEmphasized
        var s5 = AttributedString(".")
        let combined = s1 + s2 + s3 + s4 + s5
        return Text(combined)
    }

    var chineseSubheadline: Text {
        var s1 = AttributedString("你的 vibe，不只是朋友一句「好不好看」。而是來自 ")
        var s2 = AttributedString("群體共識")
        s2.inlinePresentationIntent = .stronglyEmphasized
        var s3 = AttributedString("，再經過 ")
        var s4 = AttributedString("AI 洞察")
        s4.inlinePresentationIntent = .stronglyEmphasized
        var s5 = AttributedString("精煉。")
        let combined = s1 + s2 + s3 + s4 + s5
        return Text(combined)
    }
}
#endif

#Preview {
    OnboardingStepIntro(next: {})
        .environmentObject(ThemeManager())
}


