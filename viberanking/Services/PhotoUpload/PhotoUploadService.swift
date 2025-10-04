//
//  PhotoUploadService.swift
//  viberanking
//
//  Created by Kiro on 2025/07/23.
//

import Foundation
import SwiftUI
import UniformTypeIdentifiers
import os.log

// MARK: - Photo Upload Service Implementation
class PhotoUploadService {
    
    // MARK: - Dependencies
    private let fileAPI = FileAPI()
    private let webpConverter = WebPConverter.shared
    
    // MARK: - Upload Management
    private var activeUploads: [String: UploadTask] = [:]
    
    // MARK: - Logging
    private let logger = Logger(subsystem: "com.viberanking.app", category: "PhotoUploadService")
    
    // MARK: - Public Methods
    
    /// Upload photo with WebP conversion
    func uploadPhoto(_ image: UIImage, for userId: String) async throws -> Photo {
        let photoId = UUID().uuidString
        let uploadTask = UploadTask(photoId: photoId, userId: userId)

        await MainActor.run {
            activeUploads[photoId] = uploadTask
        }

        logger.info("🚀 Starting photo upload - PhotoID: \(photoId), UserID: \(userId)")
        logger.debug("📊 Image size: \(image.size.width)x\(image.size.height)")

        // Extract capture date from image metadata
        let captureDate = ImageMetadataExtractor.extractCaptureDate(from: image)
        if let captureDate = captureDate {
            logger.info("📅 Extracted capture date: \(captureDate)")
        } else {
            logger.debug("⚠️ No capture date found in image metadata, will use upload time")
        }
        
        do {
            // Step 1: Resize and convert to WebP
            logger.info("🔄 Step 1: Converting to WebP - PhotoID: \(photoId)")
            await updateUploadStatus(photoId: photoId, status: .processing)

            // Resize and convert in background thread
            let (pngData, resizedSize) = await withCheckedContinuation { continuation in
                Task.detached {
                    let maxSide = CGFloat(AppConfiguration.Photo.highResSize)
                    let resizedImage = image.scaledDownIfNeeded(maxDimension: maxSide)
                    let data = resizedImage.pngData()
                    continuation.resume(returning: (data, resizedImage.size))
                }
            }

            guard let imageData = pngData else {
                logger.error("❌ Failed to convert image to PNG - PhotoID: \(photoId)")
                throw AppError.invalidImageFormat
            }

            logger.debug("📦 Resized to \(Int(resizedSize.width))x\(Int(resizedSize.height)), PNG: \(imageData.count) bytes - PhotoID: \(photoId)")

            // Convert to WebP with adaptive quality
            var targetQuality: Float = 0.8
            var webpData = try await webpConverter.convertToWebP(imageData, quality: targetQuality)

            let maxBytesBinary = AppConfiguration.Photo.maxFileSizeMB * 1024 * 1024
            let safetyRatioForBase64: Double = 0.72
            let maxBytesForPayload = Int(Double(maxBytesBinary) * safetyRatioForBase64)

            while webpData.count > maxBytesForPayload && targetQuality > 0.4 {
                targetQuality -= 0.1
                logger.warning("⚠️ WebP \(webpData.count) > \(maxBytesForPayload). Retrying quality=\(String(format: "%.1f", targetQuality))")
                webpData = try await webpConverter.convertToWebP(imageData, quality: targetQuality)
            }

            logger.info("✅ WebP conversion - Size: \(webpData.count) bytes, Quality: \(String(format: "%.1f", targetQuality))")
            
            // Step 2: Upload via API
            logger.info("📤 Step 2: Uploading to API - PhotoID: \(photoId)")
            await updateUploadStatus(photoId: photoId, status: .uploading(progress: 0.0))

            let response = try await fileAPI.uploadPhoto(webpData, takenAt: captureDate)
            logger.info("✅ API upload completed - PhotoID: \(photoId), ResponseID: \(response.photoId)")
            
            // Step 3: Create Photo object
            logger.info("🏗️ Step 3: Creating Photo object - PhotoID: \(photoId)")
            let photo = Photo(
                id: response.photoId,
                userId: userId,
                imageURL: response.urls
            )
            
            // Step 4: Complete upload
            logger.info("🎉 Step 4: Upload completed successfully - PhotoID: \(photoId)")
            await updateUploadStatus(photoId: photoId, status: .completed)
            await MainActor.run {
                activeUploads.removeValue(forKey: photoId)
            }
            
            return photo
            
        } catch {
            logger.error("💥 Upload failed - PhotoID: \(photoId), Error: \(error.localizedDescription)")
            if let appError = error as? AppError {
                logger.error("🔍 AppError details: \(appError)")
            }
            await updateUploadStatus(photoId: photoId, status: .failed(error))
            await MainActor.run {
                activeUploads.removeValue(forKey: photoId)
            }
            throw error
        }
    }
    
    /// Get upload progress for a photo
    func getUploadProgress(for photoId: String) -> UploadProgress {
        if let task = activeUploads[photoId] {
            return UploadProgress(photoId: photoId, status: task.status, progress: task.progress)
        }
        logger.debug("⚠️ No active upload found - PhotoID: \(photoId)")
        return UploadProgress(photoId: photoId, status: .pending, progress: 0.0)
    }
    
    /// Cancel upload for a specific photo
    func cancelUpload(for photoId: String) async throws {
        let hasUpload = await MainActor.run {
            return activeUploads[photoId] != nil
        }
        
        if hasUpload {
            logger.info("🚫 Cancelling upload - PhotoID: \(photoId)")
            await updateUploadStatus(photoId: photoId, status: .cancelled)
            await MainActor.run {
                activeUploads.removeValue(forKey: photoId)
            }
            logger.info("✅ Upload cancelled successfully - PhotoID: \(photoId)")
        } else {
            logger.warning("⚠️ Attempted to cancel non-existent upload - PhotoID: \(photoId)")
        }
    }
}

// MARK: - Private Methods
private extension PhotoUploadService {
    
    /// Update upload status for tracking
    func updateUploadStatus(photoId: String, status: UploadStatus) async {
        await MainActor.run {
            if var uploadTask = activeUploads[photoId] {
                uploadTask.status = status
                
                switch status {
                case .uploading(let progress):
                    uploadTask.progress = progress
                    logger.debug("📈 Upload progress updated - PhotoID: \(photoId), Progress: \(String(format: "%.1f", progress * 100))%")
                case .completed:
                    uploadTask.progress = 1.0
                    logger.info("✅ Upload status updated to completed - PhotoID: \(photoId)")
                case .failed(let error):
                    logger.error("❌ Upload status updated to failed - PhotoID: \(photoId), Error: \(error.localizedDescription)")
                case .cancelled:
                    logger.info("🚫 Upload status updated to cancelled - PhotoID: \(photoId)")
                case .processing:
                    logger.info("🔄 Upload status updated to processing - PhotoID: \(photoId)")
                case .pending:
                    logger.debug("⏳ Upload status updated to pending - PhotoID: \(photoId)")
                }
                
                activeUploads[photoId] = uploadTask
            } else {
                logger.warning("⚠️ Attempted to update status for non-existent upload task - PhotoID: \(photoId)")
            }
        }
    }
}
