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
    
    // MARK: - Mock Authentication Service
    
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
    
    func testAuthenticationViewModel_WhenInitialized_ShouldHaveCorrectInitialState() {
        // Given
        let mockService = MockAuthenticationService()
        
        // When
        let viewModel = AuthenticationViewModel(authenticationService: mockService)
        
        // Then
        XCTAssertFalse(viewModel.isAuthenticated)
        XCTAssertNil(viewModel.user)
        XCTAssertFalse(viewModel.isLoading)
        XCTAssertNil(viewModel.errorMessage)
        XCTAssertFalse(viewModel.isGuest)
        XCTAssertEqual(viewModel.authState, .signedOut)
    }
    
    func testAuthenticationViewModel_WhenGoogleSignInSucceeds_ShouldUpdateState() async {
        // Given
        let mockService = MockAuthenticationService()
        mockService.shouldSucceed = true
        mockService.mockUser = User(id: "test-id", name: "Test User", email: "test@example.com")
        let viewModel = AuthenticationViewModel(authenticationService: mockService)
        
        // When
        await viewModel.signInWithGoogle()
        
        // Then
        XCTAssertTrue(mockService.signInGoogleCalled)
        XCTAssertTrue(viewModel.isAuthenticated)
        XCTAssertNotNil(viewModel.user)
        XCTAssertEqual(viewModel.user?.id, "test-id")
        XCTAssertEqual(viewModel.user?.name, "Test User")
        XCTAssertEqual(viewModel.user?.email, "test@example.com")
        XCTAssertFalse(viewModel.isLoading)
        XCTAssertNil(viewModel.errorMessage)
        XCTAssertEqual(viewModel.authState, .signedIn)
    }
    
    func testAuthenticationViewModel_WhenGoogleSignInFails_ShouldShowError() async {
        // Given
        let mockService = MockAuthenticationService()
        mockService.shouldSucceed = false
        let viewModel = AuthenticationViewModel(authenticationService: mockService)
        
        // When
        await viewModel.signInWithGoogle()
        
        // Then
        XCTAssertTrue(mockService.signInGoogleCalled)
        XCTAssertFalse(viewModel.isAuthenticated)
        XCTAssertNil(viewModel.user)
        XCTAssertFalse(viewModel.isLoading)
        XCTAssertNotNil(viewModel.errorMessage)
        XCTAssertEqual(viewModel.errorMessage, AppError.authenticationFailed.errorDescription)
        XCTAssertNotEqual(viewModel.authState, .signedIn)
    }
    
    func testAuthenticationViewModel_WhenAppleSignInSucceeds_ShouldUpdateState() async {
        // Given
        let mockService = MockAuthenticationService()
        mockService.shouldSucceed = true
        mockService.mockUser = User(id: "apple-id", name: "Apple User", email: "apple@example.com")
        let viewModel = AuthenticationViewModel(authenticationService: mockService)
        
        // When
        await viewModel.signInWithApple()
        
        // Then
        XCTAssertTrue(mockService.signInAppleCalled)
        XCTAssertTrue(viewModel.isAuthenticated)
        XCTAssertNotNil(viewModel.user)
        XCTAssertEqual(viewModel.user?.id, "apple-id")
        XCTAssertEqual(viewModel.user?.name, "Apple User")
        XCTAssertEqual(viewModel.user?.email, "apple@example.com")
        XCTAssertFalse(viewModel.isLoading)
        XCTAssertNil(viewModel.errorMessage)
        XCTAssertEqual(viewModel.authState, .signedIn)
    }
    
    func testAuthenticationViewModel_WhenAppleSignInFails_ShouldShowError() async {
        // Given
        let mockService = MockAuthenticationService()
        mockService.shouldSucceed = false
        let viewModel = AuthenticationViewModel(authenticationService: mockService)
        
        // When
        await viewModel.signInWithApple()
        
        // Then
        XCTAssertTrue(mockService.signInAppleCalled)
        XCTAssertFalse(viewModel.isAuthenticated)
        XCTAssertNil(viewModel.user)
        XCTAssertFalse(viewModel.isLoading)
        XCTAssertNotNil(viewModel.errorMessage)
        XCTAssertEqual(viewModel.errorMessage, AppError.authenticationFailed.errorDescription)
        XCTAssertNotEqual(viewModel.authState, .signedIn)
    }
    
    func testAuthenticationViewModel_WhenSignInAsGuest_ShouldCreateGuestUser() async {
        // Given
        let mockService = MockAuthenticationService()
        let viewModel = AuthenticationViewModel(authenticationService: mockService)
        
        // When
        await viewModel.signInAsGuest()
        
        // Then
        XCTAssertTrue(viewModel.isAuthenticated)
        XCTAssertNotNil(viewModel.user)
        XCTAssertTrue(viewModel.user?.id.hasPrefix("guest_") ?? false)
        XCTAssertEqual(viewModel.user?.name, "訪客")
        XCTAssertEqual(viewModel.user?.email, "guest@example.com")
        XCTAssertFalse(viewModel.isLoading)
        XCTAssertNil(viewModel.errorMessage)
        XCTAssertTrue(viewModel.isGuest)
        XCTAssertEqual(viewModel.authState, .signedIn)
    }
    
    func testAuthenticationViewModel_WhenSignOut_ShouldClearUserState() async {
        // Given
        let mockService = MockAuthenticationService()
        mockService.shouldSucceed = true
        mockService.mockUser = User(id: "test-id", name: "Test User", email: "test@example.com")
        let viewModel = AuthenticationViewModel(authenticationService: mockService)
        await viewModel.signInWithGoogle() // Sign in first
        
        // When
        await viewModel.signOut()
        
        // Then
        XCTAssertTrue(mockService.signOutCalled)
        XCTAssertFalse(viewModel.isAuthenticated)
        XCTAssertNil(viewModel.user)
        XCTAssertFalse(viewModel.isLoading)
        XCTAssertNil(viewModel.errorMessage)
        XCTAssertFalse(viewModel.isGuest)
        XCTAssertEqual(viewModel.authState, .signedOut)
    }
    
    func testAuthenticationViewModel_WhenSignOutFails_ShouldShowError() async {
        // Given
        let mockService = MockAuthenticationService()
        mockService.shouldSucceed = false
        mockService.mockUser = User(id: "test-id", name: "Test User", email: "test@example.com")
        let viewModel = AuthenticationViewModel(authenticationService: mockService)
        await viewModel.signInWithGoogle() // Sign in first
        
        // Reset the mock service state for the sign out test
        mockService.signInGoogleCalled = false
        
        // When
        await viewModel.signOut()
        
        // Then
        XCTAssertTrue(mockService.signOutCalled)
        XCTAssertFalse(viewModel.isLoading)
        XCTAssertNotNil(viewModel.errorMessage)
        XCTAssertNotEqual(viewModel.authState, .signedOut)
    }
}