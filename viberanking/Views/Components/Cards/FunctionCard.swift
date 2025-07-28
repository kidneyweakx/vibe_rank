//
//  FunctionCard.swift
//  viberanking
//
//  Created by Kiro on 2025/07/25.
//

import SwiftUI

struct FunctionCard: View {
    let title: String
    let subtitle: String
    let icon: String
    let primaryData: String
    let secondaryData: String?
    let backgroundColor: [Color]
    let size: CardSize
    let destination: AnyView
    let onTap: () -> Void
    
    @EnvironmentObject private var themeManager: ThemeManager
    @State private var isPressed = false
    
    enum CardSize {
        case large, medium, small
        
        var height: CGFloat {
            switch self {
            case .large: return 180
            case .medium: return 140
            case .small: return 100
            }
        }
        
        var iconSize: CGFloat {
            switch self {
            case .large: return 32
            case .medium: return 28
            case .small: return 24
            }
        }
        
        var titleFont: Font {
            switch self {
            case .large: return AppTheme.Typography.title2
            case .medium: return AppTheme.Typography.headline
            case .small: return AppTheme.Typography.callout
            }
        }
        
        var dataFont: Font {
            switch self {
            case .large: return AppTheme.Typography.largeTitle
            case .medium: return AppTheme.Typography.title
            case .small: return AppTheme.Typography.headline
            }
        }
    }
    
    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: AppTheme.Spacing.sm) {
                // Header with icon and title
                HStack {
                    Image(systemName: icon)
                        .font(.system(size: size.iconSize, weight: .semibold))
                        .foregroundColor(.white)
                    
                    Spacer()
                    
                    VStack(alignment: .trailing, spacing: 2) {
                        Text(title)
                            .font(size.titleFont)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                            .multilineTextAlignment(.trailing)
                        
                        if !subtitle.isEmpty {
                            Text(subtitle)
                                .font(AppTheme.Typography.caption)
                                .foregroundColor(.white.opacity(0.8))
                                .multilineTextAlignment(.trailing)
                        }
                    }
                }
                
                Spacer()
                
                // Data section
                VStack(alignment: .leading, spacing: 4) {
                    Text(primaryData)
                        .font(size.dataFont)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                    
                    if let secondaryData = secondaryData {
                        Text(secondaryData)
                            .font(AppTheme.Typography.subheadline)
                            .foregroundColor(.white.opacity(0.9))
                    }
                }
            }
            .padding(AppTheme.Spacing.md)
            .frame(height: size.height)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: AppTheme.CornerRadius.lg)
                    .fill(
                        LinearGradient(
                            colors: backgroundColor,
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            )
            .overlay(
                RoundedRectangle(cornerRadius: AppTheme.CornerRadius.lg)
                    .stroke(
                        LinearGradient(
                            colors: [Color.white.opacity(0.3), Color.clear],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1
                    )
            )
            .shadow(
                color: themeManager.currentTheme == .dark ? 
                    Color.white.opacity(0.1) : Color.black.opacity(0.15),
                radius: 8,
                x: 0,
                y: 4
            )
        }
        .buttonStyle(PlainButtonStyle())
        .modifier(CardAnimationModifier())
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(title) 卡片")
        .accessibilityHint("點擊進入 \(title) 功能")
        .accessibilityValue(primaryData)
        .accessibilityAddTraits(.isButton)
    }
}

// MARK: - Preview
struct FunctionCard_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 16) {
            FunctionCard(
                title: "個人資料",
                subtitle: "查看統計",
                icon: "person.circle.fill",
                primaryData: "7.5",
                secondaryData: "平均評分",
                backgroundColor: [
                    Color(red: 0.4, green: 0.7, blue: 1.0),
                    Color(red: 0.2, green: 0.5, blue: 0.9)
                ],
                size: .large,
                destination: AnyView(EmptyView()),
                onTap: {}
            )
            
            HStack(spacing: 16) {
                FunctionCard(
                    title: "評分",
                    subtitle: "今日進度",
                    icon: "star.fill",
                    primaryData: "12",
                    secondaryData: "已評分",
                    backgroundColor: [
                        Color(red: 1.0, green: 0.6, blue: 0.4),
                        Color(red: 0.9, green: 0.4, blue: 0.3)
                    ],
                    size: .medium,
                    destination: AnyView(EmptyView()),
                    onTap: {}
                )
                
                FunctionCard(
                    title: "上傳",
                    subtitle: "照片管理",
                    icon: "camera.fill",
                    primaryData: "5",
                    secondaryData: "張照片",
                    backgroundColor: [
                        Color(red: 0.4, green: 0.8, blue: 0.6),
                        Color(red: 0.3, green: 0.7, blue: 0.5)
                    ],
                    size: .medium,
                    destination: AnyView(EmptyView()),
                    onTap: {}
                )
            }
        }
        .padding()
        .environmentObject(ThemeManager())
    }
}