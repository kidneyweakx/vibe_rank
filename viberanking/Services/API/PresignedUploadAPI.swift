//
//  PresignedUploadAPI.swift
//  viberanking
//
//  Created by Assistant on 2025/08/10.
//

import Foundation

// MARK: - Presigned Upload Models

struct PresignedUploadInfo: Codable {
    let url: String
    let key: String
    let headers: [String: String]?
    
    enum CodingKeys: String, CodingKey {
        case url
        case uploadUrl
        case key
        case headers
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        if let urlValue = try? container.decode(String.self, forKey: .url) {
            url = urlValue
        } else {
            url = try container.decode(String.self, forKey: .uploadUrl)
        }
        key = try container.decode(String.self, forKey: .key)
        headers = try? container.decode([String: String].self, forKey: .headers)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(url, forKey: .url)
        try container.encode(key, forKey: .key)
        try container.encodeIfPresent(headers, forKey: .headers)
    }
}

struct PresignedUploadResponse<T: Codable>: Codable {
    let success: Bool
    let data: T
}

// MARK: - Presigned Upload API

final class PresignedUploadAPI {
    private let apiClient = APIClient.shared
    
    func requestPresignedURL(userId: String, fileExtension: String = "webp", contentType: String = "image/webp") async throws -> PresignedUploadInfo {
        // Suggest a key to the backend; backend may override/return its own
        let generatedKey = "photos/\(userId)/\(UUID().uuidString).\(fileExtension)"
        let body: [String: Any] = [
            "userId": userId,
            "key": generatedKey,
            "contentType": contentType
        ]
        let response = try await apiClient.performRequest(
            endpoint: "/api/file/presign",
            method: .POST,
            body: body,
            responseType: PresignedUploadResponse<PresignedUploadInfo>.self
        )
        guard response.success else {
            throw APIError.serverError(400)
        }
        return response.data
    }
}


