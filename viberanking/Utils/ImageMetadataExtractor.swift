//
//  ImageMetadataExtractor.swift
//  viberanking
//
//  Created by Assistant on 2025/10/02.
//

import UIKit
import ImageIO
import Photos

/// Utility for extracting metadata from images
struct ImageMetadataExtractor {

    /// Extract the original capture date from an image
    /// - Parameter image: The UIImage to extract metadata from
    /// - Returns: The capture date if available, otherwise nil
    static func extractCaptureDate(from image: UIImage) -> Date? {
        guard let imageData = image.jpegData(compressionQuality: 1.0) else {
            return nil
        }

        return extractCaptureDate(from: imageData)
    }

    /// Extract the original capture date from image data
    /// - Parameter imageData: The image data to extract metadata from
    /// - Returns: The capture date if available, otherwise nil
    static func extractCaptureDate(from imageData: Data) -> Date? {
        guard let imageSource = CGImageSourceCreateWithData(imageData as CFData, nil),
              let properties = CGImageSourceCopyPropertiesAtIndex(imageSource, 0, nil) as? [CFString: Any] else {
            return nil
        }

        // Try to get the EXIF date
        if let exifDict = properties[kCGImagePropertyExifDictionary] as? [CFString: Any],
           let dateString = exifDict[kCGImagePropertyExifDateTimeOriginal] as? String {
            return parseExifDate(dateString)
        }

        // Try to get the TIFF date as fallback
        if let tiffDict = properties[kCGImagePropertyTIFFDictionary] as? [CFString: Any],
           let dateString = tiffDict[kCGImagePropertyTIFFDateTime] as? String {
            return parseExifDate(dateString)
        }

        return nil
    }

    /// Extract the original capture date from a PHAsset
    /// - Parameter asset: The PHAsset to extract metadata from
    /// - Returns: The capture date if available, otherwise nil
    static func extractCaptureDate(from asset: PHAsset) -> Date? {
        // PHAsset has a creationDate property which is the capture date
        return asset.creationDate
    }

    /// Parse EXIF date string to Date
    /// EXIF date format: "YYYY:MM:DD HH:MM:SS"
    /// - Parameter dateString: The EXIF date string
    /// - Returns: The parsed Date or nil if parsing fails
    private static func parseExifDate(_ dateString: String) -> Date? {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy:MM:dd HH:mm:ss"
        formatter.timeZone = TimeZone.current
        return formatter.date(from: dateString)
    }

    /// Extract comprehensive metadata from an image
    /// - Parameter imageData: The image data
    /// - Returns: Dictionary with all available metadata
    static func extractAllMetadata(from imageData: Data) -> [String: Any]? {
        guard let imageSource = CGImageSourceCreateWithData(imageData as CFData, nil),
              let properties = CGImageSourceCopyPropertiesAtIndex(imageSource, 0, nil) as? [String: Any] else {
            return nil
        }

        return properties
    }
}
