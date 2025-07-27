//
//  Achievement.swift
//  viberanking
//
//  Created by Kiro on 2025/07/23.
//

import Foundation

// MARK: - Achievement Model
struct Achievement: Codable, Identifiable, Equatable {
    let id: String
    let title: String
    let description: String
    let iconName: String
    let category: AchievementCategory
    let requirement: AchievementRequirement
    let reward: AchievementReward?
    let isUnlocked: Bool
    let unlockedAt: Date?
    var wasNotified: Bool
    
    init(id: String = UUID().uuidString,
         title: String,
         description: String,
         iconName: String,
         category: AchievementCategory,
         requirement: AchievementRequirement,
         reward: AchievementReward? = nil,
         isUnlocked: Bool = false,
         unlockedAt: Date? = nil,
         wasNotified: Bool = false) {
        self.id = id
        self.title = title
        self.description = description
        self.iconName = iconName
        self.category = category
        self.requirement = requirement
        self.reward = reward
        self.isUnlocked = isUnlocked
        self.unlockedAt = unlockedAt
        self.wasNotified = wasNotified
    }
}

// MARK: - Achievement Category
enum AchievementCategory: String, CaseIterable, Codable {
    case rating
    case upload
    case social
    case style
    case milestone
    
    var displayName: String {
        return "achievement.category.\(self.rawValue)".localized
    }
}

// MARK: - Achievement Requirement
struct AchievementRequirement: Codable, Equatable {
    let type: RequirementType
    let target: Int
    let current: Int
    
    init(type: RequirementType, target: Int, current: Int = 0) {
        self.type = type
        self.target = target
        self.current = current
    }
    
    var isCompleted: Bool {
        return current >= target
    }
    
    var progressPercentage: Double {
        return min(Double(current) / Double(target), 1.0)
    }
}

// MARK: - Requirement Type
enum RequirementType: String, CaseIterable, Codable {
    case ratingsGiven
    case photosUploaded
    case ratingsReceived
    case hotRatingsReceived
    case consecutiveDays
    case styleReportsGenerated
    case attractivenessScore
    case multipleStyleMastery
    
    var displayName: String {
        return "achievement.requirement_type.\(self.rawValue)".localized
    }
}

// MARK: - Achievement Reward
struct AchievementReward: Codable, Equatable {
    let type: RewardType
    let value: Int
    let description: String
    
    init(type: RewardType, value: Int, description: String) {
        self.type = type
        self.value = value
        self.description = description
    }
}

// MARK: - Reward Type
enum RewardType: String, CaseIterable, Codable {
    case acceleratedRating
    case bonusAnalysis
    case specialBadge
    case priorityQueue
    case evolutionAnalysis
    
    var displayName: String {
        return "achievement.reward_type.\(self.rawValue)".localized
    }
}

// MARK: - User Achievement Progress
struct UserAchievementProgress: Codable, Equatable {
    let userId: String
    var achievements: [Achievement]
    var totalUnlocked: Int
    var lastUpdated: Date
    
    init(userId: String) {
        self.userId = userId
        self.achievements = []
        self.totalUnlocked = 0
        self.lastUpdated = Date()
    }
    
    var unlockedAchievements: [Achievement] {
        return achievements.filter { $0.isUnlocked }
    }
    
    var lockedAchievements: [Achievement] {
        return achievements.filter { !$0.isUnlocked }
    }
    
    mutating func unlockAchievement(id: String) {
        if let index = achievements.firstIndex(where: { $0.id == id && !$0.isUnlocked }) {
            var achievement = achievements[index]
            achievement = Achievement(
                id: achievement.id,
                title: achievement.title,
                description: achievement.description,
                iconName: achievement.iconName,
                category: achievement.category,
                requirement: achievement.requirement,
                reward: achievement.reward
            )
            achievements[index] = achievement
            totalUnlocked += 1
            lastUpdated = Date()
        }
    }
}