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
    @State private var showExitConfirmation: Bool = false

    private let totalSteps: Int = 8

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
                OnboardingStepPrivacyPolicy(next: goNext)
                    .tag(0)

                OnboardingStepIntro(next: goNext)
                    .tag(1)

                OnboardingStepValue(next: goNext, back: goBack)
                    .tag(2)

                OnboardingStepAge(selectAge: { range in answers.ageRange = range; goNext() }, back: goBack)
                    .tag(3)

                OnboardingStepGender(selectGender: { gender in answers.gender = gender; goNext() }, back: goBack)
                    .tag(4)

                OnboardingStepVibeSelection(next: { goNext() }, back: goBack, onSelect: { idx in answers.vibeLevel = idx })
                    .tag(5)

                OnboardingStepTimeInvestment(next: { hours in answers.timeInvestmentHours = hours; goNext() }, back: goBack)
                    .tag(6)

                OnboardingStepNotifications(
                    complete: completeOnboarding,
                    back: goBack,
                    onToggle: { enabled in
                        answers.notificationsEnabled = enabled
                    }
                )
                    .tag(7)
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
        }
        .background(Color.black.ignoresSafeArea())
        .animation(.spring(response: 0.35, dampingFraction: 0.8), value: currentStepIndex)
        .preferredColorScheme(.dark)
        .fullScreenCover(isPresented: $showProfileSetup) {
            UserProfileSetupView(initialUserData: initialUserData, onboardingAnswers: answers)
                .environmentObject(authViewModel)
        }
        .alert("onb.exit.title".localized(table: "Onboarding"), isPresented: $showExitConfirmation) {
            Button("onb.exit.cancel".localized(table: "Onboarding"), role: .cancel) { }
            Button("onb.exit.confirm".localized(table: "Onboarding"), role: .destructive) {
                handleExit()
            }
        } message: {
            Text("onb.exit.message".localized(table: "Onboarding"))
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
        } else {
            // At first step, show exit confirmation
            showExitConfirmation = true
        }
    }

    private func handleExit() {
        // For guest users, clear the temporary session
        if initialUserData.authProvider == "guest" {
            Task {
                await authViewModel.signOut(dueTo: "User cancelled onboarding")
            }
        } else {
            // For OAuth users, also sign out to allow re-authentication
            Task {
                await authViewModel.signOut(dueTo: "User cancelled onboarding")
            }
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


