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
    
    func signOut() {
        isLoading = true
        
        Task {
            do {
                try await authenticationService.signOut()
                self.user = nil
                self.isAuthenticated = false
            } catch {
                self.errorMessage = (error as? AppError)?.errorDescription ?? error.localizedDescription
            }
            isLoading = false
        }
    }
}
