//
//  StyleReport.swift
//  viberanking
//
//  Created by Kiro on 2025/07/23.
//

import Foundation

// MARK: - Style Type Enum
enum StyleType: String, CaseIterable, Codable {
    case elegant
    case casual
    case trendy
    case classic
    case sporty
    case artistic
    case streetwear
    case minimalist
    case edgy
    case formal
    case colorful

    var displayName: String {
        return "style.\(self.rawValue).display_name".localized
    }

    var description: String {
        return "style.\(self.rawValue).description".localized
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
        case .streetwear:
            return "🛹"
        case .minimalist:
            return "⚪️"
        case .edgy:
            return "🎸"
        case .formal:
            return "👔"
        case .colorful:
            return "🌈"
        }
    }
}

// MARK: - Style Report Model
struct StyleReport: Codable, Identifiable, Equatable {
    let id: String
    let userId: String
    let dominantStyle: StyleType
    let styleBreakdown: [String: Double] // Using String keys for Codable compatibility
    let ranking: StyleRanking
    let recommendations: [String]
    let generatedAt: Date
    
    static func == (lhs: StyleReport, rhs: StyleReport) -> Bool {
        return lhs.id == rhs.id &&
               lhs.userId == rhs.userId &&
               lhs.dominantStyle == rhs.dominantStyle &&
               lhs.styleBreakdown == rhs.styleBreakdown &&
               lhs.ranking == rhs.ranking &&
               lhs.recommendations == rhs.recommendations &&
               lhs.generatedAt == rhs.generatedAt
    }
}

// MARK: - Style Ranking Model
struct StyleRanking: Codable, Equatable {
    let overallAttractiveness: Double
    let totalVotes: Int
    let femaleAttractiveness: Double
    let maleAttractiveness: Double
    
    static func == (lhs: StyleRanking, rhs: StyleRanking) -> Bool {
        return lhs.overallAttractiveness == rhs.overallAttractiveness &&
               lhs.totalVotes == rhs.totalVotes &&
               lhs.femaleAttractiveness == rhs.femaleAttractiveness &&
               lhs.maleAttractiveness == rhs.maleAttractiveness
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
