//
//  EventAPI.swift
//  viberanking
//
//  Created by Assistant on 2025/08/11.
//

import Foundation

// MARK: - Event API Models

struct EventListResponse: Decodable {
    let success: Bool
    let data: [EventItem]
}

struct EventItem: Decodable, Identifiable {
    let id: String
    let title: String
    let description: String?
    let imageUrl: String?
    let linkUrl: String?
    let startsAt: String?
    let endsAt: String?

    enum CodingKeys: String, CodingKey {
        case id
        case title
        case description
        case imageUrl
        case linkUrl
        case startsAt
        case endsAt
        // Alternatives
        case name
        case image
        case url
        case imageURL
        case startAt
        case endAt
        case eventId
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        // id could be "id" or "eventId"
        self.id = (try? container.decode(String.self, forKey: .id))
            ?? (try? container.decode(String.self, forKey: .eventId))
            ?? UUID().uuidString

        // title could be "title" or fallback to "name"
        self.title = (try? container.decode(String.self, forKey: .title))
            ?? (try? container.decode(String.self, forKey: .name))
            ?? ""

        self.description = try? container.decodeIfPresent(String.self, forKey: .description)

        // image url could be provided in various keys
        var resolvedImageUrl: String? = nil
        if let value = try? container.decodeIfPresent(String.self, forKey: .imageUrl) { resolvedImageUrl = value }
        if resolvedImageUrl == nil, let value = try? container.decodeIfPresent(String.self, forKey: .image) { resolvedImageUrl = value }
        if resolvedImageUrl == nil, let value = try? container.decodeIfPresent(String.self, forKey: .imageURL) { resolvedImageUrl = value }
        if resolvedImageUrl == nil, let value = try? container.decodeIfPresent(String.self, forKey: .url) { resolvedImageUrl = value }
        self.imageUrl = resolvedImageUrl

        // link could be a dedicated link or generic url
        var resolvedLink: String? = nil
        if let value = try? container.decodeIfPresent(String.self, forKey: .linkUrl) { resolvedLink = value }
        if resolvedLink == nil, let value = try? container.decodeIfPresent(String.self, forKey: .url) { resolvedLink = value }
        self.linkUrl = resolvedLink

        // dates as raw strings (decode leniently)
        var resolvedStart: String? = nil
        if let value = try? container.decodeIfPresent(String.self, forKey: .startsAt) { resolvedStart = value }
        if resolvedStart == nil, let value = try? container.decodeIfPresent(String.self, forKey: .startAt) { resolvedStart = value }
        self.startsAt = resolvedStart

        var resolvedEnd: String? = nil
        if let value = try? container.decodeIfPresent(String.self, forKey: .endsAt) { resolvedEnd = value }
        if resolvedEnd == nil, let value = try? container.decodeIfPresent(String.self, forKey: .endAt) { resolvedEnd = value }
        self.endsAt = resolvedEnd
    }
}

// MARK: - Event API

final class EventAPI {
    private let apiClient = APIClient.shared

    /// Fetch list of events for home feed
    func getEventList() async throws -> EventListResponse {
        return try await apiClient.performRequest(
            endpoint: "/api/event/list",
            method: .GET,
            responseType: EventListResponse.self
        )
    }
}


