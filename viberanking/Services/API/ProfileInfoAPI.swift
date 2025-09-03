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
    
    // Journey/Stats info - 使用新的 ProfileJourneyInfo 模型
    let journey: ProfileJourneyInfo
    
    // User photos
    let photos: UserPhotosData
}

struct UserBasicInfo: Codable {
    let id: String
    let name: String
    let email: String
    let avatar: String?  // API 實際返回的是 "avatar" 而不是 "profileImageURL"
    let gender: String?
    let provider: String?  // API 返回的額外字段
    // 注意：API 響應中沒有 createdAt 字段，所以移除它
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
        
        // First try with photoLimit parameter
        do {
            print("📡 ProfileInfoAPI: Attempting request with photoLimit parameter...")
            let endpoint = "/api/info/profileInfo/\(userId)?photoLimit=\(photoLimit)"
            print("   - Endpoint: \(endpoint)")
            
            let startTime = Date()
            let response = try await apiClient.performRequest(
                endpoint: endpoint,
                method: .GET,
                responseType: ProfileInfoResponse.self
            )
            let endTime = Date()
            let duration = endTime.timeIntervalSince(startTime)
            
            print("✅ ProfileInfoAPI: Request with photoLimit succeeded!")
            print("   ⏱️ Duration: \(String(format: "%.2f", duration)) seconds")
            print("   📊 Response Analysis:")
            print("   - Success: \(response.success)")
            
            if response.success {
                let data = response.data
                print("   - User ID: \(data.user.id)")
                print("   - User Name: \(data.user.name)")
                print("   - User Email: \(data.user.email)")
                print("   - User Avatar: \(data.user.avatar ?? "None")")
                print("   - User Gender: \(data.user.gender ?? "None")")
                print("   - User Provider: \(data.user.provider ?? "None")")
                print("   - Journey Info Available: \(data.journey != nil)")
                print("   - Photos Count: \(data.photos.photos.count)")
                print("   - Total Photos: \(data.photos.totalCount)")
                print("   - Has More Photos: \(data.photos.hasMore)")
            }
            
            return response
        } catch {
            print("⚠️ ProfileInfoAPI: Request with photoLimit failed, trying without parameter")
            print("   🔍 Error Details:")
            print("   - Error Type: \(type(of: error))")
            print("   - Error Description: \(error.localizedDescription)")
            
            if let urlError = error as? URLError {
                print("   - URL Error Code: \(urlError.code.rawValue)")
                print("   - Failed URL: \(urlError.failureURLString ?? "Unknown")")
            }
            
            // If that fails, try without photoLimit parameter (matching OpenAPI spec)
            print("📡 ProfileInfoAPI: Attempting request without photoLimit parameter...")
            let endpoint = "/api/info/profileInfo/\(userId)"
            print("   - Endpoint: \(endpoint)")
            
            let startTime = Date()
            let response = try await apiClient.performRequest(
                endpoint: endpoint,
                method: .GET,
                responseType: ProfileInfoResponse.self
            )
            let endTime = Date()
            let duration = endTime.timeIntervalSince(startTime)
            
            print("✅ ProfileInfoAPI: Request without photoLimit succeeded!")
            print("   ⏱️ Duration: \(String(format: "%.2f", duration)) seconds")
            print("   📊 Response Analysis:")
            print("   - Success: \(response.success)")
            
            if response.success {
                let data = response.data
                print("   - User ID: \(data.user.id)")
                print("   - User Name: \(data.user.name)")
                print("   - Photos Count: \(data.photos.photos.count)")
                print("   - Total Photos: \(data.photos.totalCount)")
            }
            
            return response
        }
    }
}
