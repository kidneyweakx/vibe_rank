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
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.black.ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
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
                        materialChartView
                        
                        // 統計卡片
                        statsGrid
                        
                        // AI 改進方案 (付費區塊)
                        aiImprovementSection
                    }
                    .padding(.top, 20)
                    .padding(.bottom, 100)
                }
            }
            .navigationBarHidden(true)
        }
        .sheet(isPresented: $showingPaywall) {
            PaywallView(isPresented: $showingPaywall)
        }
        .task {
            if let userId = authViewModel.user?.id {
                await viewModel.loadUserJourney(userId: userId)
            }
        }
        .refreshable {
            await viewModel.refreshData()
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
    
    private var materialChartView: some View {
        VStack(spacing: 16) {
            // 圖表標題
            HStack {
                Text("風格趨勢")
                    .font(.headline)
                    .foregroundColor(.white)
                Spacer()
                Text("過去30天")
                    .font(.caption)
                    .foregroundColor(.gray)
            }
            .padding(.horizontal, 20)
            
            // Material Design 圖表
            VStack(spacing: 0) {
                // Y軸刻度
                HStack {
                    VStack(alignment: .trailing, spacing: 0) {
                        ForEach([100, 75, 50, 25, 0], id: \.self) { value in
                            HStack {
                                Text("\(value)")
                                    .font(.caption2)
                                    .foregroundColor(.gray)
                                    .frame(width: 20, alignment: .trailing)
                                
                                Rectangle()
                                    .fill(Color.gray.opacity(0.2))
                                    .frame(height: 0.5)
                            }
                            .frame(height: value == 0 ? 0 : 36)
                        }
                    }
                }
                .frame(height: 180)
                
                // X軸刻度
                HStack {
                    Spacer().frame(width: 24)
                    HStack {
                        ForEach(0..<7) { index in
                            Text("W\(index + 1)")
                                .font(.caption2)
                                .foregroundColor(.gray)
                                .frame(maxWidth: .infinity)
                        }
                    }
                }
                .padding(.top, 8)
            }
            .overlay(
                // 圖表內容
                GeometryReader { geometry in
                    let width = geometry.size.width - 24
                    let height: CGFloat = 180
                    let chartData = viewModel.chartData.isEmpty ? 
                        [0.3, 0.5, 0.4, 0.7, 0.6, 0.8, 0.75] : 
                        viewModel.chartData.map { CGFloat($0.score / 100.0) }
                    
                    if !chartData.isEmpty {
                        let stepX = width / CGFloat(chartData.count - 1)
                        
                        // 區塊背景
                        ForEach(Array(chartData.enumerated()), id: \.offset) { index, value in
                            let x = CGFloat(index) * stepX + 24
                            let barHeight = value * height
                            
                            RoundedRectangle(cornerRadius: 4)
                                .fill(
                                    LinearGradient(
                                        colors: [
                                            Color.cyan.opacity(0.6),
                                            Color.blue.opacity(0.3)
                                        ],
                                        startPoint: .top,
                                        endPoint: .bottom
                                    )
                                )
                                .frame(width: 20, height: barHeight)
                                .position(x: x, y: height - barHeight/2)
                        }
                        
                        // 連接線
                        Path { path in
                            for (index, value) in chartData.enumerated() {
                                let x = CGFloat(index) * stepX + 24
                                let y = height - (value * height)
                                
                                if index == 0 {
                                    path.move(to: CGPoint(x: x, y: y))
                                } else {
                                    path.addLine(to: CGPoint(x: x, y: y))
                                }
                            }
                        }
                        .stroke(
                            LinearGradient(
                                colors: [.cyan, .blue],
                                startPoint: .leading,
                                endPoint: .trailing
                            ),
                            style: StrokeStyle(lineWidth: 3, lineCap: .round, lineJoin: .round)
                        )
                        
                        // 數據點
                        ForEach(Array(chartData.enumerated()), id: \.offset) { index, value in
                            let x = CGFloat(index) * stepX + 24
                            let y = height - (value * height)
                            
                            Circle()
                                .fill(Color.white)
                                .frame(width: 8, height: 8)
                                .overlay(
                                    Circle()
                                        .stroke(Color.cyan, lineWidth: 2)
                                )
                                .position(x: x, y: y)
                        }
                    }
                }
            )
            .padding(.horizontal, 20)
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
    
    private var statsGrid: some View {
        VStack(spacing: 16) {
            // 整體表現
            StatCards(
                title: "整體表現", 
                value: String(format: "%.0f%%", viewModel.overallPerformance), 
                color: .cyan, 
                icon: "chart.line.uptrend.xyaxis"
            )
            
            // 吸引力評分
            HStack(spacing: 16) {
                StatCards(
                    title: "女性吸引力", 
                    value: String(format: "%.1f", viewModel.femaleAttraction / 10), 
                    color: .pink, 
                    icon: "heart.fill"
                )
                StatCards(
                    title: "男性吸引力", 
                    value: String(format: "%.1f", viewModel.maleAttraction / 10), 
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
                
                if let stats = viewModel.userStats {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("❤️ 獲得: \(stats.likeCount)")
                                .foregroundColor(.white)
                            Spacer()
                            Text("🔄 獲得: \(stats.normalCount)")
                                .foregroundColor(.white)
                        }
                        
                        Text("總評分: \(stats.totalRatings)")
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
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
