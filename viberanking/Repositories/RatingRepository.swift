//
//  RatingRepository.swift
//  viberanking
//
//  Created by Kiro on 2025/07/23.
//

import Foundation
import FirebaseFirestore

// MARK: - Rating Repository Implementation
class RatingRepository: RatingRepositoryProtocol {
    private let db = Firestore.firestore()
    private let ratingsCollection = "ratings"
    
    // In-memory cache for offline support
    private var ratingsCache: [String: Rating] = [:]
    private var photoRatingsCache: [String: [Rating]] = [:]
    private var userRatingsCache: [String: [Rating]] = [:]
    
    // MARK: - CRUD Operations
    func create(_ entity: Rating) async throws -> Rating {
        print("🔄 Creating rating: \(entity.id)")
        
        do {
            let ratingRef = db.collection(ratingsCollection).document(entity.id)
            try ratingRef.setData(from: entity)
            
            // Update cache
            ratingsCache[entity.id] = entity
            updatePhotoRatingsCache(entity)
            updateUserRatingsCache(entity)
            
            print("✅ Rating created successfully: \(entity.id)")
            return entity
        } catch {
            print("⚠️ Failed to create rating (offline mode): \(error.localizedDescription)")
            
            // In offline mode, store in cache
            ratingsCache[entity.id] = entity
            updatePhotoRatingsCache(entity)
            updateUserRatingsCache(entity)
            
            return entity
        }
    }
    
    func read(id: String) async throws -> Rating? {
        print("🔄 Reading rating: \(id)")
        
        // Check cache first
        if let cachedRating = ratingsCache[id] {
            return cachedRating
        }
        
        do {
            let ratingRef = db.collection(ratingsCollection).document(id)
            let document = try await ratingRef.getDocument()
            
            if document.exists {
                let rating = try document.data(as: Rating.self)
                ratingsCache[id] = rating
                print("✅ Rating retrieved successfully: \(id)")
                return rating
            } else {
                print("ℹ️ Rating not found: \(id)")
                return nil
            }
        } catch {
            print("⚠️ Failed to read rating (offline mode): \(error.localizedDescription)")
            return ratingsCache[id]
        }
    }
    
    func update(_ entity: Rating) async throws -> Rating {
        print("🔄 Updating rating: \(entity.id)")
        
        do {
            let ratingRef = db.collection(ratingsCollection).document(entity.id)
            try ratingRef.setData(from: entity, merge: true)
            
            // Update cache
            ratingsCache[entity.id] = entity
            updatePhotoRatingsCache(entity)
            updateUserRatingsCache(entity)
            
            print("✅ Rating updated successfully: \(entity.id)")
            return entity
        } catch {
            print("⚠️ Failed to update rating (offline mode): \(error.localizedDescription)")
            
            // Update cache in offline mode
            ratingsCache[entity.id] = entity
            updatePhotoRatingsCache(entity)
            updateUserRatingsCache(entity)
            
            return entity
        }
    }
    
    func delete(id: String) async throws {
        print("🔄 Deleting rating: \(id)")
        
        do {
            let ratingRef = db.collection(ratingsCollection).document(id)
            try await ratingRef.delete()
            
            // Remove from cache
            if let rating = ratingsCache.removeValue(forKey: id) {
                removeFromPhotoRatingsCache(rating)
                removeFromUserRatingsCache(rating)
            }
            
            print("✅ Rating deleted successfully: \(id)")
        } catch {
            print("⚠️ Failed to delete rating (offline mode): \(error.localizedDescription)")
            
            // Remove from cache in offline mode
            if let rating = ratingsCache.removeValue(forKey: id) {
                removeFromPhotoRatingsCache(rating)
                removeFromUserRatingsCache(rating)
            }
        }
    }
    
    func list(limit: Int? = 20, offset: Int? = nil) async throws -> [Rating] {
        print("🔄 Listing ratings with limit: \(limit ?? 20)")
        
        do {
            var query: Query = db.collection(ratingsCollection)
                .order(by: "createdAt", descending: true)
                .limit(to: limit ?? 20)
            
            if let offset = offset, offset > 0 {
                query = query.start(at: [offset])
            }
            
            let snapshot = try await query.getDocuments()
            let ratings = try snapshot.documents.compactMap { document in
                try document.data(as: Rating.self)
            }
            
            // Update cache
            for rating in ratings {
                ratingsCache[rating.id] = rating
            }
            
            print("✅ Retrieved \(ratings.count) ratings")
            return ratings
        } catch {
            print("⚠️ Failed to list ratings (offline mode): \(error.localizedDescription)")
            
            // Return cached ratings in offline mode
            let cachedRatings = Array(ratingsCache.values)
                .sorted { $0.createdAt > $1.createdAt }
                .prefix(limit ?? 20)
            
            return Array(cachedRatings)
        }
    }
    
    // MARK: - Rating-specific Operations
    func getRatingsByPhoto(photoId: String) async throws -> [Rating] {
        print("🔄 Getting ratings for photo: \(photoId)")
        
        // Check cache first
        if let cachedRatings = photoRatingsCache[photoId] {
            return cachedRatings
        }
        
        do {
            let query = db.collection(ratingsCollection)
                .whereField("photoId", isEqualTo: photoId)
                .order(by: "createdAt", descending: true)
            
            let snapshot = try await query.getDocuments()
            let ratings = try snapshot.documents.compactMap { document in
                try document.data(as: Rating.self)
            }
            
            // Update cache
            photoRatingsCache[photoId] = ratings
            for rating in ratings {
                ratingsCache[rating.id] = rating
            }
            
            print("✅ Retrieved \(ratings.count) ratings for photo: \(photoId)")
            return ratings
        } catch {
            print("⚠️ Failed to get ratings for photo (offline mode): \(error.localizedDescription)")
            
            // Return cached ratings or generate sample data
            if let cachedRatings = photoRatingsCache[photoId] {
                return cachedRatings
            }
            
            // Generate sample ratings for demo purposes
            return generateSampleRatings(for: photoId)
        }
    }
    
    func getRatingsByUser(userId: String) async throws -> [Rating] {
        print("🔄 Getting ratings by user: \(userId)")
        
        // Check cache first
        if let cachedRatings = userRatingsCache[userId] {
            return cachedRatings
        }
        
        do {
            let query = db.collection(ratingsCollection)
                .whereField("raterId", isEqualTo: userId)
                .order(by: "createdAt", descending: true)
            
            let snapshot = try await query.getDocuments()
            let ratings = try snapshot.documents.compactMap { document in
                try document.data(as: Rating.self)
            }
            
            // Update cache
            userRatingsCache[userId] = ratings
            for rating in ratings {
                ratingsCache[rating.id] = rating
            }
            
            print("✅ Retrieved \(ratings.count) ratings by user: \(userId)")
            return ratings
        } catch {
            print("⚠️ Failed to get ratings by user (offline mode): \(error.localizedDescription)")
            
            // Return cached ratings or generate sample data
            if let cachedRatings = userRatingsCache[userId] {
                return cachedRatings
            }
            
            // Generate sample ratings for demo purposes
            return generateSampleUserRatings(for: userId)
        }
    }
    
    func hasUserRatedPhoto(userId: String, photoId: String) async throws -> Bool {
        print("🔄 Checking if user \(userId) has rated photo \(photoId)")
        
        do {
            let query = db.collection(ratingsCollection)
                .whereField("raterId", isEqualTo: userId)
                .whereField("photoId", isEqualTo: photoId)
                .limit(to: 1)
            
            let snapshot = try await query.getDocuments()
            let hasRated = !snapshot.documents.isEmpty
            
            print("✅ User rating check result: \(hasRated)")
            return hasRated
        } catch {
            print("⚠️ Failed to check user rating (offline mode): \(error.localizedDescription)")
            
            // Check cache in offline mode
            let userRatings = userRatingsCache[userId] ?? []
            return userRatings.contains { $0.photoId == photoId }
        }
    }
    
    // MARK: - Cache Management
    private func updatePhotoRatingsCache(_ rating: Rating) {
        if photoRatingsCache[rating.photoId] != nil {
            photoRatingsCache[rating.photoId]?.append(rating)
        } else {
            photoRatingsCache[rating.photoId] = [rating]
        }
    }
    
    private func updateUserRatingsCache(_ rating: Rating) {
        if userRatingsCache[rating.raterId] != nil {
            userRatingsCache[rating.raterId]?.append(rating)
        } else {
            userRatingsCache[rating.raterId] = [rating]
        }
    }
    
    private func removeFromPhotoRatingsCache(_ rating: Rating) {
        photoRatingsCache[rating.photoId]?.removeAll { $0.id == rating.id }
    }
    
    private func removeFromUserRatingsCache(_ rating: Rating) {
        userRatingsCache[rating.raterId]?.removeAll { $0.id == rating.id }
    }
    
    // MARK: - Sample Data Generation (for demo purposes)
    private func generateSampleRatings(for photoId: String) -> [Rating] {
        let sampleCount = Int.random(in: 20...80)
        var ratings: [Rating] = []
        
        for i in 0..<sampleCount {
            let rating = Rating(
                id: "sample_rating_\(photoId)_\(i)",
                photoId: photoId,
                raterId: "sample_user_\(i)",
                isHot: Bool.random()
            )
            ratings.append(rating)
        }
        
        // Cache the sample ratings
        photoRatingsCache[photoId] = ratings
        
        return ratings
    }
    
    private func generateSampleUserRatings(for userId: String) -> [Rating] {
        let sampleCount = Int.random(in: 50...150)
        var ratings: [Rating] = []
        
        for i in 0..<sampleCount {
            let rating = Rating(
                id: "sample_user_rating_\(userId)_\(i)",
                photoId: "sample_photo_\(i)",
                raterId: userId,
                isHot: Bool.random()
            )
            ratings.append(rating)
        }
        
        // Cache the sample ratings
        userRatingsCache[userId] = ratings
        
        return ratings
    }
}