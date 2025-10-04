//
//  OnboardingStepAge.swift
//  viberanking
//
//  Created by AI Assistant on 2025/08/28.
//

import SwiftUI

struct OnboardingStepAge: View {
    let selectAge: (String) -> Void
    let back: () -> Void

    private let ageRanges: [String] = [
        "10 - 17", "18 - 24", "25 - 29", "30 - 34", "35 - 39",
        "40 - 49", "50+"
    ]

    var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    Text("onb.age.title".localized(table: "Onboarding"))
                        .font(.system(size: 28, weight: .bold))
                        .foregroundColor(.white)

                    LazyVStack(spacing: 12) {
                        ForEach(ageRanges, id: \.self) { range in
                            Button(action: { selectAge(range) }) {
                                HStack {
                                    Text(range)
                                        .font(.system(size: 16, weight: .medium))
                                        .foregroundColor(.white)
                                    Spacer()
                                    Image(systemName: "chevron.right")
                                        .font(.system(size: 14, weight: .semibold))
                                        .foregroundColor(.white.opacity(0.7))
                                }
                                .padding(.horizontal, 20)
                                .padding(.vertical, 16)
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(Color.white.opacity(0.08))
                                )
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
                .padding(24)
            }

            // Divider
            Rectangle()
                .fill(Color.white.opacity(0.1))
                .frame(height: 1)

            HStack(spacing: 12) {
                Button(action: back) {
                    Text("common.back".localized(table: "Onboarding"))
                        .font(.system(size: 17, weight: .medium))
                        .frame(maxWidth: .infinity)
                        .padding()
                        .foregroundColor(.white)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.white.opacity(0.25), lineWidth: 1.5)
                        )
                }
            }
            .padding(20)
        }
        .background(Color.black.ignoresSafeArea())
        .preferredColorScheme(.dark)
    }
}

#Preview {
    OnboardingStepAge(selectAge: { _ in }, back: {})
}


