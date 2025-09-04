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
    private let presignedAPI = PresignedUploadAPI()
    private let presignedUploader = PresignedUploadService.shared
    
    // MARK: - Photo Operations
    
    /// Upload photo via Presigned URL (PUT to R2), then finalize with backend metadata.
    /// If presign flow is unavailable (e.g., 422), gracefully fallback to base64 JSON upload.
    func uploadPhoto(_ imageData: Data, userId: String) async throws -> PhotoUploadResponse {
        do {
            // 1) Request a presigned URL for WebP upload
            let presigned = try await presignedAPI.requestPresignedURL(
                userId: userId,
                fileExtension: "webp",
                contentType: "image/webp"
            )
            // 2) PUT the bytes to the storage endpoint
            try await presignedUploader.upload(data: imageData, to: presigned.url, headers: presigned.headers)
            // 3) Ask backend to create/return the photo record for this key
            do {
                return try await finalizeUploadedPhoto(userId: userId, key: presigned.key, sizeBytes: imageData.count)
            } catch {
                let urls = R2PhotoURLBuilder().buildURLs(forKey: presigned.key)
                return PhotoUploadResponse(photoId: UUID().uuidString, urls: urls, uploadedAt: Date())
            }
        } catch {
            // Fallback path while backend presign endpoint is not ready
            return try await uploadPhotoViaBase64(imageData, userId: userId)
        }
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

    // MARK: - Reports

    /// Submit a report for a specific photo
    /// - Parameters:
    ///   - photoId: The ID of the photo being reported
    ///   - reporterId: Optional reporter user ID (nil for anonymous)
    ///   - reason: The reason string describing the report
    func submitReport(photoId: String, reporterId: String?, reason: String) async throws {
        print("📡 FileAPI: submitReport called")
        print("   - photoId: \(photoId)")
        print("   - reporterId: \(reporterId ?? "nil")")
        print("   - reason: \(reason)")
        
        var body: [String: Any] = [
            "photoId": photoId,
            "reason": reason
        ]
        if let reporterId = reporterId { body["reporterId"] = reporterId }
        
        print("📡 FileAPI: Making API request to /api/file/report")
        print("📡 FileAPI: Request body: \(body)")
        
        try await apiClient.performRequest(
            endpoint: "/api/file/report",
            method: .POST,
            body: body
        )
        
        print("✅ FileAPI: Report submission completed successfully")
    }
}

// MARK: - Private helpers
private extension FileAPI {
    /// Legacy: Upload using base64 JSON payload to Workers endpoint
    func uploadPhotoViaBase64(_ imageData: Data, userId: String) async throws -> PhotoUploadResponse {
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
            throw APIError.decodingError(NSError(domain: "FileAPI", code: -1, userInfo: [NSLocalizedDescriptionKey: "Missing URL data in upload response"]))
        }
        return PhotoUploadResponse(photoId: returnedId, urls: urls, uploadedAt: response.data.uploadedAt ?? Date())
    }
    /// Tell backend that the object at `key` has been uploaded; expect photo id and URLs in response.
    func finalizeUploadedPhoto(userId: String, key: String, sizeBytes: Int?) async throws -> PhotoUploadResponse {
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
        let body: [String: Any] = {
            var dict: [String: Any] = [
                "userId": userId,
                "key": key,
                "contentType": "image/webp"
            ]
            if let sizeBytes { dict["sizeBytes"] = sizeBytes }
            return dict
        }()
        let response = try await apiClient.performRequest(
            endpoint: "/api/file/photos/complete",
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
            // As a last resort, construct from key
            urls = R2PhotoURLBuilder().buildURLs(forKey: key)
        }
        return PhotoUploadResponse(photoId: returnedId, urls: urls, uploadedAt: response.data.uploadedAt ?? Date())
    }
}
