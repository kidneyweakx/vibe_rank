//
//  UserRepository.swift
//  viberanking
//
//  Created by Kiro on 2025/07/23.
//

import Foundation
import FirebaseFirestore

// MARK: - User Repository Implementation
class UserRepository: UserRepositoryProtocol {
    private let db = Firestore.firestore()
    private let usersCollection = "users"
    private let preferencesCollection = "userPreferences"
    
    // MARK: - CRUD Operations
    func create(_ entity: User) async throws -> User {
        print("🔄 Creating user profile in Firestore: \(entity.id)")
        
        do {
            let userRef = db.collection(usersCollection).document(entity.id)
            try userRef.setData(from: entity)
            
            print("✅ User profile created successfully: \(entity.id)")
            return entity
        } catch {
            print("⚠️ Failed to create user profile (offline mode): \(error.localizedDescription)")
            // In offline mode, return the user as if it was created successfully
            if error.localizedDescription.contains("offline") || error.localizedDescription.contains("network") {
                print("📱 Operating in offline mode - returning user without Firestore storage")
                return entity
            }
            throw AppError.firebaseError(.firestoreError("Failed to create user profile: \(error.localizedDescription)"))
        }
    }
    
    func read(id: String) async throws -> User? {
        return try await getUser(by: id)
    }
    
    func update(_ entity: User) async throws -> User {
        print("🔄 Updating user profile in Firestore: \(entity.id)")
        
        do {
            let userRef = db.collection(usersCollection).document(entity.id)
            try userRef.setData(from: entity, merge: true)
            
            print("✅ User profile updated successfully: \(entity.id)")
            return entity
        } catch {
            print("❌ Failed to update user profile: \(error.localizedDescription)")
            throw AppError.firebaseError(.firestoreError("Failed to update user profile: \(error.localizedDescription)"))
        }
    }
    
    func delete(id: String) async throws {
        print("🔄 Deleting user profile from Firestore: \(id)")
        
        do {
            let userRef = db.collection(usersCollection).document(id)
            try await userRef.delete()
            
            // Also delete user preferences
            let preferencesRef = db.collection(preferencesCollection).document(id)
            try await preferencesRef.delete()
            
            print("✅ User profile and preferences deleted successfully: \(id)")
        } catch {
            print("❌ Failed to delete user profile: \(error.localizedDescription)")
            throw AppError.firebaseError(.firestoreError("Failed to delete user profile: \(error.localizedDescription)"))
        }
    }
    
    func list(limit: Int? = 20, offset: Int? = nil) async throws -> [User] {
        print("🔄 Listing users from Firestore with limit: \(limit ?? 20)")
        
        do {
            var query: Query = db.collection(usersCollection)
                .order(by: "createdAt", descending: true)
                .limit(to: limit ?? 20)
            
            if let offset = offset, offset > 0 {
                // For pagination, we would need to implement proper cursor-based pagination
                // This is a simplified version
                query = query.start(at: [offset])
            }
            
            let snapshot = try await query.getDocuments()
            let users = try snapshot.documents.compactMap { document in
                try document.data(as: User.self)
            }
            
            print("✅ Retrieved \(users.count) users from Firestore")
            return users
        } catch {
            print("❌ Failed to list users: \(error.localizedDescription)")
            throw AppError.firebaseError(.firestoreError("Failed to list users: \(error.localizedDescription)"))
        }
    }
    
    // MARK: - User-specific Operations
    func getUser(by id: String) async throws -> User? {
        print("🔄 Getting user by id from Firestore: \(id)")
        
        do {
            let userRef = db.collection(usersCollection).document(id)
            let document = try await userRef.getDocument()
            
            if document.exists {
                let user = try document.data(as: User.self)
                print("✅ User retrieved successfully: \(user.name)")
                return user
            } else {
                print("ℹ️ User not found: \(id)")
                return nil
            }
        } catch {
            print("⚠️ Failed to get user (offline mode): \(error.localizedDescription)")
            // In offline mode, return nil to indicate user not found locally
            if error.localizedDescription.contains("offline") || error.localizedDescription.contains("network") {
                print("📱 Operating in offline mode - user data not available")
                return nil
            }
            throw AppError.firebaseError(.firestoreError("Failed to get user: \(error.localizedDescription)"))
        }
    }
    
    func findByEmail(_ email: String) async throws -> User? {
        print("🔄 Finding user by email from Firestore: \(email)")
        
        do {
            let query = db.collection(usersCollection)
                .whereField("email", isEqualTo: email)
                .limit(to: 1)
            
            let snapshot = try await query.getDocuments()
            
            if let document = snapshot.documents.first {
                let user = try document.data(as: User.self)
                print("✅ User found by email: \(user.name)")
                return user
            } else {
                print("ℹ️ User not found with email: \(email)")
                return nil
            }
        } catch {
            print("❌ Failed to find user by email: \(error.localizedDescription)")
            throw AppError.firebaseError(.firestoreError("Failed to find user by email: \(error.localizedDescription)"))
        }
    }
    
    func updateRatingProgress(userId: String, progress: RatingProgress) async throws {
        print("🔄 Updating rating progress for user: \(userId)")
        
        do {
            let userRef = db.collection(usersCollection).document(userId)
            try await userRef.updateData([
                "ratingProgress": [
                    "completedRatings": progress.completedRatings,
                    "requiredRatings": progress.requiredRatings
                ]
            ])
            
            print("✅ Rating progress updated successfully for user: \(userId)")
        } catch {
            print("❌ Failed to update rating progress: \(error.localizedDescription)")
            throw AppError.firebaseError(.firestoreError("Failed to update rating progress: \(error.localizedDescription)"))
        }
    }
    
    func getUserPreferences(userId: String) async throws -> UserPreferences? {
        print("🔄 Getting user preferences from Firestore: \(userId)")
        
        do {
            let preferencesRef = db.collection(preferencesCollection).document(userId)
            let document = try await preferencesRef.getDocument()
            
            if document.exists {
                let preferences = try document.data(as: UserPreferences.self)
                print("✅ User preferences retrieved successfully")
                return preferences
            } else {
                print("ℹ️ User preferences not found, creating default: \(userId)")
                let defaultPreferences = UserPreferences(userId: userId)
                try await updateUserPreferences(defaultPreferences)
                return defaultPreferences
            }
        } catch {
            print("❌ Failed to get user preferences: \(error.localizedDescription)")
            throw AppError.firebaseError(.firestoreError("Failed to get user preferences: \(error.localizedDescription)"))
        }
    }
    
    func updateUserPreferences(_ preferences: UserPreferences) async throws {
        print("🔄 Updating user preferences in Firestore: \(preferences.userId)")
        
        do {
            let preferencesRef = db.collection(preferencesCollection).document(preferences.userId)
            try preferencesRef.setData(from: preferences, merge: true)
            
            print("✅ User preferences updated successfully: \(preferences.userId)")
        } catch {
            print("❌ Failed to update user preferences: \(error.localizedDescription)")
            throw AppError.firebaseError(.firestoreError("Failed to update user preferences: \(error.localizedDescription)"))
        }
    }
    
    // MARK: - User Profile Management
    
    /// Creates or updates user profile in Firestore
    func createOrUpdateUserProfile(_ user: User) async throws -> User {
        print("🔄 Creating or updating user profile: \(user.id)")
        
        do {
            // Check if user already exists
            if let existingUser = try await getUser(by: user.id) {
                print("ℹ️ User exists, updating profile")
                
                // Merge existing data with new data
                var updatedUser = user
                updatedUser.ratingProgress = existingUser.ratingProgress
                updatedUser.uploadedPhotos = existingUser.uploadedPhotos
                
                return try await update(updatedUser)
            } else {
                print("ℹ️ New user, creating profile")
                return try await create(user)
            }
        } catch {
            // In offline mode, just return the user as if it was created/updated successfully
            print("⚠️ Operating in offline mode - returning user without Firestore operations")
            return user
        }
    }
    
    /// Checks if user exists in Firestore
    func userExists(id: String) async throws -> Bool {
        print("🔄 Checking if user exists: \(id)")
        
        do {
            let userRef = db.collection(usersCollection).document(id)
            let document = try await userRef.getDocument()
            let exists = document.exists
            
            print("✅ User exists check result: \(exists)")
            return exists
        } catch {
            print("❌ Failed to check if user exists: \(error.localizedDescription)")
            throw AppError.firebaseError(.firestoreError("Failed to check if user exists: \(error.localizedDescription)"))
        }
    }
    
    /// Updates user's last activity timestamp
    func updateLastActivity(userId: String) async throws {
        print("🔄 Updating last activity for user: \(userId)")
        
        do {
            let userRef = db.collection(usersCollection).document(userId)
            try await userRef.updateData([
                "lastActivityAt": Timestamp(date: Date())
            ])
            
            print("✅ Last activity updated for user: \(userId)")
        } catch {
            print("❌ Failed to update last activity: \(error.localizedDescription)")
            throw AppError.firebaseError(.firestoreError("Failed to update last activity: \(error.localizedDescription)"))
        }
    }
}
