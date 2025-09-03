//
//  OnboardingStepVibeSelection.swift
//  viberanking
//
//  Created by AI Assistant on 2025/08/28.
//

import SwiftUI

struct OnboardingStepVibeSelection: View {
    let next: () -> Void
    let back: () -> Void

    private let zhTitle = "你會怎麼形容你現在的 vibe？"
    private let enTitle = "How would you describe your current vibe?"
    private let zhOptions = [
        "帥/美到別人會嫉妒",
        "我還行，但正在摸索怎麼變更好",
        "普普通通，沒什麼特點",
        "常常缺乏自信",
        "完全不知道怎麼打理自己"
    ]
    private let enOptions = [
        "Attractive enough to make people jealous",
        "I’m okay, still figuring out how to optimize",
        "Pretty average, nothing special",
        "Usually not that confident",
        "Totally clueless about my vibe"
    ]

    @State private var selectedIndex: Int? = nil

    var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    Text("onb.vibe.title.zh".localized(table: "Onboarding"))
                        .font(.system(size: 22, weight: .semibold))
                        .foregroundColor(.white)
                    // Show single language only per request

                    VStack(spacing: 12) {
                        ForEach(0..<zhOptions.count, id: \.self) { index in
                            Button(action: { selectedIndex = index }) {
                                VStack(alignment: .leading, spacing: 8) {
                                    Text("onb.vibe.option.zh.\(index + 1)".localized(table: "Onboarding"))
                                        .font(.system(size: 16, weight: .medium))
                                        .foregroundColor(.white)
                                    // English subtitle removed to keep one language
                                }
                                .padding()
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(selectedIndex == index ? Color.blue.opacity(0.2) : Color.white.opacity(0.08))
                                )
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(selectedIndex == index ? Color.blue : Color.white.opacity(0.25), lineWidth: 1)
                                )
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
                .padding(24)
            }

            HStack(spacing: 12) {
                Button(action: back) {
                    Text("common.back".localized(table: "Onboarding"))
                        .frame(maxWidth: .infinity)
                        .padding()
                        .foregroundColor(.white)
                        .background(RoundedRectangle(cornerRadius: 12).stroke(Color.white.opacity(0.25)))
                }

                Button(action: next) {
                    Text("common.next".localized(table: "Onboarding"))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(RoundedRectangle(cornerRadius: 12).fill(LinearGradient(gradient: Gradient(colors: [.blue, .purple]), startPoint: .leading, endPoint: .trailing)))
                }
                .disabled(selectedIndex == nil)
                .opacity(selectedIndex == nil ? 0.6 : 1)
            }
            .padding(20)
        }
        .preferredColorScheme(.dark)
    }
}

#Preview {
    OnboardingStepVibeSelection(next: {}, back: {})
}


