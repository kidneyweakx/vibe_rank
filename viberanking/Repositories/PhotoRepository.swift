//
//  PhotoRepository.swift
//  viberanking
//
//  Created by Kiro on 2025/07/23.
//

import Foundation

// MARK: - Photo Repository Implementation
class PhotoRepository: PhotoRepositoryProtocol {
    // In-memory cache for offline support
    private var photosCache: [String: Photo] = [:]
    private var userPhotosCache: [String: [Photo]] = [:]
    private var uploadProgressCache: [String: UploadProgress] = [:]
    
    // MARK: - CRUD Operations
    func create(_ entity: Photo) async throws -> Photo {
        photosCache[entity.id] = entity
        updateUserPhotosCache(entity)
        return entity
    }
    
    func read(id: String) async throws -> Photo? {
        return photosCache[id]
    }
    
    func update(_ entity: Photo) async throws -> Photo {
        photosCache[entity.id] = entity
        updateUserPhotosCache(entity)
        return entity
    }
    
    func delete(id: String) async throws {
        if let photo = photosCache.removeValue(forKey: id) {
            removeFromUserPhotosCache(photo)
        }
    }
    
    func list(limit: Int? = 20, offset: Int? = nil) async throws -> [Photo] {
        let cachedPhotos = Array(photosCache.values)
            .sorted { $0.uploadedAt > $1.uploadedAt }
            .prefix(limit ?? 20)
        
        return Array(cachedPhotos)
    }
    
    func getPhotosForRating(excludingUserId: String, limit: Int = 10) async throws -> [Photo] {
        let cachedPhotos = Array(photosCache.values)
            .filter { $0.userId != excludingUserId }
            .sorted { $0.uploadedAt > $1.uploadedAt }
            .prefix(limit)
        
        if cachedPhotos.isEmpty {
            return generateSamplePhotos(excludingUserId: excludingUserId, limit: limit)
        }
        
        return Array(cachedPhotos)
    }
    
    func getPhotosByUser(userId: String) async throws -> [Photo] {
        if let cachedPhotos = userPhotosCache[userId] {
            return cachedPhotos
        }
        
        return generateSampleUserPhotos(for: userId)
    }
    
    func updatePhotoRatings(photoId: String, ratings: [Rating]) async throws {
        guard var photo = photosCache[photoId] else {
            throw AppError.photoNotFound
        }
        
        photo.ratings = ratings
        photo.totalRatings = ratings.count
        
        let hotRatings = ratings.filter { $0.isHot }.count
        photo.averageScore = ratings.isEmpty ? 0.0 : Double(hotRatings) / Double(ratings.count)
        
        _ = try await update(photo)
    }
    
    func getUploadProgress(photoId: String) async throws -> UploadProgress? {
        return uploadProgressCache[photoId]
    }
    
    func updateUploadProgress(_ progress: UploadProgress) async throws {
        uploadProgressCache[progress.photoId] = progress
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
            let urlString = "https://picsum.photos/400/400?random=\(i)"
            let url = URL(string: urlString)!
            let photoURLs = PhotoURLs(thumbnail: url, preview: url, highRes: url)
            
            let photo = Photo(
                id: "sample_photo_\(i)",
                userId: "sample_user_\(i)",
                imageURL: photoURLs
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
            let urlString = "https://picsum.photos/400/400?random=\(userId.hashValue + i)"
            let url = URL(string: urlString)!
            let photoURLs = PhotoURLs(thumbnail: url, preview: url, highRes: url)
            
            let photo = Photo(
                id: "user_photo_\(userId)_\(i)",
                userId: userId,
                imageURL: photoURLs
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
