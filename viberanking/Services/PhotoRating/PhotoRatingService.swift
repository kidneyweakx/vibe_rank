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
    private let firebaseService = FirebaseService.shared
    @Published var isLoading = false
    @Published var error: AppError?
    
    // Cache for photos to improve performance
    private var photosCache: [Photo] = []
    private var lastFetchTime: Date?
    private let cacheExpirationTime: TimeInterval = 300 // 5 minutes
    
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
            
            // Simulate Firebase Firestore query
            // In real implementation, this would query Firestore:
            // let query = firebaseService.photosCollection
            //     .whereField("userId", isNotEqualTo: userId)
            //     .order(by: "uploadedAt", descending: true)
            //     .limit(to: 50)
            
            let photos = try await simulateFetchPhotos(excludingUserId: userId)
            
            // Update cache
            photosCache = photos
            lastFetchTime = Date()
            
            return photos
            
        } catch {
            let appError = AppError.networkError(error)
            self.error = appError
            throw appError
        }
    }
    
    /// Submit a rating for a photo
    func submitRating(_ rating: Rating) async throws {
        isLoading = true
        defer { isLoading = false }
        
        do {
            // Simulate Firebase Firestore write
            // In real implementation:
            // try await firebaseService.ratingsCollection.document(rating.id).setData(from: rating)
            // Also update the photo's ratings array and statistics
            
            try await simulateSubmitRating(rating)
            
            // Update local cache if photo exists
            if let photoIndex = photosCache.firstIndex(where: { $0.id == rating.photoId }) {
                photosCache[photoIndex].addRating(rating)
            }
            
        } catch {
            let appError = AppError.networkError(error)
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
            
            // Simulate Firebase Firestore write
            // In real implementation:
            // try await firebaseService.usersCollection
            //     .document(preferences.userId)
            //     .collection("preferences")
            //     .document("current")
            //     .setData(from: preferences)
            
            try await simulateUpdatePreferences(preferences)
            
        } catch {
            let appError = AppError.networkError(error)
            self.error = appError
            throw appError
        }
    }
}

// MARK: - Private Helper Methods
private extension PhotoRatingService {
    
    /// Simulate fetching photos from Firestore
    func simulateFetchPhotos(excludingUserId: String) async throws -> [Photo] {
        // Simulate network delay
        try await Task.sleep(nanoseconds: 500_000_000)
        
        // Generate sample photos for testing
        var samplePhotos: [Photo] = []
        
        for i in 1...20 {
            let photo = Photo(
                id: "photo_\(i)",
                userId: "user_\(i % 5 + 1)", // Distribute among 5 different users
                imageURL: "https://example.com/photo_\(i).webp",
                dateTaken: Date().addingTimeInterval(-Double.random(in: 3600...86400)), // Random time within 24 hours
                metadata: PhotoMetadata(
                    dateTaken: Date().addingTimeInterval(-Double.random(in: 3600...86400)),
                    cameraModel: "iPhone 15 Pro"
                )
            )
            samplePhotos.append(photo)
        }
        
        // Filter out the current user's photos
        return samplePhotos.filter { $0.userId != excludingUserId }
    }
    
    /// Simulate submitting a rating to Firestore
    func simulateSubmitRating(_ rating: Rating) async throws {
        // Simulate network delay
        try await Task.sleep(nanoseconds: 200_000_000)
        
        // In real implementation, this would:
        // 1. Add rating to ratings collection
        // 2. Update photo's ratings array
        // 3. Recalculate photo's average score
        // 4. Update user's rating progress
        
        print("Rating submitted: Photo \(rating.photoId) rated \(rating.isHot ? "Hot" : "Not") by user \(rating.raterId)")
    }
    
    /// Simulate updating user preferences in Firestore
    func simulateUpdatePreferences(_ preferences: UserPreferences) async throws {
        // Simulate network delay
        try await Task.sleep(nanoseconds: 200_000_000)
        
        print("User preferences updated for user \(preferences.userId)")
        print("Total ratings given: \(preferences.totalRatingsGiven)")
        print("Hot rating percentage: \(preferences.hotRatingPercentage * 100)%")
    }
    
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
