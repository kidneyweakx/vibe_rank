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
    // Force dark appearance for this screen
    @Environment(\.dismiss) private var dismiss
    
    @State private var displayName: String = ""
    @State private var customUserID: String = ""
    @State private var isLoading: Bool = false
    @State private var errorMessage: String?
    @State private var showingError: Bool = false
    
    let initialUserData: InitialUserData
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 32) {
                    // Header Section
                    headerSection
                    
                    // Profile Setup Form
                    profileSetupForm
                    
                    // Continue Button
                    continueButton
                    
                    Spacer(minLength: 50)
                }
                .padding(.horizontal, 24)
                .padding(.top, 20)
            }
            .background(backgroundGradient)
            .navigationTitle("設定個人資料")
            .navigationBarTitleDisplayMode(.large)
            .navigationBarBackButtonHidden(true)
        }
        .onAppear {
            setupInitialData()
        }
        .alert("設定失敗", isPresented: $showingError) {
            Button("確定") { }
        } message: {
            Text(errorMessage ?? "未知錯誤")
        }
        .overlay {
            if isLoading {
                ProfileSetupLoadingOverlay()
            }
        }
    }
    
    // MARK: - Header Section
    
    private var headerSection: some View {
        VStack(spacing: 16) {
            // Profile Image
            AsyncImage(url: URL(string: initialUserData.profileImageURL ?? "")) { image in
                image
                    .resizable()
                    .scaledToFill()
            } placeholder: {
                Image(systemName: "person.circle.fill")
                    .font(.system(size: 80))
                    .foregroundColor(.gray)
            }
            .frame(width: 100, height: 100)
            .clipShape(Circle())
            .overlay(
                Circle()
                    .stroke(Color.white.opacity(0.2), lineWidth: 3)
            )
            
            VStack(spacing: 8) {
                Text("歡迎加入 VibeRanking!")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                
                Text("請完成您的個人資料設定")
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.6))
                    .multilineTextAlignment(.center)
            }
        }
    }
    
    // MARK: - Profile Setup Form
    
    private var profileSetupForm: some View {
        VStack(spacing: 24) {
            // Display Name Field
            VStack(alignment: .leading, spacing: 8) {
                Text("顯示名稱")
                    .font(.headline)
                    .foregroundColor(.white)
                
                TextField("輸入您的顯示名稱", text: $displayName)
                    .textFieldStyle(CustomTextFieldStyle())
                    .autocapitalization(.words)
                    .disableAutocorrection(true)
            }
            
            // Custom User ID Field
            VStack(alignment: .leading, spacing: 8) {
                Text("用戶 ID")
                    .font(.headline)
                    .foregroundColor(.white)
                
                TextField("輸入您的用戶 ID", text: $customUserID)
                    .textFieldStyle(CustomTextFieldStyle())
                    .autocapitalization(.none)
                    .disableAutocorrection(true)
                
                Text("用戶 ID 將用於識別您的帳戶，設定後無法更改")
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.6))
            }
            
        }
        .padding(24)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color(hex: "2D2D2D"))
                .shadow(color: Color.black.opacity(0.3), radius: 10, x: 0, y: 4)
        )
    }
    
    // MARK: - Continue Button
    
    private var continueButton: some View {
        Button(action: completeProfileSetup) {
            HStack {
                Text("完成設定")
                    .font(.system(size: 18, weight: .semibold))
                
                Image(systemName: "arrow.right")
                    .font(.system(size: 16, weight: .semibold))
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .frame(height: 56)
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
        }
        .disabled(isLoading || displayName.isEmpty || customUserID.isEmpty)
        .opacity(displayName.isEmpty || customUserID.isEmpty ? 0.6 : 1.0)
        .padding(.horizontal, 24)
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
                let email = initialUserData.authProvider == "guest" ? "guest@example.com" : initialUserData.email
                let profileData = UserProfileData(
                    customUserID: customUserID,
                    displayName: displayName,
                    email: email,
                    profileImageURL: initialUserData.profileImageURL,
                    authProvider: initialUserData.authProvider,
                    providerUserID: initialUserData.providerUserID
                )
                
                try await authViewModel.completeProfileSetup(profileData)
                
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
                
                Text("設定中...")
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