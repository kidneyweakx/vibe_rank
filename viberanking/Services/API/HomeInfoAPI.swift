//
//  HomeInfoAPI.swift
//  viberanking
//
//  Created by Kiro on 2025/01/27.
//

import Foundation

// MARK: - Home Info API Response Models

struct HomeInfoResponse: Codable {
    let success: Bool
    let data: HomeInfoData
}

struct HomeInfoData: Codable {
    let topUsers: TopUsersData
    let recentEvents: [RecentEvent]
}

// Backend returns { overall, male, female, totalUsers } from getRankingList
struct TopUsersData: Codable {
    let overall: [TopUser]
    let male: [TopUser]
    let female: [TopUser]
    let totalUsers: Int
}

struct TopUser: Codable {
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

struct RecentEvent: Codable {
    let id: String
    let title: String
    let description: String?
    let key: String
    let url: String?
    let imageUrl: String
    let format: String
    let size: Int
    let startsAt: String
    let endsAt: String?
    let createdAt: String
    let updatedAt: String
}

// Legacy models kept for backward compatibility
struct FeaturedUser: Codable {
    let id: String
    let name: String
    let avatar: String?
    let rank: Int
    let score: Double
    let recentPhotos: [String]
    let isRising: Bool
}

struct TrendingEvent: Codable {
    let id: String
    let title: String
    let description: String?
    let imageURL: String
    let startDate: Date
    let endDate: Date?
    let participantCount: Int
    let isActive: Bool
}

struct HomeStatistics: Codable {
    let totalUsers: Int
    let totalPhotos: Int
    let totalRatings: Int
    let activeEvents: Int
}

struct Announcement: Codable {
    let id: String
    let title: String
    let message: String
    let type: AnnouncementType
    let isActive: Bool
    let createdAt: Date
}

enum AnnouncementType: String, Codable {
    case info = "info"
    case warning = "warning"
    case success = "success"
    case event = "event"
}

// MARK: - Home Info API Implementation

class HomeInfoAPI {
    
    private let apiClient = APIClient.shared
    
    /// Get comprehensive home information including featured users, events, and statistics
    func getHomeInfo() async throws -> HomeInfoResponse {
        return try await apiClient.performRequest(
            endpoint: "/api/info/homeInfo",
            method: .GET,
            responseType: HomeInfoResponse.self
        )
    }
}
