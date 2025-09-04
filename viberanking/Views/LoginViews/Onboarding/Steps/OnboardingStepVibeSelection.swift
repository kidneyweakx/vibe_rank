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


    @State private var selectedIndex: Int? = nil

    var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    Text("onb.vibe.title".localized(table: "Onboarding"))
                        .font(.system(size: 22, weight: .semibold))
                        .foregroundColor(.white)

                    VStack(spacing: 12) {
                        ForEach(0..<5, id: \.self) { index in
                            Button(action: { selectedIndex = index }) {
                                VStack(alignment: .leading, spacing: 8) {
                                    Text("onb.vibe.option.\(index + 1)".localized(table: "Onboarding"))
                                        .font(.system(size: 16, weight: .medium))
                                        .foregroundColor(.white)
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


