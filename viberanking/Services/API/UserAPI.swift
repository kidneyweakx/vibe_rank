//
//  UserAPI.swift
//  viberanking
//
//  Created by Kiro on 2025/08/09.
//

import Foundation

// MARK: - User API Response Models

struct UserProfileResponse: Codable {
    let success: Bool
    let data: UserProfile
}

struct UserProfile: Codable {
    let id: String
    let email: String
    let name: String
    let avatar: String?
    let gender: String?
    let createdAt: Date
}

struct UserInfoResponse: Codable {
    let success: Bool
    let data: UserInfoData
}

struct UserInfoData: Codable {
    let user: PublicUserInfo
    let stats: UserPublicStats
    let recentPhotos: [RecentPhoto]
    let shareInfo: ShareInfo
}

struct PublicUserInfo: Codable {
    let id: String
    let name: String
    let avatar: String?
    let gender: String?
    let memberSince: Date
}

struct UserPublicStats: Codable {
    let totalScore: Double
    let likeCount: Int
    let normalCount: Int
    let totalRatings: Int
    let photoCount: Int
}

struct RecentPhoto: Codable {
    let id: String
    let url: String
    let uploadedAt: Date
}

struct ShareInfo: Codable {
    let shareUrl: String
    let shareText: String
    let qrCodeUrl: String
}

struct UserShareResponse: Codable {
    let success: Bool
    let data: UserShareData
}

struct UserShareData: Codable {
    let userId: String
    let userName: String
    let userAvatar: String?
    let shareUrl: String
    let apiUrl: String
    let qrCodeUrl: String
    let createdAt: Date
}

// MARK: - Username / ID Management Models

struct UserIDAvailabilityResponse: Codable {
    let success: Bool
    let available: Bool
    let message: String?
}

struct QRCodeResponse: Codable {
    let success: Bool
    let data: QRCodeData
}

struct QRCodeData: Codable {
    let qrText: String
    let displayUrl: String
    let userName: String
}

// MARK: - User API Implementation

class UserAPI {
    
    private let apiClient = APIClient.shared
    
    // MARK: - User Profile Operations
    
    /// Get user complete profile (requires authentication)
    func getUserProfile(userId: String) async throws -> UserProfileResponse {
        return try await apiClient.performRequest(
            endpoint: "/api/user/profile/\(userId)",
            method: .GET,
            responseType: UserProfileResponse.self
        )
    }
    
    /// Get user public information (shareable)
    func getUserInfo(userId: String) async throws -> UserInfoResponse {
        return try await apiClient.performRequest(
            endpoint: "/api/user/info/\(userId)",
            method: .GET,
            responseType: UserInfoResponse.self
        )
    }
    
    /// Generate share link
    func getUserShareLink(userId: String) async throws -> UserShareResponse {
        return try await apiClient.performRequest(
            endpoint: "/api/user/share/\(userId)",
            method: .GET,
            responseType: UserShareResponse.self
        )
    }
    
    /// Get QR code data
    func getQRCodeData(userId: String) async throws -> QRCodeResponse {
        return try await apiClient.performRequest(
            endpoint: "/api/user/qr/\(userId)",
            method: .GET,
            responseType: QRCodeResponse.self
        )
    }
    
    /// Update user profile
    func updateUserProfile(userId: String, name: String?, gender: String?, avatar: String?) async throws -> UserProfileResponse {
        var body: [String: Any] = [:]
        
        if let name = name {
            body["name"] = name
        }
        if let gender = gender {
            body["gender"] = gender
        }
        if let avatar = avatar {
            body["avatar"] = avatar
        }
        
        return try await apiClient.performRequest(
            endpoint: "/api/user/profile/\(userId)",
            method: .PUT,
            body: body,
            responseType: UserProfileResponse.self
        )
    }

    /// Check if a desired custom user ID is available
    func checkUserIDAvailable(_ desiredId: String) async throws -> UserIDAvailabilityResponse {
        return try await apiClient.performRequest(
            endpoint: "/api/user/id/check?desiredId=\(desiredId)",
            method: .GET,
            responseType: UserIDAvailabilityResponse.self
        )
    }

    /// Update the user's custom ID (username). Backend should handle conflict errors (e.g., 409)
    func updateUserID(currentUserId: String, newUserId: String) async throws {
        let body: [String: Any] = ["newId": newUserId]
        try await apiClient.performRequest(
            endpoint: "/api/user/id/\(currentUserId)",
            method: .PUT,
            body: body
        )
    }
}