//
//  FileAPI.swift
//  viberanking
//
//  Created by Kiro on 2025/08/05.
//

import Foundation

// MARK: - File API Response Models

struct PhotoUploadResponse: Codable {
    let photoId: String
    let urls: PhotoURLs
    let uploadedAt: Date
}

// API 包裝響應結構
struct APIResponse<T: Codable>: Codable {
    let success: Bool
    let data: T
}

struct PhotoListResponse: Codable {
    let photos: [PhotoInfo]
    let totalCount: Int
    let hasMore: Bool
}

struct PhotoInfo: Codable {
    let id: String
    let userId: String
    let urls: PhotoURLs
    let uploadedAt: Date
}

// MARK: - File API Implementation

class FileAPI {
    
    private let apiClient = APIClient.shared
    
    // MARK: - Photo Operations
    
    /// Upload photo
    func uploadPhoto(_ imageData: Data, userId: String) async throws -> PhotoUploadResponse {
        print("🚀 開始上傳文件到 API")
        print("📤 API 端點: /file/photos/upload")
        print("👤 用戶 ID: \(userId)")
        print("📦 圖片數據大小: \(imageData.count) bytes")
        
        let base64Image = imageData.base64EncodedString()
        
        let body: [String: Any] = [
            "userId": userId,
            "imageData": base64Image,
            "format": "png"
        ]
        
        do {
            let wrappedResponse = try await apiClient.performRequest(
                endpoint: "/api/file/photos/upload",
                method: .POST,
                body: body,
                responseType: APIResponse<PhotoUploadResponse>.self
            )
            
            if wrappedResponse.success {
                print("✅ API 上傳成功")
                return wrappedResponse.data
            } else {
                print("❌ API 返回失敗狀態")
                throw APIError.serverError(400)
            }
        } catch {
            print("❌ API 上傳失敗: \(error)")
            throw error
        }
    }
    
    /// Verify file exists
    func verifyFile(key: String) async throws -> Bool {
        let endpoint = "/api/file/verify/\(key)"
        
        // This would need to be adjusted based on your APIClient implementation
        // for handling responses that don't match PhotoListResponse
        return try await apiClient.performRequest(
            endpoint: endpoint,
            method: .GET,
            responseType: Bool.self // You might need to create a proper response type
        )
    }
    
    /// Get user photos list
    func getUserPhotos(userId: String, page: Int = 1, limit: Int = 20) async throws -> APIResponse<PhotoListResponse> {
        return try await apiClient.performRequest(
            endpoint: "/api/file/photos/user/\(userId)?page=\(page)&limit=\(limit)",
            method: .GET,
            responseType: APIResponse<PhotoListResponse>.self
        )
    }
    
    /// Delete file
    func deleteFile(photoId: String) async throws -> APIResponse<Bool> {
        return try await apiClient.performRequest(
            endpoint: "/api/file/photos/\(photoId)",
            method: .DELETE,
            responseType: APIResponse<Bool>.self
        )
    }
}
