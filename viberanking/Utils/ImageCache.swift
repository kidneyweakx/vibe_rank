//
//  ImageCache.swift
//  viberanking
//
//  Created by Kiro on 2025/08/09.
//

import Foundation
import SwiftUI
import os.log

class ImageCache {
    static let shared = ImageCache()
    
    private init() {}
    
    func preloadImages(urls: [String]) {
        // Simple preloading implementation
        let logger = Logger(subsystem: "com.viberanking.app", category: "ImageCache")
        logger.debug("🔄 Preloading images (URLSession cache), count: \(urls.count)")
        for urlString in urls {
            guard let url = URL(string: urlString) else { continue }
            
            Task {
                do {
                    let (data, response) = try await URLSession.shared.data(from: url)
                    let status = (response as? HTTPURLResponse)?.statusCode ?? -1
                    logger.debug("✅ Preloaded: \(url.absoluteString) (status: \(status), bytes: \(data.count))")
                } catch {
                    logger.error("❌ Failed to preload image: \(url.absoluteString), error: \(error.localizedDescription)")
                }
            }
        }
    }
}