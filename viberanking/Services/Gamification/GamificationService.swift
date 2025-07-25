//
//  GamificationService.swift
//  viberanking
//
//  Created by Kiro on 2025/07/25.
//

import Foundation
import Combine

// MARK: - Gamification Service Implementation
@MainActor
class GamificationService: ObservableObject, GamificationServiceProtocol {
    
    // MARK: - Properties
    @Published var currentIncentiveStatus: IncentiveStatus = IncentiveStatus()
    @Published var userAchievements: [Achievement] = []
    @Published var recentlyUnlockedAchievements: [Achievement] = []
    
    private let firebaseService: FirebaseService
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Constants
    private struct Constants {
        static let acceleratedRatingThreshold = 10 // Every 10 ratings gives 1 accelerated rating
        static let evolutionAnalysisPhotosRequired = 3 // Need 3+ photos for evolution analysis
        static let shareRewardThreshold = 1 // First share unlocks rewards
    }
    
    // MARK: - Initialization
    init(firebaseService: FirebaseService = FirebaseService.shared) {
        self.firebaseService = firebaseService
        setupDefaultAchievements()
    }
    
    // MARK: - Public Methods
    
    /// Update user progress and check for new achievements
    func updateUserProgress(_ progress: UserProgress) async throws {
        // Update incentive status based on progress
        await updateIncentiveStatus(from: progress)
        
        // Check for newly unlocked achievements
        let newAchievements = try await checkAchievements(for: progress.userId)
        
        // Save progress to Firebase
        try await saveUserProgress(progress)
        
        // Notify about new achievements
        if !newAchievements.isEmpty {
            recentlyUnlockedAchievements = newAchievements
        }
    }
    
    /// Check achievements for a specific user
    func checkAchievements(for userId: String) async throws -> [Achievement] {
        let progress = try await getUserProgress(userId: userId)
        let currentAchievements = try await loadUserAchievements(userId: userId)
        
        var newlyUnlocked: [Achievement] = []
        
        for achievement in getDefaultAchievements() {
            // Skip if already unlocked
            if currentAchievements.contains(where: { $0.id == achievement.id && $0.isUnlocked }) {
                continue
            }
            
            // Check if achievement should be unlocked
            if shouldUnlockAchievement(achievement, with: progress) {
                let unlockedAchievement = unlockAchievement(achievement)
                newlyUnlocked.append(unlockedAchievement)
                
                // Apply achievement reward
                try await applyAchievementReward(unlockedAchievement, for: userId)
            }
        }
        
        // Save newly unlocked achievements
        if !newlyUnlocked.isEmpty {
            try await saveUserAchievements(newlyUnlocked, for: userId)
        }
        
        return newlyUnlocked
    }
    
    /// Get current incentive status for user
    func getIncentiveStatus(for userId: String) async throws -> IncentiveStatus {
        let progress = try await getUserProgress(userId: userId)
        let status = calculateIncentiveStatus(from: progress)
        
        DispatchQueue.main.async {
            self.currentIncentiveStatus = status
        }
        
        return status
    }
    
    /// Use an accelerated rating opportunity
    func useAcceleratedRating(for userId: String) async throws -> Bool {
        var status = try await getIncentiveStatus(for: userId)
        
        guard status.acceleratedRatingsAvailable > 0 else {
            return false
        }
        
        status.acceleratedRatingsAvailable -= 1
        try await saveIncentiveStatus(status, for: userId)
        
        DispatchQueue.main.async {
            self.currentIncentiveStatus = status
        }
        
        return true
    }
    
    /// Check if style evolution analysis is available
    func checkStyleEvolutionAvailability(for userId: String) async throws -> Bool {
        let progress = try await getUserProgress(userId: userId)
        return progress.totalPhotosUploaded >= Constants.evolutionAnalysisPhotosRequired
    }
    
    /// Generate style evolution analysis
    func generateStyleEvolution(for userId: String) async throws -> StyleEvolution {
        guard try await checkStyleEvolutionAvailability(for: userId) else {
            throw GamificationError.insufficientPhotosForEvolution
        }
        
        // Fetch user's uploaded photos with timestamps
        let photos = try await fetchUserPhotosForEvolution(userId: userId)
        
        // Analyze style changes over time
        let evolution = analyzeStyleEvolution(from: photos)
        
        // Save evolution analysis
        try await saveStyleEvolution(evolution, for: userId)
        
        return evolution
    }
    
    /// Record a share action and apply rewards
    func recordShareAction(for userId: String, shareType: ShareType) async throws {
        var status = try await getIncentiveStatus(for: userId)
        
        // Unlock share rewards if first time sharing
        if !status.shareRewardsUnlocked {
            status.shareRewardsUnlocked = true
            
            // Grant bonus accelerated rating
            status.acceleratedRatingsAvailable += 1
            
            try await saveIncentiveStatus(status, for: userId)
            
            DispatchQueue.main.async {
                self.currentIncentiveStatus = status
            }
        }
        
        // Record share action for analytics
        try await recordShareAnalytics(userId: userId, shareType: shareType)
    }
    
    /// Mark achievement as notified to prevent duplicate notifications
    func markAchievementAsNotified(achievementId: String) async throws {
        // Implementation would update the achievement in Firebase
        print("Marking achievement \(achievementId) as notified")
        
        // Update local achievements list
        if let index = userAchievements.firstIndex(where: { $0.id == achievementId }) {
            userAchievements[index].wasNotified = true
        }
    }
}

// MARK: - Private Methods
private extension GamificationService {
    
    /// Update incentive status based on user progress
    func updateIncentiveStatus(from progress: UserProgress) async {
        let status = calculateIncentiveStatus(from: progress)
        currentIncentiveStatus = status
    }
    
    /// Calculate incentive status from user progress
    func calculateIncentiveStatus(from progress: UserProgress) -> IncentiveStatus {
        var status = IncentiveStatus()
        
        // Calculate accelerated ratings available
        let acceleratedRatingsEarned = progress.totalRatingsGiven / Constants.acceleratedRatingThreshold
        status.acceleratedRatingsAvailable = acceleratedRatingsEarned
        
        // Calculate next accelerated rating threshold
        let ratingsToNext = Constants.acceleratedRatingThreshold - (progress.totalRatingsGiven % Constants.acceleratedRatingThreshold)
        status.nextAcceleratedRatingAt = ratingsToNext
        
        // Check evolution analysis unlock
        status.evolutionAnalysisUnlocked = progress.totalPhotosUploaded >= Constants.evolutionAnalysisPhotosRequired
        
        return status
    }
    
    /// Check if achievement should be unlocked
    func shouldUnlockAchievement(_ achievement: Achievement, with progress: UserProgress) -> Bool {
        let requirement = achievement.requirement
        
        switch requirement.type {
        case .ratingsGiven:
            return progress.totalRatingsGiven >= requirement.target
        case .photosUploaded:
            return progress.totalPhotosUploaded >= requirement.target
        case .styleReportsGenerated:
            return progress.reportsGenerated >= requirement.target
        case .ratingsReceived, .hotRatingsReceived, .consecutiveDays:
            // These require additional data not in UserProgress
            return false
        default:
            return false
        }
    }
    
    /// Unlock an achievement
    func unlockAchievement(_ achievement: Achievement) -> Achievement {
        return Achievement(
            id: achievement.id,
            title: achievement.title,
            description: achievement.description,
            iconName: achievement.iconName,
            category: achievement.category,
            requirement: AchievementRequirement(
                type: achievement.requirement.type,
                target: achievement.requirement.target,
                current: achievement.requirement.target
            ),
            reward: achievement.reward
        )
    }
    
    /// Apply achievement reward to user
    func applyAchievementReward(_ achievement: Achievement, for userId: String) async throws {
        guard let reward = achievement.reward else { return }
        
        var status = try await getIncentiveStatus(for: userId)
        
        switch reward.type {
        case .acceleratedRating:
            status.acceleratedRatingsAvailable += reward.value
        case .bonusAnalysis:
            status.evolutionAnalysisUnlocked = true
        case .specialBadge, .priorityQueue:
            // These rewards are handled by the achievement system itself
            break
        default:
            break
        }
        
        try await saveIncentiveStatus(status, for: userId)
    }
    
    /// Analyze style evolution from photos
    func analyzeStyleEvolution(from photos: [Photo]) -> StyleEvolution {
        // Sort photos by upload date
        let sortedPhotos = photos.sorted { $0.uploadedAt < $1.uploadedAt }
        
        // Group photos by time periods (e.g., monthly)
        let timeGroups = groupPhotosByTimePeriod(sortedPhotos)
        
        // Analyze style trends for each period
        let styleTrends = timeGroups.map { period, photos in
            StylePeriod(
                startDate: period.start,
                endDate: period.end,
                photos: photos,
                dominantStyle: calculateDominantStyle(from: photos),
                styleScores: calculateStyleScores(from: photos)
            )
        }
        
        return StyleEvolution(
            userId: photos.first?.userId ?? "",
            periods: styleTrends,
            overallTrend: calculateOverallTrend(from: styleTrends),
            generatedAt: Date()
        )
    }
    
    /// Group photos by time period
    func groupPhotosByTimePeriod(_ photos: [Photo]) -> [(period: (start: Date, end: Date), photos: [Photo])] {
        // Simple implementation: group by month
        let calendar = Calendar.current
        let grouped = Dictionary(grouping: photos) { photo in
            calendar.dateInterval(of: .month, for: photo.uploadedAt)?.start ?? photo.uploadedAt
        }
        
        return grouped.map { startDate, photos in
            let endDate = calendar.date(byAdding: .month, value: 1, to: startDate) ?? startDate
            return (period: (start: startDate, end: endDate), photos: photos)
        }.sorted { $0.period.start < $1.period.start }
    }
    
    /// Calculate dominant style from photos
    func calculateDominantStyle(from photos: [Photo]) -> StyleType {
        // Simplified implementation - in real app, this would use ML analysis
        let styles: [StyleType] = [.elegant, .casual, .trendy, .classic, .sporty, .artistic]
        return styles.randomElement() ?? .casual
    }
    
    /// Calculate style scores from photos
    func calculateStyleScores(from photos: [Photo]) -> [StyleType: Double] {
        // Simplified implementation - in real app, this would analyze actual photo content
        var scores: [StyleType: Double] = [:]
        for style in StyleType.allCases {
            scores[style] = Double.random(in: 0.1...1.0)
        }
        return scores
    }
    
    /// Calculate overall trend from style periods
    func calculateOverallTrend(from periods: [StylePeriod]) -> StyleTrend {
        guard periods.count >= 2 else {
            return StyleTrend(direction: .stable, confidence: 0.5, description: "需要更多數據來分析趨勢")
        }
        
        // Simple trend analysis
        let firstPeriod = periods.first!
        let lastPeriod = periods.last!
        
        if firstPeriod.dominantStyle != lastPeriod.dominantStyle {
            return StyleTrend(
                direction: .evolving,
                confidence: 0.8,
                description: "你的風格正在從\(firstPeriod.dominantStyle.rawValue)轉向\(lastPeriod.dominantStyle.rawValue)"
            )
        } else {
            return StyleTrend(
                direction: .consistent,
                confidence: 0.9,
                description: "你保持著一致的\(lastPeriod.dominantStyle.rawValue)風格"
            )
        }
    }
}

// MARK: - Firebase Integration
private extension GamificationService {
    
    /// Get user progress from Firebase
    func getUserProgress(userId: String) async throws -> UserProgress {
        // Implementation would fetch from Firebase
        // For now, return default progress
        return UserProgress(userId: userId)
    }
    
    /// Save user progress to Firebase
    func saveUserProgress(_ progress: UserProgress) async throws {
        // Implementation would save to Firebase
        print("Saving user progress for \(progress.userId)")
    }
    
    /// Load user achievements from Firebase
    func loadUserAchievements(userId: String) async throws -> [Achievement] {
        // Implementation would fetch from Firebase
        return []
    }
    
    /// Save user achievements to Firebase
    func saveUserAchievements(_ achievements: [Achievement], for userId: String) async throws {
        // Implementation would save to Firebase
        print("Saving \(achievements.count) achievements for user \(userId)")
    }
    
    /// Save incentive status to Firebase
    func saveIncentiveStatus(_ status: IncentiveStatus, for userId: String) async throws {
        // Implementation would save to Firebase
        print("Saving incentive status for user \(userId)")
    }
    
    /// Fetch user photos for evolution analysis
    func fetchUserPhotosForEvolution(userId: String) async throws -> [Photo] {
        // Implementation would fetch from Firebase
        return []
    }
    
    /// Save style evolution analysis
    func saveStyleEvolution(_ evolution: StyleEvolution, for userId: String) async throws {
        // Implementation would save to Firebase
        print("Saving style evolution for user \(userId)")
    }
    
    /// Record share analytics
    func recordShareAnalytics(userId: String, shareType: ShareType) async throws {
        // Implementation would record to Firebase Analytics
        print("Recording share action: \(shareType) for user \(userId)")
    }
}

// MARK: - Default Achievements Setup
private extension GamificationService {
    
    /// Setup default achievements
    func setupDefaultAchievements() {
        userAchievements = getDefaultAchievements()
    }
    
    /// Get default achievements list
    func getDefaultAchievements() -> [Achievement] {
        return [
            // Rating achievements
            Achievement(
                title: "評分新手",
                description: "完成你的前10次評分",
                iconName: "star.fill",
                category: .rating,
                requirement: AchievementRequirement(type: .ratingsGiven, target: 10),
                reward: AchievementReward(type: .acceleratedRating, value: 1, description: "獲得1次加速評分機會")
            ),
            Achievement(
                title: "評分達人",
                description: "完成100次評分",
                iconName: "star.circle.fill",
                category: .rating,
                requirement: AchievementRequirement(type: .ratingsGiven, target: 100),
                reward: AchievementReward(type: .acceleratedRating, value: 3, description: "獲得3次加速評分機會")
            ),
            
            // Upload achievements
            Achievement(
                title: "首次上傳",
                description: "上傳你的第一張照片",
                iconName: "camera.fill",
                category: .upload,
                requirement: AchievementRequirement(type: .photosUploaded, target: 1),
                reward: AchievementReward(type: .bonusAnalysis, value: 1, description: "解鎖風格演變分析")
            ),
            Achievement(
                title: "風格探索者",
                description: "上傳5張不同風格的照片",
                iconName: "photo.stack.fill",
                category: .upload,
                requirement: AchievementRequirement(type: .photosUploaded, target: 5),
                reward: AchievementReward(type: .specialBadge, value: 1, description: "獲得風格探索者徽章")
            ),
            
            // Style achievements
            Achievement(
                title: "風格分析師",
                description: "生成你的第一份風格報告",
                iconName: "chart.bar.fill",
                category: .style,
                requirement: AchievementRequirement(type: .styleReportsGenerated, target: 1),
                reward: AchievementReward(type: .bonusAnalysis, value: 1, description: "解鎖高級分析功能")
            )
        ]
    }
}

// MARK: - Supporting Models

/// Style evolution analysis result
struct StyleEvolution: Codable {
    let userId: String
    let periods: [StylePeriod]
    let overallTrend: StyleTrend
    let generatedAt: Date
}

/// Style analysis for a specific time period
struct StylePeriod: Codable {
    let startDate: Date
    let endDate: Date
    let photos: [Photo]
    let dominantStyle: StyleType
    let styleScores: [StyleType: Double]
}

/// Overall style trend analysis
struct StyleTrend: Codable {
    let direction: TrendDirection
    let confidence: Double
    let description: String
}

/// Trend direction enum
enum TrendDirection: String, Codable {
    case evolving = "演變中"
    case consistent = "一致"
    case stable = "穩定"
}

/// Share type enum
enum ShareType: String, Codable {
    case styleReport = "風格報告"
    case achievement = "成就"
    case evolution = "風格演變"
}

/// Gamification specific errors
enum GamificationError: Error, LocalizedError {
    case insufficientPhotosForEvolution
    case achievementAlreadyUnlocked
    case invalidRewardType
    
    var errorDescription: String? {
        switch self {
        case .insufficientPhotosForEvolution:
            return "需要至少3張照片才能進行風格演變分析"
        case .achievementAlreadyUnlocked:
            return "成就已經解鎖"
        case .invalidRewardType:
            return "無效的獎勵類型"
        }
    }
}
