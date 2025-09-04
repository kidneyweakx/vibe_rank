//
//  PhotoRatingService.swift
//  viberanking
//
//  Created by Kiro on 2025/07/23.
//

import Foundation
import Combine

// MARK: - Photo Rating Service Implementation
@MainActor
class PhotoRatingService: ObservableObject, PhotoRatingServiceProtocol {
    
    // MARK: - Properties
    private let apiClient = APIClient.shared
    
    @Published var isLoading = false
    @Published var error: AppError?
    
    // Cache for photos to improve performance
    private var photosCache: [Photo] = []
    private var lastFetchTime: Date?
    private let cacheExpirationTime: TimeInterval = 300 // 5 minutes
    
    // Removed sample photo fallback
    
    // MARK: - PhotoRatingServiceProtocol Implementation
    
    /// Fetch photos for rating, excluding the current user's photos
    func fetchPhotosForRating(excludingUser userId: String) async throws -> [Photo] {
        isLoading = true
        defer { isLoading = false }
        
        do {
            // Check cache first
            if let lastFetch = lastFetchTime,
               Date().timeIntervalSince(lastFetch) < cacheExpirationTime,
               !photosCache.isEmpty {
                return photosCache.filter { $0.userId != userId }
            }
            
            let photos = try await apiClient.performRequest(
                endpoint: "/photos/for-rating?excludeUserId=\(userId)&limit=50",
                method: .GET,
                responseType: [Photo].self
            )
            
            // If no real photos available, return empty and let UI show warning
            if photos.isEmpty { return [] }
            
            // Update cache with real photos
            photosCache = photos
            lastFetchTime = Date()
            
            return photos
            
        } catch {
            let appError = AppError.apiError(error)
            self.error = appError
            throw appError
        }
    }
    
    /// Submit a rating for a photo
    func submitRating(_ rating: Rating) async throws {
        isLoading = true
        defer { isLoading = false }
        
        do {
            // Check if this is a sample photo
            let isSamplePhoto = rating.photoId.hasPrefix("sample_")
            
            if !isSamplePhoto {
                // Only save to API if it's a real photo
                let ratingDict = try rating.toDictionary()
                _ = try await apiClient.performRequest(
                    endpoint: "/ratings",
                    method: .POST,
                    body: ratingDict ?? [:],
                    responseType: Rating.self
                )
            } else {
                print("📝 Rating submitted for sample photo: \(rating.photoId)")
                // For sample photos, we just update the local cache
            }
            
            // Update local cache if photo exists
            if let photoIndex = photosCache.firstIndex(where: { $0.id == rating.photoId }) {
                photosCache[photoIndex].addRating(rating)
            }
            
        } catch {
            let appError = AppError.apiError(error)
            self.error = appError
            throw appError
        }
    }
    
    /// Update user preferences based on their rating history
    func updateUserPreferences(from ratings: [Rating]) async throws {
        isLoading = true
        defer { isLoading = false }
        
        do {
            guard let firstRating = ratings.first else { return }
            
            var preferences = UserPreferences(userId: firstRating.raterId)
            
            // Update preferences based on ratings
            for rating in ratings {
                preferences.updateWithRating(rating)
            }
            
            // Analyze style preferences based on rated photos
            try await analyzeStylePreferences(for: &preferences, from: ratings)
            
            let preferencesDict = try preferences.toDictionary()
            _ = try await apiClient.performRequest(
                endpoint: "/users/\(preferences.userId)/preferences",
                method: .PUT,
                body: preferencesDict ?? [:],
                responseType: UserPreferences.self
            )
            
        } catch {
            let appError = AppError.apiError(error)
            self.error = appError
            throw appError
        }
    }
}

// MARK: - Private Helper Methods
private extension PhotoRatingService {
    
    /// Analyze style preferences based on rated photos
    func analyzeStylePreferences(for preferences: inout UserPreferences, from ratings: [Rating]) async throws {
        // This would analyze the photos that were rated positively
        // and extract style information to build user preferences
        
        let hotRatings = ratings.filter { $0.isHot }
        
        // Simulate style analysis
        if hotRatings.count > 0 {
            // In real implementation, this would analyze the actual photos
            // For now, simulate some style preferences
            preferences.updateStylePreference(for: "elegant", score: 0.7)
            preferences.updateStylePreference(for: "casual", score: 0.3)
            preferences.updateStylePreference(for: "trendy", score: 0.8)
        }
    }
}

// MARK: - Cache Management
extension PhotoRatingService {
    
    /// Clear the photos cache
    func clearCache() {
        photosCache.removeAll()
        lastFetchTime = nil
    }
    
    /// Get cached photos count
    var cachedPhotosCount: Int {
        return photosCache.count
    }
    
    /// Check if cache is valid
    var isCacheValid: Bool {
        guard let lastFetch = lastFetchTime else { return false }
        return Date().timeIntervalSince(lastFetch) < cacheExpirationTime
    }
}
