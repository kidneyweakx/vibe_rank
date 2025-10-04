//
//  UserProfileSetupView.swift
//  viberanking
//
//  Created by Kiro on 2025/08/09.
//

import SwiftUI

/// View for setting up user profile after first-time authentication
struct UserProfileSetupView: View {
    @EnvironmentObject private var authViewModel: AuthenticationViewModel
    @Environment(\.dismiss) private var dismiss

    @State private var displayName: String = ""
    @State private var customUserID: String = ""
    @State private var isLoading: Bool = false
    @State private var errorMessage: String?
    @State private var showingError: Bool = false
    @State private var showExitConfirmation: Bool = false

    let initialUserData: InitialUserData
    var onboardingAnswers: OnboardingAnswers? = nil

    var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(spacing: 32) {
                    // Header Section
                    headerSection
                        .padding(.top, 32)

                    // Profile Setup Form
                    profileSetupForm
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 20)
            }

            // Bottom Button Section
            bottomButtonSection
        }
        .background(Color.black.ignoresSafeArea())
        .preferredColorScheme(.dark)
        .onAppear {
            setupInitialData()
        }
        .alert("profile_setup.error_title".localized(table: "ProfileSetup"), isPresented: $showingError) {
            Button("common.ok".localized) { }
        } message: {
            Text(errorMessage ?? "profile_setup.unknown_error".localized(table: "ProfileSetup"))
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

    // MARK: - Exit Handling

    private func handleExit() {
        // Dismiss the profile setup view first
        dismiss()

        // Sign out to allow re-authentication
        Task {
            await authViewModel.signOut(dueTo: "User cancelled profile setup")
        }
    }
    
    // MARK: - Header Section

    private var headerSection: some View {
        VStack(spacing: 20) {
            // Profile Image
            AsyncImage(url: URL(string: initialUserData.profileImageURL ?? "")) { image in
                image
                    .resizable()
                    .scaledToFill()
            } placeholder: {
                Image(systemName: "person.circle.fill")
                    .font(.system(size: 80))
                    .foregroundColor(.white.opacity(0.3))
            }
            .frame(width: 100, height: 100)
            .clipShape(Circle())
            .overlay(
                Circle()
                    .stroke(
                        LinearGradient(
                            gradient: Gradient(colors: [.blue, .purple]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 3
                    )
            )

            OnboardingSectionTitle(
                title: "profile_setup.welcome_title".localized(table: "ProfileSetup"),
                subtitle: "profile_setup.welcome_subtitle".localized(table: "ProfileSetup")
            )
        }
    }
    
    // MARK: - Profile Setup Form

    private var profileSetupForm: some View {
        VStack(spacing: 24) {
            // Display Name Field
            VStack(alignment: .leading, spacing: 12) {
                OnboardingFieldLabel(
                    text: "profile_setup.display_name".localized(table: "ProfileSetup"),
                    isRequired: true
                )

                OnboardingTextField(
                    placeholder: "profile_setup.display_name_placeholder".localized(table: "ProfileSetup"),
                    text: $displayName,
                    autocapitalization: .words
                )
            }

            // Custom User ID Field
            VStack(alignment: .leading, spacing: 12) {
                OnboardingFieldLabel(
                    text: "profile_setup.user_id".localized(table: "ProfileSetup"),
                    isRequired: true
                )

                OnboardingTextField(
                    placeholder: "profile_setup.user_id_placeholder".localized(table: "ProfileSetup"),
                    text: $customUserID
                )

                OnboardingHintText(
                    text: "profile_setup.user_id_hint".localized(table: "ProfileSetup")
                )
            }
        }
    }
    
    // MARK: - Bottom Button Section

    private var bottomButtonSection: some View {
        VStack(spacing: 0) {
            // Divider
            Rectangle()
                .fill(Color.white.opacity(0.1))
                .frame(height: 1)

            HStack(spacing: 12) {
                // Back/Cancel Button
                Button(action: { showExitConfirmation = true }) {
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
                .disabled(isLoading)

                // Continue Button
                Button(action: completeProfileSetup) {
                    if isLoading {
                        ProgressView()
                            .tint(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                    } else {
                        HStack(spacing: 8) {
                            Text("profile_setup.continue".localized(table: "ProfileSetup"))
                                .font(.system(size: 17, weight: .semibold))

                            Image(systemName: "arrow.right")
                                .font(.system(size: 14, weight: .semibold))
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                    }
                }
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(
                            LinearGradient(
                                gradient: Gradient(colors: [Color.blue, Color.purple]),
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                )
                .disabled(isLoading || displayName.isEmpty || customUserID.isEmpty)
                .opacity(displayName.isEmpty || customUserID.isEmpty ? 0.6 : 1.0)
            }
            .padding(20)
        }
        .background(Color.black)
    }
    
    // MARK: - Background
    
    private var backgroundGradient: some View {
        Color.black.ignoresSafeArea()
    }
    
    // MARK: - Methods
    
    private func setupInitialData() {
        displayName = initialUserData.name
        // For guest users, use a better default name and generate ID from guest ID
        if initialUserData.authProvider == "guest" {
            displayName = "Guest_\(String(initialUserData.providerUserID.suffix(8)))"
            customUserID = generateSuggestedUserID(from: "guest")
        } else {
            customUserID = generateSuggestedUserID(from: initialUserData.name)
        }
    }
    
    private func generateSuggestedUserID(from name: String) -> String {
        let cleanName = name
            .lowercased()
            .replacingOccurrences(of: " ", with: "_")
            .replacingOccurrences(of: "[^a-z0-9_]", with: "", options: .regularExpression)
        
        let randomSuffix = String(Int.random(in: 1000...9999))
        return "\(cleanName)_\(randomSuffix)"
    }
    
    private func completeProfileSetup() {
        isLoading = true
        errorMessage = nil
        
        Task {
            do {
                let email = initialUserData.authProvider == "guest" ? "guest\(String(initialUserData.providerUserID.suffix(8)))@example.com" : initialUserData.email
                if let answers = onboardingAnswers {
                    let payload = OnboardingCompletePayload(
                        account: .init(
                            customUserID: customUserID,
                            displayName: displayName,
                            avatarUrl: initialUserData.profileImageURL
                        ),
                        auth: .init(
                            provider: initialUserData.authProvider,
                            providerUserID: initialUserData.providerUserID,
                            email: email
                        ),
                        demographics: .init(
                            gender: nil,
                            ageRange: answers.ageRange
                        ),
                        questionnaire: .init(
                            vibeLevel: answers.vibeLevel,
                            timeInvestmentHours: answers.timeInvestmentHours,
                            notificationsEnabled: answers.notificationsEnabled
                        ),
                        consent: nil,
                        client: .init(
                            locale: Locale.current.identifier,
                            timezone: TimeZone.current.identifier,
                            appVersion: Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String
                        )
                    )
                    try await authViewModel.completeOnboarding(payload)
                } else {
                    let profileData = UserProfileData(
                        customUserID: customUserID,
                        displayName: displayName,
                        email: email,
                        profileImageURL: initialUserData.profileImageURL,
                        authProvider: initialUserData.authProvider,
                        providerUserID: initialUserData.providerUserID
                    )
                    try await authViewModel.completeProfileSetup(profileData)
                }
                
                // Profile setup completed successfully
                // The AuthenticationViewModel will handle the navigation
                
            } catch {
                self.errorMessage = (error as? AppError)?.errorDescription ?? error.localizedDescription
                self.showingError = true
            }
            
            isLoading = false
        }
    }
}


// MARK: - Custom Text Field Style

struct CustomTextFieldStyle: TextFieldStyle {
    @Environment(\.colorScheme) private var colorScheme
    
    func _body(configuration: TextField<Self._Label>) -> some View {
        configuration
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(colorScheme == .dark ? Color(hex: "3A3A3A") : Color(hex: "F8F9FA"))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.gray.opacity(0.3), lineWidth: 1)
            )
    }
}

// MARK: - Supporting Models

struct InitialUserData {
    let name: String
    let email: String
    let profileImageURL: String?
    let authProvider: String
    let providerUserID: String
}

struct UserProfileData {
    let customUserID: String
    let displayName: String
    let email: String
    let profileImageURL: String?
    let authProvider: String
    let providerUserID: String
}

// MARK: - Profile Setup Loading Overlay

struct ProfileSetupLoadingOverlay: View {
    var body: some View {
        ZStack {
            Color.black.opacity(0.3)
                .ignoresSafeArea()
            
            VStack(spacing: 16) {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    .scaleEffect(1.2)
                
                Text("profile_setup.processing".localized(table: "ProfileSetup"))
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.white)
            }
            .padding(24)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.black.opacity(0.8))
            )
        }
    }
}

// MARK: - Preview

struct UserProfileSetupView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            UserProfileSetupView(
                initialUserData: InitialUserData(
                    name: "測試用戶",
                    email: "test@example.com",
                    profileImageURL: nil,
                    authProvider: "apple",
                    providerUserID: "test_id"
                )
            )
            .environmentObject(AuthenticationViewModel())
            .preferredColorScheme(.light)
            .previewDisplayName("Light Mode")
            
            UserProfileSetupView(
                initialUserData: InitialUserData(
                    name: "測試用戶",
                    email: "test@example.com",
                    profileImageURL: nil,
                    authProvider: "apple",
                    providerUserID: "test_id"
                )
            )
            .environmentObject(AuthenticationViewModel())
            .preferredColorScheme(.dark)
            .previewDisplayName("Dark Mode")
        }
    }
}