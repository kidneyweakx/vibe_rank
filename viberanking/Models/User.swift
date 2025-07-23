//
//  User.swift
//  viberanking
//
//  Created by Kiro on 2025/07/23.
//

import Foundation

// MARK: - User Model
struct User: Codable, Identifiable {
    let id: String
    let name: String
    let email: String
    let profileImageURL: String?
    let gender: Gender?
    let createdAt: Date
    var ratingProgress: RatingProgress
    var uploadedPhotos: [Photo]
    
    init(id: String, name: String, email: String, profileImageURL: String? = nil, gender: Gender? = nil) {
        self.id = id
        self.name = name
        self.email = email
        self.profileImageURL = profileImageURL
        self.gender = gender
        self.createdAt = Date()
        self.ratingProgress = RatingProgress()
        self.uploadedPhotos = []
    }
}

// MARK: - Gender Enum
enum Gender: String, CaseIterable, Codable {
    case male = "male"
    case female = "female"
    case other = "other"
    
    var displayName: String {
        switch self {
        case .male:
            return "男性"
        case .female:
            return "女性"
        case .other:
            return "其他"
        }
    }
}

// MARK: - Rating Progress
struct RatingProgress: Codable {
    var completedRatings: Int
    let requiredRatings: Int
    
    init(completedRatings: Int = 0, requiredRatings: Int = 20) {
        self.completedRatings = completedRatings
        self.requiredRatings = requiredRatings
    }
    
    var hasUnlockedUpload: Bool {
        return completedRatings >= requiredRatings
    }
    
    var progressPercentage: Double {
        return min(Double(completedRatings) / Double(requiredRatings), 1.0)
    }
    
    var remainingRatings: Int {
        return max(requiredRatings - completedRatings, 0)
    }
}