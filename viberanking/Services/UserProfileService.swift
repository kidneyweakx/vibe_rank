//
//  UserProfileService.swift
//  viberanking
//
//  Created by Kiro on 2025/07/23.
//

import Foundation
import Combine

/// Service for managing user profiles and state persistence
@MainActor
class UserProfileService: ObservableObject {
    
    // MARK: - Properties
    
    @Published var currentUser: User?
    @Published var isLoading = false
    @Published var error: AppError?
    
    private let userRepository = UserRepository()
    private let userAPI = UserAPI()
    private let authenticationService: AuthenticationService
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Initialization
    
    init(authenticationService: AuthenticationService) {
        self.authenticationService = authenticationService
        setupSubscribers()
    }
    
    // MARK: - Authentication State Monitoring
    
    private func setupSubscribers() {
        authenticationService.$currentUser
            .receive(on: DispatchQueue.main)
            .sink { [weak self] user in
                Task {
                    if let user = user {
                        await self?.handleUserSignedIn(user: user)
                    } else {
                        await self?.handleUserSignedOut()
                    }
                }
            }
            .store(in: &cancellables)
    }
    
    /// Handle user signed in event
    private func handleUserSignedIn(user: User) async {
        print("🔄 User signed in, loading profile: \(user.id)")
        isLoading = true
        error = nil
        
        do {
            // Try to load existing user profile from our backend
            if let existingUser = try await userRepository.getUser(by: user.id) {
                print("✅ Existing user profile loaded: \(existingUser.name)")
                currentUser = existingUser
                
                // Try to update last activity
                try? await userRepository.updateLastActivity(userId: existingUser.id)
                
            } else {
                print("ℹ️ No existing profile found, entering profile setup flow instead of creating on /users")
                // Defer creation to profile setup screen instead of calling POST /users which may not exist
                throw AppError.serverError(404)
            }
            
        } catch let appError as AppError {
            print("❌ Failed to handle user sign in: \(appError.localizedDescription)")
            self.error = appError
        } catch {
            print("❌ Failed to handle user sign in with unknown error: \(error.localizedDescription)")
            self.error = .apiError(error)
        }
        
        isLoading = false
    }
    
    /// Handle user signed out event
    private func handleUserSignedOut() async {
        print("ℹ️ User signed out, clearing profile")
        currentUser = nil
        error = nil
    }
    
    // MARK: - User Profile Management
    
    /// Update user profile
    func updateUserProfile(_ user: User) async throws {
        print("🔄 Updating user profile: \(user.id)")
        isLoading = true
        error = nil
        
        do {
            let updatedUser = try await userRepository.update(user)
            currentUser = updatedUser
            print("✅ User profile updated successfully")
        } catch {
            print("❌ Failed to update user profile: \(error.localizedDescription)")
            self.error = error as? AppError ?? .validationError("Failed to update profile")
            throw error
        }
        
        isLoading = false
    }

    /// Update name and gender via dedicated API, keeping other fields intact
    func updateNameAndGender(name: String?, gender: Gender?) async throws {
        guard let currentUser = currentUser else { throw AppError.userNotFound }
        isLoading = true
        error = nil
        do {
            let response = try await userAPI.updateUserProfile(
                userId: currentUser.id,
                name: name,
                gender: gender?.rawValue,
                avatar: nil
            )
            // Try to refresh from repository to keep full data shape
            if let refreshed = try? await userRepository.getUser(by: response.data.id) {
                self.currentUser = refreshed
            } else {
                // Fallback: update current user locally based on response
                var updated = currentUser
                updated = User(
                    id: response.data.id,
                    name: response.data.name,
                    email: currentUser.email,
                    profileImageURL: response.data.avatar,
                    gender: response.data.gender.flatMap { Gender(rawValue: $0) }
                )
                // Preserve existing progress and photos if any
                self.currentUser?.ratingProgress = currentUser.ratingProgress
                self.currentUser?.uploadedPhotos = currentUser.uploadedPhotos
                self.currentUser = updated
            }
        } catch {
            self.error = error as? AppError ?? .apiError(error)
            isLoading = false
            throw error
        }
        isLoading = false
    }

    /// Update only the user's avatar URL
    func updateAvatar(urlString: String) async throws {
        guard let currentUser = currentUser else { throw AppError.userNotFound }
        isLoading = true
        error = nil
        do {
            let response = try await userAPI.updateUserProfile(
                userId: currentUser.id,
                name: nil,
                gender: nil,
                avatar: urlString
            )
            // Try to refresh from repository to keep full data shape
            if let refreshed = try? await userRepository.getUser(by: response.data.id) {
                self.currentUser = refreshed
            } else {
                var updated = currentUser
                updated = User(
                    id: response.data.id,
                    name: response.data.name,
                    email: currentUser.email,
                    profileImageURL: response.data.avatar,
                    gender: response.data.gender.flatMap { Gender(rawValue: $0) }
                )
                updated.ratingProgress = currentUser.ratingProgress
                updated.uploadedPhotos = currentUser.uploadedPhotos
                self.currentUser = updated
            }
        } catch {
            self.error = error as? AppError ?? .apiError(error)
            isLoading = false
            throw error
        }
        isLoading = false
    }

    /// Attempt to change the user's ID (username). Backend may return 409 on conflict.
    func changeUserID(to newId: String) async throws {
        guard let currentUser = currentUser else { throw AppError.userNotFound }
        isLoading = true
        error = nil
        do {
            try await userAPI.updateUserID(currentUserId: currentUser.id, newUserId: newId)
            // Try to refresh via repository
            if let refreshed = try? await userRepository.getUser(by: newId) {
                self.currentUser = refreshed
            } else if let apiProfile = try? await userAPI.getUserProfile(userId: newId) {
                // Map minimal profile back to our User model, preserving existing fields
                let mapped = User(
                    id: apiProfile.data.id,
                    name: apiProfile.data.name,
                    email: currentUser.email,
                    profileImageURL: apiProfile.data.avatar,
                    gender: apiProfile.data.gender.flatMap { Gender(rawValue: $0) }
                )
                self.currentUser = mapped
            } else {
                // Last-resort: update ID locally so UI reflects change
                var local = currentUser
                // Construct a new User with updated id keeping known fields
                let updated = User(
                    id: newId,
                    name: local.name,
                    email: local.email,
                    profileImageURL: local.profileImageURL,
                    gender: local.gender
                )
                self.currentUser = updated
            }
        } catch {
            self.error = error as? AppError ?? .apiError(error)
            isLoading = false
            throw error
        }
        isLoading = false
    }

    /// Check availability for a desired ID
    func isUserIDAvailable(_ desiredId: String) async -> Bool {
        do {
            let res = try await userAPI.checkUserIDAvailable(desiredId)
            return res.available
        } catch {
            return false
        }
    }
    
    /// Delete user account and all data
    func deleteUserAccount() async throws {
        guard let currentUser = currentUser else {
            throw AppError.userNotFound
        }
        
        print("🔄 Deleting user account: \(currentUser.id)")
        isLoading = true
        error = nil
        
        do {
            // Delete user profile from our backend
            try await userRepository.delete(id: currentUser.id)
            
            // Sign out from the authentication service
            try await authenticationService.signOut()
            
            // Clear local state is handled by the subscriber to authenticationService
            print("✅ User account deleted successfully")
        } catch {
            print("❌ Failed to delete user account: \(error.localizedDescription)")
            self.error = error as? AppError ?? .validationError("Failed to delete account")
            throw error
        }
        
        isLoading = false
    }
    
    /// Refresh current user data
    func refreshUserData() async throws {
        guard let currentUserId = currentUser?.id else {
            throw AppError.userNotFound
        }
        
        print("🔄 Refreshing user data: \(currentUserId)")
        isLoading = true
        error = nil
        
        do {
            if let refreshedUser = try await userRepository.getUser(by: currentUserId) {
                self.currentUser = refreshedUser
                print("✅ User data refreshed successfully")
            } else {
                throw AppError.userNotFound
            }
        } catch {
            print("❌ Failed to refresh user data: \(error.localizedDescription)")
            self.error = error as? AppError ?? .validationError("Failed to refresh user data")
            throw error
        }
        
        isLoading = false
    }
    
    // MARK: - Computed Properties
    
    /// Check if user is authenticated
    var isAuthenticated: Bool {
        return currentUser != nil
    }
    
    /// Check if user has unlocked upload functionality
    var hasUnlockedUpload: Bool {
        return currentUser?.ratingProgress.hasUnlockedUpload ?? false
    }
    
    /// Get remaining ratings needed to unlock upload
    var remainingRatingsForUpload: Int {
        return currentUser?.ratingProgress.remainingRatings ?? 20
    }
    
    // MARK: - Rating Progress Management
    
    /// Update user rating progress
    func updateRatingProgress(_ progress: RatingProgress) async throws {
        guard var user = currentUser else {
            throw AppError.userNotFound
        }
        
        print("🔄 Updating rating progress: \(progress.completedRatings)/\(progress.requiredRatings)")
        isLoading = true
        error = nil
        
        do {
            // Update the user's rating progress
            user.ratingProgress = progress
            
            // Save to backend
            let updatedUser = try await userRepository.update(user)
            currentUser = updatedUser
            
            print("✅ Rating progress updated successfully")
        } catch {
            print("❌ Failed to update rating progress: \(error.localizedDescription)")
            self.error = error as? AppError ?? .validationError("Failed to update rating progress")
            throw error
        }
        
        isLoading = false
    }
}
