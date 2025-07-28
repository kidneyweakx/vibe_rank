//
//  CardExamples.swift
//  viberanking
//
//  Created by Kiro on 2025/07/25.
//

import SwiftUI

struct CardExamples: View {
    @EnvironmentObject private var themeManager: ThemeManager
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Function Cards Section
                    sectionHeader("功能卡片")
                    
                    VStack(spacing: 16) {
                        // Large Function Card
                        FunctionCard(
                            title: "個人資料",
                            subtitle: "查看統計",
                            icon: "person.circle.fill",
                            primaryData: "7.5",
                            secondaryData: "平均評分",
                            backgroundColor: [
                                themeManager.currentTheme.colors.primary,
                                themeManager.currentTheme.colors.secondary
                            ],
                            size: .large,
                            destination: AnyView(EmptyView()),
                            onTap: { print("個人資料卡片被點擊") }
                        )
                        
                        // Medium Function Cards
                        HStack(spacing: 16) {
                            FunctionCard(
                                title: "評分",
                                subtitle: "今日進度",
                                icon: "star.fill",
                                primaryData: "12",
                                secondaryData: "已評分",
                                backgroundColor: [
                                    Color.orange,
                                    Color.red
                                ],
                                size: .medium,
                                destination: AnyView(EmptyView()),
                                onTap: { print("評分卡片被點擊") }
                            )
                            
                            FunctionCard(
                                title: "上傳",
                                subtitle: "照片管理",
                                icon: "camera.fill",
                                primaryData: "5",
                                secondaryData: "張照片",
                                backgroundColor: [
                                    Color.green,
                                    Color.mint
                                ],
                                size: .medium,
                                destination: AnyView(EmptyView()),
                                onTap: { print("上傳卡片被點擊") }
                            )
                        }
                    }
                    
                    // Data Cards Section
                    sectionHeader("數據卡片")
                    
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
                            onTap: { print("今日評分數據被點擊") }
                        )
                        
                        DataCard(
                            title: "本週上傳",
                            value: "3",
                            trend: .stable,
                            icon: "camera.fill",
                            color: .green,
                            size: .medium,
                            onTap: nil
                        )
                        
                        DataCard(
                            title: "總評分",
                            value: "1,234",
                            trend: .up,
                            icon: "chart.bar.fill",
                            color: .blue,
                            size: .medium,
                            onTap: { print("總評分數據被點擊") }
                        )
                        
                        DataCard(
                            title: "排名",
                            value: "#42",
                            trend: .down,
                            icon: "trophy.fill",
                            color: .purple,
                            size: .medium,
                            onTap: { print("排名數據被點擊") }
                        )
                    }
                    
                    // Small Data Cards
                    sectionHeader("小型數據卡片")
                    
                    LazyVGrid(columns: [
                        GridItem(.flexible(), spacing: AppTheme.Spacing.xs),
                        GridItem(.flexible(), spacing: AppTheme.Spacing.xs),
                        GridItem(.flexible(), spacing: AppTheme.Spacing.xs)
                    ], spacing: AppTheme.Spacing.md) {
                        DataCard(
                            title: "連續天數",
                            value: "7",
                            trend: .up,
                            icon: "flame.fill",
                            color: .red,
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
                    
                    // Animation Examples
                    sectionHeader("動畫效果示例")
                    
                    VStack(spacing: 16) {
                        RoundedRectangle(cornerRadius: 12)
                            .fill(themeManager.currentTheme.colors.cardBackground)
                            .frame(height: 80)
                            .overlay(
                                Text("點擊測試動畫效果")
                                    .font(AppTheme.Typography.callout)
                                    .foregroundColor(themeManager.currentTheme.colors.text)
                            )
                            .cardAnimation(delay: 0.1)
                            .onTapGesture {
                                print("動畫卡片被點擊")
                            }
                        
                        RoundedRectangle(cornerRadius: 12)
                            .fill(themeManager.currentTheme.colors.cardBackground)
                            .frame(height: 80)
                            .overlay(
                                Text("左右滑動測試")
                                    .font(AppTheme.Typography.callout)
                                    .foregroundColor(themeManager.currentTheme.colors.text)
                            )
                            .cardSwipeGesture(
                                onSwipeLeft: { print("向左滑動") },
                                onSwipeRight: { print("向右滑動") }
                            )
                            .cardEntranceAnimation(delay: 0.2, direction: .bottom)
                    }
                }
                .padding()
            }
            .navigationTitle("卡片組件示例")
            .navigationBarTitleDisplayMode(.large)
        }
    }
    
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
struct CardExamples_Previews: PreviewProvider {
    static var previews: some View {
        CardExamples()
            .environmentObject(ThemeManager())
    }
}