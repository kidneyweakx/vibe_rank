//
//  RepositoryProtocols.swift
//  viberanking
//
//  Created by Kiro on 2025/07/23.
//

import Foundation
import Combine

// MARK: - Base Repository Protocol
protocol BaseRepositoryProtocol {
    associatedtype Entity: Codable & Identifiable
    
    func create(_ entity: Entity) async throws -> Entity
    func read(id: String) async throws -> Entity?
    func update(_ entity: Entity) async throws -> Entity
    func delete(id: String) async throws
    func list(limit: Int?, offset: Int?) async throws -> [Entity]
}

// MARK: - User Repository Protocol
protocol UserRepositoryProtocol: BaseRepositoryProtocol where Entity == User {
    func getUser(by id: String) async throws -> User?
    func findByEmail(_ email: String) async throws -> User?
    func updateRatingProgress(userId: String, progress: RatingProgress) async throws
    func getUserPreferences(userId: String) async throws -> UserPreferences?
    func updateUserPreferences(_ preferences: UserPreferences) async throws
}

// MARK: - Photo Repository Protocol
protocol PhotoRepositoryProtocol: BaseRepositoryProtocol where Entity == Photo {
    func getPhotosForRating(excludingUserId: String, limit: Int) async throws -> [Photo]
    func getPhotosByUser(userId: String) async throws -> [Photo]
    func updatePhotoRatings(photoId: String, ratings: [Rating]) async throws
    func getUploadProgress(photoId: String) async throws -> UploadProgress?
    func updateUploadProgress(_ progress: UploadProgress) async throws
}

// MARK: - Rating Repository Protocol
protocol RatingRepositoryProtocol: BaseRepositoryProtocol where Entity == Rating {
    func getRatingsByPhoto(photoId: String) async throws -> [Rating]
    func getRatingsByUser(userId: String) async throws -> [Rating]
    func hasUserRatedPhoto(userId: String, photoId: String) async throws -> Bool
}
