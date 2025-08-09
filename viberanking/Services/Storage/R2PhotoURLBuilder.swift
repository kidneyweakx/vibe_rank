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
        let thumb = imageService.makePublicURL(for: key, variant: .thumbnail)
        let preview = imageService.makePublicURL(for: key, variant: .preview)
        let high = imageService.makePublicURL(for: key, variant: .highRes)
        // Original with no variant param
        let original = imageService.makePublicURL(for: key, variant: nil)
        
        return PhotoURLs(
            thumbnail: thumb,
            preview: preview,
            highRes: high
        )
    }
}


