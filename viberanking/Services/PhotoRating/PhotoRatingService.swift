//
//  PhotoRatingService.swift
//  viberanking
//
//  Created by Kiro on 2025/07/23.
//

import Foundation
import Combine
import FirebaseFirestore

// MARK: - Photo Rating Service Implementation
@MainActor
class PhotoRatingService: ObservableObject, PhotoRatingServiceProtocol {
    
    // MARK: - Properties
    private let db = Firestore.firestore()
    private var photosCollection: CollectionReference {
        return db.collection("photos")
    }
    private var ratingsCollection: CollectionReference {
        return db.collection("ratings")
    }
    private var usersCollection: CollectionReference {
        return db.collection("users")
    }
    
    @Published var isLoading = false
    @Published var error: AppError?
    
    // Cache for photos to improve performance
    private var photosCache: [Photo] = []
    private var lastFetchTime: Date?
    private let cacheExpirationTime: TimeInterval = 300 // 5 minutes
    
    // Sample photo service for fallback
    private let samplePhotoService = SamplePhotoService()
    
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
            
            let query = photosCollection
                .whereField("userId", isNotEqualTo: userId)
                .order(by: "uploadedAt", descending: true)
                .limit(to: 50)
            
            let snapshot = try await query.getDocuments()
            let photos = try snapshot.documents.compactMap { try $0.data(as: Photo.self) }
            
            // If no real photos available, use sample photos
            if photos.isEmpty {
                print("📸 No real photos found, using sample photos for rating")
                let samplePhotos = try await samplePhotoService.getSamplePhotos()
                
                // Update cache with sample photos
                photosCache = samplePhotos
                lastFetchTime = Date()
                
                return samplePhotos.filter { $0.userId != userId }
            }
            
            // Update cache with real photos
            photosCache = photos
            lastFetchTime = Date()
            
            return photos
            
        } catch {
            // If Firebase fails, try to use sample photos as fallback
            print("⚠️ Firebase error, falling back to sample photos: \(error.localizedDescription)")
            
            do {
                let samplePhotos = try await samplePhotoService.getSamplePhotos()
                return samplePhotos.filter { $0.userId != userId }
            } catch {
                let appError = AppError.firebaseError(.firestoreError(error.localizedDescription))
                self.error = appError
                throw appError
            }
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
                // Only save to Firebase if it's a real photo
                try await ratingsCollection.document(rating.id).setData(from: rating)
            } else {
                print("📝 Rating submitted for sample photo: \(rating.photoId)")
                // For sample photos, we just update the local cache
            }
            
            // Update local cache if photo exists
            if let photoIndex = photosCache.firstIndex(where: { $0.id == rating.photoId }) {
                photosCache[photoIndex].addRating(rating)
            }
            
        } catch {
            let appError = AppError.firebaseError(.firestoreError(error.localizedDescription))
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
            
            try await usersCollection
                .document(preferences.userId)
                .collection("preferences")
                .document("current")
                .setData(from: preferences)
            
        } catch {
            let appError = AppError.firebaseError(.firestoreError(error.localizedDescription))
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
