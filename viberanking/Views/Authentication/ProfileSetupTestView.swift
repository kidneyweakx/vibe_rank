//
//  ProfileSetupTestView.swift
//  viberanking
//
//  Created by Kiro on 2025/08/09.
//

import SwiftUI

/// Test view to demonstrate the profile setup flow
struct ProfileSetupTestView: View {
    @StateObject private var authViewModel = AuthenticationViewModel()
    @StateObject private var themeManager = ThemeManager()
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Profile Setup Test")
                .font(.title)
                .padding()
            
            Button("Simulate New User (404 Error)") {
                simulateNewUserFlow()
            }
            .padding()
            .background(Color.blue)
            .foregroundColor(.white)
            .cornerRadius(10)
            
            Button("Reset to Login") {
                resetToLogin()
            }
            .padding()
            .background(Color.gray)
            .foregroundColor(.white)
            .cornerRadius(10)
            
            Spacer()
            
            // Show the actual authentication flow
            AuthenticationCoordinatorView()
                .environmentObject(authViewModel)
                .environmentObject(themeManager)
        }
        .padding()
    }
    
    private func simulateNewUserFlow() {
        // Simulate the state that would occur when a 404 error happens
        authViewModel.initialUserData = InitialUserData(
            name: "測試新用戶",
            email: "newuser@example.com",
            profileImageURL: nil,
            authProvider: "apple",
            providerUserID: "test_new_user_id"
        )
        authViewModel.needsProfileSetup = true
        authViewModel.authState = .needsProfileSetup
    }
    
    private func resetToLogin() {
        authViewModel.initialUserData = nil
        authViewModel.needsProfileSetup = false
        authViewModel.authState = .signedOut
        authViewModel.user = nil
        authViewModel.isAuthenticated = false
    }
}

// MARK: - Preview

struct ProfileSetupTestView_Previews: PreviewProvider {
    static var previews: some View {
        ProfileSetupTestView()
    }
}