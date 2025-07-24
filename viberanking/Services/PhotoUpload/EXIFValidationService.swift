//
//  EXIFValidationService.swift
//  viberanking
//
//  Created by Kiro on 2025/07/23.
//

import Foundation
import UIKit
import ImageIO
import CoreLocation
import UniformTypeIdentifiers

// MARK: - EXIF Validation Service Protocol
protocol EXIFValidationServiceProtocol {
    func extractEXIFData(from imageData: Data) async throws -> PhotoMetadata
    func validatePhotoFreshness(_ metadata: PhotoMetadata) throws -> Bool
    func detectScreenshot(from imageData: Data) throws -> Bool
    func sanitizeEXIFData(from imageData: Data) async throws -> Data
}

// MARK: - EXIF Validation Errors
enum EXIFValidationError: Error, LocalizedError {
    case noEXIFData
    case invalidImageData
    case photoTooOld
    case screenshotDetected
    case invalidDateFormat
    case processingFailed
    
    var errorDescription: String? {
        switch self {
        case .noEXIFData:
            return "照片缺少必要的 EXIF 資料，請使用相機拍攝新照片"
        case .invalidImageData:
            return "無效的圖片資料"
        case .photoTooOld:
            return "照片拍攝時間超過 24 小時，請上傳更近期的照片"
        case .screenshotDetected:
            return "檢測到螢幕截圖，請上傳相機拍攝的照片"
        case .invalidDateFormat:
            return "照片日期格式無效"
        case .processingFailed:
            return "EXIF 資料處理失敗"
        }
    }
}

// MARK: - EXIF Validation Service Implementation
@MainActor
class EXIFValidationService: EXIFValidationServiceProtocol {
    
    // MARK: - Constants
    private let maxPhotoAge: TimeInterval = 24 * 60 * 60 // 24 hours
    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy:MM:dd HH:mm:ss"
        formatter.timeZone = TimeZone.current
        return formatter
    }()
    
    // MARK: - Public Methods
    
    /// Extract EXIF data from image data
    func extractEXIFData(from imageData: Data) async throws -> PhotoMetadata {
        return try await withCheckedThrowingContinuation { continuation in
            Task {
                do {
                    let metadata = try await self.processEXIFData(from: imageData)
                    continuation.resume(returning: metadata)
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
    }
    
    /// Validate if photo was taken within the last 24 hours
    func validatePhotoFreshness(_ metadata: PhotoMetadata) throws -> Bool {
        guard metadata.hasValidEXIF else {
            throw EXIFValidationError.noEXIFData
        }
        
        guard let dateTaken = metadata.dateTaken else {
            throw EXIFValidationError.noEXIFData
        }
        
        let now = Date()
        let timeDifference = now.timeIntervalSince(dateTaken)
        
        if timeDifference > maxPhotoAge {
            throw EXIFValidationError.photoTooOld
        }
        
        return true
    }
    
    /// Detect if image is a screenshot
    func detectScreenshot(from imageData: Data) throws -> Bool {
        guard let source = CGImageSourceCreateWithData(imageData as CFData, nil),
              let properties = CGImageSourceCopyPropertiesAtIndex(source, 0, nil) as? [String: Any] else {
            throw EXIFValidationError.invalidImageData
        }
        
        // Check for screenshot indicators
        let isScreenshot = checkScreenshotIndicators(properties: properties)
        
        if isScreenshot {
            throw EXIFValidationError.screenshotDetected
        }
        
        return isScreenshot
    }
    
    /// Remove sensitive EXIF data while keeping essential metadata
    func sanitizeEXIFData(from imageData: Data) async throws -> Data {
        return try await withCheckedThrowingContinuation { continuation in
            Task {
                do {
                    let sanitizedData = try self.removeSensitiveEXIFData(from: imageData)
                    continuation.resume(returning: sanitizedData)
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
    }
}

// MARK: - Private Methods
private extension EXIFValidationService {
    
    /// Process EXIF data from image data
    func processEXIFData(from imageData: Data) async throws -> PhotoMetadata {
        guard let source = CGImageSourceCreateWithData(imageData as CFData, nil),
              let properties = CGImageSourceCopyPropertiesAtIndex(source, 0, nil) as? [String: Any] else {
            throw EXIFValidationError.invalidImageData
        }
        
        // Extract EXIF dictionary
        let exifDict = properties[kCGImagePropertyExifDictionary as String] as? [String: Any]
        let tiffDict = properties[kCGImagePropertyTIFFDictionary as String] as? [String: Any]
        
        // Extract date taken
        let dateTaken = extractDateTaken(from: exifDict)
        
        // Extract camera model
        let cameraModel = extractCameraModel(from: tiffDict)
        
        // Check for screenshot indicators
        let isScreenshot = checkScreenshotIndicators(properties: properties)
        if isScreenshot {
            throw EXIFValidationError.screenshotDetected
        }
        
        // Create metadata
        let metadata = PhotoMetadata(dateTaken: dateTaken, cameraModel: cameraModel)
        
        // Validate freshness if date is available
        if let dateTaken = dateTaken {
            let timeDifference = Date().timeIntervalSince(dateTaken)
            if timeDifference > maxPhotoAge {
                throw EXIFValidationError.photoTooOld
            }
        }
        
        return metadata
    }
    
    /// Extract date taken from EXIF data
    func extractDateTaken(from exifDict: [String: Any]?) -> Date? {
        guard let exifDict = exifDict else { return nil }
        
        // Try different date fields
        let dateFields = [
            kCGImagePropertyExifDateTimeOriginal as String,
            kCGImagePropertyExifDateTimeDigitized as String
        ]
        
        for field in dateFields {
            if let dateString = exifDict[field] as? String {
                if let date = dateFormatter.date(from: dateString) {
                    return date
                }
            }
        }
        
        return nil
    }
    
    /// Extract camera model from TIFF data
    func extractCameraModel(from tiffDict: [String: Any]?) -> String? {
        guard let tiffDict = tiffDict else { return nil }
        
        let make = tiffDict[kCGImagePropertyTIFFMake as String] as? String
        let model = tiffDict[kCGImagePropertyTIFFModel as String] as? String
        
        switch (make, model) {
        case let (make?, model?):
            return "\(make) \(model)"
        case let (nil, model?):
            return model
        case let (make?, nil):
            return make
        default:
            return nil
        }
    }
    
    /// Check for screenshot indicators in image properties
    func checkScreenshotIndicators(properties: [String: Any]) -> Bool {
        // Check for missing EXIF data (common in screenshots)
        let exifDict = properties[kCGImagePropertyExifDictionary as String] as? [String: Any]
        let tiffDict = properties[kCGImagePropertyTIFFDictionary as String] as? [String: Any]
        
        // Screenshots typically lack camera-specific EXIF data
        let hasExifData = exifDict != nil && !exifDict!.isEmpty
        let hasTiffData = tiffDict != nil && !tiffDict!.isEmpty
        
        if !hasExifData && !hasTiffData {
            return true
        }
        
        // Check for software indicators
        if let software = tiffDict?[kCGImagePropertyTIFFSoftware as String] as? String {
            let screenshotIndicators = ["screenshot", "screen capture", "snagit", "lightshot"]
            for indicator in screenshotIndicators {
                if software.lowercased().contains(indicator) {
                    return true
                }
            }
        }
        
        // Check image dimensions (screenshots often have specific ratios)
        if let pixelWidth = properties[kCGImagePropertyPixelWidth as String] as? Int,
           let pixelHeight = properties[kCGImagePropertyPixelHeight as String] as? Int {
            
            // Common screen resolutions that might indicate screenshots
            let commonScreenSizes = [
                (1170, 2532), // iPhone 13 Pro
                (1125, 2436), // iPhone X/XS
                (828, 1792),  // iPhone XR
                (1284, 2778), // iPhone 13 Pro Max
                (1080, 1920), // Common Android
                (1440, 2560), // Common Android
            ]
            
            for (width, height) in commonScreenSizes {
                if (pixelWidth == width && pixelHeight == height) ||
                   (pixelWidth == height && pixelHeight == width) {
                    // Additional check: screenshots usually lack camera EXIF
                    if exifDict?[kCGImagePropertyExifDateTimeOriginal as String] == nil {
                        return true
                    }
                }
            }
        }
        
        return false
    }
    
    /// Remove sensitive EXIF data while preserving essential metadata
    func removeSensitiveEXIFData(from imageData: Data) throws -> Data {
        guard let source = CGImageSourceCreateWithData(imageData as CFData, nil),
              let type = CGImageSourceGetType(source) else {
            throw EXIFValidationError.invalidImageData
        }
        
        let mutableData = NSMutableData()
        guard let destination = CGImageDestinationCreateWithData(mutableData, type, 1, nil) else {
            throw EXIFValidationError.processingFailed
        }
        
        guard let properties = CGImageSourceCopyPropertiesAtIndex(source, 0, nil) as? [String: Any] else {
            throw EXIFValidationError.processingFailed
        }
        
        // Create sanitized properties
        var sanitizedProperties = properties
        
        // Remove GPS data
        sanitizedProperties.removeValue(forKey: kCGImagePropertyGPSDictionary as String)
        
        // Remove maker notes (may contain sensitive info)
        if var exifDict = sanitizedProperties[kCGImagePropertyExifDictionary as String] as? [String: Any] {
            exifDict.removeValue(forKey: kCGImagePropertyExifMakerNote as String)
            exifDict.removeValue(forKey: kCGImagePropertyExifUserComment as String)
            sanitizedProperties[kCGImagePropertyExifDictionary as String] = exifDict
        }
        
        // Remove IPTC data
        sanitizedProperties.removeValue(forKey: kCGImagePropertyIPTCDictionary as String)
        
        // Keep only essential TIFF and EXIF data
        let allowedKeys: Set<String> = [
            kCGImagePropertyTIFFMake as String,
            kCGImagePropertyTIFFModel as String,
            kCGImagePropertyExifDateTimeOriginal as String,
            kCGImagePropertyExifDateTimeDigitized as String,
            kCGImagePropertyPixelWidth as String,
            kCGImagePropertyPixelHeight as String,
            kCGImagePropertyOrientation as String
        ]
        
        // Filter properties to keep only allowed keys
        sanitizedProperties = sanitizedProperties.filter { key, _ in
            allowedKeys.contains(key) || key.hasPrefix("{TIFF}") || key.hasPrefix("{Exif}")
        }
        
        // Add image to destination with sanitized properties
        CGImageDestinationAddImageFromSource(destination, source, 0, sanitizedProperties as CFDictionary)
        
        guard CGImageDestinationFinalize(destination) else {
            throw EXIFValidationError.processingFailed
        }
        
        return mutableData as Data
    }
}