//
//  StyleReport.swift
//  viberanking
//
//  Created by Kiro on 2025/07/23.
//

import Foundation

// MARK: - Style Type Enum
enum StyleType: String, CaseIterable, Codable {
    case elegant = "優雅"
    case casual = "休閒"
    case trendy = "時尚"
    case classic = "經典"
    case sporty = "運動"
    case artistic = "藝術"
    
    var displayName: String {
        return rawValue
    }
    
    var description: String {
        switch self {
        case .elegant:
            return "精緻優雅的風格，展現品味與氣質"
        case .casual:
            return "輕鬆自然的風格，舒適且親和"
        case .trendy:
            return "時尚前衛的風格，跟上潮流趨勢"
        case .classic:
            return "經典永恆的風格，不受時間影響"
        case .sporty:
            return "運動活力的風格，展現健康活力"
        case .artistic:
            return "藝術創意的風格，獨特且富有創意"
        }
    }
    
    var emoji: String {
        switch self {
        case .elegant:
            return "✨"
        case .casual:
            return "😊"
        case .trendy:
            return "🔥"
        case .classic:
            return "👑"
        case .sporty:
            return "💪"
        case .artistic:
            return "🎨"
        }
    }
}

// MARK: - Style Report Model
struct StyleReport: Codable, Identifiable {
    let id: String
    let userId: String
    let dominantStyle: StyleType
    let styleBreakdown: [String: Double] // Using String keys for Codable compatibility
    let ranking: StyleRanking
    let recommendations: [String]
    let generatedAt: Date
    
    init(userId: String, dominantStyle: StyleType, styleBreakdown: [StyleType: Double], ranking: StyleRanking, recommendations: [String]) {
        self.id = UUID().uuidString
        self.userId = userId
        self.dominantStyle = dominantStyle
        self.styleBreakdown = Dictionary(uniqueKeysWithValues: styleBreakdown.map { ($0.key.rawValue, $0.value) })
        self.ranking = ranking
        self.recommendations = recommendations
        self.generatedAt = Date()
    }
    
    /// Get style breakdown with StyleType keys
    var styleBreakdownTyped: [StyleType: Double] {
        return Dictionary(uniqueKeysWithValues: styleBreakdown.compactMap { key, value in
            guard let styleType = StyleType(rawValue: key) else { return nil }
            return (styleType, value)
        })
    }
}

// MARK: - Style Ranking Model
struct StyleRanking: Codable {
    let overallScore: Double
    let percentile: Double
    let categoryRankings: [String: Int] // category -> rank
    
    init(overallScore: Double, percentile: Double, categoryRankings: [StyleType: Int]) {
        self.overallScore = overallScore
        self.percentile = percentile
        self.categoryRankings = Dictionary(uniqueKeysWithValues: categoryRankings.map { ($0.key.rawValue, $0.value) })
    }
    
    /// Get category rankings with StyleType keys
    var categoryRankingsTyped: [StyleType: Int] {
        return Dictionary(uniqueKeysWithValues: categoryRankings.compactMap { key, value in
            guard let styleType = StyleType(rawValue: key) else { return nil }
            return (styleType, value)
        })
    }
}

// MARK: - CTA Message Model
struct CTAMessage: Codable, Identifiable {
    let id: String
    let userId: String
    let title: String
    let subtitle: String
    let buttonText: String
    let motivationalText: String
    let dominantStyle: StyleType
    let personalizedElements: [String]
    let createdAt: Date
    
    init(userId: String, title: String, subtitle: String, buttonText: String, motivationalText: String, dominantStyle: StyleType, personalizedElements: [String]) {
        self.id = UUID().uuidString
        self.userId = userId
        self.title = title
        self.subtitle = subtitle
        self.buttonText = buttonText
        self.motivationalText = motivationalText
        self.dominantStyle = dominantStyle
        self.personalizedElements = personalizedElements
        self.createdAt = Date()
    }
}

// MARK: - CTA Trigger Conditions
struct CTATriggerConditions: Codable {
    let minimumRatingsRequired: Int
    let hasUnlockedUpload: Bool
    let userPreferencesAnalyzed: Bool
    let dominantStyleIdentified: Bool
    
    init(minimumRatingsRequired: Int = 20, hasUnlockedUpload: Bool = false, userPreferencesAnalyzed: Bool = false, dominantStyleIdentified: Bool = false) {
        self.minimumRatingsRequired = minimumRatingsRequired
        self.hasUnlockedUpload = hasUnlockedUpload
        self.userPreferencesAnalyzed = userPreferencesAnalyzed
        self.dominantStyleIdentified = dominantStyleIdentified
    }
    
    var shouldShowCTA: Bool {
        return hasUnlockedUpload && userPreferencesAnalyzed && dominantStyleIdentified
    }
}