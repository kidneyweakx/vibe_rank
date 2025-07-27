//
//  PhotoURLs.swift
//  viberanking
//
//  Created by Kiro on 2025/07/27.
//

import Foundation

// MARK: - Photo URLs Structure
struct PhotoURLs: Codable {
    let thumbnail: String
    let preview: String
    let highRes: String
    
    init(thumbnail: URL, preview: URL, highRes: URL) {
        self.thumbnail = thumbnail.absoluteString
        self.preview = preview.absoluteString
        self.highRes = highRes.absoluteString
    }
}
