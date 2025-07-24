//
//  UserProfileService.swift
//  viberanking
//
//  Created by Kiro on 2025/07/23.
//

import Foundation
import FirebaseAuth
import Combine

/// Service for managing user profiles and state persistence
@MainActor
class UserProfileService: ObservableObject {
    
    // MARK: - Properties
    
    @Published var currentUser: User?
    @Published var isLoading = false
    @Published var error: AppError?
    
    private let userRepository = UserRepository()
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Initialization
    
    nonisolated init() {
        Task { @MainActor in
            setupAuthStateListener()
        }
    }
    
    // MARK: - Authentication State Monitoring
    
    /// Set up Firebase Auth state listener
    private func setupAuthStateListener() {
        Auth.auth().addStateDidChangeListener { [weak self] _, user in
            Task { @MainActor in
                if let user = user {
                    await self?.handleUserSignedIn(firebaseUser: user)
                } else {
                    await self?.handleUserSignedOut()
                }
            }
        }
    }
    
    /// Handle user signed in event
    private func handleUserSignedIn(firebaseUser: FirebaseAuth.User) async {
        print("🔄 User signed in, loading profile: \(firebaseUser.uid)")
        isLoading = true
        error = nil
        
        do {
            // Try to load existing user profile
            if let existingUser = try await userRepository.getUser(by: firebaseUser.uid) {
                print("✅ Existing user profile loaded: \(existingUser.name)")
                currentUser = existingUser
                
                // Try to update last activity, but don't fail if offline
                do {
                    try await userRepository.updateLastActivity(userId: existingUser.id)
                } catch {
                    print("⚠️ Could not update last activity (offline mode): \(error.localizedDescription)")
                }
                
            } else {
                print("ℹ️ No existing profile found, creating new user profile")
                
                // Create new user profile from Firebase user data
                let newUser = User(
                    id: firebaseUser.uid,
                    name: firebaseUser.displayName ?? "User",
                    email: firebaseUser.email ?? "no-email@example.com",
                    profileImageURL: firebaseUser.photoURL?.absoluteString
                )
                
                do {
                    let savedUser = try await userRepository.createOrUpdateUserProfile(newUser)
                    currentUser = savedUser
                    print("✅ New user profile created: \(savedUser.name)")
                } catch {
                    print("⚠️ Could not save user profile (offline mode), using local user: \(error.localizedDescription)")
                    // In offline mode, use the local user object
                    currentUser = newUser
                }
            }
            
        } catch {
            print("⚠️ Failed to handle user sign in (offline mode): \(error.localizedDescription)")
            
            // In offline mode, create a basic user from Firebase Auth data
            if error.localizedDescription.contains("offline") || error.localizedDescription.contains("network") {
                print("📱 Creating offline user profile from Firebase Auth data")
                let offlineUser = User(
                    id: firebaseUser.uid,
                    name: firebaseUser.displayName ?? "User",
                    email: firebaseUser.email ?? "no-email@example.com",
                    profileImageURL: firebaseUser.photoURL?.absoluteString
                )
                currentUser = offlineUser
            } else {
                self.error = error as? AppError ?? AppError.userNotFound
            }
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
            self.error = error as? AppError ?? AppError.validationError("Failed to update profile")
            throw error
        }
        
        isLoading = false
    }
    
    /// Update user rating progress
    func updateRatingProgress(_ progress: RatingProgress) async throws {
        guard let currentUser = currentUser else {
            throw AppError.userNotFound
        }
        
        print("🔄 Updating rating progress for user: \(currentUser.id)")
        
        do {
            try await userRepository.updateRatingProgress(userId: currentUser.id, progress: progress)
            
            // Update local user state
            var updatedUser = currentUser
            updatedUser.ratingProgress = progress
            self.currentUser = updatedUser
            
            print("✅ Rating progress updated successfully")
        } catch {
            print("❌ Failed to update rating progress: \(error.localizedDescription)")
            self.error = error as? AppError ?? AppError.validationError("Failed to update rating progress")
            throw error
        }
    }
    
    /// Get user preferences
    func getUserPreferences() async throws -> UserPreferences? {
        guard let currentUser = currentUser else {
            throw AppError.userNotFound
        }
        
        print("🔄 Getting user preferences: \(currentUser.id)")
        
        do {
            let preferences = try await userRepository.getUserPreferences(userId: currentUser.id)
            print("✅ User preferences retrieved successfully")
            return preferences
        } catch {
            print("❌ Failed to get user preferences: \(error.localizedDescription)")
            self.error = error as? AppError ?? AppError.validationError("Failed to get preferences")
            throw error
        }
    }
    
    /// Update user preferences
    func updateUserPreferences(_ preferences: UserPreferences) async throws {
        print("🔄 Updating user preferences: \(preferences.userId)")
        
        do {
            try await userRepository.updateUserPreferences(preferences)
            print("✅ User preferences updated successfully")
        } catch {
            print("❌ Failed to update user preferences: \(error.localizedDescription)")
            self.error = error as? AppError ?? AppError.validationError("Failed to update preferences")
            throw error
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
            // Delete user profile from Firestore
            try await userRepository.delete(id: currentUser.id)
            
            // Delete Firebase Auth account
            if let firebaseUser = Auth.auth().currentUser {
                try await firebaseUser.delete()
            }
            
            // Clear local state
            self.currentUser = nil
            
            print("✅ User account deleted successfully")
        } catch {
            print("❌ Failed to delete user account: \(error.localizedDescription)")
            self.error = error as? AppError ?? AppError.validationError("Failed to delete account")
            throw error
        }
        
        isLoading = false
    }
    
    /// Check if user exists
    func userExists(id: String) async throws -> Bool {
        return try await userRepository.userExists(id: id)
    }
    
    /// Refresh current user data
    func refreshUserData() async throws {
        guard let currentUser = currentUser else {
            throw AppError.userNotFound
        }
        
        print("🔄 Refreshing user data: \(currentUser.id)")
        isLoading = true
        error = nil
        
        do {
            if let refreshedUser = try await userRepository.getUser(by: currentUser.id) {
                self.currentUser = refreshedUser
                print("✅ User data refreshed successfully")
            } else {
                throw AppError.userNotFound
            }
        } catch {
            print("❌ Failed to refresh user data: \(error.localizedDescription)")
            self.error = error as? AppError ?? AppError.validationError("Failed to refresh user data")
            throw error
        }
        
        isLoading = false
    }
    
    // MARK: - Computed Properties
    
    /// Check if user is authenticated
    var isAuthenticated: Bool {
        return currentUser != nil && Auth.auth().currentUser != nil
    }
    
    /// Check if user has unlocked upload functionality
    var hasUnlockedUpload: Bool {
        return currentUser?.ratingProgress.hasUnlockedUpload ?? false
    }
    
    /// Get remaining ratings needed to unlock upload
    var remainingRatingsForUpload: Int {
        return currentUser?.ratingProgress.remainingRatings ?? 20
    }
}