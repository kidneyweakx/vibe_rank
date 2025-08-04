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
    
    private let authenticationService: AuthenticationServiceProtocol
    private let userProfileService: UserProfileService
    private var cancellables = Set<AnyCancellable>()

    
    // MARK: - Auth State Enum
    
    enum AuthState {
        case signedOut
        case signingIn
        case signedIn
        case error(String)
    }
    
    // MARK: - Initializer
    
    init(authenticationService: AuthenticationServiceProtocol? = nil,
         userProfileService: UserProfileService? = nil) {
        self.authenticationService = authenticationService ?? AuthenticationService()
        self.userProfileService = userProfileService ?? UserProfileService()
        
        // Set initial state from service
        self.user = self.authenticationService.currentUser
        self.isAuthenticated = self.authenticationService.isAuthenticated
        self.authState = self.authenticationService.isAuthenticated ? .signedIn : .signedOut
        
        // Setup bindings and listeners
        setupUserProfileBindings()
        setupAuthStateListener()
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
                self.user = user
                self.isAuthenticated = true
                self.authState = .signedIn
                
                // Log analytics event
                logAuthenticationEvent(provider: "google", success: true)
            } catch {
                self.errorMessage = (error as? AppError)?.errorDescription ?? error.localizedDescription
                self.authState = .error(self.errorMessage ?? "Unknown error")
                
                // Log analytics event
                logAuthenticationEvent(provider: "google", success: false)
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
                self.user = user
                self.isAuthenticated = true
                self.authState = .signedIn
                
                // Log analytics event
                logAuthenticationEvent(provider: "apple", success: true)
            } catch {
                self.errorMessage = (error as? AppError)?.errorDescription ?? error.localizedDescription
                self.authState = .error(self.errorMessage ?? "Unknown error")
                
                // Log analytics event
                logAuthenticationEvent(provider: "apple", success: false)
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
        
        let guestUser = User(
            id: "guest_\(UUID().uuidString)",
            name: "guest.user_name".localized,
            email: "guest@example.com"
        )
        self.user = guestUser
        self.isAuthenticated = true
        self.authState = .signedIn
        isLoading = false
        
        // Log analytics event
        logAuthenticationEvent(provider: "guest", success: true)
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
    
    /// Log authentication events to analytics
    private func logAuthenticationEvent(provider: String, success: Bool) {
        // In a real app, this would use Firebase Analytics
        print("Authentication event: provider=\(provider), success=\(success)")
    }
}
