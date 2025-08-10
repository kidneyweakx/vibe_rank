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
}

// MARK: - Tag List Response
struct TagListResponse: Codable {
    let success: Bool
    let data: [Tag]
}


