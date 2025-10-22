//
//  PresignedUploadAPI.swift
//  viberanking
//
//  Created by Assistant on 2025/08/10.
//

import Foundation

// MARK: - Presigned Upload Models

struct PresignedUploadInfo: Codable {
    let uploadUrl: String
    let key: String
    let headers: [String: String]?
    let expiresIn: Int?

    var url: String { uploadUrl }

    private enum CodingKeys: String, CodingKey {
        case uploadUrl
        case url
        case key
        case headers
        case expiresIn
    }

    init(uploadUrl: String, key: String, headers: [String: String]?, expiresIn: Int?) {
        self.uploadUrl = uploadUrl
        self.key = key
        self.headers = headers
        self.expiresIn = expiresIn
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        if let explicitUploadUrl = try container.decodeIfPresent(String.self, forKey: .uploadUrl) {
            uploadUrl = explicitUploadUrl
        } else if let legacyUrl = try container.decodeIfPresent(String.self, forKey: .url) {
            uploadUrl = legacyUrl
        } else {
            throw DecodingError.keyNotFound(CodingKeys.uploadUrl, DecodingError.Context(codingPath: decoder.codingPath, debugDescription: "uploadUrl field missing"))
        }
        key = try container.decode(String.self, forKey: .key)
        headers = try container.decodeIfPresent([String: String].self, forKey: .headers)
        expiresIn = try container.decodeIfPresent(Int.self, forKey: .expiresIn)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(uploadUrl, forKey: .uploadUrl)
        try container.encode(key, forKey: .key)
        try container.encodeIfPresent(headers, forKey: .headers)
        try container.encodeIfPresent(expiresIn, forKey: .expiresIn)
    }
}

private struct PresignedUploadEnvelope: Codable {
    let success: Bool
    let key: String
    let uploadUrl: String
    let headers: [String: String]?
    let expiresIn: Int?
}

// MARK: - Presigned Upload API

final class PresignedUploadAPI {
    private let apiClient = APIClient.shared
    
    /// Request presigned URL for upload (userId extracted from JWT token)
    func requestPresignedURL(fileExtension: String = "webp", contentType: String = "image/webp") async throws -> PresignedUploadInfo {
        // Suggest a key to the backend; backend may override/return its own
        let generatedKey = "photos/\(UUID().uuidString).\(fileExtension)"
        let body: [String: Any] = [
            "key": generatedKey,
            "contentType": contentType
        ]
        let response = try await apiClient.performRequest(
            endpoint: "/api/file/upload-url",
            method: .POST,
            body: body,
            responseType: PresignedUploadEnvelope.self
        )
        guard response.success else {
            throw APIError.serverError(400)
        }
        return PresignedUploadInfo(
            uploadUrl: response.uploadUrl,
            key: response.key,
            headers: response.headers,
            expiresIn: response.expiresIn
        )
    }
}


