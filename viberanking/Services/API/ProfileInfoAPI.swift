//
//  ProfileInfoAPI.swift
//  viberanking
//
//  Created by Kiro on 2025/01/27.
//

import Foundation

// MARK: - Profile Info API Response Models

struct ProfileInfoResponse: Codable {
    let success: Bool
    let data: ProfileInfoData
}

struct ProfileInfoData: Codable {
    // User basic info
    let user: UserBasicInfo

    // Backend returns "stats" not "journey" (see getProfileInfo.ts:131)
    let stats: ProfileJourneyInfo

    // Backend returns photos as plain array, not { photos, totalCount, hasMore } (see getProfileInfo.ts:147)
    let photos: [PhotoInfo]

    // Latest photo reference from backend bundle (optional)
    let latestPhoto: PhotoInfo?

    // Provide computed property for backward compatibility
    var journey: ProfileJourneyInfo {
        return stats
    }

    // Provide computed property for backward compatibility
    var photosData: UserPhotosData {
        return UserPhotosData(photos: photos, totalCount: photos.count, hasMore: false)
    }
}

struct UserBasicInfo: Codable {
    let id: String
    let name: String
    let email: String
    let avatar: String?  // API 實際返回的是 "avatar" 而不是 "profileImageURL"
    let gender: String?
    let provider: String?  // API 返回的額外字段
    // 注意：API 響應中沒有 createdAt 字段，所以移除它

    private enum CodingKeys: String, CodingKey {
        case id
        case name
        case email
        case avatar
        case gender
        case provider
    }

    init(id: String, name: String, email: String, avatar: String?, gender: String?, provider: String?) {
        self.id = id
        self.name = name
        self.email = email
        self.avatar = avatar
        self.gender = gender
        self.provider = provider
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        if let stringId = try container.decodeIfPresent(String.self, forKey: .id) {
            id = stringId
        } else if let intId = try container.decodeIfPresent(Int.self, forKey: .id) {
            id = String(intId)
        } else {
            id = ""
        }
        name = try container.decodeIfPresent(String.self, forKey: .name) ?? ""
        email = try container.decodeIfPresent(String.self, forKey: .email) ?? ""
        avatar = try container.decodeIfPresent(String.self, forKey: .avatar)
        gender = try container.decodeIfPresent(String.self, forKey: .gender)
        provider = try container.decodeIfPresent(String.self, forKey: .provider)
    }
}

struct UserPhotosData: Codable {
    let photos: [PhotoInfo]
    let totalCount: Int
    let hasMore: Bool
}

// 新的 ProfileJourneyInfo 模型，匹配新 API 響應結構
struct ProfileJourneyInfo: Codable {
    // 基本統計數據
    let totalScore: Double
    let likeCount: Int
    let normalCount: Int
    let totalRatings: Int
    
    // 排名信息
    let overallRank: Int
    let genderRank: Int?
    let totalUsers: Int
    
    // 性別吸引力分數
    let femaleAttraction: Double
    let maleAttraction: Double
    
    // 最近評分
    let recentRatings: [RecentRating]
    
    // 7天趨勢
    let weeklyTrend: [DailyScore]
    
    // 成就系統
    let achievements: [Achievement]
    let nextMilestone: Milestone?
    let levelProgress: LevelProgress

    // 每週進度數據
    let weeklyProgress: WeeklyProgress

    // 注意：新 API 響應中沒有 userId 字段，所以移除它
}

// MARK: - Profile Info API Implementation

class ProfileInfoAPI {
    
    private let apiClient = APIClient.shared
    
    /// Get comprehensive profile information including user data, journey stats, and photos
    func getProfileInfo(userId: String, photoLimit: Int = 60) async throws -> ProfileInfoResponse {
        print("🔧 ProfileInfoAPI: Starting getProfileInfo call")
        print("   📋 Request Parameters:")
        print("   - User ID: \(userId)")
        print("   - Photo Limit: \(photoLimit)")
        print("   - Timestamp: \(Date())")
        
        let endpoint = "/api/info/profileInfo/\(userId)?page=1&limit=\(photoLimit)"
        print("📡 ProfileInfoAPI: Requesting endpoint: \(endpoint)")

        let startTime = Date()
        let response = try await apiClient.performRequest(
            endpoint: endpoint,
            method: .GET,
            responseType: ProfileInfoResponse.self
        )
        let endTime = Date()
        let duration = endTime.timeIntervalSince(startTime)

        print("✅ ProfileInfoAPI: Request succeeded")
        print("   ⏱️ Duration: \(String(format: "%.2f", duration)) seconds")
        print("   📊 Response Analysis:")
        print("   - Success: \(response.success)")

        if response.success {
            let data = response.data
            print("   - User ID: \(data.user.id)")
            print("   - User Name: \(data.user.name)")
            print("   - Photos Count: \(data.photos.count)")
            print("   - Latest Photo ID: \(data.latestPhoto?.id ?? "None")")
        }

        return response
    }
}
