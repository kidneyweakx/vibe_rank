//
//  AuthenticationViewModel.swift
//  viberanking
//
//  Created by Kiro on 2025/07/23.
//

import Foundation
import Combine
import SwiftUI
import FirebaseAuth

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
    private var cancellables = Set<AnyCancellable>()
    private var authStateListener: AuthStateDidChangeListenerHandle?
    
    // MARK: - Auth State Enum
    
    enum AuthState {
        case signedOut
        case signingIn
        case signedIn
        case error(String)
    }
    
    // MARK: - Initializer
    
    nonisolated init(authenticationService: AuthenticationServiceProtocol = AuthenticationService()) {
        self.authenticationService = authenticationService
        
        // Since we're in a nonisolated initializer, we need to be careful with MainActor properties
        // We'll set them in a Task after initialization
        Task { @MainActor in
            // Set initial state from service
            self.user = authenticationService.currentUser
            self.isAuthenticated = authenticationService.isAuthenticated
            self.authState = authenticationService.isAuthenticated ? .signedIn : .signedOut
            
            // Setup Firebase auth state listener
            setupAuthStateListener()
        }
    }
    
    deinit {
        // Remove auth state listener when ViewModel is deallocated
        if let listener = authStateListener {
            Auth.auth().removeStateDidChangeListener(listener)
        }
    }
    
    // MARK: - Firebase Auth State Listener
    
    private func setupAuthStateListener() {
        authStateListener = Auth.auth().addStateDidChangeListener { [weak self] (_, user) in
            guard let self = self else { return }
            
            Task { @MainActor in
                if let firebaseUser = user {
                    // User is signed in
                    self.user = User(
                        id: firebaseUser.uid,
                        name: firebaseUser.displayName ?? "Unknown",
                        email: firebaseUser.email ?? "no-email@example.com",
                        profileImageURL: firebaseUser.photoURL?.absoluteString
                    )
                    self.isAuthenticated = true
                    self.authState = .signedIn
                    self.isGuest = false
                } else {
                    // User is signed out
                    self.user = nil
                    self.isAuthenticated = false
                    self.authState = .signedOut
                    self.isGuest = false
                }
            }
        }
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
            name: "訪客",
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
    
    // MARK: - Private Methods
    
    /// Log authentication events to analytics
    private func logAuthenticationEvent(provider: String, success: Bool) {
        // In a real app, this would use Firebase Analytics
        print("Authentication event: provider=\(provider), success=\(success)")
    }
}
