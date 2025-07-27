import SwiftUI

struct StyleReportView: View {
    @StateObject private var viewModel: StyleReportViewModel
    @State private var newlyUnlockedAchievement: Achievement?
    @State private var showReportUnlockAnimation = false
    @State private var animateProgressBars = false
    @State private var showCelebrationParticles = false
    let userId: String

    init(userId: String) {
        self.userId = userId
        _viewModel = StateObject(wrappedValue: StyleReportViewModel(styleAnalysisService: StyleAnalysisService()))
    }

    var body: some View {
        ZStack {
            // Main content
            Group {
                if viewModel.isLoading {
                    loadingView
                } else if let errorMessage = viewModel.errorMessage {
                    errorView(errorMessage)
                } else if let styleReport = viewModel.styleReport {
                    reportContentView(styleReport)
                } else {
                    noReportView
                }
            }
            
            // Report unlock animation overlay
            if showReportUnlockAnimation {
                reportUnlockOverlay
            }
            
            // Achievement unlock overlay
            if let achievement = newlyUnlockedAchievement {
                achievementUnlockOverlay(achievement)
            }
            
            // Celebration particles
            if showCelebrationParticles {
                celebrationParticlesView
            }
        }
        .navigationTitle("風格分析報告")
        .navigationBarTitleDisplayMode(.large)
        .onAppear {
            viewModel.fetchStyleReport(for: userId)
        }
        .onChange(of: viewModel.styleReport) { report in
            if report != nil && !showReportUnlockAnimation {
                triggerReportUnlockAnimation()
            }
        }
    }
    
    // MARK: - Loading View
    private var loadingView: some View {
        VStack(spacing: 20) {
            ProgressView()
                .scaleEffect(1.5)
            
            Text("正在分析你的風格...")
                .font(.title2)
                .fontWeight(.medium)
            
            Text("這可能需要幾秒鐘時間")
                .font(.body)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemBackground))
    }
    
    // MARK: - Error View
    private func errorView(_ errorMessage: String) -> some View {
        VStack(spacing: 20) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 60))
                .foregroundColor(.orange)
            
            Text("報告生成失敗")
                .font(.title)
                .fontWeight(.bold)
            
            Text(errorMessage)
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            
            Button("重新嘗試") {
                viewModel.fetchStyleReport(for: userId)
            }
            .buttonStyle(.borderedProminent)
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemBackground))
    }
    
    // MARK: - No Report View
    private var noReportView: some View {
        VStack(spacing: 20) {
            Image(systemName: "chart.bar.doc.horizontal")
                .font(.system(size: 80))
                .foregroundColor(.blue)
            
            Text("還沒有風格報告")
                .font(.title)
                .fontWeight(.bold)
            
            Text("完成更多評分來解鎖你的個人風格分析")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemBackground))
    }
    
    // MARK: - Report Content View
    private func reportContentView(_ styleReport: StyleReport) -> some View {
        ScrollView {
            LazyVStack(spacing: 24) {
                // Header with dominant style
                dominantStyleHeader(styleReport)
                
                // Overall attractiveness trend
                overallTrendCard(styleReport)
                
                // Gender analysis
                genderAnalysisCard(styleReport)
                
                // Style breakdown with animated bars
                styleBreakdownCard(styleReport)
                
                // Ranking comparison
                rankingComparisonCard(styleReport)
                
                // AI recommendations
                recommendationsCard(styleReport)
                
                // Share button
                shareButton(styleReport)
            }
            .padding()
        }
        .onAppear {
            // Trigger progress bar animations after a delay
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                withAnimation(.easeInOut(duration: 1.0)) {
                    animateProgressBars = true
                }
            }
        }
    }
    
    // MARK: - Dominant Style Header
    private func dominantStyleHeader(_ styleReport: StyleReport) -> some View {
        VStack(spacing: 16) {
            Text(styleReport.dominantStyle.emoji)
                .font(.system(size: 80))
            
            Text("你的主要風格")
                .font(.headline)
                .foregroundColor(.secondary)
            
            Text(styleReport.dominantStyle.displayName)
                .font(.largeTitle)
                .fontWeight(.bold)
                .foregroundColor(.primary)
            
            Text(styleReport.dominantStyle.description)
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(
            LinearGradient(
                colors: [Color.blue.opacity(0.1), Color.purple.opacity(0.1)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .cornerRadius(16)
    }
    
    // MARK: - Overall Trend Card
    private func overallTrendCard(_ styleReport: StyleReport) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "chart.line.uptrend.xyaxis")
                    .foregroundColor(.blue)
                Text("7天吸引力趋势")
                    .font(.title2)
                    .fontWeight(.semibold)
            }
            
            // Enhanced trend data with better simulation
            EnhancedLineChartView(
                data: generateEnhanced7DayTrendData(currentScore: styleReport.ranking.overallAttractiveness),
                primaryColor: .blue,
                secondaryColor: .purple
            )
            .frame(height: 140)
            
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("目前分數")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text("\(styleReport.ranking.overallAttractiveness, specifier: "%.0f")%")
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundColor(.blue)
                }
                
                Spacer()
                
                VStack(alignment: .center, spacing: 4) {
                    Text("7天變化")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    let weeklyChange = calculateWeeklyChange(currentScore: styleReport.ranking.overallAttractiveness)
                    Text("\(weeklyChange > 0 ? "+" : "")\(weeklyChange, specifier: "%.1f")%")
                        .font(.headline)
                        .fontWeight(.bold)
                        .foregroundColor(weeklyChange >= 0 ? .green : .red)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    Text("總評分數")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text("\(styleReport.ranking.totalVotes)")
                        .font(.title2)
                        .fontWeight(.semibold)
                }
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(16)
    }
    
    // MARK: - Gender Analysis Card
    private func genderAnalysisCard(_ styleReport: StyleReport) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "person.2.fill")
                    .foregroundColor(.purple)
                Text("性別吸引力分析")
                    .font(.title2)
                    .fontWeight(.semibold)
            }
            
            HStack(spacing: 20) {
                // Female attractiveness
                VStack(spacing: 8) {
                    Image(systemName: "person.fill")
                        .font(.title2)
                        .foregroundColor(.pink)
                    
                    Text("女性評價")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Text("\(styleReport.ranking.femaleAttractiveness, specifier: "%.0f")%")
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundColor(.pink)
                    
                    // Weekly growth for female ratings
                    let femaleGrowth = calculateGenderWeeklyGrowth(score: styleReport.ranking.femaleAttractiveness, isFemale: true)
                    Text("\(femaleGrowth > 0 ? "+" : "")\(femaleGrowth, specifier: "%.1f")%")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(femaleGrowth >= 0 ? .green : .red)
                    
                    EnhancedProgressBar(
                        value: animateProgressBars ? styleReport.ranking.femaleAttractiveness : 0,
                        maxValue: 100,
                        color: .pink
                    )
                    .frame(height: 8)
                    .animation(.easeInOut(duration: 1.0).delay(0.2), value: animateProgressBars)
                }
                
                Spacer()
                
                // Male attractiveness
                VStack(spacing: 8) {
                    Image(systemName: "person.fill")
                        .font(.title2)
                        .foregroundColor(.blue)
                    
                    Text("男性評價")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Text("\(styleReport.ranking.maleAttractiveness, specifier: "%.0f")%")
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundColor(.blue)
                    
                    // Weekly growth for male ratings
                    let maleGrowth = calculateGenderWeeklyGrowth(score: styleReport.ranking.maleAttractiveness, isFemale: false)
                    Text("\(maleGrowth > 0 ? "+" : "")\(maleGrowth, specifier: "%.1f")%")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(maleGrowth >= 0 ? .green : .red)
                    
                    EnhancedProgressBar(
                        value: animateProgressBars ? styleReport.ranking.maleAttractiveness : 0,
                        maxValue: 100,
                        color: .blue
                    )
                    .frame(height: 8)
                    .animation(.easeInOut(duration: 1.0).delay(0.4), value: animateProgressBars)
                }
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(16)
    }
    
    // MARK: - Style Breakdown Card
    private func styleBreakdownCard(_ styleReport: StyleReport) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "paintbrush.fill")
                    .foregroundColor(.orange)
                Text("風格分析排名")
                    .font(.title2)
                    .fontWeight(.semibold)
            }
            
            let sortedStyles = styleReport.styleBreakdown.sorted { $0.value > $1.value }
            
            ForEach(Array(sortedStyles.enumerated()), id: \.offset) { index, styleData in
                let (styleName, score) = styleData
                
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        // Ranking indicator
                        Text("#\(index + 1)")
                            .font(.caption)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                            .frame(width: 24, height: 20)
                            .background(
                                RoundedRectangle(cornerRadius: 6)
                                    .fill(getRankingColor(for: index))
                            )
                        
                        // Find the StyleType enum case
                        if let styleType = StyleType.allCases.first(where: { $0.rawValue == styleName }) {
                            Text(styleType.emoji)
                                .font(.title3)
                            Text(styleType.displayName)
                                .font(.headline)
                                .fontWeight(.medium)
                        } else {
                            Text(styleName)
                                .font(.headline)
                                .fontWeight(.medium)
                        }
                        
                        Spacer()
                        
                        VStack(alignment: .trailing, spacing: 2) {
                            Text("\(score, specifier: "%.0f")%")
                                .font(.headline)
                                .fontWeight(.bold)
                                .foregroundColor(.primary)
                            
                            // Style trend indicator
                            let trendChange = calculateStyleTrend(score: score, index: index)
                            HStack(spacing: 2) {
                                Image(systemName: trendChange >= 0 ? "arrow.up" : "arrow.down")
                                    .font(.caption2)
                                    .foregroundColor(trendChange >= 0 ? .green : .red)
                                Text("\(abs(trendChange), specifier: "%.1f")%")
                                    .font(.caption2)
                                    .foregroundColor(trendChange >= 0 ? .green : .red)
                            }
                        }
                    }
                    
                    EnhancedProgressBar(
                        value: animateProgressBars ? score : 0,
                        maxValue: 100,
                        color: getStyleColor(for: index)
                    )
                    .frame(height: 12)
                    .animation(.spring(response: 0.8, dampingFraction: 0.8).delay(Double(index) * 0.1), value: animateProgressBars)
                }
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(16)
    }
    
    // MARK: - Ranking Comparison Card
    private func rankingComparisonCard(_ styleReport: StyleReport) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "trophy.fill")
                    .foregroundColor(.yellow)
                Text("排名表現")
                    .font(.title2)
                    .fontWeight(.semibold)
            }
            
            HStack(spacing: 20) {
                VStack(spacing: 8) {
                    Text("🏆")
                        .font(.largeTitle)
                    
                    Text("整體排名")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    // Simulated ranking based on attractiveness score
                    let ranking = calculateRanking(from: styleReport.ranking.overallAttractiveness)
                    Text("前 \(ranking)%")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.yellow)
                }
                
                Spacer()
                
                VStack(spacing: 8) {
                    Text("📈")
                        .font(.largeTitle)
                    
                    Text("進步幅度")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Text("+15%")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.green)
                }
                
                Spacer()
                
                VStack(spacing: 8) {
                    Text("⭐")
                        .font(.largeTitle)
                    
                    Text("風格分數")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Text("\(Int(styleReport.ranking.overallAttractiveness))")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.orange)
                }
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(16)
    }
    
    // MARK: - Recommendations Card
    private func recommendationsCard(_ styleReport: StyleReport) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "lightbulb.fill")
                    .foregroundColor(.yellow)
                Text("AI 風格建議")
                    .font(.title2)
                    .fontWeight(.semibold)
            }
            
            ForEach(Array(styleReport.recommendations.enumerated()), id: \.offset) { index, recommendation in
                HStack(alignment: .top, spacing: 12) {
                    Text("\(index + 1)")
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .frame(width: 20, height: 20)
                        .background(Circle().fill(Color.blue))
                    
                    Text(recommendation)
                        .font(.body)
                        .fixedSize(horizontal: false, vertical: true)
                    
                    Spacer()
                }
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(16)
    }
    
    // MARK: - Share Button
    private func shareButton(_ styleReport: StyleReport) -> some View {
        Button(action: {
            shareReport(styleReport)
        }) {
            HStack {
                Image(systemName: "square.and.arrow.up")
                Text("分享我的風格報告")
                    .fontWeight(.semibold)
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color.blue)
            .foregroundColor(.white)
            .cornerRadius(12)
        }
    }
    
    // MARK: - Report Unlock Overlay
    private var reportUnlockOverlay: some View {
        StyleReportUnlockView {
            withAnimation(.easeInOut(duration: 0.5)) {
                showReportUnlockAnimation = false
                showCelebrationParticles = true
            }
            
            // Hide celebration particles after animation
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                showCelebrationParticles = false
            }
        }
        .transition(.opacity)
    }
    
    // MARK: - Achievement Unlock Overlay
    private func achievementUnlockOverlay(_ achievement: Achievement) -> some View {
        ZStack {
            Color.black.opacity(0.8)
                .ignoresSafeArea()
            
            VStack(spacing: 20) {
                Text("🏆")
                    .font(.system(size: 80))
                    .scaleEffect(1.2)
                    .animation(.spring(response: 0.6, dampingFraction: 0.8), value: newlyUnlockedAchievement)
                
                Text("成就解鎖！")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(.yellow)
                
                AchievementView(achievement: achievement)
                    .scaleEffect(1.1)
                
                Button("太棒了！") {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        newlyUnlockedAchievement = nil
                    }
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
            }
            .padding()
        }
        .transition(.scale.combined(with: .opacity))
    }
    
    // MARK: - Celebration Particles View
    private var celebrationParticlesView: some View {
        // This would be a particle system in a real implementation
        // For now, we'll use a simple animation
        ZStack {
            ForEach(0..<20, id: \.self) { index in
                Text(["🎉", "⭐", "✨", "🎊"].randomElement() ?? "🎉")
                    .font(.title)
                    .position(
                        x: CGFloat.random(in: 0...UIScreen.main.bounds.width),
                        y: CGFloat.random(in: 0...UIScreen.main.bounds.height)
                    )
                    .opacity(showCelebrationParticles ? 1 : 0)
                    .scaleEffect(showCelebrationParticles ? 1 : 0)
                    .animation(
                        .easeInOut(duration: 0.5)
                        .delay(Double(index) * 0.1),
                        value: showCelebrationParticles
                    )
            }
        }
        .allowsHitTesting(false)
    }
    
    // MARK: - Helper Methods
    private func triggerReportUnlockAnimation() {
        withAnimation(.easeInOut(duration: 0.5)) {
            showReportUnlockAnimation = true
        }
    }
    
    private func generateTrendData(currentScore: Double) -> [Double] {
        let baseScore = currentScore / 100.0
        let variation = 0.1
        
        return (0..<7).map { index in
            let progress = Double(index) / 6.0
            let trend = baseScore * (0.6 + 0.4 * progress)
            let noise = Double.random(in: -variation...variation)
            return max(0, min(1, trend + noise))
        }
    }
    
    private func generateEnhanced7DayTrendData(currentScore: Double) -> [TrendDataPoint] {
        let baseScore = currentScore / 100.0
        let calendar = Calendar.current
        let today = Date()
        
        return (0..<7).map { dayOffset in
            let date = calendar.date(byAdding: .day, value: -6 + dayOffset, to: today) ?? today
            let progress = Double(dayOffset) / 6.0
            
            // Create more realistic trend with some volatility
            let trendBase = baseScore * (0.7 + 0.3 * progress)
            let dailyVariation = Double.random(in: -0.08...0.08)
            let score = max(0.1, min(1.0, trendBase + dailyVariation))
            
            return TrendDataPoint(
                date: date,
                score: score,
                votes: Int.random(in: 15...45)
            )
        }
    }
    
    private func calculateWeeklyChange(currentScore: Double) -> Double {
        // Simulate weekly change based on current score
        let baseChange = Double.random(in: -5.0...8.0)
        let scoreInfluence = (currentScore - 50) * 0.1
        return baseChange + scoreInfluence
    }
    
    private func calculateGenderWeeklyGrowth(score: Double, isFemale: Bool) -> Double {
        // Simulate gender-specific weekly growth
        let baseGrowth = Double.random(in: -3.0...6.0)
        let genderModifier = isFemale ? 0.5 : -0.3
        return baseGrowth + genderModifier
    }
    
    private func calculateStyleTrend(score: Double, index: Int) -> Double {
        // Simulate style trend based on ranking position
        let baseTrend = Double.random(in: -2.0...3.0)
        let rankingModifier = Double(5 - index) * 0.2
        return baseTrend + rankingModifier
    }
    
    private func getRankingColor(for index: Int) -> Color {
        switch index {
        case 0: return .yellow
        case 1: return .orange
        case 2: return .red
        default: return .gray
        }
    }
    
    private func getStyleColor(for index: Int) -> Color {
        let colors: [Color] = [.blue, .purple, .green, .orange, .pink, .cyan, .indigo]
        return colors[index % colors.count]
    }
    
    private func calculateRanking(from score: Double) -> Int {
        // Simple ranking calculation based on score
        switch score {
        case 90...: return 5
        case 80..<90: return 10
        case 70..<80: return 20
        case 60..<70: return 35
        case 50..<60: return 50
        default: return 70
        }
    }
    
    private func shareReport(_ styleReport: StyleReport) {
        // Implement sharing functionality
        let shareText = "我的風格分析：主要風格是\(styleReport.dominantStyle.displayName)，整體吸引力\(Int(styleReport.ranking.overallAttractiveness))%！"
        
        let activityVC = UIActivityViewController(
            activityItems: [shareText],
            applicationActivities: nil
        )
        
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let window = windowScene.windows.first {
            window.rootViewController?.present(activityVC, animated: true)
        }
    }
}

// MARK: - Enhanced Components
struct TrendDataPoint {
    let date: Date
    let score: Double
    let votes: Int
}

struct EnhancedLineChartView: View {
    let data: [TrendDataPoint]
    let primaryColor: Color
    let secondaryColor: Color
    
    @State private var selectedPoint: TrendDataPoint?
    @State private var animateChart = false
    
    var body: some View {
        GeometryReader { geometry in
            let chartData = data.map { $0.score }
            let path = Path.quadCurvedPath(with: chartData, in: geometry.frame(in: .local))
            
            ZStack {
                // Gradient fill
                path
                    .fill(
                        LinearGradient(
                            colors: [primaryColor.opacity(0.3), primaryColor.opacity(0.1), Color.clear],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .scaleEffect(y: animateChart ? 1.0 : 0.0, anchor: .bottom)
                
                // Main line
                path
                    .stroke(
                        LinearGradient(
                            colors: [primaryColor, secondaryColor],
                            startPoint: .leading,
                            endPoint: .trailing
                        ),
                        style: StrokeStyle(lineWidth: 3, lineCap: .round, lineJoin: .round)
                    )
                    .scaleEffect(y: animateChart ? 1.0 : 0.0, anchor: .bottom)
                
                // Data points
                ForEach(Array(data.enumerated()), id: \.offset) { index, point in
                    let x = CGFloat(index) * (geometry.size.width / CGFloat(data.count - 1))
                    let y = (1 - CGFloat(point.score)) * geometry.size.height
                    
                    Circle()
                        .fill(primaryColor)
                        .frame(width: 8, height: 8)
                        .position(x: x, y: y)
                        .scaleEffect(animateChart ? 1.0 : 0.0)
                        .animation(.spring(response: 0.6, dampingFraction: 0.8).delay(Double(index) * 0.1), value: animateChart)
                }
            }
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 1.0)) {
                animateChart = true
            }
        }
    }
}

struct EnhancedProgressBar: View {
    let value: Double
    let maxValue: Double
    let color: Color
    
    @State private var animatedValue: Double = 0
    
    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                // Background
                RoundedRectangle(cornerRadius: 6)
                    .fill(Color(.systemGray5))
                    .frame(width: geometry.size.width, height: geometry.size.height)
                
                // Progress fill with gradient
                RoundedRectangle(cornerRadius: 6)
                    .fill(
                        LinearGradient(
                            colors: [color, color.opacity(0.7)],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(
                        width: min(CGFloat(animatedValue / maxValue) * geometry.size.width, geometry.size.width),
                        height: geometry.size.height
                    )
                    .shadow(color: color.opacity(0.3), radius: 2, x: 0, y: 1)
            }
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 0.8)) {
                animatedValue = value
            }
        }
        .onChange(of: value) { newValue in
            withAnimation(.easeInOut(duration: 0.8)) {
                animatedValue = newValue
            }
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