//
//  JourneyTabView.swift
//  viberanking
//
//  Created by Kiro on 2025/07/29.
//

import SwiftUI

struct JourneyTabView: View {
    @EnvironmentObject private var themeManager: ThemeManager
    @EnvironmentObject private var authViewModel: AuthenticationViewModel
    @StateObject private var viewModel = JourneyViewModel()
    @State private var showingPaywall = false
    @State private var isLoaded = false
    
    var body: some View {
        if #available(iOS 16.0, *) {
            NavigationStack {
                mainContent
            }
        } else {
            NavigationView {
                mainContent
            }
            .navigationViewStyle(StackNavigationViewStyle())
        }
    }
    
    private var mainContent: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            if isLoaded {
                ScrollView {
                    LazyVStack(spacing: 24) {
                        // 標題
                        HStack {
                            Text("風格歷程")
                                .font(.largeTitle)
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                            Spacer()
                        }
                        .padding(.horizontal, 20)
                        
                        // 成就徽章
                        achievementBadge
                        
                        // 圖表
                        simplifiedChartView
                        
                        // 統計卡片
                        statsGrid
                        
                        // AI 改進方案 (付費區塊)
                        aiImprovementSection
                    }
                    .padding(.top, 20)
                    .safeAreaInset(edge: .bottom) {
                        // Avoid being overlapped by custom tab bar on compact-height devices (e.g., iPhone 13 non-fullscreen)
                        Color.clear.frame(height: 90)
                    }
                }
            } else {
                // Loading state
                VStack {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        .scaleEffect(1.2)
                    
                    Text("載入風格數據...")
                        .foregroundColor(.white.opacity(0.7))
                        .padding(.top, 16)
                }
            }
        }
        .navigationBarHidden(true)
        .sheet(isPresented: $showingPaywall) {
            PaywallView(isPresented: $showingPaywall)
        }
        .onAppear {
            loadDataIfNeeded()
        }
    }
    
    private func loadDataIfNeeded() {
        guard !isLoaded else { return }
        
        print("🔄 JourneyTabView: Starting to load data...")
        
        if let userId = authViewModel.user?.id {
            print("👤 JourneyTabView: Loading data for user: \(userId)")
            Task {
                do {
                    await viewModel.loadUserJourney(userId: userId)
                    await MainActor.run {
                        print("✅ JourneyTabView: Data loaded successfully")
                        withAnimation(.easeInOut(duration: 0.3)) {
                            isLoaded = true
                        }
                    }
                } catch {
                    print("❌ JourneyTabView: Error loading data: \(error)")
                    await MainActor.run {
                        // Still show the view with mock data
                        withAnimation(.easeInOut(duration: 0.3)) {
                            isLoaded = true
                        }
                    }
                }
            }
        } else {
            print("🔄 JourneyTabView: No user found, loading with mock data")
            // Load with mock data if no user
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                print("✅ JourneyTabView: Mock data loaded")
                withAnimation(.easeInOut(duration: 0.3)) {
                    isLoaded = true
                }
            }
        }
    }
    
    private var achievementBadge: some View {
        VStack(spacing: 12) {
            let score = viewModel.overallPerformance
            let (title, subtitle, color, icon) = getAchievementInfo(score: score)
            
            HStack(spacing: 16) {
                // 徽章圖標
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [color.opacity(0.8), color.opacity(0.4)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 60, height: 60)
                    
                    Image(systemName: icon)
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(.white)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                    
                    Text(subtitle)
                        .font(.subheadline)
                        .foregroundColor(.gray)
                    
                    Text("綜合評分: \(Int(score))")
                        .font(.caption)
                        .foregroundColor(color)
                }
                
                Spacer()
            }
            .padding(20)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.gray.opacity(0.1))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(color.opacity(0.3), lineWidth: 1)
                    )
            )
        }
        .padding(.horizontal, 20)
    }
    
    private func getAchievementInfo(score: Double) -> (String, String, Color, String) {
        switch score {
        case 0..<50:
            return ("路人之軀", "繼續努力，你會變得更好", .gray, "person.fill")
        case 50..<60:
            return ("小有魅力", "已經開始展現個人風格", .blue, "star.fill")
        case 60..<70:
            return ("魅力四射", "你的風格很有吸引力", .purple, "sparkles")
        case 70..<80:
            return ("風格達人", "你的品味令人印象深刻", .orange, "crown.fill")
        case 80..<90:
            return ("時尚偶像", "你是真正的風格標杆", .pink, "flame.fill")
        default:
            return ("傳奇風範", "你已達到風格的巔峰", .yellow, "trophy.fill")
        }
    }
    
    private var simplifiedChartView: some View {
        VStack(spacing: 16) {
            // 圖表標題
            HStack {
                Text("風格趨勢")
                    .font(.headline)
                    .foregroundColor(.white)
                Spacer()
                Text("過去7天")
                    .font(.caption)
                    .foregroundColor(.gray)
            }
            .padding(.horizontal, 20)
            
            // 簡化的圖表
            VStack(spacing: 12) {
                // 圖表區域
                HStack(alignment: .bottom, spacing: 8) {
                    ForEach(0..<7, id: \.self) { index in
                        let height = getBarHeight(for: index)
                        let color = getBarColor(for: index)
                        
                        VStack(spacing: 4) {
                            // 數值標籤
                            Text("\(Int(height * 100))")
                                .font(.caption2)
                                .foregroundColor(.white.opacity(0.8))
                                .opacity(height > 0.1 ? 1 : 0)
                            
                            // 柱狀圖
                            RoundedRectangle(cornerRadius: 4)
                                .fill(
                                    LinearGradient(
                                        colors: [color.opacity(0.8), color.opacity(0.4)],
                                        startPoint: .top,
                                        endPoint: .bottom
                                    )
                                )
                                .frame(width: 32, height: max(8, height * 120))
                                .animation(.easeInOut(duration: 0.6).delay(Double(index) * 0.1), value: height)
                            
                            // 日期標籤
                            Text("W\(index + 1)")
                                .font(.caption2)
                                .foregroundColor(.gray)
                        }
                    }
                }
                .frame(height: 160)
                .padding(.horizontal, 16)
                
                // 趨勢指示器
                HStack {
                    Image(systemName: "arrow.up.right")
                        .foregroundColor(.green)
                        .font(.caption)
                    
                    Text("整體趨勢向上")
                        .font(.caption)
                        .foregroundColor(.green)
                    
                    Spacer()
                    
                    Text("平均分數: \(String(format: "%.1f", viewModel.overallPerformance))")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.7))
                }
                .padding(.horizontal, 16)
            }
            .padding(.vertical, 16)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.gray.opacity(0.05))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(Color.gray.opacity(0.1), lineWidth: 1)
                    )
            )
            .padding(.horizontal, 20)
        }
    }
    
    private func getBarHeight(for index: Int) -> CGFloat {
        let mockData: [CGFloat] = [0.3, 0.5, 0.4, 0.7, 0.6, 0.8, 0.75]
        return mockData[index]
    }
    
    private func getBarColor(for index: Int) -> Color {
        let height = getBarHeight(for: index)
        switch height {
        case 0.0..<0.3:
            return .red
        case 0.3..<0.5:
            return .orange
        case 0.5..<0.7:
            return .yellow
        default:
            return .green
        }
    }
    
    private var statsGrid: some View {
        VStack(spacing: 16) {
            // 整體表現
            StatCards(
                title: "整體表現", 
                value: String(format: "%.0f%%", max(0, min(100, viewModel.overallPerformance))), 
                color: .cyan, 
                icon: "chart.line.uptrend.xyaxis"
            )
            
            // 吸引力評分
            HStack(spacing: 16) {
                StatCards(
                    title: "女性吸引力", 
                    value: String(format: "%.1f", max(0, min(10, viewModel.femaleAttraction / 10))), 
                    color: .pink, 
                    icon: "heart.fill"
                )
                StatCards(
                    title: "男性吸引力", 
                    value: String(format: "%.1f", max(0, min(10, viewModel.maleAttraction / 10))), 
                    color: .blue, 
                    icon: "star.fill"
                )
            }
            
            // 個人歷程
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Image(systemName: "map.fill")
                        .foregroundColor(.orange)
                    Text("個人歷程")
                        .font(.headline)
                        .foregroundColor(.white)
                    Spacer()
                }
                
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("❤️ 獲得: \(viewModel.userStats?.likeCount ?? 0)")
                            .foregroundColor(.white)
                        Spacer()
                        Text("🔄 獲得: \(viewModel.userStats?.normalCount ?? 0)")
                            .foregroundColor(.white)
                    }
                    
                    Text("總評分: \(viewModel.userStats?.totalRatings ?? 0)")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
            }
            .padding(16)
            .background(RoundedRectangle(cornerRadius: 16).fill(Color.gray.opacity(0.1)))
            
            // 目前趴數
            VStack(spacing: 12) {
                HStack {
                    Image(systemName: "trophy.fill")
                        .foregroundColor(.yellow)
                    Text("目前趴數")
                        .font(.headline)
                        .foregroundColor(.white)
                    Spacer()
                }
                
                HStack {
                    VStack(alignment: .leading) {
                        Text("你的排名")
                            .font(.caption)
                            .foregroundColor(.gray)
                        Text(viewModel.currentRankPercentage)
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.yellow)
                    }
                    
                    Spacer()
                    
                    VStack(alignment: .trailing) {
                        Text("總用戶")
                            .font(.caption)
                            .foregroundColor(.gray)
                        Text(viewModel.totalUsers)
                            .font(.title3)
                            .foregroundColor(.white)
                    }
                }
            }
            .padding(16)
            .background(RoundedRectangle(cornerRadius: 16).fill(Color.gray.opacity(0.1)))
        }
        .padding(.horizontal, 20)
    }
    
    private var aiImprovementSection: some View {
        VStack(spacing: 16) {
            HStack {
                Image(systemName: "brain.head.profile")
                    .foregroundColor(.purple)
                Text("AI 改進方案")
                    .font(.headline)
                    .foregroundColor(.white)
                Spacer()
                Image(systemName: "lock.fill")
                    .foregroundColor(.yellow)
                    .font(.caption)
            }
            
            VStack(alignment: .leading, spacing: 12) {
                Text("個人化風格建議")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                        Text("專業風格分析")
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                    
                    HStack {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                        Text("個人化穿搭建議")
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                    
                    HStack {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                        Text("色彩搭配推薦")
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                    
                    HStack {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                        Text("風格趨勢預測")
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                }
                
                Button(action: {
                    showingPaywall = true
                }) {
                    HStack {
                        Image(systemName: "sparkles")
                        Text("解鎖 AI 建議 - $10.00")
                            .fontWeight(.semibold)
                        Spacer()
                        Image(systemName: "arrow.right")
                    }
                    .foregroundColor(.white)
                    .padding(.vertical, 16)
                    .padding(.horizontal, 20)
                    .background(
                        LinearGradient(
                            colors: [.purple, .pink],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .cornerRadius(12)
                }
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.gray.opacity(0.1))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.purple.opacity(0.3), lineWidth: 1)
                )
        )
        .padding(.horizontal, 20)
    }
}

// MARK: - 輔助組件

struct StatCards: View {
    let title: String
    let value: String
    let color: Color
    let icon: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(color)
                Spacer()
                Text(value)
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
            }
            
            Text(title)
                .font(.subheadline)
                .foregroundColor(.white)
        }
        .padding(16)
        .background(RoundedRectangle(cornerRadius: 16).fill(Color.gray.opacity(0.1)))
    }
}

#Preview {
    JourneyTabView()
        .environmentObject(ThemeManager())
        .environmentObject(AuthenticationViewModel())
        .preferredColorScheme(.dark)
}
