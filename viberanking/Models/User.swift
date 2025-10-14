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
    var lastActivityAt: Date?
    var ratingProgress: RatingProgress
    var uploadedPhotos: [Photo]
    var onboardedAt: Date?
    
    init(
        id: String,
        name: String,
        email: String,
        profileImageURL: String? = nil,
        gender: Gender? = nil,
        onboardedAt: Date? = nil
    ) {
        self.id = id
        self.name = name
        self.email = email
        self.profileImageURL = profileImageURL
        self.gender = gender
        self.createdAt = Date()
        self.lastActivityAt = Date()
        self.ratingProgress = RatingProgress()
        self.uploadedPhotos = []
        self.onboardedAt = onboardedAt
    }
    
    /// Update last activity timestamp
    mutating func updateLastActivity() {
        lastActivityAt = Date()
    }
    
    /// Check if user was active recently (within last 24 hours)
    var isRecentlyActive: Bool {
        guard let lastActivity = lastActivityAt else { return false }
        let twentyFourHoursAgo = Date().addingTimeInterval(-24 * 60 * 60)
        return lastActivity >= twentyFourHoursAgo
    }
}

// MARK: - Gender Enum
enum Gender: String, CaseIterable, Codable {
    case male
    case female
    case other
    
    var displayName: String {
        switch self {
        case .male:
            return "gender.male".localized
        case .female:
            return "gender.female".localized
        case .other:
            return "gender.other".localized
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