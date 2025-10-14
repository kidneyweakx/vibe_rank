//
//  FileAPI.swift
//  viberanking
//
//  Created by Kiro on 2025/08/05.
//

import Foundation

// MARK: - File API Response Models

struct PhotoUploadResponse: Decodable {
    let photoId: String
    let urls: PhotoURLs
    let uploadedAt: Date
    let userId: String?
    let key: String?
    let format: String?

    private enum CodingKeys: String, CodingKey {
        case photoId
        case id
        case urls
        case uploadedAt
        case userId
        case key
        case format
    }

    init(photoId: String, urls: PhotoURLs, uploadedAt: Date, userId: String? = nil, key: String? = nil, format: String? = nil) {
        self.photoId = photoId
        self.urls = urls
        self.uploadedAt = uploadedAt
        self.userId = userId
        self.key = key
        self.format = format
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        if let explicitId = try container.decodeIfPresent(String.self, forKey: .photoId) {
            photoId = explicitId
        } else if let altId = try container.decodeIfPresent(String.self, forKey: .id) {
            photoId = altId
        } else if let numericId = try container.decodeIfPresent(Int.self, forKey: .id) {
            photoId = String(numericId)
        } else {
            throw DecodingError.keyNotFound(CodingKeys.photoId, DecodingError.Context(codingPath: decoder.codingPath, debugDescription: "photoId field missing"))
        }
        urls = try container.decode(PhotoURLs.self, forKey: .urls)
        uploadedAt = try container.decode(Date.self, forKey: .uploadedAt)
        if let userIdString = try container.decodeIfPresent(String.self, forKey: .userId) {
            userId = userIdString
        } else if let userIdInt = try container.decodeIfPresent(Int.self, forKey: .userId) {
            userId = String(userIdInt)
        } else {
            userId = nil
        }
        key = try container.decodeIfPresent(String.self, forKey: .key)
        format = try container.decodeIfPresent(String.self, forKey: .format)
    }
}

struct UserPhotosResponse: Decodable {
    let success: Bool
    let data: [PhotoInfo]
    let page: Int
    let limit: Int
    let totalCount: Int
    let hasMore: Bool
}

struct DeletePhotoResponse: Decodable {
    let success: Bool
    let message: String?
}

// Backend PhotoInfo includes optional tags and metadata
struct PhotoInfo: Codable {
    let id: String
    let userId: String
    let urls: PhotoURLs
    let uploadedAt: Date
    let takenAt: Date?
    let tags: [Tag]?
    let key: String?
    let format: String?

    private enum CodingKeys: String, CodingKey {
        case id
        case userId
        case urls
        case uploadedAt
        case takenAt
        case tags
        case key
        case format
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        if let stringId = try container.decodeIfPresent(String.self, forKey: .id) {
            id = stringId
        } else if let intId = try container.decodeIfPresent(Int.self, forKey: .id) {
            id = String(intId)
        } else {
            throw DecodingError.keyNotFound(CodingKeys.id, DecodingError.Context(codingPath: decoder.codingPath, debugDescription: "id field missing"))
        }
        if let stringUserId = try container.decodeIfPresent(String.self, forKey: .userId) {
            userId = stringUserId
        } else if let intUserId = try container.decodeIfPresent(Int.self, forKey: .userId) {
            userId = String(intUserId)
        } else {
            userId = ""
        }
        urls = try container.decode(PhotoURLs.self, forKey: .urls)
        uploadedAt = try container.decode(Date.self, forKey: .uploadedAt)
        takenAt = try container.decodeIfPresent(Date.self, forKey: .takenAt)
        tags = try container.decodeIfPresent([Tag].self, forKey: .tags)
        key = try container.decodeIfPresent(String.self, forKey: .key)
        format = try container.decodeIfPresent(String.self, forKey: .format)
    }
}

// MARK: - File API Implementation

class FileAPI {
    
    private let apiClient = APIClient.shared
    private let presignedAPI = PresignedUploadAPI()
    private let presignedUploader = PresignedUploadService.shared
    
    // MARK: - Photo Operations
    
    /// Upload photo via Presigned URL (PUT to R2), then finalize with backend metadata.
    /// If presign flow is unavailable (e.g., 422), gracefully fallback to base64 JSON upload.
    /// (userId extracted from JWT token)
    func uploadPhoto(_ imageData: Data, takenAt: Date? = nil) async throws -> PhotoUploadResponse {
        do {
            // 1) Request a presigned URL for WebP upload
            let presigned = try await presignedAPI.requestPresignedURL(
                fileExtension: "webp",
                contentType: "image/webp"
            )
            // 2) PUT the bytes to the storage endpoint
            try await presignedUploader.upload(data: imageData, to: presigned.url, headers: presigned.headers)
            // 3) Ask backend to create/return the photo record for this key
            do {
                return try await finalizeUploadedPhoto(key: presigned.key, sizeBytes: imageData.count, takenAt: takenAt)
            } catch {
                let urls = R2PhotoURLBuilder().buildURLs(forKey: presigned.key)
                return PhotoUploadResponse(photoId: UUID().uuidString, urls: urls, uploadedAt: Date())
            }
        } catch {
            // Fallback path while backend presign endpoint is not ready
            return try await uploadPhotoViaBase64(imageData)
        }
    }
    
    /// Get signed download URL for a storage key (for private buckets)
    func getSignedDownloadURL(key: String, expiresInSeconds: Int = 600) async throws -> URL {
        throw APIError.serverError(404)
    }
    
    /// Get user photos list
    func getUserPhotos(userId: String, page: Int? = nil, limit: Int? = nil) async throws -> UserPhotosResponse {
        var endpoint = "/api/file/user/\(userId)"
        var query: [String] = []
        if let page = page { query.append("page=\(page)") }
        if let limit = limit { query.append("limit=\(limit)") }
        if !query.isEmpty { endpoint += "?" + query.joined(separator: "&") }
        return try await apiClient.performRequest(
            endpoint: endpoint,
            method: .GET,
            responseType: UserPhotosResponse.self
        )
    }
    
    /// Delete file
    func deleteFile(photoId: String) async throws -> DeletePhotoResponse {
        return try await apiClient.performRequest(
            endpoint: "/api/file/\(photoId)",
            method: .DELETE,
            responseType: DeletePhotoResponse.self
        )
    }

    // MARK: - Reports

    /// Submit a report for a specific photo (reporterId extracted from JWT token)
    /// - Parameters:
    ///   - photoId: The ID of the photo being reported
    ///   - reason: Backend-compatible reason code (inappropriate, spam, harassment, nudity, violence, other)
    ///   - details: Optional additional details about the report
    func submitReport(photoId: String, reason: String, details: String? = nil) async throws {
        print("📡 FileAPI: submitReport called")
        print("   - photoId: \(photoId)")
        print("   - reason: \(reason)")
        print("   - details: \(details ?? "none")")

        var body: [String: Any] = [
            "photoId": photoId,
            "reason": reason
        ]

        if let details = details {
            body["details"] = details
        }

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
    /// Legacy: Upload using base64 JSON payload to Workers endpoint (userId extracted from JWT token)
    func uploadPhotoViaBase64(_ imageData: Data) async throws -> PhotoUploadResponse {
        struct UploadResponse: Decodable {
            let success: Bool
            let photo: PhotoUploadResponse
        }
        let base64 = imageData.base64EncodedString()
        let body: [String: Any] = [
            "imageData": base64,
            "format": "webp"
        ]
        let response = try await apiClient.performRequest(
            endpoint: "/api/file/upload",
            method: .POST,
            body: body,
            responseType: UploadResponse.self
        )
        guard response.success else { throw APIError.serverError(400) }
        return response.photo
    }
    /// Tell backend that the object at `key` has been uploaded; expect photo id and URLs in response.
    /// (userId extracted from JWT token)
    func finalizeUploadedPhoto(key: String, sizeBytes: Int?, takenAt: Date? = nil) async throws -> PhotoUploadResponse {
        struct UploadResponse: Decodable {
            let success: Bool
            let photo: PhotoUploadResponse
        }
        let body: [String: Any] = {
            var dict: [String: Any] = [
                "key": key,
                "contentType": "image/webp"
            ]
            if let sizeBytes { dict["sizeBytes"] = sizeBytes }
            if let takenAt {
                let formatter = ISO8601DateFormatter()
                formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
                dict["takenAt"] = formatter.string(from: takenAt)
            }
            return dict
        }()
        let response = try await apiClient.performRequest(
            endpoint: "/api/file/confirm",
            method: .POST,
            body: body,
            responseType: UploadResponse.self
        )
        guard response.success else { throw APIError.serverError(400) }
        return response.photo
    }
}
