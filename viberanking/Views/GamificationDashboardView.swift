//
//  GamificationDashboardView.swift
//  viberanking
//
//  Created by Kiro on 2025/07/25.
//

import SwiftUI

// MARK: - Gamification Dashboard View
struct GamificationDashboardView: View {
    @StateObject private var gamificationService = GamificationService()
    @State private var selectedTab = 0
    @State private var showAchievementUnlock = false
    @State private var unlockedAchievement: Achievement?
    @State private var showShareView = false
    @State private var shareContent: ShareContent?
    
    // Mock data - in real app, this would come from the service
    @State private var userProgress = UserProgress(userId: "test-user")
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Tab selector
                TabSelector(selectedTab: $selectedTab)
                
                // Content based on selected tab
                TabView(selection: $selectedTab) {
                    // Progress tab
                    ProgressTabView(
                        incentiveStatus: gamificationService.currentIncentiveStatus,
                        userProgress: userProgress
                    )
                    .tag(0)
                    
                    // Achievements tab
                    AchievementsTabView(
                        achievements: gamificationService.userAchievements,
                        onAchievementTap: handleAchievementTap
                    )
                    .tag(1)
                    
                    // Rewards tab
                    RewardsTabView(
                        incentiveStatus: gamificationService.currentIncentiveStatus,
                        onShareTap: handleShareTap
                    )
                    .tag(2)
                }
                .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
            }
            .navigationTitle("遊戲化系統")
            .navigationBarTitleDisplayMode(.large)
            .onAppear {
                loadUserData()
            }
            .onChange(of: gamificationService.recentlyUnlockedAchievements) { achievements in
                if let achievement = achievements.first {
                    showAchievementUnlock(achievement)
                }
            }
            .overlay(
                // Achievement unlock overlay
                Group {
                    if showAchievementUnlock, let achievement = unlockedAchievement {
                        AchievementUnlockView(
                            achievement: achievement,
                            onDismiss: {
                                showAchievementUnlock = false
                                unlockedAchievement = nil
                            }
                        )
                    }
                }
            )
            .sheet(isPresented: $showShareView) {
                if let content = shareContent {
                    ShareRewardView(
                        shareContent: content,
                        onShareCompleted: handleShareCompleted
                    )
                }
            }
        }
    }
    
    private func loadUserData() {
        // Mock data loading - in real app, this would fetch from Firebase
        userProgress.totalRatingsGiven = 25
        userProgress.totalPhotosUploaded = 2
        userProgress.reportsGenerated = 1
        
        Task {
            do {
                try await gamificationService.updateUserProgress(userProgress)
            } catch {
                print("Error updating user progress: \(error)")
            }
        }
    }
    
    private func showAchievementUnlock(_ achievement: Achievement) {
        unlockedAchievement = achievement
        showAchievementUnlock = true
    }
    
    private func handleAchievementTap(_ achievement: Achievement) {
        if achievement.isUnlocked {
            // Create share content for achievement
            shareContent = ShareContent(
                shareType: .achievement,
                title: "我解鎖了新成就！",
                description: achievement.description,
                shareText: "我在數位頂尖社交評價平台解鎖了「\(achievement.title)」成就！快來一起評分吧！",
                shareImage: nil,
                previewImage: nil,
                hasSharedBefore: false
            )
            showShareView = true
        }
    }
    
    private func handleShareTap() {
        // Create general share content
        shareContent = ShareContent(
            shareType: .styleReport,
            title: "我的風格分析報告",
            description: "查看我在數位頂尖社交評價平台的風格分析",
            shareText: "快來數位頂尖社交評價平台看看我的風格分析報告！",
            shareImage: nil,
            previewImage: nil,
            hasSharedBefore: gamificationService.currentIncentiveStatus.shareRewardsUnlocked
        )
        showShareView = true
    }
    
    private func handleShareCompleted(_ shareType: ShareType) {
        Task {
            do {
                try await gamificationService.recordShareAction(for: userProgress.userId, shareType: shareType)
            } catch {
                print("Error recording share action: \(error)")
            }
        }
        showShareView = false
    }
}

// MARK: - Tab Selector
struct TabSelector: View {
    @Binding var selectedTab: Int
    
    private let tabs = [
        ("進度", "chart.bar.fill"),
        ("成就", "star.fill"),
        ("獎勵", "gift.fill")
    ]
    
    var body: some View {
        HStack(spacing: 0) {
            ForEach(0..<tabs.count, id: \.self) { index in
                Button(action: {
                    selectedTab = index
                }) {
                    VStack(spacing: 4) {
                        Image(systemName: tabs[index].1)
                            .font(.title3)
                        
                        Text(tabs[index].0)
                            .font(.caption)
                            .fontWeight(.medium)
                    }
                    .foregroundColor(selectedTab == index ? .blue : .secondary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
        .background(Color(.secondarySystemBackground))
        .overlay(
            Rectangle()
                .fill(.blue)
                .frame(height: 2)
                .offset(x: CGFloat(selectedTab - 1) * UIScreen.main.bounds.width / 3, y: 0)
                .animation(.spring(response: 0.3, dampingFraction: 0.8), value: selectedTab),
            alignment: .bottom
        )
    }
}

// MARK: - Progress Tab View
struct ProgressTabView: View {
    let incentiveStatus: IncentiveStatus
    let userProgress: UserProgress
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Overall progress summary
                OverallProgressCard(userProgress: userProgress)
                
                // Gamification progress
                GamificationProgressView(
                    incentiveStatus: incentiveStatus,
                    userProgress: userProgress
                )
            }
            .padding(.top)
        }
    }
}

// MARK: - Overall Progress Card
struct OverallProgressCard: View {
    let userProgress: UserProgress
    
    var body: some View {
        VStack(spacing: 16) {
            Text("整體進度")
                .font(.title2)
                .fontWeight(.bold)
            
            HStack(spacing: 20) {
                ProgressStat(
                    title: "評分數量",
                    value: "\(userProgress.totalRatingsGiven)",
                    icon: "star.fill",
                    color: .yellow
                )
                
                ProgressStat(
                    title: "上傳照片",
                    value: "\(userProgress.totalPhotosUploaded)",
                    icon: "camera.fill",
                    color: .blue
                )
                
                ProgressStat(
                    title: "生成報告",
                    value: "\(userProgress.reportsGenerated)",
                    icon: "chart.bar.fill",
                    color: .green
                )
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.secondarySystemBackground))
                .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
        )
        .padding(.horizontal)
    }
}

// MARK: - Progress Stat
struct ProgressStat: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)
            
            Text(value)
                .font(.title)
                .fontWeight(.bold)
                .foregroundColor(color)
            
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Achievements Tab View
struct AchievementsTabView: View {
    let achievements: [Achievement]
    let onAchievementTap: (Achievement) -> Void
    
    var body: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                ForEach(achievements) { achievement in
                    Button(action: {
                        onAchievementTap(achievement)
                    }) {
                        AchievementView(achievement: achievement)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
            .padding()
        }
    }
}

// MARK: - Rewards Tab View
struct RewardsTabView: View {
    let incentiveStatus: IncentiveStatus
    let onShareTap: () -> Void
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Available rewards
                RewardCard(
                    title: "加速評分機會",
                    description: "可用次數：\(incentiveStatus.acceleratedRatingsAvailable)",
                    icon: "bolt.fill",
                    color: .yellow,
                    isAvailable: incentiveStatus.acceleratedRatingsAvailable > 0
                )
                
                RewardCard(
                    title: "風格演變分析",
                    description: incentiveStatus.evolutionAnalysisUnlocked ? "已解鎖" : "需要3張照片解鎖",
                    icon: "chart.line.uptrend.xyaxis",
                    color: .green,
                    isAvailable: incentiveStatus.evolutionAnalysisUnlocked
                )
                
                // Share button
                Button(action: onShareTap) {
                    HStack {
                        Image(systemName: "square.and.arrow.up")
                            .font(.title2)
                        
                        Text("分享獲得獎勵")
                            .font(.headline)
                            .fontWeight(.semibold)
                        
                        Spacer()
                        
                        if !incentiveStatus.shareRewardsUnlocked {
                            Text("首次分享獲得獎勵")
                                .font(.caption)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Capsule().fill(.orange.opacity(0.2)))
                                .foregroundColor(.orange)
                        }
                    }
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(.blue.opacity(0.1))
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(.blue.opacity(0.3), lineWidth: 1)
                            )
                    )
                }
                .buttonStyle(PlainButtonStyle())
                .padding(.horizontal)
            }
            .padding(.top)
        }
    }
}

// MARK: - Reward Card
struct RewardCard: View {
    let title: String
    let description: String
    let icon: String
    let color: Color
    let isAvailable: Bool
    
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(isAvailable ? color : .gray)
                .frame(width: 30)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Text(description)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            if isAvailable {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(color)
                    .font(.title2)
            } else {
                Image(systemName: "lock.fill")
                    .foregroundColor(.gray)
                    .font(.title2)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.secondarySystemBackground))
                .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
        )
        .padding(.horizontal)
    }
}

// MARK: - Preview
struct GamificationDashboardView_Previews: PreviewProvider {
    static var previews: some View {
        GamificationDashboardView()
    }
}