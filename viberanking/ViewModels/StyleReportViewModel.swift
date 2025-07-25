import Foundation
import Combine

@MainActor
class StyleReportViewModel: ObservableObject {
    @Published var styleReport: StyleReport?
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var reportProgress: Double = 0.0
    @Published var isReportUnlocked = false
    @Published var newlyUnlockedAchievements: [Achievement] = []

    private let styleAnalysisService: StyleAnalysisServiceProtocol
    private let gamificationService: GamificationService
    private var cancellables = Set<AnyCancellable>()

    init(styleAnalysisService: StyleAnalysisServiceProtocol) {
        self.styleAnalysisService = styleAnalysisService
        self.gamificationService = GamificationService()
    }

    func fetchStyleReport(for userId: String) {
        isLoading = true
        errorMessage = nil
        reportProgress = 0.0

        Task {
            do {
                // Simulate progress updates
                await updateProgress(0.2, message: "cta.analyzing_preferences".localized)
                
                let userPreferences = try await styleAnalysisService.getUserPreferences(for: userId)
                await updateProgress(0.4, message: "cta.analyzing_progress".localized)
                
                await updateProgress(0.6, message: "cta.analyzing_progress".localized)
                
                let report = try await styleAnalysisService.generateStyleReport(for: userId)
                await updateProgress(0.8, message: "cta.analyzing_progress".localized)
                
                // Check for newly unlocked achievements
                let achievements = try await gamificationService.checkAchievements(for: userId)
                let newAchievements = achievements.filter { $0.isUnlocked && !$0.wasNotified }
                
                await updateProgress(1.0, message: "common.done".localized)
                
                // Update UI on main thread
                await MainActor.run {
                    self.styleReport = report
                    self.newlyUnlockedAchievements = newAchievements
                    self.isReportUnlocked = true
                    self.isLoading = false
                    self.reportProgress = 1.0
                }
                
                // Mark achievements as notified
                for achievement in newAchievements {
                    try await gamificationService.markAchievementAsNotified(achievementId: achievement.id)
                }
                
            } catch let error as StyleAnalysisError {
                await MainActor.run {
                    self.errorMessage = error.errorDescription
                    self.isLoading = false
                    self.reportProgress = 0.0
                }
            } catch {
                await MainActor.run {
                    self.errorMessage = "report.error".localized + ": \(error.localizedDescription)"
                    self.isLoading = false
                    self.reportProgress = 0.0
                }
            }
        }
    }
    
    func refreshReport(for userId: String) {
        // Clear existing data
        styleReport = nil
        isReportUnlocked = false
        newlyUnlockedAchievements = []
        
        // Fetch new report
        fetchStyleReport(for: userId)
    }
    
    func checkReportUnlockStatus(for userId: String) async {
        do {
            // Check if user has enough ratings to unlock report
            let userPreferences = try await styleAnalysisService.getUserPreferences(for: userId)
            
            await MainActor.run {
                // Assuming 50 ratings needed to unlock report
                self.isReportUnlocked = userPreferences.totalRatingsGiven >= 50
                self.reportProgress = min(Double(userPreferences.totalRatingsGiven) / 50.0, 1.0)
            }
        } catch {
            print("Failed to check report unlock status: \(error)")
        }
    }
    
    func getReportHistory(for userId: String) async -> [StyleReport] {
        do {
            // This would fetch historical reports in a real implementation
            // For now, return empty array
            return []
        } catch {
            print("Failed to fetch report history: \(error)")
            return []
        }
    }
    
    func shareReport(_ report: StyleReport) {
        // Generate shareable content
        let shareText = generateShareText(from: report)
        
        // Trigger share sheet (implementation would depend on the platform)
        print("Sharing report: \(shareText)")
    }
    
    // MARK: - Private Methods
    
    private func updateProgress(_ progress: Double, message: String) async {
        await MainActor.run {
            self.reportProgress = progress
        }
        
        // Simulate processing time
        try? await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds
    }
    
    private func generateShareText(from report: StyleReport) -> String {
        let dominantStyle = report.dominantStyle.displayName
        let score = Int(report.ranking.overallAttractiveness)
        let totalVotes = report.ranking.totalVotes
        
        return """
        🎨 我的風格分析報告出爐了！
        
        主要風格：\(dominantStyle) \(report.dominantStyle.emoji)
        整體吸引力：\(score)%
        總評分數：\(totalVotes)
        
        #風格分析 #個人魅力 #VibeRanking
        """
    }
}

// MARK: - Mock Achievement Data
extension StyleReportViewModel {
    func getMockAchievements() -> [Achievement] {
        return [
            Achievement(
                title: "achievement.style_star.title".localized,
                description: "achievement.style_star.description".localized,
                iconName: "star.fill",
                category: .milestone,
                requirement: AchievementRequirement(type: .styleReportsGenerated, target: 1),
                reward: AchievementReward(type: .specialBadge, value: 1, description: "achievement.style_star.reward".localized)
            ),
            Achievement(
                title: "achievement.charm_master.title".localized,
                description: "achievement.charm_master.description".localized,
                iconName: "heart.fill",
                category: .style,
                requirement: AchievementRequirement(type: .attractivenessScore, target: 80),
                reward: AchievementReward(type: .acceleratedRating, value: 5, description: "achievement.charm_master.reward".localized)
            ),
            Achievement(
                title: "achievement.style_master.title".localized,
                description: "achievement.style_master.description".localized,
                iconName: "crown.fill",
                category: .style,
                requirement: AchievementRequirement(type: .multipleStyleMastery, target: 3),
                reward: AchievementReward(type: .specialBadge, value: 1, description: "achievement.style_master.reward".localized)
            ),
            Achievement(
                title: "achievement.popularity_king.title".localized,
                description: "achievement.popularity_king.description".localized,
                iconName: "person.3.fill",
                category: .milestone,
                requirement: AchievementRequirement(type: .ratingsReceived, target: 100),
                reward: AchievementReward(type: .evolutionAnalysis, value: 1, description: "achievement.popularity_king.reward".localized)
            )
        ]
    }
}
