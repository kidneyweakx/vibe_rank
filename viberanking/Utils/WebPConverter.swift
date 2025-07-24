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
import SDWebImageWebPCoder

// MARK: - WebP Image Conversion Utility
class WebPConverter {
    static let shared = WebPConverter()
    
    private let webPCoder = SDImageWebPCoder.shared
    
    private init() {}
    
    // MARK: - Public Methods
    
    /// Convert image data to WebP format with specified quality
    func convertToWebP(_ imageData: Data, quality: Float) async throws -> Data {
        guard let image = UIImage(data: imageData) else {
            throw AppError.invalidImageFormat
        }
        
        let webpData = webPCoder.encodedData(with: image, format: .webP, options: [SDImageCoderOption.encodeCompressionQuality: quality])
        
        guard let data = webpData else {
            throw AppError.imageUploadFailed
        }
        
        return data
    }
    
    /// Generate thumbnails in optimized format (WebP-like compression)
    func generateThumbnails(_ imageData: Data) async throws -> PhotoSizes {
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
        
        return photoSizes
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
        guard let image = UIImage(data: imageData) else {
            throw AppError.invalidImageFormat
        }
        
        let resizedImage = image.resize(targetSize: targetSize)
        
        guard let resizedImageData = resizedImage.pngData() else {
            throw AppError.imageUploadFailed
        }
        
        return try await convertToWebP(resizedImageData, quality: quality)
    }
}

extension UIImage {
    func resize(targetSize: CGSize) -> UIImage {
        let size = self.size
        
        let widthRatio  = targetSize.width  / size.width
        let heightRatio = targetSize.height / size.height
        
        var newSize: CGSize
        if(widthRatio > heightRatio) {
            newSize = CGSize(width: size.width * heightRatio, height: size.height * heightRatio)
        } else {
            newSize = CGSize(width: size.width * widthRatio,  height: size.height * widthRatio)
        }
        
        let rect = CGRect(x: 0, y: 0, width: newSize.width, height: newSize.height)
        
        UIGraphicsBeginImageContextWithOptions(newSize, false, 1.0)
        self.draw(in: rect)
        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return newImage ?? self
    }
}
