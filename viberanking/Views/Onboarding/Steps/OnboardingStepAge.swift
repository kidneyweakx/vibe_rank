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
                VStack(alignment: .leading, spacing: 16) {
                    Text("How old are you")
                        .font(.system(size: 24, weight: .bold))

                    LazyVStack(spacing: 12) {
                        ForEach(ageRanges, id: \.self) { range in
                            Button(action: { selectAge(range) }) {
                                HStack {
                                    Text(range)
                                    Spacer()
                                    Image(systemName: "chevron.right")
                                }
                                .padding()
                                .background(RoundedRectangle(cornerRadius: 12).fill(Color.gray.opacity(0.12)))
                            }
                            .buttonStyle(.plain)
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
            }
            .padding(20)
        }
    }
}

#Preview {
    OnboardingStepAge(selectAge: { _ in }, back: {})
}


