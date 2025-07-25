import SwiftUI

struct StyleReportView: View {
    @StateObject private var viewModel: StyleReportViewModel
    @State private var newlyUnlockedAchievement: Achievement?
    let userId: String

    init(userId: String) {
        self.userId = userId
        _viewModel = StateObject(wrappedValue: StyleReportViewModel(styleAnalysisService: StyleAnalysisService()))
    }

    var body: some View {
        Group {
            if viewModel.isLoading {
                ProgressView("report.loading".localized)
            } else if let errorMessage = viewModel.errorMessage {
                VStack {
                    Text("report.error".localized)
                        .font(.largeTitle)
                    Text(errorMessage)
                        .font(.body)
                        .foregroundColor(.secondary)
                }
            } else if let styleReport = viewModel.styleReport {
                ScrollView {
                    VStack(spacing: 20) {
                        Text("report.title".localized)
                            .font(.largeTitle)
                            .fontWeight(.bold)
                            .padding(.top, 20)

                        // Overall Attractiveness
                        VStack(alignment: .leading, spacing: 10) {
                            Text("report.overall_trend".localized)
                                .font(.title2)
                                .fontWeight(.semibold)
                            
                            LineChartView(data: [0.5, 0.6, 0.55, 0.7, 0.65, 0.8, 0.85])
                                .frame(height: 150)
                            
                            HStack {
                                VStack(alignment: .leading) {
                                    Text("report.current".localized)
                                        .font(.headline)
                                    Text("\(styleReport.ranking.overallAttractiveness, specifier: "%.0f")%")
                                        .font(.system(size: 40, weight: .bold))
                                        .foregroundColor(.blue)
                                }
                                Spacer()
                                VStack(alignment: .leading) {
                                    Text("report.last_week".localized)
                                        .font(.headline)
                                    Text("50%")
                                        .font(.system(size: 40, weight: .bold))
                                        .foregroundColor(.gray)
                                }
                            }
                            
                            Text("report.total_votes".localized(with: styleReport.ranking.totalVotes))
                                .font(.headline)
                        }
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color(.secondarySystemBackground))
                        .cornerRadius(10)

                        // Gender Analysis
                        VStack(alignment: .leading, spacing: 10) {
                            Text("report.gender_analysis".localized)
                                .font(.title2)
                                .fontWeight(.semibold)
                            HStack {
                                VStack(alignment: .leading) {
                                    Text("report.female_attractiveness".localized)
                                        .font(.headline)
                                    Text("\(styleReport.ranking.femaleAttractiveness, specifier: "%.0f")%")
                                        .font(.system(size: 40, weight: .bold))
                                        .foregroundColor(.red)
                                }
                                Spacer()
                                VStack(alignment: .leading) {
                                    Text("report.male_attractiveness".localized)
                                        .font(.headline)
                                    Text("\(styleReport.ranking.maleAttractiveness, specifier: "%.0f")%")
                                        .font(.system(size: 40, weight: .bold))
                                        .foregroundColor(.indigo)
                                }
                            }
                        }
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color(.secondarySystemBackground))
                        .cornerRadius(10)

                        // Style Performance
                        VStack(alignment: .leading, spacing: 10) {
                            Text("report.style_performance".localized)
                                .font(.title2)
                                .fontWeight(.semibold)
                            ForEach(styleReport.styleBreakdown.sorted(by: { $0.value > $1.value }), id: \.key) { style, score in
                                VStack(alignment: .leading) {
                                    HStack {
                                        Text(style)
                                            .font(.headline)
                                        Spacer()
                                        Text("\(score, specifier: "%.0f")%")
                                            .font(.headline)
                                            .fontWeight(.bold)
                                    }
                                    ProgressBar(value: score, maxValue: 100)
                                        .frame(height: 10)
                                }
                            }
                        }
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color(.secondarySystemBackground))
                        .cornerRadius(10)

                        // Achievements
                        VStack(alignment: .leading, spacing: 10) {
                            Text("report.achievements".localized)
                                .font(.title2)
                                .fontWeight(.semibold)
                            
                            let unlockedAchievements = mockAchievements.filter { $0.isUnlocked }
                            let lockedAchievements = mockAchievements.filter { !$0.isUnlocked }

                            if !unlockedAchievements.isEmpty {
                                Text("report.unlocked".localized)
                                    .font(.headline)
                                ForEach(unlockedAchievements, id: \.id) { achievement in
                                    AchievementView(achievement: achievement)
                                }
                            }
                            
                            if !lockedAchievements.isEmpty {
                                Text("report.locked".localized)
                                    .font(.headline)
                                ForEach(lockedAchievements, id: \.id) { achievement in
                                    AchievementView(achievement: achievement)
                                }
                            }
                        }
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color(.secondarySystemBackground))
                        .cornerRadius(10)

                        // AI Insights
                        VStack(alignment: .leading, spacing: 10) {
                            Text("report.ai_insights".localized)
                                .font(.title2)
                                .fontWeight(.semibold)
                            ForEach(styleReport.recommendations, id: \.self) { recommendation in
                                Text("• \(recommendation)")
                                    .font(.body)
                            }
                        }
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color(.secondarySystemBackground))
                        .cornerRadius(10)
                    }
                    .padding()
                }
            } else {
                VStack {
                    Text("report.no_report".localized)
                        .font(.largeTitle)
                    Text("report.complete_more".localized)
                        .font(.body)
                        .foregroundColor(.secondary)
                }
            }
        }
        .navigationTitle("report.title".localized)
        .onAppear {
            viewModel.fetchStyleReport(for: userId)
        }
        .overlay(
            Group {
                if let achievement = newlyUnlockedAchievement {
                    VStack {
                        Text("report.achievement_unlocked".localized)
                            .font(.largeTitle)
                            .fontWeight(.bold)
                            .foregroundColor(.yellow)
                        
                        AchievementView(achievement: achievement)
                        
                        Button("report.celebrate".localized) {
                            newlyUnlockedAchievement = nil
                        }
                        .padding()
                        .background(Color.yellow)
                        .foregroundColor(.black)
                        .cornerRadius(10)
                    }
                    .padding()
                    .background(Color.black.opacity(0.8))
                    .cornerRadius(20)
                    .transition(.scale)
                }
            }
        )
        // Temporary button to simulate unlocking an achievement
        .safeAreaInset(edge: .bottom) {
            Button("report.unlock_achievement".localized) {
                withAnimation {
                    newlyUnlockedAchievement = mockAchievements.first(where: { !$0.isUnlocked })
                }
            }
            .padding()
        }
    }
}

struct StyleReportView_Previews: PreviewProvider {
    static var previews: some View {
        StyleReportView(userId: "123")
            .previewDevice("iPhone 14 Pro")
    }
}

let mockAchievements = [
    Achievement(title: "achievement.hot_streak".localized, description: "achievement.hot_streak_desc".localized, iconName: "flame.fill", category: .rating, requirement: .init(type: .consecutiveDays, target: 10), reward: .init(type: .acceleratedRating, value: 1, description: "1")),
    Achievement(title: "achievement.style_king".localized, description: "achievement.style_king_desc".localized, iconName: "crown.fill", category: .style, requirement: .init(type: .hotRatingsReceived, target: 100), reward: .init(type: .specialBadge, value: 1, description: "1")),
    Achievement(title: "achievement.rising_star".localized, description: "achievement.rising_star_desc".localized, iconName: "star.fill", category: .milestone, requirement: .init(type: .ratingsReceived, target: 100)),
    Achievement(title: "achievement.legend".localized, description: "achievement.legend_desc".localized, iconName: "star.leading.half.filled", category: .milestone, requirement: .init(type: .ratingsReceived, target: 1000)),
    Achievement(title: "achievement.trendsetter".localized, description: "achievement.trendsetter_desc".localized, iconName: "paintbrush.fill", category: .style, requirement: .init(type: .styleReportsGenerated, target: 1)),
    Achievement(title: "achievement.diamond".localized, description: "achievement.diamond_desc".localized, iconName: "diamond.fill", category: .style, requirement: .init(type: .hotRatingsReceived, target: 500))
]

let mockReport = StyleReport(
    id: "1",
    userId: "123",
    dominantStyle: .streetwear,
    styleBreakdown: [
        StyleType.streetwear.rawValue: 85,
        StyleType.minimalist.rawValue: 78,
        StyleType.edgy.rawValue: 72,
        StyleType.formal.rawValue: 65,
        StyleType.colorful.rawValue: 58
    ],
    ranking: StyleRanking(
        overallAttractiveness: 73,
        totalVotes: 156,
        femaleAttractiveness: 89,
        maleAttractiveness: 67
    ),
    recommendations: [
        "Your streetwear style is on point! Keep it up.",
        "Consider adding more minimalist pieces to your wardrobe."
    ],
    generatedAt: Date()
)
