//
//  StyleReport.swift
//  viberanking
//
//  Created by Kiro on 2025/07/23.
//

import Foundation

// MARK: - Style Report Model
struct StyleReport: Codable, Identifiable {
    let id: String
    let userId: String
    let dominantStyle: StyleType
    let styleBreakdown: [String: Double] // Using String keys for Codable compatibility
    let ranking: StyleRanking
    let recommendations: [String]
    let generatedAt: Date
    
    init(userId: String,
         dominantStyle: StyleType,
         styleBreakdown: [StyleType: Double],
         ranking: StyleRanking,
         recommendations: [String]) {
        self.id = UUID().uuidString
        self.userId = userId
        self.dominantStyle = dominantStyle
        // Convert StyleType keys to String keys for Codable compatibility
        self.styleBreakdown = Dictionary(uniqueKeysWithValues: styleBreakdown.map { ($0.key.rawValue, $0.value) })
        self.ranking = ranking
        self.recommendations = recommendations
        self.generatedAt = Date()
    }
}

// MARK: - Style Type Enum
enum StyleType: String, CaseIterable, Codable {
    case elegant = "優雅"
    case casual = "休閒"
    case trendy = "時尚"
    case classic = "經典"
    case sporty = "運動"
    case artistic = "藝術"
    
    var displayName: String {
        return self.rawValue
    }
    
    var description: String {
        switch self {
        case .elegant:
            return "展現優雅氣質，注重細節與品味"
        case .casual:
            return "輕鬆自然的日常風格"
        case .trendy:
            return "緊跟時尚潮流，展現個性"
        case .classic:
            return "經典不敗的永恆風格"
        case .sporty:
            return "活力運動風，展現健康活力"
        case .artistic:
            return "富有創意與藝術感的獨特風格"
        }
    }
}

// MARK: - Style Ranking
struct StyleRanking: Codable {
    let overallRank: Int
    let totalUsers: Int
    let categoryRanks: [String: Int] // Using String keys for Codable compatibility
    let percentile: Double
    
    init(overallRank: Int, totalUsers: Int, categoryRanks: [StyleType: Int] = [:]) {
        self.overallRank = overallRank
        self.totalUsers = totalUsers
        // Convert StyleType keys to String keys for Codable compatibility
        self.categoryRanks = Dictionary(uniqueKeysWithValues: categoryRanks.map { ($0.key.rawValue, $0.value) })
        self.percentile = Double(totalUsers - overallRank + 1) / Double(totalUsers) * 100
    }
    
    var rankingDescription: String {
        let percentage = Int(percentile)
        return "您的風格排名前 \(percentage)%"
    }
}

// MARK: - Style Evolution (for gamification)
struct StyleEvolution: Codable {
    let userId: String
    let reports: [StyleReport]
    let evolutionTrend: [String: Double] // Using String keys for Codable compatibility
    let lastUpdated: Date
    
    init(userId: String, reports: [StyleReport] = []) {
        self.userId = userId
        self.reports = reports
        self.evolutionTrend = [:]
        self.lastUpdated = Date()
    }
    
    var hasEvolution: Bool {
        return reports.count > 1
    }
    
    var latestReport: StyleReport? {
        return reports.sorted { $0.generatedAt > $1.generatedAt }.first
    }
}