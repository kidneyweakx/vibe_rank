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
            // Step 1: Convert to WebP (在背景線程執行)
            logger.info("🔄 Step 1: Converting to WebP - PhotoID: \(photoId)")
            await updateUploadStatus(photoId: photoId, status: .processing)
            
            // 在背景線程處理：先限制最大邊長，再轉成 PNG 資料
            let imageData = await withCheckedContinuation { continuation in
                Task.detached {
                    let maxSide = CGFloat(AppConfiguration.Photo.highResSize)
                    let boundedImage = image.scaledDownIfNeeded(maxDimension: maxSide)
                    let data = boundedImage.pngData()
                    continuation.resume(returning: data)
                }
            }
            
            guard let imageData = imageData else {
                logger.error("❌ Failed to convert image to PNG data - PhotoID: \(photoId)")
                throw AppError.invalidImageFormat
            }
            
            logger.debug("📦 PNG data size: \(imageData.count) bytes - PhotoID: \(photoId)")
            
            // 先以預設品質轉 WebP，若仍超過大小上限則逐步降低品質
            var targetQuality: Float = 0.8
            var webpData = try await convertToWebP(imageData, quality: targetQuality)
            // 若走 base64 JSON 上傳，實際線上限制應預留 25% 空間 (base64 膨脹約 33%)
            let maxBytesBinary = AppConfiguration.Photo.maxFileSizeMB * 1024 * 1024
            let safetyRatioForBase64: Double = 0.72
            let maxBytesForPayload = Int(Double(maxBytesBinary) * safetyRatioForBase64)
            while webpData.count > maxBytesForPayload && targetQuality > 0.4 {
                targetQuality -= 0.1
                logger.warning("⚠️ WebP size \(webpData.count) > \(maxBytesForPayload). Retrying with quality=\(String(format: "%.1f", targetQuality)) - PhotoID: \(photoId)")
                webpData = try await convertToWebP(imageData, quality: targetQuality)
            }
            logger.info("✅ WebP conversion completed - PhotoID: \(photoId), Size: \(webpData.count) bytes (limit: \(maxBytesForPayload)), Quality: \(String(format: "%.1f", targetQuality))")
            
            // Step 2: Upload via API
            logger.info("📤 Step 2: Uploading to API - PhotoID: \(photoId)")
            await updateUploadStatus(photoId: photoId, status: .uploading(progress: 0.0))

            let response = try await fileAPI.uploadPhoto(webpData)
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
    
    /// Convert image to WebP format using WebPConverter
    func convertToWebP(_ imageData: Data, quality: Float) async throws -> Data {
        logger.debug("🔧 Converting to WebP - Input size: \(imageData.count) bytes, Quality: \(quality)")
        let startTime = CFAbsoluteTimeGetCurrent()
        
        do {
            let webpData = try await webpConverter.convertToWebP(imageData, quality: quality)
            let duration = CFAbsoluteTimeGetCurrent() - startTime
            logger.info("✅ WebP conversion successful - Output size: \(webpData.count) bytes, Duration: \(String(format: "%.2f", duration))s")
            return webpData
        } catch {
            logger.error("❌ WebP conversion failed - Error: \(error.localizedDescription)")
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
        logger.info("🖼️ Generating thumbnails - Input size: \(imageData.count) bytes")
        let startTime = CFAbsoluteTimeGetCurrent()
        
        do {
            let photoSizes = try await webpConverter.generateThumbnails(imageData)
            let duration = CFAbsoluteTimeGetCurrent() - startTime
            logger.info("✅ Thumbnails generated successfully - Duration: \(String(format: "%.2f", duration))s")
            return photoSizes
        } catch {
            logger.error("❌ Thumbnail generation failed - Error: \(error.localizedDescription)")
            throw error
        }
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
