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
                ProgressView("Loading Report...")
            } else if let errorMessage = viewModel.errorMessage {
                VStack {
                    Text("Error")
                        .font(.largeTitle)
                    Text(errorMessage)
                        .font(.body)
                        .foregroundColor(.secondary)
                }
            } else if let styleReport = viewModel.styleReport {
                ScrollView {
                    VStack(spacing: 20) {
                        Text("Style Analysis Report")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                            .padding(.top, 20)

                        // Overall Attractiveness
                        VStack(alignment: .leading, spacing: 10) {
                            Text("Overall Attractiveness Trend")
                                .font(.title2)
                                .fontWeight(.semibold)
                            
                            LineChartView(data: [0.5, 0.6, 0.55, 0.7, 0.65, 0.8, 0.85])
                                .frame(height: 150)
                            
                            HStack {
                                VStack(alignment: .leading) {
                                    Text("Current")
                                        .font(.headline)
                                    Text("\(styleReport.ranking.overallAttractiveness, specifier: "%.0f")%")
                                        .font(.system(size: 40, weight: .bold))
                                        .foregroundColor(.blue)
                                }
                                Spacer()
                                VStack(alignment: .leading) {
                                    Text("Last Week")
                                        .font(.headline)
                                    Text("50%")
                                        .font(.system(size: 40, weight: .bold))
                                        .foregroundColor(.gray)
                                }
                            }
                            
                            Text("Total Votes: \(styleReport.ranking.totalVotes)")
                                .font(.headline)
                        }
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color(.secondarySystemBackground))
                        .cornerRadius(10)

                        // Gender Analysis
                        VStack(alignment: .leading, spacing: 10) {
                            Text("Gender Analysis")
                                .font(.title2)
                                .fontWeight(.semibold)
                            HStack {
                                VStack(alignment: .leading) {
                                    Text("Female Attractiveness")
                                        .font(.headline)
                                    Text("\(styleReport.ranking.femaleAttractiveness, specifier: "%.0f")%")
                                        .font(.system(size: 40, weight: .bold))
                                        .foregroundColor(.red)
                                }
                                Spacer()
                                VStack(alignment: .leading) {
                                    Text("Male Attractiveness")
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
                            Text("Style Performance")
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
                            Text("Achievements")
                                .font(.title2)
                                .fontWeight(.semibold)
                            
                            let unlockedAchievements = mockAchievements.filter { $0.isUnlocked }
                            let lockedAchievements = mockAchievements.filter { !$0.isUnlocked }

                            if !unlockedAchievements.isEmpty {
                                Text("Unlocked")
                                    .font(.headline)
                                ForEach(unlockedAchievements, id: \.id) { achievement in
                                    AchievementView(achievement: achievement)
                                }
                            }
                            
                            if !lockedAchievements.isEmpty {
                                Text("Locked")
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
                            Text("AI Insights")
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
                    Text("No Report Available")
                        .font(.largeTitle)
                    Text("Complete more ratings to unlock your style report.")
                        .font(.body)
                        .foregroundColor(.secondary)
                }
            }
        }
        .navigationTitle("Style Report")
        .onAppear {
            viewModel.fetchStyleReport(for: userId)
        }
        .overlay(
            Group {
                if let achievement = newlyUnlockedAchievement {
                    VStack {
                        Text("Achievement Unlocked!")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                            .foregroundColor(.yellow)
                        
                        AchievementView(achievement: achievement)
                        
                        Button("Celebrate!") {
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
            Button("Unlock Achievement") {
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
    Achievement(title: "Hot Streak", description: "Rate 10 photos in a row as 'Hot'", iconName: "flame.fill", category: .rating, requirement: .init(type: .consecutiveDays, target: 10), reward: .init(type: .acceleratedRating, value: 1, description: "1")),
    Achievement(title: "Style King", description: "Achieve a 90% or higher overall attractiveness score", iconName: "crown.fill", category: .style, requirement: .init(type: .hotRatingsReceived, target: 100), reward: .init(type: .specialBadge, value: 1, description: "1")),
    Achievement(title: "Rising Star", description: "Get 100 votes on your photos", iconName: "star.fill", category: .milestone, requirement: .init(type: .ratingsReceived, target: 100)),
    Achievement(title: "Legend", description: "Get 1000 votes on your photos", iconName: "star.leading.half.filled", category: .milestone, requirement: .init(type: .ratingsReceived, target: 1000)),
    Achievement(title: "Trendsetter", description: "Be the first to wear a new style", iconName: "paintbrush.fill", category: .style, requirement: .init(type: .styleReportsGenerated, target: 1)),
    Achievement(title: "Diamond", description: "Achieve a 95% or higher overall attractiveness score", iconName: "diamond.fill", category: .style, requirement: .init(type: .hotRatingsReceived, target: 500))
]

let mockReport = StyleReport(
    id: "1",
    userId: "123",
    dominantStyle: .streetwear,
    styleBreakdown: [
        .streetwear: 85,
        .minimalist: 78,
        .edgy: 72,
        .formal: 65,
        .colorful: 58
    ].reduce(into: [:]) { $0[$1.key.rawValue] = $1.value },
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
