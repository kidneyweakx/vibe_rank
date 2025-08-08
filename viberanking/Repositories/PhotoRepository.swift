//
//  PhotoRepository.swift
//  viberanking
//
//  Created by Kiro on 2025/07/23.
//

import Foundation

// MARK: - Photo Repository Implementation
class PhotoRepository: PhotoRepositoryProtocol {
    private let apiClient = APIClient.shared
    
    // MARK: - CRUD Operations
    func create(_ entity: Photo) async throws -> Photo {
        print("🔄 Creating photo record via API: \(entity.id)")
        do {
            let photoDict = try entity.toDictionary()
            return try await apiClient.performRequest(
                endpoint: "/photos",
                method: .POST,
                body: photoDict,
                responseType: Photo.self
            )
        } catch {
            throw AppError.apiError(error)
        }
    }
    
    func read(id: String) async throws -> Photo? {
        print("🔄 Getting photo by id from API: \(id)")
        do {
            return try await apiClient.performRequest(
                endpoint: "/photos/\(id)",
                method: .GET,
                responseType: Photo.self
            )
        } catch {
            print("API error while getting photo: \(error)")
            return nil
        }
    }
    
    func update(_ entity: Photo) async throws -> Photo {
        print("🔄 Updating photo record via API: \(entity.id)")
        do {
            let photoDict = try entity.toDictionary()
            return try await apiClient.performRequest(
                endpoint: "/photos/\(entity.id)",
                method: .PUT,
                body: photoDict,
                responseType: Photo.self
            )
        } catch {
            throw AppError.apiError(error)
        }
    }
    
    func delete(id: String) async throws {
        print("🔄 Deleting photo record via API: \(id)")
        do {
            try await apiClient.performRequest(
                endpoint: "/photos/\(id)",
                method: .DELETE
            )
        } catch {
            throw AppError.apiError(error)
        }
    }
    
    func list(limit: Int? = 20, offset: Int? = nil) async throws -> [Photo] {
        print("🔄 Listing photos from API with limit: \(limit ?? 20)")
        // TODO: API does not support pagination yet.
        throw AppError.apiError(NSError(domain: "PhotoRepository", code: -1, userInfo: [NSLocalizedDescriptionKey: "List functionality not implemented"]))
    }
    
    func getPhotosForRating(excludingUserId: String, limit: Int = 10) async throws -> [Photo] {
        print("🔄 Getting photos for rating from API, excluding user: \(excludingUserId)")
        do {
            return try await apiClient.performRequest(
                endpoint: "/photos/for-rating?excludeUser=\(excludingUserId)&limit=\(limit)",
                method: .GET,
                responseType: [Photo].self
            )
        } catch {
            throw AppError.apiError(error)
        }
    }
    
    func getPhotosByUser(userId: String) async throws -> [Photo] {
        print("🔄 Getting photos by user from API: \(userId)")
        do {
            return try await apiClient.performRequest(
                endpoint: "/users/\(userId)/photos",
                method: .GET,
                responseType: [Photo].self
            )
        } catch {
            throw AppError.apiError(error)
        }
    }
    
    func updatePhotoRatings(photoId: String, ratings: [Rating]) async throws {
        print("🔄 Updating photo ratings via API for photo: \(photoId)")
        do {
            let ratingsDict = try ratings.map { try $0.toDictionary() }
            try await apiClient.performRequest(
                endpoint: "/photos/\(photoId)/ratings",
                method: .PUT,
                body: ["ratings": ratingsDict]
            )
        } catch {
            throw AppError.apiError(error)
        }
    }

    // Note: The upload progress methods are removed as they were part of the in-memory cache.
    // Real upload progress should be handled by the upload service itself.
    func getUploadProgress(photoId: String) async throws -> UploadProgress? {
        // This should be handled by a download/upload manager, not in the repository.
        return nil
    }
    
    func updateUploadProgress(_ progress: UploadProgress) async throws {
        // This should be handled by a download/upload manager, not in the repository.
    }
}
