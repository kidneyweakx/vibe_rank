//
//  PhotoURLs.swift
//  viberanking
//
//  Created by Kiro on 2025/07/27.
//

import Foundation

// MARK: - Photo URLs Structure
struct PhotoURLs: Codable {
    let thumbnail: String?
    let preview: String?
    let highRes: String?
    let original: String?
    
    init(thumbnail: URL, preview: URL, highRes: URL) {
        self.thumbnail = thumbnail.absoluteString
        self.preview = preview.absoluteString
        self.highRes = highRes.absoluteString
        self.original = nil
    }
    
    // 從 API 響應創建的便利初始化器
    init(original: String) {
        self.original = original
        self.thumbnail = nil
        self.preview = nil
        self.highRes = nil
    }
    
    // 計算屬性：獲取最佳可用的圖片 URL
    var bestAvailableURL: String {
        return highRes ?? preview ?? original ?? thumbnail ?? ""
    }
    
    // 計算屬性：獲取縮略圖 URL（優先使用 thumbnail，否則使用其他）
    var thumbnailURL: String {
        return thumbnail ?? preview ?? original ?? highRes ?? ""
    }
    
    // 計算屬性：獲取預覽 URL（優先使用 preview，否則使用其他）
    var previewURL: String {
        return preview ?? highRes ?? original ?? thumbnail ?? ""
    }
}
