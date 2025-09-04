//
//  OnboardingSetupView.swift
//  viberanking
//
//  Created by AI Assistant on 2025/08/28.
//

import SwiftUI

/// Container for the onboarding questionnaire flow after authentication
struct OnboardingSetupView: View {
    @EnvironmentObject private var authViewModel: AuthenticationViewModel
    @EnvironmentObject private var themeManager: ThemeManager

    let initialUserData: InitialUserData

    @State private var currentStepIndex: Int = 0
    @State private var showProfileSetup: Bool = false
    @State private var answers = OnboardingAnswers()

    private let totalSteps: Int = 7

    var body: some View {
        VStack(spacing: 0) {
            // Progress Bar
            ProgressView(value: progressValue)
                .progressViewStyle(LinearProgressViewStyle())
                .tint(.white)
                .padding(.horizontal, 20)
                .padding(.top, 12)

            // Steps content
            TabView(selection: $currentStepIndex) {
                OnboardingStepIntro(next: goNext)
                    .tag(0)

                OnboardingStepValue(next: goNext, back: goBack)
                    .tag(1)

                OnboardingStepAge(selectAge: { range in answers.ageRange = range; goNext() }, back: goBack)
                    .tag(2)

                OnboardingStepGender(selectGender: { gender in answers.gender = gender; goNext() }, back: goBack)
                    .tag(3)

                OnboardingStepVibeSelection(next: { goNext() }, back: goBack, onSelect: { idx in answers.vibeLevel = idx })
                    .tag(4)

                OnboardingStepTimeInvestment(next: { hours in answers.timeInvestmentHours = hours; goNext() }, back: goBack)
                    .tag(5)

                OnboardingStepNotifications(complete: completeOnboarding, back: goBack)
                    .tag(6)
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
        }
        .background(Color.black.ignoresSafeArea())
        .animation(.easeInOut, value: currentStepIndex)
        .preferredColorScheme(.dark)
        .fullScreenCover(isPresented: $showProfileSetup) {
            UserProfileSetupView(initialUserData: initialUserData, onboardingAnswers: answers)
                .environmentObject(authViewModel)
        }
    }

    private var progressValue: Double {
        guard totalSteps > 0 else { return 0 }
        return Double(currentStepIndex + 1) / Double(totalSteps)
    }

    private func goNext() {
        if currentStepIndex < totalSteps - 1 {
            currentStepIndex += 1
        }
    }

    private func goBack() {
        if currentStepIndex > 0 {
            currentStepIndex -= 1
        }
    }

    private func completeOnboarding() {
        // Present the profile setup form after questionnaire
        showProfileSetup = true
    }
}

#Preview {
    OnboardingSetupView(initialUserData: InitialUserData(name: "Test", email: "t@e.com", profileImageURL: nil, authProvider: "apple", providerUserID: "id"))
        .environmentObject(AuthenticationViewModel())
        .environmentObject(ThemeManager())
}


