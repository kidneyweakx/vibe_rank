//
//  ProfileTabView.swift
//  viberanking
//
//  Created by Kiro on 2025/07/25.
//

import SwiftUI

struct ProfileTabView: View {
    @EnvironmentObject private var authViewModel: AuthenticationViewModel
    @EnvironmentObject private var themeManager: ThemeManager
    @State private var showingSettings = false
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Cute background matching the main theme
                LinearGradient(
                    colors: [themeManager.currentTheme.colors.primary, themeManager.currentTheme.colors.secondary],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                // Floating decorative elements
                GeometryReader { geometry in
                    ForEach(0..<8, id: \.self) { index in
                        FloatingShape(geometry: geometry, index: index)
                    }
                }
                .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: AppTheme.Spacing.lg) {
                        // Profile Header
                        profileHeader
                        
                        // Stats Cards
                        statsSection
                        
                        // Achievement Section
                        achievementSection
                        
                        // Settings Section
                        settingsSection
                        
                        Spacer(minLength: AppTheme.Spacing.xxl)
                    }
                    .padding(.horizontal, AppTheme.Spacing.md)
                }
            }
            .navigationTitle("個人檔案")
            .navigationBarTitleDisplayMode(.large)
            .toolbarBackground(.hidden, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        showingSettings = true
                    } label: {
                        ZStack {
                            Circle()
                                .fill(.ultraThinMaterial)
                                .frame(width: 36, height: 36)
                                .shadow(color: .black.opacity(0.1), radius: 5, x: 0, y: 2)
                            
                            Image(systemName: "gearshape.fill")
                                .foregroundColor(.white)
                                .font(.system(size: 16, weight: .semibold))
                        }
                    }
                }
            }
            .sheet(isPresented: $showingSettings) {
                SettingsView()
            }
        }
    }
}

// MARK: - View Components
private extension ProfileTabView {
    
    var profileHeader: some View {
        VStack(spacing: AppTheme.Spacing.md) {
            // Avatar with cute design
            ZStack {
                // Glow effect
                Circle()
                    .fill(themeManager.currentTheme.colors.accent.opacity(0.3))
                    .frame(width: 130, height: 130)
                    .blur(radius: 20)
                
                // Main avatar circle
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [themeManager.currentTheme.colors.accent, themeManager.currentTheme.colors.accent.opacity(0.8)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 100, height: 100)
                    .shadow(color: themeManager.currentTheme.colors.accent.opacity(0.4), radius: 20, x: 0, y: 10)
                
                // Inner highlight
                Circle()
                    .stroke(
                        LinearGradient(
                            colors: [.white.opacity(0.6), .clear],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 3
                    )
                    .frame(width: 100, height: 100)
                
                if authViewModel.isGuest {
                    Text("👤")
                        .font(.system(size: 50))
                        .shadow(color: .black.opacity(0.2), radius: 2, x: 0, y: 1)
                } else {
                    Text(String(authViewModel.user?.name.prefix(1) ?? "U").uppercased())
                        .font(.system(size: 40, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                        .shadow(color: .black.opacity(0.3), radius: 3, x: 0, y: 2)
                }
            }
            
            // User Info with glass morphism
            VStack(spacing: AppTheme.Spacing.xs) {
                Text(authViewModel.user?.name ?? "訪客用戶")
                    .font(.system(size: 24, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                    .shadow(color: .black.opacity(0.3), radius: 2, x: 0, y: 1)
                
                if authViewModel.isGuest {
                    HStack(spacing: AppTheme.Spacing.xs) {
                        Image(systemName: "person.crop.circle.badge.questionmark")
                            .foregroundColor(.orange)
                        Text("訪客模式")
                            .font(AppTheme.Typography.caption)
                            .fontWeight(.semibold)
                            .foregroundColor(.orange)
                    }
                    .padding(.horizontal, AppTheme.Spacing.md)
                    .padding(.vertical, AppTheme.Spacing.xs)
                    .background(
                        Capsule()
                            .fill(.ultraThinMaterial)
                            .shadow(color: .black.opacity(0.1), radius: 5, x: 0, y: 2)
                    )
                } else {
                    Text(authViewModel.user?.email ?? "")
                        .font(AppTheme.Typography.subheadline)
                        .foregroundColor(.white.opacity(0.8))
                        .padding(.horizontal, AppTheme.Spacing.md)
                        .padding(.vertical, AppTheme.Spacing.xs)
                        .background(
                            Capsule()
                                .fill(.ultraThinMaterial)
                                .shadow(color: .black.opacity(0.1), radius: 5, x: 0, y: 2)
                        )
                }
            }
        }
        .padding(AppTheme.Spacing.lg)
        .background(
            RoundedRectangle(cornerRadius: AppTheme.CornerRadius.xl)
                .fill(.ultraThinMaterial)
                .shadow(color: .black.opacity(0.1), radius: 20, x: 0, y: 10)
        )
    }
    
    var statsSection: some View {
        VStack(spacing: AppTheme.Spacing.md) {
            HStack {
                Text("統計數據")
                    .font(AppTheme.Typography.headline)
                    .foregroundColor(themeManager.currentTheme.colors.text)
                Spacer()
            }
            
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: AppTheme.Spacing.md) {
                StatCard(
                    icon: "star.fill",
                    title: "完成評分",
                    value: "\(authViewModel.user?.ratingProgress.completedRatings ?? 0)",
                    color: themeManager.currentTheme.colors.accent
                )
                
                StatCard(
                    icon: "target",
                    title: "目標評分",
                    value: "\(authViewModel.user?.ratingProgress.requiredRatings ?? 0)",
                    color: themeManager.currentTheme.colors.primary
                )
                
                StatCard(
                    icon: "chart.line.uptrend.xyaxis",
                    title: "進度",
                    value: "\(Int((authViewModel.user?.ratingProgress.progressPercentage ?? 0) * 100))%",
                    color: .green
                )
                
                StatCard(
                    icon: "photo.stack",
                    title: "上傳照片",
                    value: "0", // TODO: Add photo count
                    color: themeManager.currentTheme.colors.secondary
                )
            }
        }
    }
    
    var achievementSection: some View {
        VStack(spacing: AppTheme.Spacing.md) {
            HStack {
                Text("成就")
                    .font(AppTheme.Typography.headline)
                    .foregroundColor(themeManager.currentTheme.colors.text)
                Spacer()
                Button("查看全部") {
                    // TODO: Navigate to achievements
                }
                .font(AppTheme.Typography.caption)
                .foregroundColor(themeManager.currentTheme.colors.primary)
            }
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: AppTheme.Spacing.md) {
                    AchievementBadge(
                        icon: "star.fill",
                        title: "首次評分",
                        isUnlocked: (authViewModel.user?.ratingProgress.completedRatings ?? 0) > 0
                    )
                    
                    AchievementBadge(
                        icon: "flame.fill",
                        title: "連續評分",
                        isUnlocked: (authViewModel.user?.ratingProgress.completedRatings ?? 0) > 10
                    )
                    
                    AchievementBadge(
                        icon: "crown.fill",
                        title: "評分達人",
                        isUnlocked: (authViewModel.user?.ratingProgress.completedRatings ?? 0) > 50
                    )
                    
                    AchievementBadge(
                        icon: "lock.open.fill",
                        title: "解鎖上傳",
                        isUnlocked: authViewModel.user?.ratingProgress.hasUnlockedUpload ?? false
                    )
                }
                .padding(.horizontal, AppTheme.Spacing.md)
            }
        }
        .cardStyle()
    }
    
    var settingsSection: some View {
        VStack(spacing: AppTheme.Spacing.md) {
            HStack {
                Text("設定")
                    .font(AppTheme.Typography.headline)
                    .foregroundColor(themeManager.currentTheme.colors.text)
                Spacer()
            }
            
            VStack(spacing: 0) {
                SettingRow(
                    icon: "globe",
                    title: "語言設定",
                    action: {
                        // TODO: Navigate to language settings
                    }
                )
                
                Divider()
                
                SettingRow(
                    icon: "bell.fill",
                    title: "通知設定",
                    action: {
                        // TODO: Navigate to notification settings
                    }
                )
                
                Divider()
                
                SettingRow(
                    icon: "questionmark.circle.fill",
                    title: "幫助與支援",
                    action: {
                        // TODO: Navigate to help
                    }
                )
                
                if !authViewModel.isGuest {
                    Divider()
                    
                    SettingRow(
                        icon: "rectangle.portrait.and.arrow.right",
                        title: "登出",
                        isDestructive: true,
                        action: {
                            authViewModel.signOut()
                        }
                    )
                } else {
                    Divider()
                    
                    SettingRow(
                        icon: "person.crop.circle.fill.badge.plus",
                        title: "註冊帳號",
                        action: {
                            authViewModel.signOut() // Return to login
                        }
                    )
                }
            }
        }
        .cardStyle(padding: 0)
    }
}

// MARK: - Supporting Views
struct StatCard: View {
    @EnvironmentObject private var themeManager: ThemeManager
    let icon: String
    let title: String
    let value: String
    let color: Color
    
    var body: some View {
        VStack(spacing: AppTheme.Spacing.sm) {
            ZStack {
                Circle()
                    .fill(color.opacity(0.2))
                    .frame(width: 50, height: 50)
                
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(color)
            }
            
            Text(value)
                .font(AppTheme.Typography.title2)
                .fontWeight(.bold)
                .foregroundColor(themeManager.currentTheme.colors.text)
            
            Text(title)
                .font(AppTheme.Typography.caption)
                .foregroundColor(themeManager.currentTheme.colors.text.opacity(0.7))
                .multilineTextAlignment(.center)
        }
        .cardStyle()
    }
}

struct AchievementBadge: View {
    @EnvironmentObject private var themeManager: ThemeManager
    let icon: String
    let title: String
    let isUnlocked: Bool
    
    var body: some View {
        VStack(spacing: AppTheme.Spacing.xs) {
            ZStack {
                Circle()
                    .fill(isUnlocked ? themeManager.currentTheme.colors.accent : themeManager.currentTheme.colors.text.opacity(0.2))
                    .frame(width: 60, height: 60)
                    .shadow(color: isUnlocked ? themeManager.currentTheme.colors.accent.opacity(0.3) : .clear, radius: 8, x: 0, y: 4)
                
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(isUnlocked ? .white : themeManager.currentTheme.colors.text.opacity(0.7))
            }
            
            Text(title)
                .font(AppTheme.Typography.caption)
                .foregroundColor(isUnlocked ? themeManager.currentTheme.colors.text : themeManager.currentTheme.colors.text.opacity(0.7))
                .multilineTextAlignment(.center)
        }
        .frame(width: 80)
        .scaleEffect(isUnlocked ? 1.0 : 0.9)
        .opacity(isUnlocked ? 1.0 : 0.6)
    }
}

struct SettingRow: View {
    @EnvironmentObject private var themeManager: ThemeManager
    let icon: String
    let title: String
    let isDestructive: Bool
    let action: () -> Void
    
    init(icon: String, title: String, isDestructive: Bool = false, action: @escaping () -> Void) {
        self.icon = icon
        self.title = title
        self.isDestructive = isDestructive
        self.action = action
    }
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: AppTheme.Spacing.md) {
                Image(systemName: icon)
                    .font(.title3)
                    .foregroundColor(isDestructive ? .red : themeManager.currentTheme.colors.primary)
                    .frame(width: 24)
                
                Text(title)
                    .font(AppTheme.Typography.body)
                    .foregroundColor(isDestructive ? .red : themeManager.currentTheme.colors.text)
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(themeManager.currentTheme.colors.text.opacity(0.7))
            }
            .padding(.horizontal, AppTheme.Spacing.md)
            .padding(.vertical, AppTheme.Spacing.md)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            VStack {
                ThemeSwitcherView()
                Spacer()
            }
            .navigationTitle("設定")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("完成") {
                        dismiss()
                    }
                }
            }
        }
    }
}

#Preview {
    ProfileTabView()
        .environmentObject(AuthenticationViewModel())
        .environmentObject(ThemeManager())
}