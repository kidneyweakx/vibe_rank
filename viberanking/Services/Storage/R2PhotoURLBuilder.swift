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
        // Use original/public object URL only for now (no variant pipeline)
        let original = imageService.makePublicURL(for: key, variant: nil)
        return PhotoURLs(original: original.absoluteString)
    }
}


