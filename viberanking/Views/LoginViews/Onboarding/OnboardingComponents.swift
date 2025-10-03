//
//  OnboardingComponents.swift
//  viberanking
//
//  Unified design system components for onboarding flow
//

import SwiftUI

// MARK: - Onboarding Primary Button

struct OnboardingPrimaryButton: View {
    let title: String
    let action: () -> Void
    var isEnabled: Bool = true
    var isLoading: Bool = false

    @State private var isPressed: Bool = false

    var body: some View {
        Button(action: action) {
            if isLoading {
                ProgressView()
                    .tint(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 56)
            } else {
                HStack(spacing: 12) {
                    Text(title)
                        .font(.system(size: 18, weight: .semibold))

                    Image(systemName: "arrow.right")
                        .font(.system(size: 16, weight: .semibold))
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 56)
            }
        }
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(
                    LinearGradient(
                        gradient: Gradient(colors: [Color.blue, Color.purple]),
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
        )
        .scaleEffect(isPressed ? 0.96 : 1.0)
        .animation(.spring(response: 0.2, dampingFraction: 0.8), value: isPressed)
        .disabled(!isEnabled || isLoading)
        .opacity(isEnabled ? 1.0 : 0.6)
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in
                    if !isPressed && isEnabled {
                        isPressed = true
                    }
                }
                .onEnded { _ in
                    isPressed = false
                }
        )
    }
}

// MARK: - Onboarding Secondary Button

struct OnboardingSecondaryButton: View {
    let title: String
    let action: () -> Void
    var isEnabled: Bool = true

    @State private var isPressed: Bool = false

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 17, weight: .medium))
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 56)
        }
        .background(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.white.opacity(0.3), lineWidth: 1.5)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color.white.opacity(isPressed ? 0.1 : 0))
                )
        )
        .scaleEffect(isPressed ? 0.96 : 1.0)
        .animation(.spring(response: 0.2, dampingFraction: 0.8), value: isPressed)
        .disabled(!isEnabled)
        .opacity(isEnabled ? 1.0 : 0.6)
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in
                    if !isPressed && isEnabled {
                        isPressed = true
                    }
                }
                .onEnded { _ in
                    isPressed = false
                }
        )
    }
}

// MARK: - Onboarding Text Field

struct OnboardingTextField: View {
    let placeholder: String
    @Binding var text: String
    var keyboardType: UIKeyboardType = .default
    var autocapitalization: UITextAutocapitalizationType = .none
    var autocorrection: Bool = false

    var body: some View {
        TextField(placeholder, text: $text)
            .font(.system(size: 17))
            .foregroundColor(.white)
            .autocapitalization(autocapitalization)
            .disableAutocorrection(!autocorrection)
            .keyboardType(keyboardType)
            .padding(.horizontal, 20)
            .padding(.vertical, 18)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.white.opacity(0.08))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(Color.white.opacity(0.2), lineWidth: 1)
            )
    }
}

// MARK: - Onboarding Container

struct OnboardingContainer<Content: View>: View {
    let content: Content
    var showProgress: Bool = false
    var progress: Double = 0

    init(showProgress: Bool = false, progress: Double = 0, @ViewBuilder content: () -> Content) {
        self.showProgress = showProgress
        self.progress = progress
        self.content = content()
    }

    var body: some View {
        VStack(spacing: 0) {
            if showProgress {
                ProgressView(value: progress)
                    .progressViewStyle(LinearProgressViewStyle())
                    .tint(.white)
                    .padding(.horizontal, 20)
                    .padding(.top, 12)
            }

            content
        }
        .background(Color.black.ignoresSafeArea())
        .preferredColorScheme(.dark)
    }
}

// MARK: - Onboarding Section Title

struct OnboardingSectionTitle: View {
    let title: String
    var subtitle: String? = nil

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.system(size: 28, weight: .bold))
                .foregroundColor(.white)

            if let subtitle = subtitle {
                Text(subtitle)
                    .font(.system(size: 16))
                    .foregroundColor(.white.opacity(0.7))
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }
}

// MARK: - Onboarding Button Row

struct OnboardingButtonRow: View {
    var backAction: (() -> Void)? = nil
    var nextAction: (() -> Void)? = nil
    var nextTitle: String = "common.next".localized(table: "Onboarding")
    var isNextEnabled: Bool = true
    var isLoading: Bool = false

    var body: some View {
        HStack(spacing: 12) {
            if let backAction = backAction {
                OnboardingSecondaryButton(
                    title: "common.back".localized(table: "Onboarding"),
                    action: backAction
                )
            }

            if let nextAction = nextAction {
                OnboardingPrimaryButton(
                    title: nextTitle,
                    action: nextAction,
                    isEnabled: isNextEnabled,
                    isLoading: isLoading
                )
            }
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 20)
    }
}

// MARK: - Onboarding Card

struct OnboardingCard<Content: View>: View {
    let content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        VStack(spacing: 0) {
            content
        }
        .padding(24)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.white.opacity(0.05))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(Color.white.opacity(0.1), lineWidth: 1)
        )
    }
}

// MARK: - Onboarding Field Label

struct OnboardingFieldLabel: View {
    let text: String
    var isRequired: Bool = false

    var body: some View {
        HStack(spacing: 4) {
            Text(text)
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.white)

            if isRequired {
                Text("*")
                    .foregroundColor(.red)
            }
        }
    }
}

// MARK: - Onboarding Hint Text

struct OnboardingHintText: View {
    let text: String

    var body: some View {
        Text(text)
            .font(.system(size: 14))
            .foregroundColor(.white.opacity(0.6))
    }
}
