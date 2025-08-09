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
                        
                        // 圖表
                        chartView
                        
                        // 統計卡片
                        statsGrid
                    }
                    .padding(.top, 20)
                    .padding(.bottom, 100)
                }
            }
            .navigationBarHidden(true)
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
    
    private var chartView: some View {
        VStack(spacing: 12) {
            // 圖表區域
            ZStack {
                // 背景網格
                VStack {
                    ForEach(0..<3) { _ in
                        Rectangle()
                            .fill(Color.gray.opacity(0.1))
                            .frame(height: 0.5)
                        Spacer()
                    }
                }
                .frame(height: 180)
                
                // 曲線圖
                GeometryReader { geometry in
                    let width = geometry.size.width
                    let height = geometry.size.height
                    let chartData = viewModel.chartData.map { CGFloat($0.score / 100.0) }
                    
                    if !chartData.isEmpty {
                        let stepX = width / CGFloat(chartData.count - 1)
                        
                        // 主線條
                        Path { path in
                            for (index, value) in chartData.enumerated() {
                                let x = CGFloat(index) * stepX
                                let y = height - (value * height)
                                
                                if index == 0 {
                                    path.move(to: CGPoint(x: x, y: y))
                                } else {
                                    path.addLine(to: CGPoint(x: x, y: y))
                                }
                            }
                        }
                        .stroke(
                            LinearGradient(colors: [.cyan, .blue], startPoint: .leading, endPoint: .trailing),
                            style: StrokeStyle(lineWidth: 3, lineCap: .round)
                        )
                        
                        // 陰影填充
                        Path { path in
                            for (index, value) in chartData.enumerated() {
                                let x = CGFloat(index) * stepX
                                let y = height - (value * height)
                                
                                if index == 0 {
                                    path.move(to: CGPoint(x: x, y: y))
                                } else {
                                    path.addLine(to: CGPoint(x: x, y: y))
                                }
                            }
                            path.addLine(to: CGPoint(x: width, y: height))
                            path.addLine(to: CGPoint(x: 0, y: height))
                            path.closeSubpath()
                        }
                        .fill(
                            LinearGradient(
                                colors: [.cyan.opacity(0.3), .clear],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                    }
                }
                .frame(height: 180)
            }
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
        .preferredColorScheme(.dark)
}
