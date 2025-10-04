//
//  UserRepository.swift
//  viberanking
//
//  Created by Kiro on 2025/07/23.
//

import Foundation

// MARK: - User Repository Implementation
class UserRepository: UserRepositoryProtocol {
    private let apiClient = APIClient.shared
    private let userAPI = UserAPI()
    
    // MARK: - Private Helper Methods
    
    private func validateUserId(_ id: String) throws {
        guard !id.isEmpty, !id.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw AppError.validationError("User ID cannot be empty")
        }
    }
    
    // MARK: - CRUD Operations
    
    func create(_ entity: User) async throws -> User {
        print("🔄 Creating user profile via API: \(entity.id)")
        do {
            let userDict = try entity.toDictionary()
            return try await apiClient.performRequest(
                endpoint: "/users",
                method: .POST,
                body: userDict,
                responseType: User.self
            )
        } catch let apiError as APIError {
            if case .serverError(let code) = apiError, code == 404 {
                print("ℹ️ POST /users 端點不存在或已移動。請確認後端路徑是否為 /api/user/profile 或相關使用者建立端點。")
                throw AppError.serverError(404)
            }
            throw AppError.apiError(apiError)
        } catch {
            throw AppError.apiError(error)
        }
    }
    
    func read(id: String) async throws -> User? {
        try validateUserId(id)
        return try await getUser(by: id)
    }
    
    func update(_ entity: User) async throws -> User {
        print("🔄 Updating user profile via API: \(entity.id)")
        try validateUserId(entity.id)
        
        do {
            let userDict = try entity.toDictionary()
            return try await apiClient.performRequest(
                endpoint: "/users/\(entity.id)",
                method: .PUT,
                body: userDict,
                responseType: User.self
            )
        } catch {
            throw AppError.apiError(error)
        }
    }
    
    func delete(id: String) async throws {
        print("🔄 Deleting user profile via API: \(id)")
        try validateUserId(id)
        
        do {
            try await apiClient.performRequest(
                endpoint: "/users/\(id)",
                method: .DELETE
            )
        } catch {
            throw AppError.apiError(error)
        }
    }
    
    func list(limit: Int? = 20, offset: Int? = nil) async throws -> [User] {
        print("🔄 Listing users from API with limit: \(limit ?? 20)")
        // TODO: API does not support pagination yet.
        throw AppError.apiError(NSError(domain: "UserRepository", code: -1, userInfo: [NSLocalizedDescriptionKey: "List functionality not implemented"]))
    }
    
    // MARK: - User-specific Operations
    
    func getUser(by id: String) async throws -> User? {
        print("🔄 Getting user by id from API: \(id)")
        try validateUserId(id)
        
        do {
            let response = try await userAPI.getUserProfile(userId: id)
            let profile = response.data
            let mappedGender = profile.gender.flatMap { Gender(rawValue: $0) }
            let user = User(
                id: profile.id,
                name: profile.name,
                email: profile.email,
                profileImageURL: profile.avatar,
                gender: mappedGender
            )
            return user
        } catch let apiError as APIError {
            if case .serverError(let code) = apiError, code == 404 {
                print("API error while getting user: Not Found (404) – 將視為無資料並嘗試建立新檔案")
                return nil
            }
            print("API error while getting user: \(apiError)")
            throw AppError.apiError(apiError)
        } catch {
            print("API error while getting user (unknown): \(error)")
            throw AppError.apiError(error)
        }
    }
    
    func findByEmail(_ email: String) async throws -> User? {
        print("🔄 Finding user by email from API: \(email)")
        // TODO: API does not support findByEmail yet.
        throw AppError.apiError(NSError(domain: "UserRepository", code: -1, userInfo: [NSLocalizedDescriptionKey: "Find by email functionality not implemented"]))
    }
    
    func updateRatingProgress(userId: String, progress: RatingProgress) async throws {
        print("🔄 Updating rating progress for user via API: \(userId)")
        try validateUserId(userId)
        
        do {
            let progressDict = try progress.toDictionary()
            try await apiClient.performRequest(
                endpoint: "/users/\(userId)/rating-progress",
                method: .PUT,
                body: progressDict
            )
        } catch {
            throw AppError.apiError(error)
        }
    }
    
    func getUserPreferences(userId: String) async throws -> UserPreferences? {
        print("🔄 Getting user preferences from API: \(userId)")
        try validateUserId(userId)
        
        do {
            return try await apiClient.performRequest(
                endpoint: "/users/\(userId)/preferences",
                method: .GET,
                responseType: UserPreferences.self
            )
        } catch {
            print("API error while getting user preferences: \(error)")
            return nil
        }
    }
    
    func updateUserPreferences(_ preferences: UserPreferences) async throws {
        print("🔄 Updating user preferences via API: \(preferences.userId)")
        try validateUserId(preferences.userId)
        
        do {
            let preferencesDict = try preferences.toDictionary()
            try await apiClient.performRequest(
                endpoint: "/users/\(preferences.userId)/preferences",
                method: .PUT,
                body: preferencesDict
            )
        } catch {
            throw AppError.apiError(error)
        }
    }
    
    // MARK: - User Profile Management
    
    func createOrUpdateUserProfile(_ user: User) async throws -> User {
        print("🔄 Creating or updating user profile via API: \(user.id)")
        if try await userExists(id: user.id) {
            return try await update(user)
        } else {
            return try await create(user)
        }
    }
    
    func userExists(id: String) async throws -> Bool {
        print("🔄 Checking if user exists via API: \(id)")
        try validateUserId(id)
        
        if let _ = try await getUser(by: id) {
            return true
        }
        return false
    }
    
    // Removed updateLastActivity API call as endpoint doesn't exist in backend
}

// MARK: - Codable Helper
extension Encodable {
    func toDictionary() throws -> [String: Any]? {
        let data = try JSONEncoder().encode(self)
        let dictionary = try JSONSerialization.jsonObject(with: data, options: .allowFragments) as? [String: Any]
        return dictionary
    }
}
