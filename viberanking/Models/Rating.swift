//
//  Rating.swift
//  viberanking
//
//  Created by Kiro on 2025/07/23.
//

import Foundation

// MARK: - Rating Model
struct Rating: Codable, Identifiable {
    let id: String
    let photoId: String
    let raterId: String
    let isHot: Bool // true for "Hot", false for "Not"
    let createdAt: Date
    
    init(id: String = UUID().uuidString,
         photoId: String,
         raterId: String,
         isHot: Bool) {
        self.id = id
        self.photoId = photoId
        self.raterId = raterId
        self.isHot = isHot
        self.createdAt = Date()
    }
}
