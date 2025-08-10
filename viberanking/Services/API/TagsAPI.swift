//
//  TagsAPI.swift
//  viberanking
//
//  Created by Assistant on 2025/08/10.
//

import Foundation

struct CreateTagBody: Codable {
    let name: String
    let displayName: String
    let emoji: String?
    let color: String?
    let category: String?
}

struct TagsAttachBody: Codable {
    let tagIds: [String]
}

struct APIBoolResponse: Codable {
    let success: Bool
}

final class TagsAPI {
    private let apiClient = APIClient.shared

    func getAllTags(category: String? = nil) async throws -> TagListResponse {
        var endpoint = "/api/tags/"
        if let category = category, !category.isEmpty {
            endpoint += "?category=\(category.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? category)"
        }
        return try await apiClient.performRequest(endpoint: endpoint, method: .GET, responseType: TagListResponse.self)
    }

    func createTag(_ body: CreateTagBody) async throws -> TagListResponse {
        return try await apiClient.performRequest(
            endpoint: "/api/tags/",
            method: .POST,
            body: [
                "name": body.name,
                "displayName": body.displayName,
                "emoji": body.emoji as Any,
                "color": body.color as Any,
                "category": body.category as Any
            ].compactMapValues { $0 },
            responseType: TagListResponse.self
        )
    }

    func getTagsForPhoto(photoId: String) async throws -> TagListResponse {
        return try await apiClient.performRequest(
            endpoint: "/api/tags/photos/\(photoId)",
            method: .GET,
            responseType: TagListResponse.self
        )
    }

    func attachTags(to photoId: String, tagIds: [String]) async throws -> APIBoolResponse {
        return try await apiClient.performRequest(
            endpoint: "/api/tags/photos/\(photoId)",
            method: .POST,
            body: ["tagIds": tagIds],
            responseType: APIBoolResponse.self
        )
    }

    func searchTags(by tagIds: [String], limit: Int? = nil, offset: Int? = nil) async throws -> TagListResponse {
        var params = ["tagIds": tagIds.joined(separator: ",")]
        if let limit = limit { params["limit"] = String(limit) }
        if let offset = offset { params["offset"] = String(offset) }
        let query = params.map { "\($0.key)=\($0.value.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? $0.value)" }.joined(separator: "&")
        let endpoint = "/api/tags/search?\(query)"
        return try await apiClient.performRequest(endpoint: endpoint, method: .GET, responseType: TagListResponse.self)
    }
}


