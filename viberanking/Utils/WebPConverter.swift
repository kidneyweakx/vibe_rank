//
//  WebPConverter.swift
//  viberanking
//
//  Created by Kiro on 2025/07/23.
//

import Foundation
import CoreGraphics
import ImageIO
import UniformTypeIdentifiers

// MARK: - WebP Image Conversion Utility
class WebPConverter {
    static let shared = WebPConverter()
    
    private init() {}
    
    // MARK: - Public Methods
    
    /// Convert image data to WebP format with specified quality
    func convertToWebP(_ imageData: Data, quality: Float) async throws -> Data {
        return try await withCheckedThrowingContinuation { continuation in
            Task {
                do {
                    // For now, we'll use JPEG with high compression as WebP alternative
                    // This provides significant size reduction while maintaining compatibility
                    let convertedData = try self.convertToHighCompressionJPEG(imageData, quality: quality)
                    continuation.resume(returning: convertedData)
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
    }
    
    /// Generate thumbnails in optimized format (WebP-like compression)
    func generateThumbnails(_ imageData: Data) async throws -> PhotoSizes {
        return try await withCheckedThrowingContinuation { continuation in
            Task {
                do {
                    // Generate thumbnail (150x150)
                    let thumbnailData = try await self.resizeAndCompress(
                        imageData, 
                        targetSize: CGSize(width: AppConfiguration.Photo.thumbnailSize, height: AppConfiguration.Photo.thumbnailSize),
                        quality: AppConfiguration.Photo.webpQualityThumbnail
                    )
                    
                    // Generate preview (800x800)
                    let previewData = try await self.resizeAndCompress(
                        imageData,
                        targetSize: CGSize(width: AppConfiguration.Photo.previewSize, height: AppConfiguration.Photo.previewSize),
                        quality: AppConfiguration.Photo.webpQualityPreview
                    )
                    
                    // Generate high resolution (1200x1200)
                    let highResData = try await self.resizeAndCompress(
                        imageData,
                        targetSize: CGSize(width: AppConfiguration.Photo.highResSize, height: AppConfiguration.Photo.highResSize),
                        quality: AppConfiguration.Photo.webpQualityHighRes
                    )
                    
                    let photoSizes = PhotoSizes(
                        thumbnail: thumbnailData,
                        preview: previewData,
                        highRes: highResData
                    )
                    
                    print("Generated thumbnails: \(thumbnailData.count) bytes thumbnail, \(previewData.count) bytes preview, \(highResData.count) bytes high-res")
                    
                    continuation.resume(returning: photoSizes)
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
    }
    
    /// Resize image data to specified dimensions
    func resizeImageData(_ imageData: Data, targetWidth: Int, targetHeight: Int) async throws -> Data {
        let targetSize = CGSize(width: targetWidth, height: targetHeight)
        return try await resizeAndCompress(imageData, targetSize: targetSize, quality: 0.8)
    }
}

// MARK: - Private Methods
private extension WebPConverter {
    
    /// Resize and compress image data with optimal settings
    func resizeAndCompress(_ imageData: Data, targetSize: CGSize, quality: Float) async throws -> Data {
        guard let source = CGImageSourceCreateWithData(imageData as CFData, nil),
              let cgImage = CGImageSourceCreateImageAtIndex(source, 0, nil) else {
            throw AppError.invalidImageFormat
        }
        
        let originalSize = CGSize(width: cgImage.width, height: cgImage.height)
        
        // Calculate aspect ratio preserving size
        let aspectRatio = originalSize.width / originalSize.height
        let targetAspectRatio = targetSize.width / targetSize.height
        
        var newSize: CGSize
        if aspectRatio > targetAspectRatio {
            // Image is wider than target
            newSize = CGSize(width: targetSize.width, height: targetSize.width / aspectRatio)
        } else {
            // Image is taller than target
            newSize = CGSize(width: targetSize.height * aspectRatio, height: targetSize.height)
        }
        
        // Ensure we don't upscale
        if newSize.width > originalSize.width || newSize.height > originalSize.height {
            newSize = originalSize
        }
        
        // Create optimized context
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        guard let context = CGContext(
            data: nil,
            width: Int(newSize.width),
            height: Int(newSize.height),
            bitsPerComponent: 8,
            bytesPerRow: 0,
            space: colorSpace,
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        ) else {
            throw AppError.imageUploadFailed
        }
        
        // Set high quality interpolation
        context.interpolationQuality = .high
        context.setShouldAntialias(true)
        context.setAllowsAntialiasing(true)
        
        // Draw resized image
        context.draw(cgImage, in: CGRect(origin: .zero, size: newSize))
        
        guard let resizedCGImage = context.makeImage() else {
            throw AppError.imageUploadFailed
        }
        
        // Convert to optimized JPEG with specified quality
        return try convertCGImageToJPEG(resizedCGImage, quality: quality)
    }
    
    /// Convert image data to high compression JPEG (WebP alternative)
    func convertToHighCompressionJPEG(_ imageData: Data, quality: Float) throws -> Data {
        guard let source = CGImageSourceCreateWithData(imageData as CFData, nil),
              let cgImage = CGImageSourceCreateImageAtIndex(source, 0, nil) else {
            throw AppError.invalidImageFormat
        }
        
        return try convertCGImageToJPEG(cgImage, quality: quality)
    }
    
    /// Convert CGImage to JPEG data with specified quality
    func convertCGImageToJPEG(_ cgImage: CGImage, quality: Float) throws -> Data {
        let mutableData = NSMutableData()
        
        guard let destination = CGImageDestinationCreateWithData(
            mutableData,
            UTType.jpeg.identifier as CFString,
            1,
            nil
        ) else {
            throw AppError.imageUploadFailed
        }
        
        // Optimize JPEG settings for maximum compression while maintaining quality
        let options: [CFString: Any] = [
            kCGImageDestinationLossyCompressionQuality: quality,
            kCGImageDestinationOptimizeColorForSharing: true
        ]
        
        CGImageDestinationAddImage(destination, cgImage, options as CFDictionary)
        
        guard CGImageDestinationFinalize(destination) else {
            throw AppError.imageUploadFailed
        }
        
        return mutableData as Data
    }
}
