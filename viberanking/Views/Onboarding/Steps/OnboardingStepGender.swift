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
                VStack(alignment: .leading, spacing: 16) {
                    Text("Select your gender")
                        .font(.system(size: 24, weight: .bold))

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
    OnboardingStepGender(selectGender: { _ in }, back: {})
}


