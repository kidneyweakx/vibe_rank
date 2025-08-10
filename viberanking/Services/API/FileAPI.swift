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
    // Removed presigned flow in favor of `/api/file/photos/upload`
    
    // MARK: - Photo Operations
    
    /// Upload photo by calling backend `/api/file/photos/upload` with base64 payload.
    func uploadPhoto(_ imageData: Data, userId: String) async throws -> PhotoUploadResponse {
        struct UploadData: Codable {
            let id: String?
            let photoId: String?
            let url: String?
            let urls: PhotoURLs?
            let uploadedAt: Date?
        }
        struct UploadResponse: Codable {
            let success: Bool
            let data: UploadData
        }
        let base64 = imageData.base64EncodedString()
        let body: [String: Any] = [
            "userId": userId,
            "imageData": base64,
            "format": "webp"
        ]
        let response = try await apiClient.performRequest(
            endpoint: "/api/file/photos/upload",
            method: .POST,
            body: body,
            responseType: UploadResponse.self
        )
        guard response.success else { throw APIError.serverError(400) }
        let returnedId = response.data.photoId ?? response.data.id ?? UUID().uuidString
        let urls: PhotoURLs
        if let u = response.data.urls {
            urls = u
        } else if let urlString = response.data.url {
            urls = PhotoURLs(original: urlString)
        } else {
            // Fallback: cannot build URLs without backend data
            throw APIError.decodingError(NSError(domain: "FileAPI", code: -1, userInfo: [NSLocalizedDescriptionKey: "Missing URL data in upload response"]))
        }
        return PhotoUploadResponse(photoId: returnedId, urls: urls, uploadedAt: response.data.uploadedAt ?? Date())
    }
    
    /// Get signed download URL for a storage key (for private buckets)
    func getSignedDownloadURL(key: String, expiresInSeconds: Int = 600) async throws -> URL {
        struct SignedURLResponse: Codable { let url: String }
        let response: APIResponse<SignedURLResponse> = try await apiClient.performRequest(
            endpoint: "/api/file/signed-url?key=\(key.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? key)&expires=\(expiresInSeconds)",
            method: .GET,
            responseType: APIResponse<SignedURLResponse>.self
        )
        guard response.success, let url = URL(string: response.data.url) else {
            throw APIError.serverError(400)
        }
        return url
    }

    /// Verify file exists
    func verifyFile(key: String) async throws -> Bool {
        let endpoint = "/api/file/verify/\(key)"
        try await apiClient.performRequest(endpoint: endpoint, method: .GET)
        return true
    }
    
    /// Get user photos list
    func getUserPhotos(userId: String, page: Int? = nil, limit: Int? = nil) async throws -> APIResponse<PhotoListResponse> {
        var endpoint = "/api/file/photos/user/\(userId)"
        var query: [String] = []
        if let page = page { query.append("page=\(page)") }
        if let limit = limit { query.append("limit=\(limit)") }
        if !query.isEmpty { endpoint += "?" + query.joined(separator: "&") }
        return try await apiClient.performRequest(
            endpoint: endpoint,
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
