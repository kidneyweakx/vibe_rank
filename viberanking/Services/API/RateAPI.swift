//
//  RateAPI.swift
//  viberanking
//
//  Created by Kiro on 2025/08/09.
//

import Foundation

// MARK: - Rate API Response Models

struct RatePhotoResponse: Codable {
    let success: Bool
    let rating: RatingInfo?
}

struct RatingInfo: Codable {
    let id: String
    let type: String
    let createdAt: Date
}

// MARK: - Journey Info Models

struct JourneyInfoResponse: Codable {
    let success: Bool
    let data: JourneyInfo
}

struct JourneyInfo: Codable {
    // User basic stats
    let userId: String
    let totalScore: Double
    let likeCount: Int
    let normalCount: Int
    let totalRatings: Int
    
    // Ranking info
    let overallRank: Int
    let genderRank: Int?
    let totalUsers: Int
    
    // Gender attraction scores (real data)
    let femaleAttraction: Double
    let maleAttraction: Double
    
    // Recent ratings for chart
    let recentRatings: [RecentRating]
    
    // Pre-calculated 7-day trend
    let weeklyTrend: [DailyScore]
    
    // Extended features
    let achievements: [Achievement]
    let nextMilestone: Milestone?
    let levelProgress: LevelProgress
}

struct DailyScore: Codable {
    let date: String // "2024-01-15"
    let score: Double? // Optional to handle null values from API
    let ratingCount: Int
}

struct Achievement: Codable {
    let id: String
    let title: String
    let description: String
    let icon: String
    let unlockedAt: Date?
    let progress: Double // 0.0-1.0
}

struct Milestone: Codable {
    let title: String
    let description: String
    let targetValue: Int
    let currentValue: Int
    let reward: String
}

struct LevelProgress: Codable {
    let currentLevel: Int // 1-10
    let currentScore: Double
    let nextLevelThreshold: Double
    let progressPercentage: Double
}

// Backend returns: { id, type, createdAt, raterName, raterGender } (see journeyService.ts:266)
struct RecentRating: Codable {
    let id: String
    let type: String
    let createdAt: Date
    let raterName: String?
    let raterGender: String?
}

struct RandomPhotosResponse: Codable {
    let success: Bool
    let data: [RatingPhoto]
}

struct RatingPhoto: Codable {
    let id: String
    let userId: String
    let key: String?
    let url: String
    let format: String
    let size: Int?
    let uploadedAt: Date
    let user: PhotoUser
}

struct PhotoUser: Codable {
    let id: String
    let name: String
    let gender: String?
}

// MARK: - Rate API Implementation

class RateAPI {
    
    private let apiClient = APIClient.shared
    
    // MARK: - Rating Operations
    
    /// Rate a photo (raterId extracted from JWT token)
    func ratePhoto(photoId: String, type: RatingType) async throws -> RatePhotoResponse {
        let body: [String: Any] = [
            "photoId": photoId,
            "type": type.rawValue
        ]

        return try await apiClient.performRequest(
            endpoint: "/api/rate/photo",
            method: .POST,
            body: body,
            responseType: RatePhotoResponse.self
        )
    }
    
    /// Get comprehensive journey info
    func getJourneyInfo(userId: String) async throws -> JourneyInfoResponse {
        return try await apiClient.performRequest(
            endpoint: "/api/info/journeyInfo/\(userId)",
            method: .GET,
            responseType: JourneyInfoResponse.self
        )
    }
    
    /// Get random photos for rating (userId extracted from JWT token)
    func getRandomPhotos(limit: Int = 10) async throws -> RandomPhotosResponse {
        print("🔍 Fetching random photos, limit: \(limit)")
        let response = try await apiClient.performRequest(
            endpoint: "/api/rate/photos/random?limit=\(limit)",
            method: .GET,
            responseType: RandomPhotosResponse.self
        )
        print("✅ Successfully fetched \(response.data.count) photos")
        return response
    }
}

// MARK: - Rating Type

enum RatingType: String, CaseIterable {
    case like = "like"
    case normal = "normal"
    
    var emoji: String {
        switch self {
        case .like: return "❤️"
        case .normal: return "🔄"
        }
    }
    
    var score: Double {
        switch self {
        case .like: return 1.0
        case .normal: return 0.2
        }
    }
}