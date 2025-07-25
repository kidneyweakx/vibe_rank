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
    
    init(id: String = UUID().uuidString,
         title: String,
         description: String,
         iconName: String,
         category: AchievementCategory,
         requirement: AchievementRequirement,
         reward: AchievementReward? = nil) {
        self.id = id
        self.title = title
        self.description = description
        self.iconName = iconName
        self.category = category
        self.requirement = requirement
        self.reward = reward
        self.isUnlocked = false
        self.unlockedAt = nil
    }
}

// MARK: - Achievement Category
enum AchievementCategory: String, CaseIterable, Codable {
    case rating = "評分"
    case upload = "上傳"
    case social = "社交"
    case style = "風格"
    case milestone = "里程碑"
    
    var displayName: String {
        return self.rawValue
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
    case ratingsGiven = "給出評分數量"
    case photosUploaded = "上傳照片數量"
    case ratingsReceived = "獲得評分數量"
    case hotRatingsReceived = "獲得Hot評分數量"
    case consecutiveDays = "連續使用天數"
    case styleReportsGenerated = "生成風格報告數量"
    
    var displayName: String {
        return self.rawValue
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
    case acceleratedRating = "加速評分機會"
    case bonusAnalysis = "額外分析功能"
    case specialBadge = "特殊徽章"
    case priorityQueue = "優先評分隊列"
    
    var displayName: String {
        return self.rawValue
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