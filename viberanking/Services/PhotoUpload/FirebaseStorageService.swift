//
//  FirebaseStorageService.swift
//  viberanking
//
//  Created by Kiro on 2025/07/23.
//

import Foundation
import FirebaseStorage
import FirebaseFirestore

// MARK: - Firebase Storage Service Protocol
protocol FirebaseStorageServiceProtocol {
    func uploadPhotoSizes(_ photoSizes: PhotoSizes, photoId: String) async throws -> PhotoURLs
    func deletePhoto(photoId: String) async throws
    func getDownloadURL(for path: String) async throws -> URL
    func uploadSingleFile(_ data: Data, to path: String) async throws -> URL
}

// MARK: - Photo URLs Structure
struct PhotoURLs: Codable {
    let thumbnail: String
    let preview: String
    let highRes: String
    
    init(thumbnail: URL, preview: URL, highRes: URL) {
        self.thumbnail = thumbnail.absoluteString
        self.preview = preview.absoluteString
        self.highRes = highRes.absoluteString
    }
}

// MARK: - Firebase Storage Service Implementation
class FirebaseStorageService: FirebaseStorageServiceProtocol {
    
    // MARK: - Properties
    private let storage = Storage.storage()
    private let maxRetryAttempts = AppConfiguration.Performance.maxRetryAttempts
    
    // MARK: - Public Methods
    
    /// Upload all photo sizes to Firebase Storage
    func uploadPhotoSizes(_ photoSizes: PhotoSizes, photoId: String) async throws -> PhotoURLs {
        async let thumbnailUpload = uploadWithRetry(
            data: photoSizes.thumbnail,
            path: "\(AppConfiguration.StoragePaths.photos)/\(photoId)/thumbnail.webp"
        )
        
        async let previewUpload = uploadWithRetry(
            data: photoSizes.preview,
            path: "\(AppConfiguration.StoragePaths.photos)/\(photoId)/preview.webp"
        )
        
        async let highResUpload = uploadWithRetry(
            data: photoSizes.highRes,
            path: "\(AppConfiguration.StoragePaths.photos)/\(photoId)/highres.webp"
        )
        
        // Wait for all uploads to complete
        let (thumbnailURL, previewURL, highResURL) = try await (thumbnailUpload, previewUpload, highResUpload)
        
        return PhotoURLs(thumbnail: thumbnailURL, preview: previewURL, highRes: highResURL)
    }
    
    /// Delete all files associated with a photo
    func deletePhoto(photoId: String) async throws {
        let storageRef = storage.reference()
        
        let filePaths = [
            "\(AppConfiguration.StoragePaths.photos)/\(photoId)/thumbnail.webp",
            "\(AppConfiguration.StoragePaths.photos)/\(photoId)/preview.webp",
            "\(AppConfiguration.StoragePaths.photos)/\(photoId)/highres.webp"
        ]
        
        // Delete all files concurrently
        try await withThrowingTaskGroup(of: Void.self) { group in
            for path in filePaths {
                group.addTask {
                    try await self.deleteFileWithRetry(path: path)
                }
            }
            
            // Wait for all deletions to complete
            for try await _ in group {}
        }
    }
    
    /// Get download URL for a specific path
    func getDownloadURL(for path: String) async throws -> URL {
        let storageRef = storage.reference().child(path)
        return try await storageRef.downloadURL()
    }
    
    /// Upload a single file to Firebase Storage
    func uploadSingleFile(_ data: Data, to path: String) async throws -> URL {
        return try await uploadWithRetry(data: data, path: path)
    }
}

// MARK: - Private Methods
private extension FirebaseStorageService {
    
    /// Upload data with retry mechanism
    func uploadWithRetry(data: Data, path: String) async throws -> URL {
        var lastError: Error?
        
        for attempt in 1...maxRetryAttempts {
            do {
                let storageRef = storage.reference().child(path)
                
                // Set metadata for WebP files
                let metadata = StorageMetadata()
                metadata.contentType = path.hasSuffix(".webp") ? "image/webp" : "image/jpeg"
                metadata.cacheControl = "public, max-age=31536000" // 1 year cache
                
                // Upload with metadata
                _ = try await storageRef.putDataAsync(data, metadata: metadata)
                
                // Get download URL
                let downloadURL = try await storageRef.downloadURL()
                
                print("Successfully uploaded \(path) on attempt \(attempt)")
                return downloadURL
                
            } catch {
                lastError = error
                print("Upload attempt \(attempt) failed for \(path): \(error)")
                
                if attempt < maxRetryAttempts {
                    // Exponential backoff
                    let delay = TimeInterval(pow(2.0, Double(attempt - 1)))
                    try await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
                }
            }
        }
        
        throw lastError ?? AppError.imageUploadFailed
    }
    
    /// Delete file with retry mechanism
    func deleteFileWithRetry(path: String) async throws {
        var lastError: Error?
        
        for attempt in 1...maxRetryAttempts {
            do {
                let storageRef = storage.reference().child(path)
                try await storageRef.delete()
                print("Successfully deleted \(path) on attempt \(attempt)")
                return
                
            } catch {
                lastError = error
                print("Delete attempt \(attempt) failed for \(path): \(error)")
                
                // If file doesn't exist, consider it successful
                if let storageError = error as NSError?,
                   storageError.code == StorageErrorCode.objectNotFound.rawValue {
                    return
                }
                
                if attempt < maxRetryAttempts {
                    // Exponential backoff
                    let delay = TimeInterval(pow(2.0, Double(attempt - 1)))
                    try await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
                }
            }
        }
        
        throw lastError ?? AppError.imageUploadFailed
    }
}

// MARK: - Firebase Storage Extensions
private extension StorageReference {
    func putDataAsync(_ data: Data, metadata: StorageMetadata?) async throws -> StorageMetadata {
        return try await withCheckedThrowingContinuation { continuation in
            self.putData(data, metadata: metadata) { metadata, error in
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