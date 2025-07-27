//
//  AppTheme.swift
//  viberanking
//
//  Created by Kiro on 2025/07/25.
//

import SwiftUI

// MARK: - App Theme
struct AppTheme {
    @EnvironmentObject var themeManager: ThemeManager
    
    // MARK: - Colors
    var colors: ColorScheme {
        themeManager.currentTheme.colors
    }
    
    // MARK: - Typography
    struct Typography {
        static let largeTitle = Font.system(size: 34, weight: .bold, design: .rounded)
        static let title = Font.system(size: 28, weight: .bold, design: .rounded)
        static let title2 = Font.system(size: 22, weight: .semibold, design: .rounded)
        static let headline = Font.system(size: 17, weight: .semibold, design: .rounded)
        static let body = Font.system(size: 17, weight: .regular, design: .default)
        static let callout = Font.system(size: 16, weight: .regular, design: .default)
        static let subheadline = Font.system(size: 15, weight: .regular, design: .default)
        static let footnote = Font.system(size: 13, weight: .regular, design: .default)
        static let caption = Font.system(size: 12, weight: .regular, design: .default)
    }
    
    // MARK: - Spacing
    struct Spacing {
        static let xs: CGFloat = 4
        static let sm: CGFloat = 8
        static let md: CGFloat = 16
        static let lg: CGFloat = 24
        static let xl: CGFloat = 32
        static let xxl: CGFloat = 48
    }
    
    // MARK: - Corner Radius
    struct CornerRadius {
        static let sm: CGFloat = 8
        static let md: CGFloat = 12
        static let lg: CGFloat = 16
        static let xl: CGFloat = 24
        static let round: CGFloat = 50
    }
    
    // MARK: - Shadows
    struct Shadow {
        static let light = Color.black.opacity(0.1)
        static let medium = Color.black.opacity(0.2)
        static let heavy = Color.black.opacity(0.3)
    }
}

// MARK: - Custom Button Styles
struct PrimaryButtonStyle: ButtonStyle {
    @EnvironmentObject var themeManager: ThemeManager
    let isDestructive: Bool
    
    init(isDestructive: Bool = false) {
        self.isDestructive = isDestructive
    }
    
    func makeBody(configuration: Configuration) -> some View {
        let colors = themeManager.currentTheme.colors
        
        configuration.label
            .font(AppTheme.Typography.headline)
            .foregroundColor(colors.text)
            .padding(.horizontal, AppTheme.Spacing.lg)
            .padding(.vertical, AppTheme.Spacing.md)
            .background(
                RoundedRectangle(cornerRadius: AppTheme.CornerRadius.lg)
                    .fill(
                        isDestructive ?
                        LinearGradient(colors: [Color.red], startPoint: .leading, endPoint: .trailing) :
                        LinearGradient(colors: [colors.primary, colors.secondary], startPoint: .leading, endPoint: .trailing)
                    )
            )
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}

struct SecondaryButtonStyle: ButtonStyle {
    @EnvironmentObject var themeManager: ThemeManager
    
    func makeBody(configuration: Configuration) -> some View {
        let colors = themeManager.currentTheme.colors
        
        configuration.label
            .font(AppTheme.Typography.headline)
            .foregroundColor(colors.primary)
            .padding(.horizontal, AppTheme.Spacing.lg)
            .padding(.vertical, AppTheme.Spacing.md)
            .background(
                RoundedRectangle(cornerRadius: AppTheme.CornerRadius.lg)
                    .stroke(colors.primary, lineWidth: 2)
                    .background(
                        RoundedRectangle(cornerRadius: AppTheme.CornerRadius.lg)
                            .fill(Color.clear)
                    )
            )
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}

// MARK: - Custom Card Style
struct CardStyle: ViewModifier {
    @EnvironmentObject var themeManager: ThemeManager
    let padding: CGFloat
    
    init(padding: CGFloat = AppTheme.Spacing.md) {
        self.padding = padding
    }
    
    func body(content: Content) -> some View {
        let colors = themeManager.currentTheme.colors
        
        content
            .padding(padding)
            .background(
                RoundedRectangle(cornerRadius: AppTheme.CornerRadius.lg)
                    .fill(LinearGradient(colors: [colors.background, colors.background.opacity(0.8)], startPoint: .top, endPoint: .bottom))
                    .shadow(color: AppTheme.Shadow.light, radius: 8, x: 0, y: 4)
            )
    }
}

// MARK: - Custom TabBar Style
struct CustomTabBar: ViewModifier {
    @EnvironmentObject var themeManager: ThemeManager

    func body(content: Content) -> some View {
        content
            .onAppear {
                setupAppearance()
            }
            .accentColor(themeManager.currentTheme.colors.accent)
    }

    func setupAppearance() {
        let appearance = UITabBarAppearance()
        let colors = themeManager.currentTheme.colors

        // Use a transparent background to blend with the content
        appearance.configureWithTransparentBackground()
        
        // A subtle background color that matches the theme
        appearance.backgroundColor = UIColor(colors.background).withAlphaComponent(0.9)

        // Add a blur effect for a modern, Instagram-like feel
        let blurEffect = UIBlurEffect(style: .systemUltraThinMaterial)
        appearance.backgroundEffect = blurEffect

        // Add a subtle top shadow to separate the tab bar from the content
        appearance.shadowColor = UIColor.black.withAlphaComponent(0.1)

        // Normal (unselected) state
        appearance.stackedLayoutAppearance.normal.iconColor = UIColor(colors.text.opacity(0.7))
        appearance.stackedLayoutAppearance.normal.titleTextAttributes = [
            .foregroundColor: UIColor(colors.text.opacity(0.7)),
            .font: UIFont.systemFont(ofSize: 10, weight: .regular)
        ]

        // Selected state
        appearance.stackedLayoutAppearance.selected.iconColor = UIColor(colors.accent)
        appearance.stackedLayoutAppearance.selected.titleTextAttributes = [
            .foregroundColor: UIColor(colors.accent),
            .font: UIFont.systemFont(ofSize: 10, weight: .bold)
        ]

        UITabBar.appearance().standardAppearance = appearance
        UITabBar.appearance().scrollEdgeAppearance = appearance
        UITabBar.appearance().isTranslucent = true
    }
}

// MARK: - View Extensions
extension View {
    func cardStyle(padding: CGFloat = AppTheme.Spacing.md) -> some View {
        modifier(CardStyle(padding: padding))
    }
    
    func primaryButton(isDestructive: Bool = false) -> some View {
        buttonStyle(PrimaryButtonStyle(isDestructive: isDestructive))
    }
    
    func secondaryButton() -> some View {
        buttonStyle(SecondaryButtonStyle())
    }
}