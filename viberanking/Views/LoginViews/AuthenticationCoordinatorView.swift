//
//  AuthenticationCoordinatorView.swift
//  viberanking
//
//  Created by Kiro on 2025/08/09.
//

import SwiftUI

/// Coordinator view that manages the authentication flow including profile setup
struct AuthenticationCoordinatorView: View {
    @EnvironmentObject private var authViewModel: AuthenticationViewModel
    @EnvironmentObject private var themeManager: ThemeManager
    
    var body: some View {
        Group {
            switch authViewModel.authState {
            case .signedOut, .signingIn, .error:
                LoginView()
                    .transition(.opacity)
                
            case .needsProfileSetup:
                if let initialUserData = authViewModel.initialUserData {
                    OnboardingSetupView(initialUserData: initialUserData)
                        .transition(.slide)
                } else {
                    // Fallback to login if no user data is available
                    LoginView()
                        .transition(.opacity)
                }
                
            case .signedIn:
                // This should be handled by the parent view (MainTabView or similar)
                EmptyView()
            }
        }
        .animation(.easeInOut(duration: 0.3), value: authViewModel.authState)
        .preferredColorScheme(.dark)
    }
}

// MARK: - Preview

struct AuthenticationCoordinatorView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            // Signed Out State
            AuthenticationCoordinatorView()
                .environmentObject(AuthCoordinatorPreviewViewModel(state: .signedOut))
                .environmentObject(ThemeManager())
                .previewDisplayName("Signed Out")
            
            // Profile Setup State
            AuthenticationCoordinatorView()
                .environmentObject(AuthCoordinatorPreviewViewModel(state: .needsProfileSetup))
                .environmentObject(ThemeManager())
                .previewDisplayName("Profile Setup")
            
            // Signing In State
            AuthenticationCoordinatorView()
                .environmentObject(AuthCoordinatorPreviewViewModel(state: .signingIn))
                .environmentObject(ThemeManager())
                .previewDisplayName("Signing In")
        }
    }
}

// Preview helper
@MainActor
class AuthCoordinatorPreviewViewModel: AuthenticationViewModel {
    init(state: AuthState) {
        super.init(authenticationService: PreviewAuthenticationService())
        
        self.authState = state
        
        if state == .needsProfileSetup {
            self.initialUserData = InitialUserData(
                name: "測試用戶",
                email: "test@example.com",
                profileImageURL: nil,
                authProvider: "apple",
                providerUserID: "test_id"
            )
            self.needsProfileSetup = true
        }
    }
}