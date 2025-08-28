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
            VStack(spacing: 28) {
                VStack(alignment: .leading, spacing: 14) {
                    Text("onb.intro.headline".localized(table: "Onboarding"))
                        .font(.system(size: 30, weight: .bold))
                        .foregroundColor(.white)
                        .multilineTextAlignment(.leading)

                    Text("onb.intro.subheadline".localized(table: "Onboarding"))
                        .font(.system(size: 18))
                        .foregroundColor(.white.opacity(0.85))
                        .fixedSize(horizontal: false, vertical: true)

                    Text("onb.intro.description".localized(table: "Onboarding"))
                        .font(.system(size: 16))
                        .foregroundColor(.white.opacity(0.75))
                        .fixedSize(horizontal: false, vertical: true)
                }

                Button(action: next) {
                    HStack {
                        Text("onb.intro.cta".localized(table: "Onboarding"))
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
            }
            .padding(24)
        }
        .background(Color.black)
        .preferredColorScheme(.dark)
    }
}

// i18n: All strings come from Onboarding.strings per locale.

#Preview {
    OnboardingStepIntro(next: {})
        .environmentObject(ThemeManager())
}



