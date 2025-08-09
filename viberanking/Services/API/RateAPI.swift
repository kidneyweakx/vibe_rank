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

struct UserStatsResponse: Codable {
    let success: Bool
    let data: UserStats
}

struct UserStats: Codable {
    let userId: String
    let totalScore: Double
    let likeCount: Int
    let normalCount: Int
    let totalRatings: Int
    let overallRank: Int
    let genderRank: Int?
    let recentRatings: [RecentRating]
}

struct RecentRating: Codable {
    let photoId: String
    let photoUrl: String
    let type: String
    let createdAt: Date
}

struct RankingsResponse: Codable {
    let success: Bool
    let data: RankingsData
}

struct RankingsData: Codable {
    let overall: [UserRanking]
    let male: [UserRanking]
    let female: [UserRanking]
    let totalUsers: Int
}

struct UserRanking: Codable {
    let userId: String
    let name: String
    let avatar: String?
    let gender: String?
    let totalScore: Double
    let likeCount: Int
    let normalCount: Int
    let totalRatings: Int
    let rank: Int
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
    
    /// Rate a photo
    func ratePhoto(raterId: String, photoId: String, type: RatingType) async throws -> RatePhotoResponse {
        let body: [String: Any] = [
            "raterId": raterId,
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
    
    /// Get user statistics and ranking
    func getUserStats(userId: String) async throws -> UserStatsResponse {
        return try await apiClient.performRequest(
            endpoint: "/api/rate/user/\(userId)/stats",
            method: .GET,
            responseType: UserStatsResponse.self
        )
    }
    
    /// Get rankings
    func getRankings(limit: Int = 50) async throws -> RankingsResponse {
        return try await apiClient.performRequest(
            endpoint: "/api/rate/rankings?limit=\(limit)",
            method: .GET,
            responseType: RankingsResponse.self
        )
    }
    
    /// Get random photos for rating
    func getRandomPhotos(userId: String, limit: Int = 10) async throws -> RandomPhotosResponse {
        print("🔍 Fetching random photos for userId: \(userId), limit: \(limit)")
        let response = try await apiClient.performRequest(
            endpoint: "/api/rate/photos/random?userId=\(userId)&limit=\(limit)",
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