//
//  HomeView.swift
//  viberanking
//
//  Created by Kiro on 2025/07/25.
//

import SwiftUI

struct HomeView: View {
    @EnvironmentObject private var themeManager: ThemeManager
    @EnvironmentObject private var authViewModel: AuthenticationViewModel
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Welcome Section
                    welcomeSection
                    
                    // Quick Actions - Function Cards
                    quickActionsSection
                    
                    // Statistics - Data Cards
                    statisticsSection
                    
                    // Recent Activity
                    recentActivitySection
                }
                .padding()
            }
            .navigationTitle("首頁")
            .navigationBarTitleDisplayMode(.large)
            .background(themeManager.currentTheme.colors.background)
        }
    }
    
    // MARK: - Welcome Section
    private var welcomeSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("歡迎回來")
                        .font(AppTheme.Typography.title2)
                        .foregroundColor(themeManager.currentTheme.colors.text.opacity(0.8))
                    
                    Text("準備開始評分了嗎？")
                        .font(AppTheme.Typography.largeTitle)
                        .fontWeight(.bold)
                        .foregroundColor(themeManager.currentTheme.colors.text)
                }
                
                Spacer()
                
                // Profile Avatar
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [themeManager.currentTheme.colors.primary, themeManager.currentTheme.colors.secondary],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 60, height: 60)
                    .overlay(
                        Image(systemName: "person.fill")
                            .font(.system(size: 24))
                            .foregroundColor(.white)
                    )
            }
        }
        .padding(.bottom, 8)
    }
    
    // MARK: - Quick Actions Section
    private var quickActionsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            sectionHeader("快速操作")
            
            VStack(spacing: 16) {
                // Main Rating Card
                FunctionCard(
                    title: "開始評分",
                    subtitle: "為照片評分",
                    icon: "star.fill",
                    primaryData: "12",
                    secondaryData: "今日已評分",
                    backgroundColor: [
                        themeManager.currentTheme.colors.primary,
                        themeManager.currentTheme.colors.secondary
                    ],
                    size: .large,
                    destination: AnyView(EmptyView()),
                    onTap: {
                        // Navigate to rating view
                        print("導航到評分頁面")
                    }
                )
                
                // Secondary Action Cards
                HStack(spacing: 16) {
                    FunctionCard(
                        title: "上傳照片",
                        subtitle: "分享你的作品",
                        icon: "camera.fill",
                        primaryData: "5",
                        secondaryData: "本週上傳",
                        backgroundColor: [
                            Color.green,
                            Color.mint
                        ],
                        size: .medium,
                        destination: AnyView(EmptyView()),
                        onTap: {
                            print("導航到上傳頁面")
                        }
                    )
                    
                    FunctionCard(
                        title: "個人資料",
                        subtitle: "查看統計",
                        icon: "person.circle.fill",
                        primaryData: "7.5",
                        secondaryData: "平均評分",
                        backgroundColor: [
                            Color.purple,
                            Color.pink
                        ],
                        size: .medium,
                        destination: AnyView(EmptyView()),
                        onTap: {
                            print("導航到個人資料頁面")
                        }
                    )
                }
            }
        }
    }
    
    // MARK: - Statistics Section
    private var statisticsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            sectionHeader("統計數據")
            
            LazyVGrid(columns: [
                GridItem(.flexible(), spacing: AppTheme.Spacing.sm),
                GridItem(.flexible(), spacing: AppTheme.Spacing.sm)
            ], spacing: AppTheme.Spacing.md) {
                DataCard(
                    title: "今日評分",
                    value: "12",
                    trend: .up,
                    icon: "star.fill",
                    color: .orange,
                    size: .medium,
                    onTap: {
                        print("查看今日評分詳情")
                    }
                )
                
                DataCard(
                    title: "總評分數",
                    value: "1,234",
                    trend: .up,
                    icon: "chart.bar.fill",
                    color: .blue,
                    size: .medium,
                    onTap: {
                        print("查看總評分詳情")
                    }
                )
                
                DataCard(
                    title: "排名",
                    value: "#42",
                    trend: .down,
                    icon: "trophy.fill",
                    color: .purple,
                    size: .medium,
                    onTap: {
                        print("查看排名詳情")
                    }
                )
                
                DataCard(
                    title: "連續天數",
                    value: "7",
                    trend: .up,
                    icon: "flame.fill",
                    color: .red,
                    size: .medium,
                    onTap: nil
                )
            }
        }
    }
    
    // MARK: - Recent Activity Section
    private var recentActivitySection: some View {
        VStack(alignment: .leading, spacing: 16) {
            sectionHeader("最近活動")
            
            LazyVGrid(columns: [
                GridItem(.flexible(), spacing: AppTheme.Spacing.xs),
                GridItem(.flexible(), spacing: AppTheme.Spacing.xs),
                GridItem(.flexible(), spacing: AppTheme.Spacing.xs)
            ], spacing: AppTheme.Spacing.md) {
                DataCard(
                    title: "本週上傳",
                    value: "3",
                    trend: .stable,
                    icon: "camera.fill",
                    color: .green,
                    size: .small,
                    onTap: nil
                )
                
                DataCard(
                    title: "本月目標",
                    value: "85%",
                    trend: .up,
                    icon: "target",
                    color: .indigo,
                    size: .small,
                    onTap: nil
                )
                
                DataCard(
                    title: "積分",
                    value: "2,450",
                    trend: .stable,
                    icon: "star.circle.fill",
                    color: .yellow,
                    size: .small,
                    onTap: nil
                )
            }
        }
    }
    
    // MARK: - Helper Methods
    private func sectionHeader(_ title: String) -> some View {
        HStack {
            Text(title)
                .font(AppTheme.Typography.title2)
                .fontWeight(.bold)
                .foregroundColor(themeManager.currentTheme.colors.text)
            
            Spacer()
        }
        .padding(.top, 8)
    }
}

// MARK: - Preview
struct HomeView_Previews: PreviewProvider {
    static var previews: some View {
        HomeView()
            .environmentObject(ThemeManager())
            .environmentObject(AuthenticationViewModel())
    }
}