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
    
    var body: some View {
        NavigationStack {
            ZStack {
                FloatingShapesBackground()
                
                ScrollView {
                    VStack(spacing: AppTheme.Spacing.md) {
                        // Profile Header
                        profileHeader
                        
                        // Stats Cards
                        statsSection
                        
                        // Achievement Section
                        achievementSection
                        
                        // Settings Section
                        settingsSection
                        
                        Spacer(minLength: AppTheme.Spacing.xl)
                    }
                    .padding(.horizontal, AppTheme.Spacing.md)
                }
            }
            .navigationTitle(NSLocalizedString("profile.title", comment: ""))
            .navigationBarTitleDisplayMode(.large)
            .toolbarBackground(.hidden, for: .navigationBar)
        }
    }
}

// MARK: - View Components
private extension ProfileTabView {
    
    var profileHeader: some View {
        VStack(spacing: AppTheme.Spacing.sm) {
            // Avatar with cute design
            ZStack {
                // Glow effect
                Circle()
                    .fill(themeManager.currentTheme.colors.accent.opacity(0.3))
                    .frame(width: 100, height: 100)
                    .blur(radius: 15)
                
                // Main avatar circle
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [themeManager.currentTheme.colors.accent, themeManager.currentTheme.colors.accent.opacity(0.8)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 80, height: 80)
                    .shadow(color: themeManager.currentTheme.colors.accent.opacity(0.3), radius: 15, x: 0, y: 8)
                
                // Inner highlight
                Circle()
                    .stroke(
                        LinearGradient(
                            colors: [.white.opacity(0.5), .clear],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 2
                    )
                    .frame(width: 80, height: 80)
                
                if authViewModel.isGuest {
                    Text("👤")
                        .font(.system(size: 40))
                        .shadow(color: .black.opacity(0.2), radius: 2, x: 0, y: 1)
                } else {
                    Text(String(authViewModel.user?.name.prefix(1) ?? "U").uppercased())
                        .font(.system(size: 32, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                        .shadow(color: .black.opacity(0.2), radius: 2, x: 0, y: 1)
                }
            }
            
            // User Info with glass morphism
            VStack(spacing: AppTheme.Spacing.xs) {
                Text(authViewModel.user?.name ?? NSLocalizedString("profile.guest.name", comment: ""))
                    .font(.system(size: 20, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                    .shadow(color: .black.opacity(0.2), radius: 2, x: 0, y: 1)
                
                if authViewModel.isGuest {
                    HStack(spacing: AppTheme.Spacing.xs) {
                        Image(systemName: "person.crop.circle.badge.questionmark")
                            .foregroundColor(.orange)
                        Text(NSLocalizedString("profile.guest.mode", comment: ""))
                            .font(AppTheme.Typography.caption)
                            .fontWeight(.semibold)
                            .foregroundColor(.orange)
                    }
                    .padding(.horizontal, AppTheme.Spacing.sm)
                    .padding(.vertical, AppTheme.Spacing.xs)
                    .background(
                        Capsule()
                            .fill(.ultraThinMaterial)
                    )
                } else {
                    Text(authViewModel.user?.email ?? "")
                        .font(AppTheme.Typography.caption)
                        .foregroundColor(.white.opacity(0.8))
                        .padding(.horizontal, AppTheme.Spacing.sm)
                        .padding(.vertical, AppTheme.Spacing.xs)
                        .background(
                            Capsule()
                                .fill(.ultraThinMaterial)
                        )
                }
            }
        }
        .padding(AppTheme.Spacing.md)
        .background(
            RoundedRectangle(cornerRadius: AppTheme.CornerRadius.xl)
                .fill(.ultraThinMaterial)
                .shadow(color: .black.opacity(0.1), radius: 15, x: 0, y: 8)
        )
    }
    
    var statsSection: some View {
        VStack(spacing: AppTheme.Spacing.md) {
            HStack {
                Text(NSLocalizedString("profile.stats.title", comment: ""))
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
                    title: NSLocalizedString("profile.stats.completedRatings", comment: ""),
                    value: "\(authViewModel.user?.ratingProgress.completedRatings ?? 0)",
                    color: themeManager.currentTheme.colors.accent
                )
                
                StatCard(
                    icon: "target",
                    title: NSLocalizedString("profile.stats.requiredRatings", comment: ""),
                    value: "\(authViewModel.user?.ratingProgress.requiredRatings ?? 0)",
                    color: themeManager.currentTheme.colors.primary
                )
                
                StatCard(
                    icon: "chart.line.uptrend.xyaxis",
                    title: NSLocalizedString("profile.stats.progress", comment: ""),
                    value: "\(Int((authViewModel.user?.ratingProgress.progressPercentage ?? 0) * 100))%",
                    color: .green
                )
                
                StatCard(
                    icon: "photo.stack",
                    title: NSLocalizedString("profile.stats.uploadedPhotos", comment: ""),
                    value: "0", // TODO: Add photo count
                    color: themeManager.currentTheme.colors.secondary
                )
            }
        }
    }
    
    var achievementSection: some View {
        VStack(spacing: AppTheme.Spacing.md) {
            HStack {
                Text(NSLocalizedString("profile.achievements.title", comment: ""))
                    .font(AppTheme.Typography.headline)
                    .foregroundColor(themeManager.currentTheme.colors.text)
                Spacer()
                Button(NSLocalizedString("profile.achievements.viewAll", comment: "")) {
                    // TODO: Navigate to achievements
                }
                .font(AppTheme.Typography.caption)
                .foregroundColor(themeManager.currentTheme.colors.primary)
            }
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: AppTheme.Spacing.sm) {
                    AchievementBadge(
                        icon: "star.fill",
                        title: NSLocalizedString("profile.achievements.firstRating", comment: ""),
                        isUnlocked: (authViewModel.user?.ratingProgress.completedRatings ?? 0) > 0
                    )
                    
                    AchievementBadge(
                        icon: "flame.fill",
                        title: NSLocalizedString("profile.achievements.ratingStreak", comment: ""),
                        isUnlocked: (authViewModel.user?.ratingProgress.completedRatings ?? 0) > 10
                    )
                    
                    AchievementBadge(
                        icon: "crown.fill",
                        title: NSLocalizedString("profile.achievements.ratingExpert", comment: ""),
                        isUnlocked: (authViewModel.user?.ratingProgress.completedRatings ?? 0) > 50
                    )
                    
                    AchievementBadge(
                        icon: "lock.open.fill",
                        title: NSLocalizedString("profile.achievements.uploadUnlocked", comment: ""),
                        isUnlocked: authViewModel.user?.ratingProgress.hasUnlockedUpload ?? false
                    )
                }
                .padding(.horizontal, AppTheme.Spacing.sm)
            }
        }
        .cardStyle()
    }
    
    var settingsSection: some View {
        VStack(spacing: AppTheme.Spacing.md) {
            HStack {
                Text(NSLocalizedString("profile.settings.title", comment: ""))
                    .font(AppTheme.Typography.headline)
                    .foregroundColor(themeManager.currentTheme.colors.text)
                Spacer()
            }
            
            VStack(spacing: 0) {
                ThemeSwitcherView()
                    .padding(.vertical, AppTheme.Spacing.sm)
                
                Divider()

                SettingRow(
                    icon: "globe",
                    title: NSLocalizedString("profile.settings.language", comment: ""),
                    action: {
                        // TODO: Navigate to language settings
                    }
                )
                
                Divider()
                
                SettingRow(
                    icon: "bell.fill",
                    title: NSLocalizedString("profile.settings.notifications", comment: ""),
                    action: {
                        // TODO: Navigate to notification settings
                    }
                )
                
                Divider()
                
                SettingRow(
                    icon: "questionmark.circle.fill",
                    title: NSLocalizedString("profile.settings.help", comment: ""),
                    action: {
                        // TODO: Navigate to help
                    }
                )
                
                if !authViewModel.isGuest {
                    Divider()
                    
                    SettingRow(
                        icon: "rectangle.portrait.and.arrow.right",
                        title: NSLocalizedString("profile.settings.logout", comment: ""),
                        isDestructive: true,
                        action: {
                            authViewModel.signOut()
                        }
                    )
                } else {
                    Divider()
                    
                    SettingRow(
                        icon: "person.crop.circle.fill.badge.plus",
                        title: NSLocalizedString("profile.settings.register", comment: ""),
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
        HStack(spacing: AppTheme.Spacing.sm) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(color)
                .frame(width: 24, height: 24)
                .background(
                    Circle()
                        .fill(color.opacity(0.15))
                        .frame(width: 36, height: 36)
                )

            VStack(alignment: .leading, spacing: AppTheme.Spacing.xs) {
                Text(title)
                    .font(AppTheme.Typography.caption)
                    .foregroundColor(themeManager.currentTheme.colors.text.opacity(0.7))
                
                Text(value)
                    .font(AppTheme.Typography.headline)
                    .fontWeight(.bold)
                    .foregroundColor(themeManager.currentTheme.colors.text)
            }
            Spacer()
        }
        .padding(AppTheme.Spacing.sm)
        .cardStyle(padding: AppTheme.Spacing.sm)
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
                    .fill(isUnlocked ? themeManager.currentTheme.colors.accent : themeManager.currentTheme.colors.text.opacity(0.1))
                    .frame(width: 50, height: 50)
                    .shadow(color: isUnlocked ? themeManager.currentTheme.colors.accent.opacity(0.2) : .clear, radius: 5, x: 0, y: 2)
                
                Image(systemName: icon)
                    .font(.title3)
                    .foregroundColor(isUnlocked ? .white : themeManager.currentTheme.colors.text.opacity(0.5))
            }
            
            Text(title)
                .font(AppTheme.Typography.caption)
                .foregroundColor(isUnlocked ? themeManager.currentTheme.colors.text : themeManager.currentTheme.colors.text.opacity(0.5))
                .multilineTextAlignment(.center)
        }
        .frame(width: 70)
        .scaleEffect(isUnlocked ? 1.0 : 0.95)
        .opacity(isUnlocked ? 1.0 : 0.7)
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
                    .font(.callout)
                    .foregroundColor(isDestructive ? .red : themeManager.currentTheme.colors.primary)
                    .frame(width: 20)
                
                Text(title)
                    .font(AppTheme.Typography.body)
                    .foregroundColor(isDestructive ? .red : themeManager.currentTheme.colors.text)
                
                Spacer()
            }
            .padding(.horizontal, AppTheme.Spacing.md)
            .padding(.vertical, AppTheme.Spacing.sm)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Background View
struct FloatingShapesBackground: View {
    @EnvironmentObject private var themeManager: ThemeManager

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [themeManager.currentTheme.colors.primary, themeManager.currentTheme.colors.secondary],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            GeometryReader { geometry in
                ForEach(0..<8, id: \.self) { index in
                    FloatingShape(geometry: geometry, index: index)
                }
            }
            .ignoresSafeArea()
        }
    }
}

#Preview {
    ProfileTabView()
        .environmentObject(AuthenticationViewModel())
        .environmentObject(ThemeManager())
}

// MARK: - Floating Shapes for Cute Background
struct FloatingShape: View {
    @EnvironmentObject var themeManager: ThemeManager
    let geometry: GeometryProxy
    let index: Int
    
    @State private var offset: CGSize = .zero
    @State private var rotation: Double = 0
    @State private var scale: Double = 1.0
    
    private var shapeType: ShapeType {
        ShapeType.allCases[index % ShapeType.allCases.count]
    }
    
    private var color: Color {
        let colors = themeManager.currentTheme.colors
        switch index % 4 {
        case 0: return colors.accent.opacity(0.6)
        case 1: return Color.white.opacity(0.4)
        case 2: return colors.secondary.opacity(0.3)
        default: return colors.accent.opacity(0.3)
        }
    }
    
    private var size: CGFloat {
        switch index % 3 {
        case 0: return 8
        case 1: return 12
        default: return 16
        }
    }
    
    var body: some View {
        Group {
            switch shapeType {
            case .star:
                Text("⭐️")
                    .font(.system(size: size))
            case .diamond:
                Diamond()
                    .fill(color)
                    .frame(width: size, height: size)
            case .circle:
                Circle()
                    .fill(color)
                    .frame(width: size, height: size)
            case .sparkle:
                Text("✨")
                    .font(.system(size: size))
            }
        }
        .position(
            x: CGFloat.random(in: 0...geometry.size.width),
            y: CGFloat.random(in: 0...geometry.size.height)
        )
        .offset(offset)
        .rotationEffect(.degrees(rotation))
        .scaleEffect(scale)
        .onAppear {
            startAnimation()
        }
    }
    
    private func startAnimation() {
        let duration = Double.random(in: 3...8)
        let delay = Double.random(in: 0...2)
        
        withAnimation(
            .easeInOut(duration: duration)
            .repeatForever(autoreverses: true)
            .delay(delay)
        ) {
            offset = CGSize(
                width: CGFloat.random(in: -30...30),
                height: CGFloat.random(in: -30...30)
            )
            rotation = Double.random(in: 0...360)
            scale = Double.random(in: 0.8...1.2)
        }
    }
}

enum ShapeType: CaseIterable {
    case star, diamond, circle, sparkle
}

struct Diamond: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let center = CGPoint(x: rect.midX, y: rect.midY)
        let radius = min(rect.width, rect.height) / 2
        
        path.move(to: CGPoint(x: center.x, y: center.y - radius))
        path.addLine(to: CGPoint(x: center.x + radius, y: center.y))
        path.addLine(to: CGPoint(x: center.x, y: center.y + radius))
        path.addLine(to: CGPoint(x: center.x - radius, y: center.y))
        path.closeSubpath()
        
        return path
    }
}
