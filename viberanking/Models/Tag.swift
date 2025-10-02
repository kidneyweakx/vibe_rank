//
//  Tag.swift
//  viberanking
//
//  Created by Assistant on 2025/08/10.
//

import Foundation

// MARK: - Tag Model
struct Tag: Codable, Identifiable, Hashable {
    let id: String
    let name: String
    let displayName: String
    let emoji: String?
    let color: String?
    let category: String?
    let normal: Bool

    // Custom decoding to provide default for backward compatibility
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        name = try container.decode(String.self, forKey: .name)
        displayName = try container.decode(String.self, forKey: .displayName)
        emoji = try container.decodeIfPresent(String.self, forKey: .emoji)
        color = try container.decodeIfPresent(String.self, forKey: .color)
        category = try container.decodeIfPresent(String.self, forKey: .category)
        normal = try container.decodeIfPresent(Bool.self, forKey: .normal) ?? false
    }

    // Memberwise initializer for manual construction
    init(id: String, name: String, displayName: String, emoji: String? = nil, color: String? = nil, category: String? = nil, normal: Bool = false) {
        self.id = id
        self.name = name
        self.displayName = displayName
        self.emoji = emoji
        self.color = color
        self.category = category
        self.normal = normal
    }
}

// MARK: - Tag List Response
struct TagListResponse: Codable {
    let success: Bool
    let data: [Tag]
}


