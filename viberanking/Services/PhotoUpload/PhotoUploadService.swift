//
//  PhotoUploadService.swift
//  viberanking
//
//  Created by Kiro on 2025/07/23.
//

import Foundation
import SwiftUI
import FirebaseStorage
import FirebaseFirestore
import UniformTypeIdentifiers

// MARK: - Photo Upload Service Implementation
@MainActor
class PhotoUploadService: PhotoUploadServiceProtocol {
    
    // MARK: - Dependencies
    private let storage = Storage.storage()
    private let firestore = Firestore.firestore()
    private let webpConverter = WebPConverter.shared
    
    // MARK: - Upload Management
    private var activeUploads: [String: UploadTask] = [:]
    
    // MARK: - Initialization
    init() {
        // No-op
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
            
            // Step 2: Upload to Firebase Storage
            updateUploadStatus(photoId: photoId, status: .uploading(progress: 0.0))
            let imageURL = try await uploadToFirebaseStorage(photoSizes: photoSizes, photoId: photoId)
            
            // Step 3: Create Photo object
            let photo = Photo(
                id: photoId,
                userId: userId,
                imageURL: imageURL
            )
            
            // Step 4: Save to Firestore
            try await savePhotoToFirestore(photo)
            
            // Step 5: Complete upload
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
    
    /// Generate thumbnails at different sizes using WebP conversion
    func generateThumbnails(_ imageData: Data) async throws -> PhotoSizes {
        return try await webpConverter.generateThumbnails(imageData)
    }
    
    /// Get upload progress for a photo
    func getUploadProgress(for photoId: String) async throws -> UploadProgress {
        let document = firestore.collection("uploadProgress").document(photoId)
        let snapshot = try await document.getDocument()
        
        if let data = snapshot.data(),
           let progress = try? Firestore.Decoder().decode(UploadProgress.self, from: data) {
            return progress
        } else {
            // Return default progress if not found
            return UploadProgress(photoId: photoId)
        }
    }
    
    /// Get upload statuses for multiple photos
    func getUploadStatuses(for photoIds: [String]) async throws -> [String: UploadProgress] {
        var statuses: [String: UploadProgress] = [:]
        
        // Use batch read for efficiency
        let documents = photoIds.map { firestore.collection("uploadProgress").document($0) }
        
        for document in documents {
            do {
                let snapshot = try await document.getDocument()
                if let data = snapshot.data(),
                   let progress = try? Firestore.Decoder().decode(UploadProgress.self, from: data) {
                    statuses[document.documentID] = progress
                } else {
                    statuses[document.documentID] = UploadProgress(photoId: document.documentID)
                }
            } catch {
                // Continue with other documents if one fails
                statuses[document.documentID] = UploadProgress(photoId: document.documentID)
            }
        }
        
        return statuses
    }
    
    /// Cancel upload for a specific photo
    func cancelUpload(for photoId: String) async throws {
        if let uploadTask = activeUploads[photoId] {
            updateUploadStatus(photoId: photoId, status: .cancelled)
            activeUploads.removeValue(forKey: photoId)
            
            // Attempt to delete any partially uploaded files
            try await cleanupPartialUpload(photoId: photoId)
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
    
    /// Upload photo sizes to Firebase Storage with progress tracking
    func uploadToFirebaseStorage(photoSizes: PhotoSizes, photoId: String) async throws -> String {
        let storageRef = storage.reference()
        
        // Upload thumbnail first (smallest file)
        updateUploadStatus(photoId: photoId, status: .uploading(progress: 0.1))
        let thumbnailRef = storageRef.child("photos/\(photoId)/thumbnail.webp")
        _ = try await thumbnailRef.putDataAsync(photoSizes.thumbnail)
        
        // Upload preview image
        updateUploadStatus(photoId: photoId, status: .uploading(progress: 0.4))
        let previewRef = storageRef.child("photos/\(photoId)/preview.webp")
        _ = try await previewRef.putDataAsync(photoSizes.preview)
        
        // Upload high resolution image (main image URL)
        updateUploadStatus(photoId: photoId, status: .uploading(progress: 0.7))
        let highResRef = storageRef.child("photos/\(photoId)/highres.webp")
        _ = try await highResRef.putDataAsync(photoSizes.highRes)
        let highResURL = try await highResRef.downloadURL()
        
        updateUploadStatus(photoId: photoId, status: .uploading(progress: 0.9))
        
        return highResURL.absoluteString
    }
    
    /// Save photo metadata to Firestore
    func savePhotoToFirestore(_ photo: Photo) async throws {
        let document = firestore.collection(AppConfiguration.Collections.photos).document(photo.id)
        let data = try Firestore.Encoder().encode(photo)
        try await document.setData(data)
        
        // Initialize upload progress
        let progress = UploadProgress(photoId: photo.id)
        let progressDocument = firestore.collection("uploadProgress").document(photo.id)
        let progressData = try Firestore.Encoder().encode(progress)
        try await progressDocument.setData(progressData)
    }
    
    /// Clean up partially uploaded files
    func cleanupPartialUpload(photoId: String) async throws {
        let storageRef = storage.reference()
        
        let filePaths = [
            "photos/\(photoId)/thumbnail.webp",
            "photos/\(photoId)/preview.webp",
            "photos/\(photoId)/highres.webp"
        ]
        
        for path in filePaths {
            do {
                try await storageRef.child(path).delete()
            } catch {
                // Continue cleanup even if some files fail to delete
                print("Failed to delete \(path): \(error)")
            }
        }
        
        // Remove from Firestore if it exists
        do {
            try await firestore.collection(AppConfiguration.Collections.photos).document(photoId).delete()
            try await firestore.collection("uploadProgress").document(photoId).delete()
        } catch {
            print("Failed to cleanup Firestore documents: \(error)")
        }
    }
}

// MARK: - Firebase Storage Extensions
private extension StorageReference {
    func putDataAsync(_ data: Data) async throws -> StorageMetadata {
        return try await withCheckedThrowingContinuation { continuation in
            self.putData(data, metadata: nil) { metadata, error in
                if let error = error {
                    continuation.resume(throwing: error)
                } else if let metadata = metadata {
                    continuation.resume(returning: metadata)
                } else {
                    continuation.resume(throwing: AppError.imageUploadFailed)
                }
            }
        }
    }
}
