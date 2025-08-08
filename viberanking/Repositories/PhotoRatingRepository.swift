//
//  PhotoRatingRepository.swift
//  viberanking
//
//  Created by Kiro on 2025/07/23.
//

import Foundation
import Combine

// MARK: - Photo Rating Repository Implementation
@MainActor
class PhotoRatingRepository: ObservableObject {
    
    // MARK: - Properties
    private let apiClient = APIClient.shared
    
    @Published var isLoading = false
    @Published var error: AppError?
    
    // Local cache for better performance
    private var ratingsCache: [String: [Rating]] = [:] // photoId -> [Rating]
    private var userRatingsCache: [String: [Rating]] = [:] // userId -> [Rating]
    
    // MARK: - Photo Rating Operations
    
    /// Submit a new rating
    func submitRating(_ rating: Rating) async throws {
        isLoading = true
        defer { isLoading = false }
        
        do {
            // Check if user has already rated this photo
            if try await hasUserRatedPhoto(userId: rating.raterId, photoId: rating.photoId) {
                throw AppError.validationError("用戶已經評分過這張照片")
            }
            
            let ratingDict = try rating.toDictionary()
            _ = try await apiClient.performRequest(
                endpoint: "/ratings",
                method: .POST,
                body: ratingDict ?? [:],
                responseType: Rating.self
            )
            
            // Update local cache
            updateLocalCache(with: rating)
            
        } catch {
            let appError = error as? AppError ?? AppError.apiError(error)
            self.error = appError
            throw appError
        }
    }
    
    /// Get ratings for a specific photo
    func getRatingsByPhoto(photoId: String) async throws -> [Rating] {
        isLoading = true
        defer { isLoading = false }
        
        do {
            // Check cache first
            if let cachedRatings = ratingsCache[photoId] {
                return cachedRatings
            }
            
            let ratings = try await apiClient.performRequest(
                endpoint: "/photos/\(photoId)/ratings",
                method: .GET,
                responseType: [Rating].self
            )
            
            // Update cache
            ratingsCache[photoId] = ratings
            
            return ratings
            
        } catch {
            let appError = AppError.apiError(error)
            self.error = appError
            throw appError
        }
    }
    
    /// Get all ratings given by a specific user
    func getRatingsByUser(userId: String) async throws -> [Rating] {
        isLoading = true
        defer { isLoading = false }
        
        do {
            // Check cache first
            if let cachedRatings = userRatingsCache[userId] {
                return cachedRatings
            }
            
            let ratings = try await apiClient.performRequest(
                endpoint: "/users/\(userId)/ratings",
                method: .GET,
                responseType: [Rating].self
            )
            
            // Update cache
            userRatingsCache[userId] = ratings
            
            return ratings
            
        } catch {
            let appError = AppError.apiError(error)
            self.error = appError
            throw appError
        }
    }
    
    /// Check if a user has already rated a specific photo
    func hasUserRatedPhoto(userId: String, photoId: String) async throws -> Bool {
        do {
            struct HasRatedResponse: Codable {
                let hasRated: Bool
            }
            
            let response = try await apiClient.performRequest(
                endpoint: "/ratings/has-rated?userId=\(userId)&photoId=\(photoId)",
                method: .GET,
                responseType: HasRatedResponse.self
            )
            return response.hasRated
        } catch {
            throw error
        }
    }
    
    /// Get rating statistics for a photo
    func getRatingStatistics(photoId: String) async throws -> RatingStatistics {
        do {
            let ratings = try await getRatingsByPhoto(photoId: photoId)
            return RatingStatistics(from: ratings)
        } catch {
            throw error
        }
    }
    
    /// Get user's rating progress
    func getUserRatingProgress(userId: String) async throws -> UserRatingProgress {
        do {
            let userRatings = try await getRatingsByUser(userId: userId)
            return UserRatingProgress(from: userRatings)
        } catch {
            throw error
        }
    }
}

// MARK: - Private Helper Methods
private extension PhotoRatingRepository {
    
    /// Update local cache with new rating
    func updateLocalCache(with rating: Rating) {
        // Update photo ratings cache
        if ratingsCache[rating.photoId] != nil {
            ratingsCache[rating.photoId]?.append(rating)
        }
        
        // Update user ratings cache
        if userRatingsCache[rating.raterId] != nil {
            userRatingsCache[rating.raterId]?.append(rating)
        }
    }
}

// MARK: - Cache Management
extension PhotoRatingRepository {
    
    /// Clear all caches
    func clearCache() {
        ratingsCache.removeAll()
        userRatingsCache.removeAll()
    }
    
    /// Clear cache for specific photo
    func clearPhotoCache(photoId: String) {
        ratingsCache.removeValue(forKey: photoId)
    }
    
    /// Clear cache for specific user
    func clearUserCache(userId: String) {
        userRatingsCache.removeValue(forKey: userId)
    }
}

// MARK: - Supporting Models
struct RatingStatistics: Codable {
    let totalRatings: Int
    let hotRatings: Int
    let notRatings: Int
    let averageScore: Double
    let hotPercentage: Double
    
    init(from ratings: [Rating]) {
        self.totalRatings = ratings.count
        self.hotRatings = ratings.filter { $0.isHot }.count
        self.notRatings = ratings.filter { !$0.isHot }.count
        
        if totalRatings > 0 {
            self.averageScore = Double(hotRatings) / Double(totalRatings)
            self.hotPercentage = averageScore * 100
        } else {
            self.averageScore = 0.0
            self.hotPercentage = 0.0
        }
    }
}

struct UserRatingProgress: Codable {
    let totalRatingsGiven: Int
    let hotRatingsGiven: Int
    let notRatingsGiven: Int
    let hotRatingPercentage: Double
    let hasUnlockedUpload: Bool
    let remainingRatingsForUpload: Int
    
    private let requiredRatingsForUpload = 20
    
    init(from ratings: [Rating]) {
        self.totalRatingsGiven = ratings.count
        self.hotRatingsGiven = ratings.filter { $0.isHot }.count
        self.notRatingsGiven = ratings.filter { !$0.isHot }.count
        
        if totalRatingsGiven > 0 {
            self.hotRatingPercentage = (Double(hotRatingsGiven) / Double(totalRatingsGiven)) * 100
        } else {
            self.hotRatingPercentage = 0.0
        }
        
        self.hasUnlockedUpload = totalRatingsGiven >= requiredRatingsForUpload
        self.remainingRatingsForUpload = max(requiredRatingsForUpload - totalRatingsGiven, 0)
    }
}
