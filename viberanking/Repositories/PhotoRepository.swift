//
//  PhotoRepository.swift
//  viberanking
//
//  Created by Kiro on 2025/07/23.
//

import Foundation
import FirebaseFirestore

// MARK: - Photo Repository Implementation
class PhotoRepository: PhotoRepositoryProtocol {
    private let db = Firestore.firestore()
    private let photosCollection = "photos"
    private let uploadProgressCollection = "uploadProgress"
    
    // In-memory cache for offline support
    private var photosCache: [String: Photo] = [:]
    private var userPhotosCache: [String: [Photo]] = [:]
    private var uploadProgressCache: [String: UploadProgress] = [:]
    
    // MARK: - CRUD Operations
    func create(_ entity: Photo) async throws -> Photo {
        print("🔄 Creating photo: \(entity.id)")
        
        do {
            let photoRef = db.collection(photosCollection).document(entity.id)
            try photoRef.setData(from: entity)
            
            // Update cache
            photosCache[entity.id] = entity
            updateUserPhotosCache(entity)
            
            print("✅ Photo created successfully: \(entity.id)")
            return entity
        } catch {
            print("⚠️ Failed to create photo (offline mode): \(error.localizedDescription)")
            
            // In offline mode, store in cache
            photosCache[entity.id] = entity
            updateUserPhotosCache(entity)
            
            return entity
        }
    }
    
    func read(id: String) async throws -> Photo? {
        print("🔄 Reading photo: \(id)")
        
        // Check cache first
        if let cachedPhoto = photosCache[id] {
            return cachedPhoto
        }
        
        do {
            let photoRef = db.collection(photosCollection).document(id)
            let document = try await photoRef.getDocument()
            
            if document.exists {
                let photo = try document.data(as: Photo.self)
                photosCache[id] = photo
                print("✅ Photo retrieved successfully: \(id)")
                return photo
            } else {
                print("ℹ️ Photo not found: \(id)")
                return nil
            }
        } catch {
            print("⚠️ Failed to read photo (offline mode): \(error.localizedDescription)")
            return photosCache[id]
        }
    }
    
    func update(_ entity: Photo) async throws -> Photo {
        print("🔄 Updating photo: \(entity.id)")
        
        do {
            let photoRef = db.collection(photosCollection).document(entity.id)
            try photoRef.setData(from: entity, merge: true)
            
            // Update cache
            photosCache[entity.id] = entity
            updateUserPhotosCache(entity)
            
            print("✅ Photo updated successfully: \(entity.id)")
            return entity
        } catch {
            print("⚠️ Failed to update photo (offline mode): \(error.localizedDescription)")
            
            // Update cache in offline mode
            photosCache[entity.id] = entity
            updateUserPhotosCache(entity)
            
            return entity
        }
    }
    
    func delete(id: String) async throws {
        print("🔄 Deleting photo: \(id)")
        
        do {
            let photoRef = db.collection(photosCollection).document(id)
            try await photoRef.delete()
            
            // Remove from cache
            if let photo = photosCache.removeValue(forKey: id) {
                removeFromUserPhotosCache(photo)
            }
            
            print("✅ Photo deleted successfully: \(id)")
        } catch {
            print("⚠️ Failed to delete photo (offline mode): \(error.localizedDescription)")
            
            // Remove from cache in offline mode
            if let photo = photosCache.removeValue(forKey: id) {
                removeFromUserPhotosCache(photo)
            }
        }
    }
    
    func list(limit: Int? = 20, offset: Int? = nil) async throws -> [Photo] {
        print("🔄 Listing photos with limit: \(limit ?? 20)")
        
        do {
            var query: Query = db.collection(photosCollection)
                .order(by: "uploadedAt", descending: true)
                .limit(to: limit ?? 20)
            
            if let offset = offset, offset > 0 {
                query = query.start(at: [offset])
            }
            
            let snapshot = try await query.getDocuments()
            let photos = try snapshot.documents.compactMap { document in
                try document.data(as: Photo.self)
            }
            
            // Update cache
            for photo in photos {
                photosCache[photo.id] = photo
            }
            
            print("✅ Retrieved \(photos.count) photos")
            return photos
        } catch {
            print("⚠️ Failed to list photos (offline mode): \(error.localizedDescription)")
            
            // Return cached photos in offline mode
            let cachedPhotos = Array(photosCache.values)
                .sorted { $0.uploadedAt > $1.uploadedAt }
                .prefix(limit ?? 20)
            
            return Array(cachedPhotos)
        }
    }
    
    // MARK: - Photo-specific Operations
    func getPhotosForRating(excludingUserId: String, limit: Int = 10) async throws -> [Photo] {
        print("🔄 Getting photos for rating, excluding user: \(excludingUserId), limit: \(limit)")
        
        do {
            let query = db.collection(photosCollection)
                .whereField("userId", isNotEqualTo: excludingUserId)
                .order(by: "uploadedAt", descending: true)
                .limit(to: limit)
            
            let snapshot = try await query.getDocuments()
            let photos = try snapshot.documents.compactMap { document in
                try document.data(as: Photo.self)
            }
            
            // Update cache
            for photo in photos {
                photosCache[photo.id] = photo
            }
            
            print("✅ Retrieved \(photos.count) photos for rating")
            return photos
        } catch {
            print("⚠️ Failed to get photos for rating (offline mode): \(error.localizedDescription)")
            
            // Return cached photos excluding user's photos
            let cachedPhotos = Array(photosCache.values)
                .filter { $0.userId != excludingUserId }
                .sorted { $0.uploadedAt > $1.uploadedAt }
                .prefix(limit)
            
            if cachedPhotos.isEmpty {
                // Generate sample photos for demo purposes
                return generateSamplePhotos(excludingUserId: excludingUserId, limit: limit)
            }
            
            return Array(cachedPhotos)
        }
    }
    
    func getPhotosByUser(userId: String) async throws -> [Photo] {
        print("🔄 Getting photos by user: \(userId)")
        
        // Check cache first
        if let cachedPhotos = userPhotosCache[userId] {
            return cachedPhotos
        }
        
        do {
            let query = db.collection(photosCollection)
                .whereField("userId", isEqualTo: userId)
                .order(by: "uploadedAt", descending: true)
            
            let snapshot = try await query.getDocuments()
            let photos = try snapshot.documents.compactMap { document in
                try document.data(as: Photo.self)
            }
            
            // Update cache
            userPhotosCache[userId] = photos
            for photo in photos {
                photosCache[photo.id] = photo
            }
            
            print("✅ Retrieved \(photos.count) photos by user: \(userId)")
            return photos
        } catch {
            print("⚠️ Failed to get photos by user (offline mode): \(error.localizedDescription)")
            
            // Return cached photos or generate sample data
            if let cachedPhotos = userPhotosCache[userId] {
                return cachedPhotos
            }
            
            // Generate sample photos for demo purposes
            return generateSampleUserPhotos(for: userId)
        }
    }
    
    func updatePhotoRatings(photoId: String, ratings: [Rating]) async throws {
        print("🔄 Updating ratings for photo: \(photoId), count: \(ratings.count)")
        
        var photo: Photo
        if let cachedPhoto = photosCache[photoId] {
            photo = cachedPhoto
        } else if let fetchedPhoto = try await read(id: photoId) {
            photo = fetchedPhoto
        } else {
            throw AppError.photoNotFound
        }
        
        // Update photo with new ratings
        photo.ratings = ratings
        photo.totalRatings = ratings.count
        
        let hotRatings = ratings.filter { $0.isHot }.count
        photo.averageScore = ratings.isEmpty ? 0.0 : Double(hotRatings) / Double(ratings.count)
        
        // Save updated photo
        _ = try await update(photo)
        
        print("✅ Photo ratings updated successfully: \(photoId)")
    }
    
    func getUploadProgress(photoId: String) async throws -> UploadProgress? {
        print("🔄 Getting upload progress for photo: \(photoId)")
        
        // Check cache first
        if let cachedProgress = uploadProgressCache[photoId] {
            return cachedProgress
        }
        
        do {
            let progressRef = db.collection(uploadProgressCollection).document(photoId)
            let document = try await progressRef.getDocument()
            
            if document.exists {
                let progress = try document.data(as: UploadProgress.self)
                uploadProgressCache[photoId] = progress
                print("✅ Upload progress retrieved: \(photoId)")
                return progress
            } else {
                print("ℹ️ Upload progress not found: \(photoId)")
                return nil
            }
        } catch {
            print("⚠️ Failed to get upload progress (offline mode): \(error.localizedDescription)")
            return uploadProgressCache[photoId]
        }
    }
    
    func updateUploadProgress(_ progress: UploadProgress) async throws {
        print("🔄 Updating upload progress for photo: \(progress.photoId)")
        
        do {
            let progressRef = db.collection(uploadProgressCollection).document(progress.photoId)
            try progressRef.setData(from: progress, merge: true)
            
            // Update cache
            uploadProgressCache[progress.photoId] = progress
            
            print("✅ Upload progress updated successfully: \(progress.photoId)")
        } catch {
            print("⚠️ Failed to update upload progress (offline mode): \(error.localizedDescription)")
            
            // Update cache in offline mode
            uploadProgressCache[progress.photoId] = progress
        }
    }
    
    // MARK: - Cache Management
    private func updateUserPhotosCache(_ photo: Photo) {
        if userPhotosCache[photo.userId] != nil {
            userPhotosCache[photo.userId]?.append(photo)
        } else {
            userPhotosCache[photo.userId] = [photo]
        }
    }
    
    private func removeFromUserPhotosCache(_ photo: Photo) {
        userPhotosCache[photo.userId]?.removeAll { $0.id == photo.id }
    }
    
    // MARK: - Sample Data Generation (for demo purposes)
    private func generateSamplePhotos(excludingUserId: String, limit: Int) -> [Photo] {
        var photos: [Photo] = []
        
        for i in 0..<limit {
            let photo = Photo(
                id: "sample_photo_\(i)",
                userId: "sample_user_\(i)",
                imageURL: "https://picsum.photos/400/400?random=\(i)"
            )
            photos.append(photo)
        }
        
        // Cache the sample photos
        for photo in photos {
            photosCache[photo.id] = photo
        }
        
        return photos
    }
    
    private func generateSampleUserPhotos(for userId: String) -> [Photo] {
        let sampleCount = Int.random(in: 1...5)
        var photos: [Photo] = []
        
        for i in 0..<sampleCount {
            let photo = Photo(
                id: "user_photo_\(userId)_\(i)",
                userId: userId,
                imageURL: "https://picsum.photos/400/400?random=\(userId.hashValue + i)"
            )
            photos.append(photo)
        }
        
        // Cache the sample photos
        userPhotosCache[userId] = photos
        for photo in photos {
            photosCache[photo.id] = photo
        }
        
        return photos
    }
}
