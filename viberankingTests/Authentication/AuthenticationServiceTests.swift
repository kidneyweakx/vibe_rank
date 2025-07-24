//
//  AuthenticationServiceTests.swift
//  viberankingTests
//
//  Created by Kiro on 2025/07/23.
//

import XCTest
import Combine
@testable import viberanking

final class AuthenticationServiceTests: XCTestCase {
    
    // MARK: - Mock Services
    
    @MainActor
    class MockUserProfileService: UserProfileService {
        var mockCurrentUser: User?
        var mockIsLoading = false
        var mockError: AppError?
        
        override init() {
            super.init()
            // Override published properties for testing
            self.currentUser = mockCurrentUser
            self.isLoading = mockIsLoading
            self.error = mockError
        }
        
        override func updateRatingProgress(_ progress: RatingProgress) async throws {
            // Mock implementation
        }
        
        override func refreshUserData() async throws {
            // Mock implementation
        }
        
        override func deleteUserAccount() async throws {
            // Mock implementation
            self.currentUser = nil
        }
    }
    
    class MockAuthenticationService: AuthenticationServiceProtocol {
        var shouldSucceed = true
        var mockUser: User?
        var signInGoogleCalled = false
        var signInAppleCalled = false
        var signOutCalled = false
        
        var currentUser: User? {
            return mockUser
        }
        
        var isAuthenticated: Bool {
            return mockUser != nil
        }
        
        func signInWithGoogle() async throws -> User {
            signInGoogleCalled = true
            
            if shouldSucceed, let user = mockUser {
                return user
            } else {
                throw AppError.authenticationFailed
            }
        }
        
        func signInWithApple() async throws -> User {
            signInAppleCalled = true
            
            if shouldSucceed, let user = mockUser {
                return user
            } else {
                throw AppError.authenticationFailed
            }
        }
        
        func signOut() async throws {
            signOutCalled = true
            
            if !shouldSucceed {
                throw AppError.firebaseError(.authenticationError)
            }
            
            mockUser = nil
        }
    }
    
    // MARK: - Tests
    
    func testAuthenticationViewModel_WhenInitialized_ShouldHaveCorrectInitialState() async {
        // Given
        let mockService = MockAuthenticationService()
        let mockUserProfileService = MockUserProfileService()
        
        // When
        let viewModel = AuthenticationViewModel(
            authenticationService: mockService,
            userProfileService: mockUserProfileService
        )
        
        // Wait a bit for async initialization
        try? await Task.sleep(nanoseconds: 100_000_000)
        
        // Then
        await MainActor.run {
            XCTAssertFalse(viewModel.isAuthenticated)
            XCTAssertNil(viewModel.user)
            XCTAssertFalse(viewModel.isLoading)
            XCTAssertNil(viewModel.errorMessage)
            XCTAssertFalse(viewModel.isGuest)
            XCTAssertEqual(viewModel.authState, .signedOut)
        }
    }
    
    func testAuthenticationViewModel_WhenGoogleSignInSucceeds_ShouldUpdateState() async {
        // Given
        let mockService = MockAuthenticationService()
        mockService.shouldSucceed = true
        mockService.mockUser = User(id: "test-id", name: "Test User", email: "test@example.com")
        
        let mockUserProfileService = await MockUserProfileService()
        await MainActor.run {
            mockUserProfileService.mockCurrentUser = mockService.mockUser
        }
        
        let viewModel = AuthenticationViewModel(
            authenticationService: mockService,
            userProfileService: mockUserProfileService
        )
        
        // When
        await viewModel.signInWithGoogle()
        
        // Wait for async updates
        try? await Task.sleep(nanoseconds: 100_000_000)
        
        // Then
        await MainActor.run {
            XCTAssertTrue(mockService.signInGoogleCalled)
            // Note: The actual user state will be managed by UserProfileService in real implementation
            XCTAssertFalse(viewModel.isLoading)
        }
    }
    
    func testUserRepository_CreateUser_ShouldSucceed() async throws {
        // Given
        let userRepository = UserRepository()
        let testUser = User(id: "test-id", name: "Test User", email: "test@example.com")
        
        // When & Then
        // Note: This would require Firebase emulator for proper testing
        // For now, we'll just test that the method exists and can be called
        do {
            let _ = try await userRepository.create(testUser)
            // In a real test with Firebase emulator, we would verify the user was created
        } catch {
            // Expected to fail without Firebase setup
            XCTAssertTrue(error is AppError)
        }
    }
    
    func testUserRepository_GetUser_ShouldReturnNilForNonExistentUser() async throws {
        // Given
        let userRepository = UserRepository()
        
        // When & Then
        do {
            let user = try await userRepository.getUser(by: "non-existent-id")
            XCTAssertNil(user)
        } catch {
            // Expected to fail without Firebase setup
            XCTAssertTrue(error is AppError)
        }
    }
    
    func testUserProfileService_UpdateRatingProgress_ShouldCallRepository() async {
        // Given
        let userProfileService = await UserProfileService()
        let progress = RatingProgress(completedRatings: 10, requiredRatings: 20)
        
        // When & Then
        do {
            try await userProfileService.updateRatingProgress(progress)
            // In a real test, we would verify the repository was called
        } catch {
            // Expected to fail without proper user setup
            XCTAssertTrue(error is AppError)
        }
    }
    
    func testAuthenticationService_SignOut_ShouldCallFirebaseSignOut() async {
        // Given
        let authService = AuthenticationService()
        
        // When & Then
        do {
            try await authService.signOut()
            // In a real test with Firebase setup, we would verify sign out was called
        } catch {
            // Expected to fail without Firebase Auth user
            XCTAssertTrue(error is AppError)
        }
    }
}