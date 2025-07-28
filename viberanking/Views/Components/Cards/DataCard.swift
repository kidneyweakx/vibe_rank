//
//  DataCard.swift
//  viberanking
//
//  Created by Kiro on 2025/07/25.
//

import SwiftUI

struct DataCard: View {
    let title: String
    let value: String
    let trend: TrendDirection?
    let icon: String
    let color: Color
    let size: CardSize
    let onTap: (() -> Void)?
    
    @EnvironmentObject private var themeManager: ThemeManager
    
    enum TrendDirection {
        case up, down, stable
        
        var icon: String {
            switch self {
            case .up: return "arrow.up.right"
            case .down: return "arrow.down.right"
            case .stable: return "minus"
            }
        }
        
        var color: Color {
            switch self {
            case .up: return .green
            case .down: return .red
            case .stable: return .gray
            }
        }
        
        var description: String {
            switch self {
            case .up: return "上升趨勢"
            case .down: return "下降趨勢"
            case .stable: return "穩定"
            }
        }
    }
    
    enum CardSize {
        case large, medium, small
        
        var height: CGFloat {
            switch self {
            case .large: return 120
            case .medium: return 100
            case .small: return 80
            }
        }
        
        var iconSize: CGFloat {
            switch self {
            case .large: return 24
            case .medium: return 20
            case .small: return 16
            }
        }
        
        var valueFont: Font {
            switch self {
            case .large: return AppTheme.Typography.title
            case .medium: return AppTheme.Typography.title2
            case .small: return AppTheme.Typography.headline
            }
        }
        
        var titleFont: Font {
            switch self {
            case .large: return AppTheme.Typography.callout
            case .medium: return AppTheme.Typography.subheadline
            case .small: return AppTheme.Typography.footnote
            }
        }
    }
    
    var body: some View {
        let cardContent = VStack(alignment: .leading, spacing: AppTheme.Spacing.sm) {
            // Header with icon and trend
            HStack {
                Image(systemName: icon)
                    .font(.system(size: size.iconSize, weight: .medium))
                    .foregroundColor(color)
                
                Spacer()
                
                if let trend = trend {
                    HStack(spacing: 4) {
                        Image(systemName: trend.icon)
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(trend.color)
                        
                        Text(trend.description)
                            .font(AppTheme.Typography.caption)
                            .foregroundColor(trend.color)
                    }
                }
            }
            
            Spacer()
            
            // Data section
            VStack(alignment: .leading, spacing: 2) {
                Text(value)
                    .font(size.valueFont)
                    .fontWeight(.bold)
                    .foregroundColor(themeManager.currentTheme.colors.text)
                
                Text(title)
                    .font(size.titleFont)
                    .foregroundColor(themeManager.currentTheme.colors.text.opacity(0.7))
            }
        }
        .padding(AppTheme.Spacing.md)
        .frame(height: size.height)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: AppTheme.CornerRadius.md)
                .fill(themeManager.currentTheme.colors.cardBackground)
                .overlay(
                    RoundedRectangle(cornerRadius: AppTheme.CornerRadius.md)
                        .stroke(color.opacity(0.2), lineWidth: 1)
                )
        )
        .shadow(
            color: themeManager.currentTheme == .dark ? 
                Color.white.opacity(0.05) : Color.black.opacity(0.08),
            radius: 6,
            x: 0,
            y: 2
        )
        
        if let onTap = onTap {
            Button(action: onTap) {
                cardContent
            }
            .buttonStyle(PlainButtonStyle())
            .modifier(CardAnimationModifier())
            .accessibilityElement(children: .combine)
            .accessibilityLabel("\(title): \(value)")
            .accessibilityHint(trend?.description ?? "")
            .accessibilityAddTraits(.isButton)
        } else {
            cardContent
                .accessibilityElement(children: .combine)
                .accessibilityLabel("\(title): \(value)")
                .accessibilityHint(trend?.description ?? "")
        }
    }
}

// MARK: - Preview
struct DataCard_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 16) {
            HStack(spacing: 16) {
                DataCard(
                    title: "今日評分",
                    value: "12",
                    trend: .up,
                    icon: "star.fill",
                    color: .orange,
                    size: .medium,
                    onTap: {}
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
            }
            
            HStack(spacing: 16) {
                DataCard(
                    title: "總評分",
                    value: "1,234",
                    trend: .up,
                    icon: "chart.bar.fill",
                    color: .blue,
                    size: .small,
                    onTap: {}
                )
                
                DataCard(
                    title: "排名",
                    value: "#42",
                    trend: .down,
                    icon: "trophy.fill",
                    color: .purple,
                    size: .small,
                    onTap: {}
                )
                
                DataCard(
                    title: "連續天數",
                    value: "7",
                    trend: .up,
                    icon: "flame.fill",
                    color: .red,
                    size: .small,
                    onTap: nil
                )
            }
        }
        .padding()
        .environmentObject(ThemeManager())
    }
}