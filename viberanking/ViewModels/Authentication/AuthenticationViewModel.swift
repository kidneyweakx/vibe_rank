//
//  AuthenticationViewModel.swift
//  viberanking
//
//  Created by Kiro on 2025/07/23.
//

import Foundation
import Combine
import SwiftUI

/// ViewModel that manages authentication state and user interactions
@MainActor
class AuthenticationViewModel: ObservableObject {
    
    // MARK: - Properties
    
    @Published var user: User?
    @Published var isAuthenticated: Bool = false
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    @Published var isGuest: Bool = false
    @Published var authState: AuthState = .signedOut
    @Published var needsProfileSetup: Bool = false
    @Published var initialUserData: InitialUserData?
    
    private let authenticationService: AuthenticationServiceProtocol
    private let userProfileService: UserProfileService
    private var cancellables = Set<AnyCancellable>()

    
    // MARK: - Auth State Enum
    
    enum AuthState: Equatable {
        case signedOut
        case signingIn
        case signedIn
        case needsProfileSetup
        case error(String)
        
        static func == (lhs: AuthState, rhs: AuthState) -> Bool {
            switch (lhs, rhs) {
            case (.signedOut, .signedOut),
                 (.signingIn, .signingIn),
                 (.signedIn, .signedIn),
                 (.needsProfileSetup, .needsProfileSetup):
                return true
            case (.error(let lhsMessage), .error(let rhsMessage)):
                return lhsMessage == rhsMessage
            default:
                return false
            }
        }
    }
    
    // MARK: - Initializer
    
    init(authenticationService: AuthenticationService? = nil) {
        let authService = authenticationService ?? AuthenticationService()
        self.authenticationService = authService
        self.userProfileService = UserProfileService(authenticationService: authService)
        
        // Set initial state from service
        self.user = self.userProfileService.currentUser
        self.isAuthenticated = self.userProfileService.isAuthenticated
        self.authState = self.userProfileService.isAuthenticated ? .signedIn : .signedOut
        
        // Setup bindings and listeners
        setupUserProfileBindings()
    }
    

    
    // MARK: - Setup Methods
    
    private func setupUserProfileBindings() {
        // Bind user profile service state to view model
        userProfileService.$currentUser
            .receive(on: DispatchQueue.main)
            .sink { [weak self] user in
                self?.user = user
                self?.isAuthenticated = user != nil
                self?.authState = user != nil ? .signedIn : .signedOut
            }
            .store(in: &cancellables)
        
        userProfileService.$isLoading
            .receive(on: DispatchQueue.main)
            .sink { [weak self] isLoading in
                self?.isLoading = isLoading
            }
            .store(in: &cancellables)
        
        userProfileService.$error
            .receive(on: DispatchQueue.main)
            .sink { [weak self] error in
                if let error = error {
                    self?.errorMessage = error.errorDescription
                    self?.authState = .error(error.errorDescription ?? "Unknown error")
                }
            }
            .store(in: &cancellables)
    }
    
    private func setupAuthStateListener() {
        // Since we're no longer using Firebase Auth, we'll monitor the authentication service directly
        // The authentication state will be managed through the service's currentUser property
    }
    
    // MARK: - Public Methods
    
    /// Sign in with Google
    func signInWithGoogle() {
        isLoading = true
        errorMessage = nil
        authState = .signingIn
        isGuest = false
        
        Task {
            do {
                let user = try await authenticationService.signInWithGoogle()
                // Route to onboarding immediately after login
                self.user = user
                self.isAuthenticated = false
                self.initialUserData = InitialUserData(
                    name: user.name,
                    email: user.email,
                    profileImageURL: user.profileImageURL,
                    authProvider: "google",
                    providerUserID: user.id
                )
                self.needsProfileSetup = true
                self.authState = .needsProfileSetup
                
                // Log analytics event
                logAuthenticationEvent(provider: "google_onboard", success: true)
            } catch {
                // Check if this is a 404 error indicating new user needs profile setup
                if let appError = error as? AppError,
                   case .serverError(let statusCode) = appError,
                   statusCode == 404 {
                    self.handleNewUserProfileSetup(provider: "google")
                } else {
                    self.errorMessage = (error as? AppError)?.errorDescription ?? error.localizedDescription
                    self.authState = .error(self.errorMessage ?? "Unknown error")
                    
                    // Log analytics event
                    logAuthenticationEvent(provider: "google", success: false)
                }
            }
            isLoading = false
        }
    }
    
    /// Sign in with Apple
    func signInWithApple() {
        isLoading = true
        errorMessage = nil
        authState = .signingIn
        isGuest = false
        
        Task {
            do {
                let user = try await authenticationService.signInWithApple()
                // Route to onboarding immediately after login
                self.user = user
                self.isAuthenticated = false
                self.initialUserData = InitialUserData(
                    name: user.name,
                    email: user.email,
                    profileImageURL: user.profileImageURL,
                    authProvider: "apple",
                    providerUserID: user.id
                )
                self.needsProfileSetup = true
                self.authState = .needsProfileSetup
                
                // Log analytics event
                logAuthenticationEvent(provider: "apple_onboard", success: true)
            } catch {
                // Check if this is a 404 error indicating new user needs profile setup
                if let appError = error as? AppError,
                   case .serverError(let statusCode) = appError,
                   statusCode == 404 {
                    self.handleNewUserProfileSetup(provider: "apple")
                } else {
                    self.errorMessage = (error as? AppError)?.errorDescription ?? error.localizedDescription
                    self.authState = .error(self.errorMessage ?? "Unknown error")
                    
                    // Log analytics event
                    logAuthenticationEvent(provider: "apple", success: false)
                }
            }
            isLoading = false
        }
    }
    
    /// Sign in as guest (for testing and limited functionality)
    func signInAsGuest() {
        isLoading = true
        errorMessage = nil
        authState = .signingIn
        isGuest = true

        // Create a temporary guest user and require onboarding
        let guestUser = User(
            id: "guest_\(UUID().uuidString)",
            name: "guest.user_name".localized,
            email: "guest@example.com"
        )
        self.user = guestUser
        self.isAuthenticated = false
        self.initialUserData = InitialUserData(
            name: "",
            email: guestUser.email,
            profileImageURL: nil,
            authProvider: "guest",
            providerUserID: guestUser.id
        )
        self.needsProfileSetup = true
        self.authState = .needsProfileSetup
        isLoading = false

        // Log analytics event
        logAuthenticationEvent(provider: "guest_onboard", success: true)
    }
    
    /// Sign out the current user
    func signOut() {
        isLoading = true
        
        Task {
            do {
                if !isGuest {
                    try await authenticationService.signOut()
                }
                self.user = nil
                self.isAuthenticated = false
                self.isGuest = false
                self.authState = .signedOut
                
                // Log analytics event
                logAuthenticationEvent(provider: "signout", success: true)
            } catch {
                self.errorMessage = (error as? AppError)?.errorDescription ?? error.localizedDescription
                self.authState = .error(self.errorMessage ?? "Unknown error")
                
                // Log analytics event
                logAuthenticationEvent(provider: "signout", success: false)
            }
            isLoading = false
        }
    }
    
    /// Delete user account and all associated data
    func deleteAccount() {
        isLoading = true
        errorMessage = nil
        
        Task {
            do {
                try await userProfileService.deleteUserAccount()
                self.user = nil
                self.isAuthenticated = false
                self.isGuest = false
                self.authState = .signedOut
                
                // Log analytics event
                logAuthenticationEvent(provider: "account_deletion", success: true)
            } catch {
                self.errorMessage = (error as? AppError)?.errorDescription ?? error.localizedDescription
                self.authState = .error(self.errorMessage ?? "Unknown error")
                
                // Log analytics event
                logAuthenticationEvent(provider: "account_deletion", success: false)
            }
            isLoading = false
        }
    }
    
    /// Refresh user data from Firestore
    func refreshUserData() {
        Task {
            do {
                try await userProfileService.refreshUserData()
                // User data will be updated through bindings
            } catch {
                self.errorMessage = (error as? AppError)?.errorDescription ?? error.localizedDescription
                self.authState = .error(self.errorMessage ?? "Unknown error")
            }
        }
    }

    /// Update name and gender
    func saveProfileEdits(name: String?, gender: Gender?) async throws {
        do {
            try await userProfileService.updateNameAndGender(name: name, gender: gender)
        } catch {
            self.errorMessage = (error as? AppError)?.errorDescription ?? error.localizedDescription
            throw error
        }
    }

    /// Update avatar URL after uploading image
    func saveAvatar(urlString: String) async throws {
        do {
            try await userProfileService.updateAvatar(urlString: urlString)
        } catch {
            self.errorMessage = (error as? AppError)?.errorDescription ?? error.localizedDescription
            throw error
        }
    }

    /// Check if desired user ID is available
    func checkUserIDAvailability(_ desiredId: String) async -> Bool {
        return await userProfileService.isUserIDAvailable(desiredId)
    }

    /// Change user ID (username)
    func changeUserID(to newId: String) async throws {
        do {
            try await userProfileService.changeUserID(to: newId)
        } catch {
            self.errorMessage = (error as? AppError)?.errorDescription ?? error.localizedDescription
            throw error
        }
    }
    
    /// Update user rating progress
    func updateRatingProgress(_ progress: RatingProgress) {
        Task {
            do {
                try await userProfileService.updateRatingProgress(progress)
                // User data will be updated through bindings
            } catch {
                self.errorMessage = (error as? AppError)?.errorDescription ?? error.localizedDescription
            }
        }
    }
    
    // MARK: - Computed Properties
    
    var hasUnlockedUpload: Bool {
        return user?.ratingProgress.hasUnlockedUpload ?? false
    }
    
    var remainingRatingsForUpload: Int {
        return user?.ratingProgress.remainingRatings ?? 20
    }
    
    var ratingProgress: RatingProgress {
        return user?.ratingProgress ?? RatingProgress()
    }
    
    // MARK: - Private Methods
    
    /// Handle new user profile setup flow
    private func handleNewUserProfileSetup(provider: String) {
        // Get the pending user data from the authentication service
        if let userData = authenticationService.getPendingUserData() {
            self.initialUserData = userData
        } else {
            // Fallback if no data is available
            self.initialUserData = InitialUserData(
                name: "New User",
                email: "user@example.com",
                profileImageURL: nil,
                authProvider: provider,
                providerUserID: "temp_id"
            )
        }
        
        self.needsProfileSetup = true
        self.authState = .needsProfileSetup
        
        // Log analytics event
        logAuthenticationEvent(provider: "\(provider)_new_user", success: true)
    }
    
    /// Complete profile setup for new user
    func completeProfileSetup(_ profileData: UserProfileData) async throws {
        isLoading = true
        errorMessage = nil
        
        do {
            let user = try await authenticationService.completeProfileSetup(profileData)
            self.user = user
            self.isAuthenticated = true
            self.needsProfileSetup = false
            self.authState = .signedIn
            self.initialUserData = nil
            
            // Log analytics event
            logAuthenticationEvent(provider: "profile_setup", success: true)
        } catch {
            self.errorMessage = (error as? AppError)?.errorDescription ?? error.localizedDescription
            self.authState = .error(self.errorMessage ?? "Unknown error")
            
            // Log analytics event
            logAuthenticationEvent(provider: "profile_setup", success: false)
            throw error
        }
        
        isLoading = false
    }
    
    /// Log authentication events to analytics
    private func logAuthenticationEvent(provider: String, success: Bool) {
        // In a real app, this would use Firebase Analytics
        print("Authentication event: provider=\(provider), success=\(success)")
    }
}
