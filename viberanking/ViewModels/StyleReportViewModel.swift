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
                await updateProgress(0.2, message: "分析用戶偏好...")
                
                let userPreferences = try await styleAnalysisService.getUserPreferences(for: userId)
                await updateProgress(0.4, message: "計算風格分數...")
                
                await updateProgress(0.6, message: "生成個性化建議...")
                
                let report = try await styleAnalysisService.generateStyleReport(for: userId)
                await updateProgress(0.8, message: "檢查新成就...")
                
                // Check for newly unlocked achievements
                let achievements = try await gamificationService.checkAchievements(for: userId)
                let newAchievements = achievements.filter { $0.isUnlocked && !$0.wasNotified }
                
                await updateProgress(1.0, message: "完成！")
                
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
                    self.errorMessage = "報告生成失敗：\(error.localizedDescription)"
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
                title: "風格新星",
                description: "首次獲得風格報告",
                iconName: "star.fill",
                category: .milestone,
                requirement: AchievementRequirement(type: .styleReportsGenerated, target: 1),
                reward: AchievementReward(type: .specialBadge, value: 1, description: "風格新星徽章")
            ),
            Achievement(
                title: "魅力達人",
                description: "吸引力分數達到80%以上",
                iconName: "heart.fill",
                category: .style,
                requirement: AchievementRequirement(type: .attractivenessScore, target: 80),
                reward: AchievementReward(type: .acceleratedRating, value: 5, description: "5次加速評分機會")
            ),
            Achievement(
                title: "風格大師",
                description: "在三個不同風格類型中都獲得高分",
                iconName: "crown.fill",
                category: .style,
                requirement: AchievementRequirement(type: .multipleStyleMastery, target: 3),
                reward: AchievementReward(type: .specialBadge, value: 1, description: "風格大師徽章")
            ),
            Achievement(
                title: "人氣王",
                description: "獲得超過100個評分",
                iconName: "person.3.fill",
                category: .milestone,
                requirement: AchievementRequirement(type: .ratingsReceived, target: 100),
                reward: AchievementReward(type: .evolutionAnalysis, value: 1, description: "解鎖風格演變分析")
            )
        ]
    }
}
