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
    
    private let authenticationService: AuthenticationService
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
        
        // 檢查已保存的登入狀態
        checkSavedAuthenticationState()
    }
    
    /// 檢查已保存的認證狀態
    private func checkSavedAuthenticationState() {
        Task {
            // 等待 AuthenticationService 完成自動登入檢查
            try? await Task.sleep(nanoseconds: 500_000_000) // 0.5秒延遲
            
            // 檢查是否有用戶已經登入
            if let currentUser = authenticationService.currentUser {
                self.user = currentUser
                self.isAuthenticated = true
                self.authState = .signedIn
                print("✅ 自動登入成功: \(currentUser.name)")
            }
        }
    }
    

    
    // MARK: - Setup Methods
    
    private func setupUserProfileBindings() {
        // Bind user profile service state to view model
        userProfileService.$currentUser
            .receive(on: DispatchQueue.main)
            .sink { [weak self] user in
                self?.user = user
                self?.isAuthenticated = user != nil
                
                // Don't override onboarding state - only set signedIn if not in onboarding flow
                if user != nil && self?.authState != .needsProfileSetup {
                    self?.authState = .signedIn
                } else if user == nil && self?.authState != .needsProfileSetup {
                    self?.authState = .signedOut
                }
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
                self.initialUserData = nil
                self.needsProfileSetup = false
                self.authState = .signedIn
                self.isGuest = false

                resetSpotlightState()
                logAuthenticationEvent(provider: "google", success: true)
            } catch let appError as AppError {
                switch appError {
                case .needsOnboarding:
                    self.handleNewUserProfileSetup(provider: "google")
                    logAuthenticationEvent(provider: "google_onboard", success: true)
                case .serverError(let statusCode) where statusCode == 404:
                    self.handleNewUserProfileSetup(provider: "google")
                    logAuthenticationEvent(provider: "google_onboard", success: true)
                default:
                    self.errorMessage = appError.errorDescription ?? appError.localizedDescription
                    self.authState = .error(self.errorMessage ?? "Unknown error")
                    logAuthenticationEvent(provider: "google", success: false)
                }
            } catch {
                self.errorMessage = error.localizedDescription
                self.authState = .error(self.errorMessage ?? "Unknown error")
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
                self.initialUserData = nil
                self.needsProfileSetup = false
                self.authState = .signedIn
                self.isGuest = false

                resetSpotlightState()
                logAuthenticationEvent(provider: "apple", success: true)
            } catch let appError as AppError {
                switch appError {
                case .needsOnboarding:
                    self.handleNewUserProfileSetup(provider: "apple")
                    logAuthenticationEvent(provider: "apple_onboard", success: true)
                case .serverError(let statusCode) where statusCode == 404:
                    self.handleNewUserProfileSetup(provider: "apple")
                    logAuthenticationEvent(provider: "apple_onboard", success: true)
                default:
                    self.errorMessage = appError.errorDescription ?? appError.localizedDescription
                    self.authState = .error(self.errorMessage ?? "Unknown error")
                    logAuthenticationEvent(provider: "apple", success: false)
                }
            } catch {
                self.errorMessage = error.localizedDescription
                self.authState = .error(self.errorMessage ?? "Unknown error")
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

        Task {
            do {
                let guestUser = try await authenticationService.signInAsGuest()
                self.user = guestUser
                self.isAuthenticated = true
                self.initialUserData = nil
                self.needsProfileSetup = false
                self.authState = .signedIn
                self.isGuest = true

                resetSpotlightState()
                logAuthenticationEvent(provider: "guest", success: true)
            } catch let appError as AppError {
                switch appError {
                case .needsOnboarding:
                    self.handleNewUserProfileSetup(provider: "guest")
                    self.isGuest = true
                    logAuthenticationEvent(provider: "guest_onboard", success: true)
                default:
                    self.errorMessage = appError.errorDescription ?? appError.localizedDescription
                    self.authState = .error(self.errorMessage ?? "Unknown error")
                    logAuthenticationEvent(provider: "guest", success: false)
                }
            } catch {
                self.errorMessage = error.localizedDescription
                self.authState = .error(self.errorMessage ?? "Unknown error")
                logAuthenticationEvent(provider: "guest", success: false)
            }
            
            isLoading = false
        }
    }
    
    /// Sign out the current user
    func signOut(dueTo reason: String? = nil) {
        isLoading = true

        if let reason = reason {
            print("🔐 Signing out due to: \(reason)")
        }

        Task {
            do {
                if !isGuest {
                    try await authenticationService.signOut()
                }

                await MainActor.run {
                    self.user = nil
                    self.isAuthenticated = false
                    self.isGuest = false
                    self.authState = .signedOut

                    // Set error message if signed out due to session expiry
                    if reason?.contains("expired") == true || reason?.contains("401") == true {
                        self.errorMessage = "Your session has expired. Please sign in again."
                    }
                }

                // Log analytics event
                logAuthenticationEvent(provider: "signout", success: true)
            } catch {
                await MainActor.run {
                    self.errorMessage = (error as? AppError)?.errorDescription ?? error.localizedDescription
                    self.authState = .error(self.errorMessage ?? "Unknown error")
                }

                // Log analytics event
                logAuthenticationEvent(provider: "signout", success: false)
            }

            await MainActor.run {
                isLoading = false
            }
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
        self.user = nil
        self.isAuthenticated = false
        self.isGuest = provider == "guest"
        
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
            
            // Reset spotlight state for new users
            resetSpotlightState()
            
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
    
    /// Complete onboarding with consolidated API
    func completeOnboarding(_ payload: OnboardingCompletePayload) async throws {
        isLoading = true
        errorMessage = nil
        do {
            let user = try await authenticationService.completeOnboarding(payload)
            self.user = user
            self.isAuthenticated = true
            self.needsProfileSetup = false
            self.authState = .signedIn
            self.initialUserData = nil
            resetSpotlightState()
            logAuthenticationEvent(provider: "onboarding_complete", success: true)
        } catch {
            self.errorMessage = (error as? AppError)?.errorDescription ?? error.localizedDescription
            self.authState = .error(self.errorMessage ?? "Unknown error")
            logAuthenticationEvent(provider: "onboarding_complete", success: false)
            throw error
        }
        isLoading = false
    }
    
    /// Log authentication events to analytics
    private func logAuthenticationEvent(provider: String, success: Bool) {
        // In a real app, this would use Firebase Analytics
        print("Authentication event: provider=\(provider), success=\(success)")
    }
    
    /// Reset spotlight state for new users
    private func resetSpotlightState() {
        // Only reset spotlight if this user hasn't seen it before
        guard let userId = user?.id else {
            print("⚠️ No user ID available, skipping spotlight reset")
            return
        }
        
        let userSpotlightKey = "has_seen_spotlight_user_\(userId)"
        let hasSeenSpotlight = UserDefaults.standard.bool(forKey: userSpotlightKey)
        
        if !hasSeenSpotlight {
            // This is a truly new user, reset all spotlight flags
            UserDefaults.standard.set(false, forKey: "has_seen_main_spotlight")
            UserDefaults.standard.set(false, forKey: "has_seen_spotlight_rating_page")
            UserDefaults.standard.set(false, forKey: "has_seen_spotlight_trend_page")
            UserDefaults.standard.set(false, forKey: "has_seen_spotlight_journey_page")
            UserDefaults.standard.set(false, forKey: "has_seen_spotlight_profile_page")
            
            // Mark this user as having seen the spotlight
            UserDefaults.standard.set(true, forKey: userSpotlightKey)
            print("🔄 Spotlight state reset for new user: \(userId)")
        } else {
            print("ℹ️ User \(userId) has already seen spotlight, skipping reset")
        }
    }
}
