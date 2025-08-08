//
//  RatingRepository.swift
//  viberanking
//
//  Created by Kiro on 2025/07/23.
//

import Foundation

// MARK: - Rating Repository Implementation
class RatingRepository: RatingRepositoryProtocol {
    private let apiClient = APIClient.shared
    
    // MARK: - CRUD Operations
    func create(_ entity: Rating) async throws -> Rating {
        print("🔄 Creating rating via API: \(entity.id)")
        do {
            let ratingDict = try entity.toDictionary()
            return try await apiClient.performRequest(
                endpoint: "/ratings",
                method: .POST,
                body: ratingDict,
                responseType: Rating.self
            )
        } catch {
            throw AppError.apiError(error)
        }
    }
    
    func read(id: String) async throws -> Rating? {
        print("🔄 Reading rating via API: \(id)")
        do {
            return try await apiClient.performRequest(
                endpoint: "/ratings/\(id)",
                method: .GET,
                responseType: Rating.self
            )
        } catch {
            print("API error while getting rating: \(error)")
            return nil
        }
    }
    
    func update(_ entity: Rating) async throws -> Rating {
        print("🔄 Updating rating via API: \(entity.id)")
        do {
            let ratingDict = try entity.toDictionary()
            return try await apiClient.performRequest(
                endpoint: "/ratings/\(entity.id)",
                method: .PUT,
                body: ratingDict,
                responseType: Rating.self
            )
        } catch {
            throw AppError.apiError(error)
        }
    }
    
    func delete(id: String) async throws {
        print("🔄 Deleting rating via API: \(id)")
        do {
            try await apiClient.performRequest(
                endpoint: "/ratings/\(id)",
                method: .DELETE
            )
        } catch {
            throw AppError.apiError(error)
        }
    }
    
    func list(limit: Int? = 20, offset: Int? = nil) async throws -> [Rating] {
        print("🔄 Listing ratings from API with limit: \(limit ?? 20)")
        // TODO: API does not support pagination yet.
        throw AppError.apiError(NSError(domain: "RatingRepository", code: -1, userInfo: [NSLocalizedDescriptionKey: "List functionality not implemented"]))
    }
    
    // MARK: - Rating-specific Operations
    func getRatingsByPhoto(photoId: String) async throws -> [Rating] {
        print("🔄 Getting ratings for photo from API: \(photoId)")
        do {
            return try await apiClient.performRequest(
                endpoint: "/photos/\(photoId)/ratings",
                method: .GET,
                responseType: [Rating].self
            )
        } catch {
            throw AppError.apiError(error)
        }
    }
    
    func getRatingsByUser(userId: String) async throws -> [Rating] {
        print("🔄 Getting ratings by user from API: \(userId)")
        do {
            return try await apiClient.performRequest(
                endpoint: "/users/\(userId)/ratings",
                method: .GET,
                responseType: [Rating].self
            )
        } catch {
            throw AppError.apiError(error)
        }
    }
    
    func hasUserRatedPhoto(userId: String, photoId: String) async throws -> Bool {
        print("🔄 Checking if user \(userId) has rated photo \(photoId) via API")
        
        struct HasRatedResponse: Codable {
            let hasRated: Bool
        }

        do {
            let response = try await apiClient.performRequest(
                endpoint: "/ratings/has-rated?userId=\(userId)&photoId=\(photoId)",
                method: .GET,
                responseType: HasRatedResponse.self
            )
            return response.hasRated
        } catch {
            // If the API fails, we might assume the user hasn't rated, to be safe.
            // Or we could re-throw the error to let the caller decide.
            print("API error while checking if user has rated photo: \(error)")
            throw AppError.apiError(error)
        }
    }
}
