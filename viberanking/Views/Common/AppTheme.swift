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