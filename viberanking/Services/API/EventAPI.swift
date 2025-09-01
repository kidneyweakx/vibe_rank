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

    private enum CodingKeys: String, CodingKey {
        case success
        case data
        case items
        case list
        case results
    }

    init(success: Bool = true, data: [EventItem]) {
        self.success = success
        self.data = data
    }

    init(from decoder: Decoder) throws {
        // Try keyed container first
        if let container = try? decoder.container(keyedBy: CodingKeys.self) {
            let successValue = (try? container.decode(Bool.self, forKey: .success)) ?? true

            // Case 1: data is an array at root: { data: [...] }
            if let events = try? container.decode([EventItem].self, forKey: .data) {
                self.success = successValue
                self.data = events
                return
            }

            // Case 2: data is an object with items/list/results arrays: { data: { items: [...] } }
            if let nested = try? container.nestedContainer(keyedBy: CodingKeys.self, forKey: .data) {
                if let events = try? nested.decode([EventItem].self, forKey: .items) {
                    self.success = successValue
                    self.data = events
                    return
                }
                if let events = try? nested.decode([EventItem].self, forKey: .list) {
                    self.success = successValue
                    self.data = events
                    return
                }
                if let events = try? nested.decode([EventItem].self, forKey: .results) {
                    self.success = successValue
                    self.data = events
                    return
                }
            }

            // Case 3: items/list/results at top-level without data wrapper
            if let events = try? container.decode([EventItem].self, forKey: .items) {
                self.success = successValue
                self.data = events
                return
            }
            if let events = try? container.decode([EventItem].self, forKey: .list) {
                self.success = successValue
                self.data = events
                return
            }
            if let events = try? container.decode([EventItem].self, forKey: .results) {
                self.success = successValue
                self.data = events
                return
            }

            // Fallback: empty
            self.success = successValue
            self.data = []
            return
        }

        // Case 4: top-level is an array: [ ... ]
        let single = try decoder.singleValueContainer()
        if let events = try? single.decode([EventItem].self) {
            self.success = true
            self.data = events
            return
        }

        // Fallback: empty
        self.success = true
        self.data = []
    }
}

struct EventItem: Decodable, Identifiable {
    let id: String
    let title: String
    let description: String?
    let imageURL: String?
    let linkUrl: String?
    let startsAt: String?
    let endsAt: String?
    
    // Additional properties for enhanced HomeView
    let startDate: Date?
    let endDate: Date?
    let participantCount: Int
    let isActive: Bool

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
        case imageURL
        case url
        case startAt
        case endAt
        case eventId
        // Enhanced properties
        case participantCount
        case isActive
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
        if resolvedImageUrl == nil, let value = try? container.decodeIfPresent(String.self, forKey: .imageURL) { resolvedImageUrl = value }
        if resolvedImageUrl == nil, let value = try? container.decodeIfPresent(String.self, forKey: .image) { resolvedImageUrl = value }
        if resolvedImageUrl == nil, let value = try? container.decodeIfPresent(String.self, forKey: .url) { resolvedImageUrl = value }
        self.imageURL = resolvedImageUrl

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
        
        // Parse dates for enhanced properties
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSS'Z'"
        dateFormatter.timeZone = TimeZone(abbreviation: "UTC")
        
        self.startDate = resolvedStart.flatMap { dateFormatter.date(from: $0) }
        self.endDate = resolvedEnd.flatMap { dateFormatter.date(from: $0) }
        
        // Default values for enhanced properties
        self.participantCount = (try? container.decodeIfPresent(Int.self, forKey: .participantCount)) ?? 0
        self.isActive = (try? container.decodeIfPresent(Bool.self, forKey: .isActive)) ?? true
    }
    
    // Custom initializer for creating EventItem instances programmatically
    init(
        id: String,
        title: String,
        description: String? = nil,
        imageURL: String? = nil,
        linkUrl: String? = nil,
        startsAt: String? = nil,
        endsAt: String? = nil,
        startDate: Date? = nil,
        endDate: Date? = nil,
        participantCount: Int = 0,
        isActive: Bool = true
    ) {
        self.id = id
        self.title = title
        self.description = description
        self.imageURL = imageURL
        self.linkUrl = linkUrl
        self.startsAt = startsAt
        self.endsAt = endsAt
        self.startDate = startDate
        self.endDate = endDate
        self.participantCount = participantCount
        self.isActive = isActive
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


