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
    private let exifValidationService: EXIFValidationServiceProtocol
    
    // MARK: - Initialization
    nonisolated init(exifValidationService: EXIFValidationServiceProtocol) {
        self.exifValidationService = exifValidationService
    }
    
    convenience init() {
        self.init(exifValidationService: EXIFValidationService())
    }
    
    // MARK: - Public Methods
    
    /// Upload photo with EXIF validation and WebP conversion
    func uploadPhoto(_ imageData: Data, for userId: String) async throws -> Photo {
        // Step 1: Extract and validate EXIF data
        let metadata = try await exifValidationService.extractEXIFData(from: imageData)
        
        // Step 2: Validate photo freshness
        _ = try exifValidationService.validatePhotoFreshness(metadata)
        
        // Step 3: Check for screenshots
        _ = try exifValidationService.detectScreenshot(from: imageData)
        
        // Step 4: Sanitize EXIF data
        let sanitizedData = try await exifValidationService.sanitizeEXIFData(from: imageData)
        
        // Step 5: Generate photo sizes (WebP conversion will be implemented in task 4.2)
        let photoSizes = try await generateThumbnails(sanitizedData)
        
        // Step 6: Upload to Firebase Storage
        let photoId = UUID().uuidString
        let imageURL = try await uploadToFirebaseStorage(photoSizes: photoSizes, photoId: photoId)
        
        // Step 7: Create Photo object
        let photo = Photo(
            id: photoId,
            userId: userId,
            imageURL: imageURL,
            dateTaken: metadata.dateTaken,
            metadata: metadata
        )
        
        // Step 8: Save to Firestore
        try await savePhotoToFirestore(photo)
        
        return photo
    }
    
    /// Convert image to WebP format (placeholder for task 4.2)
    func convertToWebP(_ imageData: Data, quality: Float) async throws -> Data {
        // TODO: Implement WebP conversion in task 4.2
        // For now, return original data as placeholder
        return imageData
    }
    
    /// Generate thumbnails at different sizes
    func generateThumbnails(_ imageData: Data) async throws -> PhotoSizes {
        return try await withCheckedThrowingContinuation { continuation in
            Task {
                do {
                    // Generate thumbnail (150x150)
                    let thumbnailData = try self.resizeImageData(imageData, to: CGSize(width: 150, height: 150), quality: 0.6)
                    
                    // Generate preview (800x800)
                    let previewData = try self.resizeImageData(imageData, to: CGSize(width: 800, height: 800), quality: 0.8)
                    
                    // Generate high resolution (1200x1200)
                    let highResData = try self.resizeImageData(imageData, to: CGSize(width: 1200, height: 1200), quality: 0.9)
                    
                    let photoSizes = PhotoSizes(
                        thumbnail: thumbnailData,
                        preview: previewData,
                        highRes: highResData
                    )
                    
                    continuation.resume(returning: photoSizes)
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
    }
    
    /// Extract EXIF data from image data
    func extractEXIFData(_ imageData: Data) async throws -> PhotoMetadata {
        return try await exifValidationService.extractEXIFData(from: imageData)
    }
    
    /// Validate photo freshness
    func validatePhotoFreshness(_ metadata: PhotoMetadata) async throws -> Bool {
        return try exifValidationService.validatePhotoFreshness(metadata)
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
}

// MARK: - Private Methods
private extension PhotoUploadService {
    
    /// Resize image data to specified size while maintaining aspect ratio
    func resizeImageData(_ imageData: Data, to targetSize: CGSize, quality: CGFloat) throws -> Data {
        guard let source = CGImageSourceCreateWithData(imageData as CFData, nil),
              let cgImage = CGImageSourceCreateImageAtIndex(source, 0, nil) else {
            throw AppError.invalidImageFormat
        }
        
        let originalSize = CGSize(width: cgImage.width, height: cgImage.height)
        
        let widthRatio = targetSize.width / originalSize.width
        let heightRatio = targetSize.height / originalSize.height
        
        // Choose the smaller ratio to maintain aspect ratio
        let ratio = min(widthRatio, heightRatio)
        
        let newSize = CGSize(width: originalSize.width * ratio, height: originalSize.height * ratio)
        
        // Create context and draw resized image
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        guard let context = CGContext(data: nil,
                                    width: Int(newSize.width),
                                    height: Int(newSize.height),
                                    bitsPerComponent: 8,
                                    bytesPerRow: 0,
                                    space: colorSpace,
                                    bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue) else {
            throw AppError.imageUploadFailed
        }
        
        context.interpolationQuality = .high
        context.draw(cgImage, in: CGRect(origin: .zero, size: newSize))
        
        guard let resizedCGImage = context.makeImage() else {
            throw AppError.imageUploadFailed
        }
        
        // Convert to JPEG data
        let mutableData = NSMutableData()
        guard let destination = CGImageDestinationCreateWithData(mutableData, UTType.jpeg.identifier as CFString, 1, nil) else {
            throw AppError.imageUploadFailed
        }
        
        let options: [CFString: Any] = [
            kCGImageDestinationLossyCompressionQuality: quality
        ]
        
        CGImageDestinationAddImage(destination, resizedCGImage, options as CFDictionary)
        
        guard CGImageDestinationFinalize(destination) else {
            throw AppError.imageUploadFailed
        }
        
        return mutableData as Data
    }
    
    /// Upload photo sizes to Firebase Storage
    func uploadToFirebaseStorage(photoSizes: PhotoSizes, photoId: String) async throws -> String {
        let storageRef = storage.reference()
        
        // Upload high resolution image (main image URL)
        let highResRef = storageRef.child("photos/\(photoId)/highres.jpg")
        _ = try await highResRef.putDataAsync(photoSizes.highRes)
        let highResURL = try await highResRef.downloadURL()
        
        // Upload preview image
        let previewRef = storageRef.child("photos/\(photoId)/preview.jpg")
        _ = try await previewRef.putDataAsync(photoSizes.preview)
        
        // Upload thumbnail
        let thumbnailRef = storageRef.child("photos/\(photoId)/thumbnail.jpg")
        _ = try await thumbnailRef.putDataAsync(photoSizes.thumbnail)
        
        return highResURL.absoluteString
    }
    
    /// Save photo metadata to Firestore
    func savePhotoToFirestore(_ photo: Photo) async throws {
        let document = firestore.collection("photos").document(photo.id)
        let data = try Firestore.Encoder().encode(photo)
        try await document.setData(data)
        
        // Initialize upload progress
        let progress = UploadProgress(photoId: photo.id)
        let progressDocument = firestore.collection("uploadProgress").document(photo.id)
        let progressData = try Firestore.Encoder().encode(progress)
        try await progressDocument.setData(progressData)
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