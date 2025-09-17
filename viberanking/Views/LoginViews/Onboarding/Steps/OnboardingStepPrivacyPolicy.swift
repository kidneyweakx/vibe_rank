//
//  OnboardingStepPrivacyPolicy.swift
//  viberanking
//
//  Created by AI Assistant on 2025/09/17.
//

import SwiftUI

struct OnboardingStepPrivacyPolicy: View {
    let next: () -> Void

    @State private var isAgreed: Bool = false
    @State private var policyText: String = ""

    var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    Text("onb.privacy.title".localized(table: "Onboarding"))
                        .font(.system(size: 28, weight: .bold))
                        .foregroundColor(.white)

                    Text("onb.privacy.lastUpdated".localized(table: "Onboarding"))
                        .font(.system(size: 14))
                        .foregroundColor(.white.opacity(0.6))

                    Text(policyText)
                        .font(.system(size: 14))
                        .foregroundColor(.white.opacity(0.9))
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(24)
            }

            VStack(spacing: 12) {
                Toggle(isOn: $isAgreed) {
                    Text("onb.privacy.agree".localized(table: "Onboarding"))
                        .foregroundColor(.white)
                        .font(.system(size: 15))
                }
                .toggleStyle(SwitchToggleStyle(tint: .blue))
                .padding(.horizontal, 20)

                Button(action: next) {
                    HStack {
                        Spacer()
                        Text("onb.privacy.cta".localized(table: "Onboarding"))
                            .font(.system(size: 17, weight: .semibold))
                        Spacer()
                    }
                    .foregroundColor(.white)
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 14)
                            .fill(isAgreed ? LinearGradient(gradient: Gradient(colors: [.blue, .purple]), startPoint: .leading, endPoint: .trailing) : LinearGradient(gradient: Gradient(colors: [.gray.opacity(0.6), .gray.opacity(0.6)]), startPoint: .leading, endPoint: .trailing))
                    )
                }
                .disabled(!isAgreed)
                .buttonStyle(.plain)
                .padding(.horizontal, 20)
                .padding(.bottom, 20)
            }
        }
        .background(Color.black.ignoresSafeArea())
        .preferredColorScheme(.dark)
        .onAppear(perform: loadPolicy)
    }

    private func loadPolicy() {
        let languageCode = LocalizationManager.shared.currentLanguage.code

        if let path = Bundle.main.path(forResource: "PrivacyPolicy", ofType: "txt", inDirectory: nil, forLocalization: languageCode) {
            if let text = try? String(contentsOfFile: path) {
                policyText = text
                return
            }
        }

        if let url = Bundle.main.url(forResource: "PrivacyPolicy", withExtension: "txt"),
           let text = try? String(contentsOf: url) {
            policyText = text
            return
        }

        policyText = ""
    }
}

#Preview {
    OnboardingStepPrivacyPolicy(next: {})
        .environmentObject(ThemeManager())
}


