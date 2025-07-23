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
    private let firebaseService = FirebaseService.shared
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
            
            // Simulate Firestore write
            // In real implementation:
            // try await firebaseService.ratingsCollection.document(rating.id).setData(from: rating)
            
            try await simulateSubmitRating(rating)
            
            // Update local cache
            updateLocalCache(with: rating)
            
        } catch {
            let appError = error as? AppError ?? AppError.networkError(error)
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
            
            // Simulate Firestore query
            // In real implementation:
            // let query = firebaseService.ratingsCollection
            //     .whereField("photoId", isEqualTo: photoId)
            //     .order(by: "createdAt", descending: true)
            
            let ratings = try await simulateFetchRatingsByPhoto(photoId: photoId)
            
            // Update cache
            ratingsCache[photoId] = ratings
            
            return ratings
            
        } catch {
            let appError = AppError.networkError(error)
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
            
            // Simulate Firestore query
            // In real implementation:
            // let query = firebaseService.ratingsCollection
            //     .whereField("raterId", isEqualTo: userId)
            //     .order(by: "createdAt", descending: true)
            
            let ratings = try await simulateFetchRatingsByUser(userId: userId)
            
            // Update cache
            userRatingsCache[userId] = ratings
            
            return ratings
            
        } catch {
            let appError = AppError.networkError(error)
            self.error = appError
            throw appError
        }
    }
    
    /// Check if a user has already rated a specific photo
    func hasUserRatedPhoto(userId: String, photoId: String) async throws -> Bool {
        do {
            let userRatings = try await getRatingsByUser(userId: userId)
            return userRatings.contains { $0.photoId == photoId }
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
    
    /// Simulate submitting a rating to Firestore
    func simulateSubmitRating(_ rating: Rating) async throws {
        // Simulate network delay
        try await Task.sleep(nanoseconds: 300_000_000)
        
        // In real implementation, this would also:
        // 1. Update the photo document with new rating
        // 2. Recalculate photo statistics
        // 3. Update user's rating progress
        
        print("Rating submitted successfully: \(rating.id)")
    }
    
    /// Simulate fetching ratings by photo from Firestore
    func simulateFetchRatingsByPhoto(photoId: String) async throws -> [Rating] {
        // Simulate network delay
        try await Task.sleep(nanoseconds: 200_000_000)
        
        // Generate sample ratings for testing
        var ratings: [Rating] = []
        let ratingCount = Int.random(in: 5...25)
        
        for i in 1...ratingCount {
            let rating = Rating(
                id: "rating_\(photoId)_\(i)",
                photoId: photoId,
                raterId: "user_\(i % 10 + 1)",
                isHot: Bool.random()
            )
            ratings.append(rating)
        }
        
        return ratings
    }
    
    /// Simulate fetching ratings by user from Firestore
    func simulateFetchRatingsByUser(userId: String) async throws -> [Rating] {
        // Simulate network delay
        try await Task.sleep(nanoseconds: 200_000_000)
        
        // Generate sample user ratings for testing
        var ratings: [Rating] = []
        let ratingCount = Int.random(in: 10...50)
        
        for i in 1...ratingCount {
            let rating = Rating(
                id: "rating_\(userId)_\(i)",
                photoId: "photo_\(i % 20 + 1)",
                raterId: userId,
                isHot: Bool.random()
            )
            ratings.append(rating)
        }
        
        return ratings
    }
    
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