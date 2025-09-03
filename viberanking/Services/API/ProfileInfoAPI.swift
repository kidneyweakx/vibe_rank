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
    
    // Journey/Stats info
    let journey: JourneyInfo
    
    // User photos
    let photos: UserPhotosData
}

struct UserBasicInfo: Codable {
    let id: String
    let name: String
    let email: String
    let profileImageURL: String?
    let gender: String?
    let createdAt: Date
}

struct UserPhotosData: Codable {
    let photos: [PhotoInfo]
    let totalCount: Int
    let hasMore: Bool
}

// MARK: - Profile Info API Implementation

class ProfileInfoAPI {
    
    private let apiClient = APIClient.shared
    
    /// Get comprehensive profile information including user data, journey stats, and photos
    func getProfileInfo(userId: String, photoLimit: Int = 60) async throws -> ProfileInfoResponse {
        return try await apiClient.performRequest(
            endpoint: "/api/info/profileInfo/\(userId)?photoLimit=\(photoLimit)",
            method: .GET,
            responseType: ProfileInfoResponse.self
        )
    }
}
