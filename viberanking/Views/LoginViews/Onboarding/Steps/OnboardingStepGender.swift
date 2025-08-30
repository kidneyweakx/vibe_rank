//
//  OnboardingStepGender.swift
//  viberanking
//
//  Created by AI Assistant on 2025/08/28.
//

import SwiftUI

struct OnboardingStepGender: View {
    let selectGender: (Gender) -> Void
    let back: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    Text("onb.gender.title".localized(table: "Onboarding"))
                        .font(.system(size: 26, weight: .bold))
                        .foregroundColor(.white)

                    HStack(spacing: 12) {
                        ForEach(Gender.allCases, id: \.self) { gender in
                            GenderSelectionButton(gender: gender, isSelected: false, action: { selectGender(gender) })
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
            }
            .padding(20)
        }
        .preferredColorScheme(.dark)
    }
}

#Preview {
    OnboardingStepGender(selectGender: { _ in }, back: {})
}


