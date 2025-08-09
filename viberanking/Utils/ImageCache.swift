//
//  ImageCache.swift
//  viberanking
//
//  Created by Kiro on 2025/08/09.
//

import Foundation
import SwiftUI

class ImageCache {
    static let shared = ImageCache()
    
    private init() {}
    
    func preloadImages(urls: [String]) {
        // Simple preloading implementation
        for urlString in urls {
            guard let url = URL(string: urlString) else { continue }
            
            Task {
                do {
                    let (_, _) = try await URLSession.shared.data(from: url)
                    // Image is now cached by URLSession
                } catch {
                    print("Failed to preload image: \(error)")
                }
            }
        }
    }
}