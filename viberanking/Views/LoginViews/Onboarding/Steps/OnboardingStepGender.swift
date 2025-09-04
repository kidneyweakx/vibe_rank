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
    
    @State private var selectedGender: Gender? = nil

    var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    Text("onb.gender.title".localized(table: "Onboarding"))
                        .font(.system(size: 26, weight: .bold))
                        .foregroundColor(.white)

                    HStack(spacing: 12) {
                        ForEach(Gender.allCases, id: \.self) { gender in
                            GenderSelectionButton(
                                gender: gender, 
                                isSelected: selectedGender == gender, 
                                action: { 
                                    selectedGender = gender
                                    selectGender(gender)
                                }
                            )
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

// MARK: - Gender Selection Button

struct GenderSelectionButton: View {
    let gender: Gender
    let isSelected: Bool
    let action: () -> Void
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: genderIcon)
                    .font(.system(size: 24))
                    .foregroundColor(isSelected ? .white : .secondary)
                
                Text(gender.displayName)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(isSelected ? .white : .secondary)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 80)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(
                        isSelected 
                            ? LinearGradient(
                                gradient: Gradient(colors: [Color.blue, Color.purple]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                            : LinearGradient(
                                gradient: Gradient(colors: [
                                    colorScheme == .dark ? Color(hex: "3A3A3A") : Color(hex: "F0F0F0")
                                ]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                    )
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(
                        isSelected ? Color.clear : Color.gray.opacity(0.3),
                        lineWidth: 1
                    )
            )
        }
        .preferredColorScheme(.dark)
        .buttonStyle(PlainButtonStyle())
    }
    
    private var genderIcon: String {
        switch gender {
        case .male:
            return "person.fill"
        case .female:
            return "person.fill"
        case .other:
            return "person.2.fill"
        }
    }
}

#Preview {
    OnboardingStepGender(selectGender: { _ in }, back: {})
}


