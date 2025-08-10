//
//  R2PhotoURLBuilder.swift
//  viberanking
//
//  Created by Assistant on 2025/08/09.
//

import Foundation

/// Helper to construct `PhotoURLs` from an R2 object key using `R2ImageService`.
struct R2PhotoURLBuilder {
    private let imageService: R2ImageServiceProtocol
    
    init(imageService: R2ImageServiceProtocol = R2ImageService.shared) {
        self.imageService = imageService
    }
    
    func buildURLs(forKey key: String) -> PhotoURLs {
        // For private S3 endpoints, return a single original signed URL
        if AppConfiguration.R2.publicDomain.contains("r2.cloudflarestorage.com") {
            // Will be resolved dynamically by view model using resolveLoadableURL
            let placeholder = imageService.makePublicURL(for: key, variant: nil)
            return PhotoURLs(original: placeholder.absoluteString)
        }
        // CDN/worker domain: build variant URLs
        let thumbURL = imageService.makePublicURL(for: key, variant: .thumbnail)
        let previewURL = imageService.makePublicURL(for: key, variant: .preview)
        let highResURL = imageService.makePublicURL(for: key, variant: .highRes)
        return PhotoURLs(thumbnail: thumbURL, preview: previewURL, highRes: highResURL)
    }
}


