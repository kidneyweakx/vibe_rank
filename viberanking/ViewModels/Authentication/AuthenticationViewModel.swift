//
//  AuthenticationViewModel.swift
//  viberanking
//
//  Created by Kiro on 2025/07/23.
//

import Foundation
import Combine
import SwiftUI

@MainActor
class AuthenticationViewModel: ObservableObject {
    
    // MARK: - Properties
    
    @Published var user: User?
    @Published var isAuthenticated: Bool = false
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    @Published var isGuest: Bool = false
    
    private let authenticationService: AuthenticationServiceProtocol
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Initializer
    
    init(authenticationService: AuthenticationServiceProtocol = AuthenticationService()) {
        self.authenticationService = authenticationService
        self.user = authenticationService.currentUser
        self.isAuthenticated = authenticationService.isAuthenticated
    }
    
    // MARK: - Public Methods
    
    func signInWithGoogle() {
        isLoading = true
        errorMessage = nil
        isGuest = false
        
        Task {
            do {
                let user = try await authenticationService.signInWithGoogle()
                self.user = user
                self.isAuthenticated = true
            } catch {
                self.errorMessage = (error as? AppError)?.errorDescription ?? error.localizedDescription
            }
            isLoading = false
        }
    }
    
    func signInWithApple() {
        isLoading = true
        errorMessage = nil
        isGuest = false
        
        Task {
            do {
                let user = try await authenticationService.signInWithApple()
                self.user = user
                self.isAuthenticated = true
            } catch {
                self.errorMessage = (error as? AppError)?.errorDescription ?? error.localizedDescription
            }
            isLoading = false
        }
    }
    
    func signInAsGuest() {
        isLoading = true
        errorMessage = nil
        isGuest = true
        
        let guestUser = User(
            id: "guest_\(UUID().uuidString)",
            name: "訪客",
            email: "guest@example.com"
        )
        self.user = guestUser
        self.isAuthenticated = true
        isLoading = false
    }
    
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
            } catch {
                self.errorMessage = (error as? AppError)?.errorDescription ?? error.localizedDescription
            }
            isLoading = false
        }
    }
}
