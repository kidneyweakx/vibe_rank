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

// MARK: - User Preferences based on ratings
struct UserPreferences: Codable {
    let userId: String
    var stylePreferences: [String: Double] // Using String keys for Codable compatibility
    var totalRatingsGiven: Int
    var hotRatingsGiven: Int
    var lastUpdated: Date
    
    init(userId: String) {
        self.userId = userId
        self.stylePreferences = [:]
        self.totalRatingsGiven = 0
        self.hotRatingsGiven = 0
        self.lastUpdated = Date()
    }
    
    var hotRatingPercentage: Double {
        guard totalRatingsGiven > 0 else { return 0.0 }
        return Double(hotRatingsGiven) / Double(totalRatingsGiven)
    }
    
    mutating func updateWithRating(_ rating: Rating) {
        totalRatingsGiven += 1
        if rating.isHot {
            hotRatingsGiven += 1
        }
        lastUpdated = Date()
    }
    
    mutating func updateStylePreference(for style: String, score: Double) {
        stylePreferences[style] = score
        lastUpdated = Date()
    }
}