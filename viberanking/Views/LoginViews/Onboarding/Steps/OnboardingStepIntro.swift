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
        VStack(spacing: 0) {
            ScrollView {
                VStack(spacing: 32) {
                    VStack(alignment: .leading, spacing: 16) {
                        Text("onb.intro.headline".localized(table: "Onboarding"))
                            .font(.system(size: 32, weight: .bold))
                            .foregroundColor(.white)
                            .multilineTextAlignment(.leading)

                        MarkdownText(text: "onb.intro.subheadline".localized(table: "Onboarding"))
                            .font(.system(size: 18))
                            .foregroundColor(.white.opacity(0.85))
                            .fixedSize(horizontal: false, vertical: true)

                        Text("onb.intro.description".localized(table: "Onboarding"))
                            .font(.system(size: 16))
                            .foregroundColor(.white.opacity(0.75))
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
                .padding(24)
            }

            // Divider
            Rectangle()
                .fill(Color.white.opacity(0.1))
                .frame(height: 1)

            HStack(spacing: 12) {
                Button(action: next) {
                    HStack(spacing: 8) {
                        Text("onb.intro.cta".localized(table: "Onboarding"))
                            .font(.system(size: 17, weight: .semibold))
                        Spacer()
                        Image(systemName: "arrow.right")
                            .font(.system(size: 14, weight: .semibold))
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(
                                LinearGradient(
                                    gradient: Gradient(colors: [.blue, .purple]),
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                    )
                }
                .buttonStyle(.plain)
            }
            .padding(20)
        }
        .background(Color.black.ignoresSafeArea())
        .preferredColorScheme(.dark)
    }
}

// i18n: All strings come from Onboarding.strings per locale.

// MARK: - MarkdownText View

struct MarkdownText: View {
    let text: String
    @State private var attributedString: AttributedString = AttributedString()
    
    var body: some View {
        Text(attributedString)
            .onAppear {
                parseMarkdown()
            }
    }
    
    private func parseMarkdown() {
        var result = AttributedString(text)
        
        // Find and replace **text** with bold formatting
        while let range = result.range(of: "\\*\\*(.*?)\\*\\*", options: .regularExpression) {
            let boldText = String(result[range].characters)
            let cleanText = boldText.replacingOccurrences(of: "**", with: "")
            
            var boldAttributedString = AttributedString(cleanText)
            boldAttributedString.font = .system(size: 18, weight: .bold)
            
            result.replaceSubrange(range, with: boldAttributedString)
        }
        
        attributedString = result
    }
}

#Preview {
    OnboardingStepIntro(next: {})
        .environmentObject(ThemeManager())
}



