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

struct ProfilePictureUploadResponse: Codable {
    let success: Bool
    let data: ProfilePictureData
}

struct ProfilePictureData: Codable {
    let photoId: String
    let urls: ProfilePictureURLs
    let uploadedAt: Date
    let avatarUrl: String  // 後端實際返回的字段名
    
    // 提供一個計算屬性來保持向後兼容
    var avatar: String {
        return avatarUrl
    }
}

struct ProfilePictureURLs: Codable {
    let original: String
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
    
    /// Update user profile (supports extended fields per OpenAPI)
    func updateUserProfile(
        userId: String,
        name: String? = nil,
        gender: String? = nil,
        avatar: String? = nil,
        bio: String? = nil,
        location: String? = nil,
        language: String? = nil,
        timezone: String? = nil,
        notificationsEnabled: Bool? = nil
    ) async throws -> UserProfileResponse {
        var body: [String: Any] = [:]
        if let name = name { body["name"] = name }
        if let gender = gender { body["gender"] = gender }
        if let avatar = avatar { body["avatar"] = avatar }
        if let bio = bio { body["bio"] = bio }
        if let location = location { body["location"] = location }
        if let language = language { body["language"] = language }
        if let timezone = timezone { body["timezone"] = timezone }
        if let notificationsEnabled = notificationsEnabled { body["notificationsEnabled"] = notificationsEnabled }
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
    
    /// Upload profile picture
    func uploadProfilePicture(userId: String, imageData: Data) async throws -> ProfilePictureUploadResponse {
        // Create multipart form data
        let boundary = "Boundary-\(UUID().uuidString)"
        var body = Data()
        
        // Add userId field
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"userId\"\r\n\r\n".data(using: .utf8)!)
        body.append("\(userId)\r\n".data(using: .utf8)!)
        
        // Add image file
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"imageFile\"; filename=\"profile.webp\"\r\n".data(using: .utf8)!)
        body.append("Content-Type: image/webp\r\n\r\n".data(using: .utf8)!)
        body.append(imageData)
        body.append("\r\n--\(boundary)--\r\n".data(using: .utf8)!)
        
        guard let url = URL(string: "\(apiClient.baseURL)/api/user/profilePicture") else {
            throw APIError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")

        // Add JWT token if available
        if let jwtToken = try? KeychainItem.readJWTToken() {
            request.setValue("Bearer \(jwtToken)", forHTTPHeaderField: "Authorization")
        }

        request.httpBody = body
        
        print("📤 ProfilePicture Upload Request:")
        print("  - URL: \(url)")
        print("  - Method: POST")
        print("  - Content-Type: multipart/form-data; boundary=\(boundary)")
        print("  - UserID: \(userId)")
        print("  - ImageData Size: \(imageData.count) bytes")
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            print("❌ Invalid HTTP response")
            throw APIError.invalidResponse
        }
        
        print("📥 ProfilePicture Upload Response:")
        print("  - Status Code: \(httpResponse.statusCode)")
        print("  - Headers: \(httpResponse.allHeaderFields)")
        print("  - Response Data Size: \(data.count) bytes")
        
        // Log raw response data
        if let responseString = String(data: data, encoding: .utf8) {
            print("  - Raw Response: \(responseString)")
        } else {
            print("  - Raw Response: (Unable to convert to string)")
        }
        
        guard httpResponse.statusCode == 200 else {
            print("❌ Server error with status code: \(httpResponse.statusCode)")
            throw APIError.serverError(httpResponse.statusCode)
        }
        
        let decoder = JSONDecoder()
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSS'Z'"
        dateFormatter.timeZone = TimeZone(abbreviation: "UTC")
        decoder.dateDecodingStrategy = .formatted(dateFormatter)
        
        do {
            let result = try decoder.decode(ProfilePictureUploadResponse.self, from: data)
            print("✅ Successfully decoded ProfilePictureUploadResponse:")
            print("  - Success: \(result.success)")
            print("  - Avatar URL: \(result.data.avatar)")
            return result
        } catch {
            print("❌ Failed to decode ProfilePictureUploadResponse:")
            print("  - Error: \(error)")
            print("  - Error Type: \(type(of: error))")
            
            if let decodingError = error as? DecodingError {
                switch decodingError {
                case .keyNotFound(let key, let context):
                    print("  - Missing Key: \(key)")
                    print("  - Context: \(context)")
                    print("  - Coding Path: \(context.codingPath)")
                case .typeMismatch(let type, let context):
                    print("  - Type Mismatch: Expected \(type)")
                    print("  - Context: \(context)")
                case .valueNotFound(let type, let context):
                    print("  - Value Not Found: \(type)")
                    print("  - Context: \(context)")
                case .dataCorrupted(let context):
                    print("  - Data Corrupted: \(context)")
                @unknown default:
                    print("  - Unknown decoding error")
                }
            }
            
            // Try to decode as generic JSON to see what we actually got
            do {
                if let jsonObject = try JSONSerialization.jsonObject(with: data) as? [String: Any] {
                    print("  - Actual JSON Structure:")
                    print("    \(jsonObject)")
                }
            } catch {
                print("  - Could not parse as JSON: \(error)")
            }
            
            throw error
        }
    }

    /// Permanently delete the current authenticated user's account
    func deleteAccount() async throws {
        try await apiClient.performRequest(
            endpoint: "/api/user/delete",
            method: .DELETE
        )
    }
}