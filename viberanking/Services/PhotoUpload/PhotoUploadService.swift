//
//  PhotoUploadService.swift
//  viberanking
//
//  Created by Kiro on 2025/07/23.
//

import Foundation
import SwiftUI
import UniformTypeIdentifiers

// MARK: - Photo Upload Service Implementation
@MainActor
class PhotoUploadService: PhotoUploadServiceProtocol {
    
    // MARK: - Dependencies
    private let storageService: R2StorageServiceProtocol
    private let webpConverter = WebPConverter.shared
    
    // MARK: - Upload Management
    private var activeUploads: [String: UploadTask] = [:]
    
    // MARK: - Initialization
    init(storageService: R2StorageServiceProtocol = R2StorageService()) {
        self.storageService = storageService
    }
    
    // MARK: - Public Methods
    
    /// Upload photo with WebP conversion
    func uploadPhoto(_ image: UIImage, for userId: String) async throws -> Photo {
        let photoId = UUID().uuidString
        let uploadTask = UploadTask(photoId: photoId, userId: userId)
        activeUploads[photoId] = uploadTask
        
        do {
            // Step 1: Generate photo sizes with WebP conversion
            updateUploadStatus(photoId: photoId, status: .processing)
            guard let imageData = image.pngData() else {
                throw AppError.invalidImageFormat
            }
            let photoSizes = try await generateThumbnails(imageData)
            
            // Step 2: Upload to R2 Storage
            updateUploadStatus(photoId: photoId, status: .uploading(progress: 0.0))
            let photoURLs = try await storageService.uploadPhotoSizes(photoSizes, photoId: photoId)
            
            // Step 3: Create Photo object
            let photo = Photo(
                id: photoId,
                userId: userId,
                imageURL: photoURLs
            )
            
            // Step 4: Complete upload
            updateUploadStatus(photoId: photoId, status: .completed)
            activeUploads.removeValue(forKey: photoId)
            
            return photo
            
        } catch {
            updateUploadStatus(photoId: photoId, status: .failed(error))
            activeUploads.removeValue(forKey: photoId)
            throw error
        }
    }
    
    /// Convert image to WebP format using WebPConverter
    func convertToWebP(_ imageData: Data, quality: Float) async throws -> Data {
        return try await webpConverter.convertToWebP(imageData, quality: quality)
    }

    /// Get upload progress for a photo
    func getUploadProgress(for photoId: String) -> UploadProgress {
        if let task = activeUploads[photoId] {
            return UploadProgress(photoId: photoId, status: task.status, progress: task.progress)
        }
        return UploadProgress(photoId: photoId, status: .pending, progress: 0.0)
    }
    
    /// Get upload statuses for multiple photos
    func getUploadStatuses(for photoIds: [String]) -> [String: UploadProgress] {
        var statuses: [String: UploadProgress] = [:]
        for photoId in photoIds {
            statuses[photoId] = getUploadProgress(for: photoId)
        }
        return statuses
    }
    
    /// Generate thumbnails at different sizes using WebP conversion
    func generateThumbnails(_ imageData: Data) async throws -> PhotoSizes {
        return try await webpConverter.generateThumbnails(imageData)
    }
    
    /// Cancel upload for a specific photo
    func cancelUpload(for photoId: String) async throws {
        if let _ = activeUploads[photoId] {
            updateUploadStatus(photoId: photoId, status: .cancelled)
            activeUploads.removeValue(forKey: photoId)
            
            // Attempt to delete any partially uploaded files
            try await storageService.deletePhoto(photoId: photoId)
        }
    }
}

// MARK: - Private Methods
private extension PhotoUploadService {
    
    /// Update upload status for tracking
    func updateUploadStatus(photoId: String, status: UploadStatus) {
        if var uploadTask = activeUploads[photoId] {
            uploadTask.status = status
            
            switch status {
            case .uploading(let progress):
                uploadTask.progress = progress
            case .completed:
                uploadTask.progress = 1.0
            default:
                break
            }
            
            activeUploads[photoId] = uploadTask
        }
    }
}
