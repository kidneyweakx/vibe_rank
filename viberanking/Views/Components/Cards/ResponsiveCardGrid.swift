//
//  ResponsiveCardGrid.swift
//  viberanking
//
//  Created by Kiro on 2025/07/25.
//

import SwiftUI

struct ResponsiveCardGrid<Content: View>: View {
    let content: () -> Content
    let spacing: CGFloat
    let columns: [GridItem]
    
    init(
        columns: [GridItem],
        spacing: CGFloat = AppTheme.Spacing.md,
        @ViewBuilder content: @escaping () -> Content
    ) {
        self.columns = columns
        self.spacing = spacing
        self.content = content
    }
    
    init(
        spacing: CGFloat = AppTheme.Spacing.md,
        @ViewBuilder content: @escaping () -> Content
    ) {
        self.columns = ResponsiveCardGrid.defaultColumns
        self.spacing = spacing
        self.content = content
    }
    
    var body: some View {
        LazyVGrid(columns: columns, spacing: spacing) {
            content()
        }
    }
    
    // MARK: - Default Configurations
    static var defaultColumns: [GridItem] {
        [
            GridItem(.flexible(), spacing: AppTheme.Spacing.sm),
            GridItem(.flexible(), spacing: AppTheme.Spacing.sm)
        ]
    }
    
    static var singleColumn: [GridItem] {
        [GridItem(.flexible())]
    }
    
    static var threeColumns: [GridItem] {
        [
            GridItem(.flexible(), spacing: AppTheme.Spacing.xs),
            GridItem(.flexible(), spacing: AppTheme.Spacing.xs),
            GridItem(.flexible(), spacing: AppTheme.Spacing.xs)
        ]
    }
    
    static func adaptiveColumns(minWidth: CGFloat = 150) -> [GridItem] {
        [GridItem(.adaptive(minimum: minWidth), spacing: AppTheme.Spacing.sm)]
    }
}

// MARK: - Card Item Protocol
protocol CardItem: Identifiable {
    var id: String { get }
    var view: AnyView { get }
    var size: CardItemSize { get }
    var priority: Int { get }
}

enum CardItemSize {
    case small, medium, large, fullWidth
    
    var gridSpan: Int {
        switch self {
        case .small: return 1
        case .medium: return 1
        case .large: return 2
        case .fullWidth: return 2
        }
    }
    
    var height: CGFloat {
        switch self {
        case .small: return 80
        case .medium: return 120
        case .large: return 180
        case .fullWidth: return 140
        }
    }
}

// MARK: - Concrete Card Item Implementation
struct ConcreteCardItem: CardItem {
    let id: String
    let view: AnyView
    let size: CardItemSize
    let priority: Int
    
    init<V: View>(
        id: String,
        size: CardItemSize = .medium,
        priority: Int = 0,
        content: V
    ) {
        self.id = id
        self.size = size
        self.priority = priority
        self.view = AnyView(content)
    }
}

// MARK: - Responsive Grid with Card Items
struct CardItemGrid: View {
    let items: [CardItem]
    let spacing: CGFloat
    
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @Environment(\.verticalSizeClass) private var verticalSizeClass
    
    init(items: [CardItem], spacing: CGFloat = AppTheme.Spacing.md) {
        self.items = items.sorted { $0.priority > $1.priority }
        self.spacing = spacing
    }
    
    var body: some View {
        LazyVGrid(columns: adaptiveColumns, spacing: spacing) {
            ForEach(items, id: \.id) { item in
                item.view
                    .frame(height: item.size.height)
                    .gridCellColumns(item.size.gridSpan)
            }
        }
    }
    
    private var adaptiveColumns: [GridItem] {
        let columnCount = isCompact ? 1 : 2
        return Array(repeating: GridItem(.flexible(), spacing: spacing), count: columnCount)
    }
    
    private var isCompact: Bool {
        horizontalSizeClass == .compact || verticalSizeClass == .compact
    }
}

// MARK: - Staggered Grid Layout
struct StaggeredCardGrid<Content: View>: View {
    let content: Content
    let columns: Int
    let spacing: CGFloat
    
    init(
        columns: Int = 2,
        spacing: CGFloat = AppTheme.Spacing.md,
        @ViewBuilder content: () -> Content
    ) {
        self.columns = columns
        self.spacing = spacing
        self.content = content()
    }
    
    var body: some View {
        HStack(alignment: .top, spacing: spacing) {
            ForEach(0..<columns, id: \.self) { column in
                LazyVStack(spacing: spacing) {
                    content
                }
                .frame(maxWidth: .infinity)
            }
        }
    }
}

// MARK: - Masonry Layout (iOS 16+)
@available(iOS 16.0, *)
struct MasonryCardGrid<Content: View>: View {
    let content: Content
    let columns: Int
    let spacing: CGFloat
    
    init(
        columns: Int = 2,
        spacing: CGFloat = AppTheme.Spacing.md,
        @ViewBuilder content: () -> Content
    ) {
        self.columns = columns
        self.spacing = spacing
        self.content = content()
    }
    
    var body: some View {
        LazyVGrid(
            columns: Array(repeating: GridItem(.flexible(), spacing: spacing), count: columns),
            spacing: spacing
        ) {
            content
        }
    }
}

// MARK: - Preview
struct ResponsiveCardGrid_Previews: PreviewProvider {
    static var previews: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Standard Grid
                Text("標準網格")
                    .font(AppTheme.Typography.headline)
                    .frame(maxWidth: .infinity, alignment: .leading)
                
                LazyVGrid(columns: [
                    GridItem(.flexible(), spacing: AppTheme.Spacing.sm),
                    GridItem(.flexible(), spacing: AppTheme.Spacing.sm)
                ], spacing: AppTheme.Spacing.md) {
                    ForEach(0..<6) { index in
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.blue.opacity(0.3))
                            .frame(height: 100)
                            .overlay(
                                Text("卡片 \(index + 1)")
                                    .font(AppTheme.Typography.headline)
                            )
                    }
                }
                
                // Card Item Grid
                Text("卡片項目網格")
                    .font(AppTheme.Typography.headline)
                    .frame(maxWidth: .infinity, alignment: .leading)
                
                CardItemGrid(items: sampleCardItems)
                
                // Three Column Grid
                Text("三欄網格")
                    .font(AppTheme.Typography.headline)
                    .frame(maxWidth: .infinity, alignment: .leading)
                
                LazyVGrid(columns: [
                    GridItem(.flexible(), spacing: AppTheme.Spacing.xs),
                    GridItem(.flexible(), spacing: AppTheme.Spacing.xs),
                    GridItem(.flexible(), spacing: AppTheme.Spacing.xs)
                ], spacing: AppTheme.Spacing.md) {
                    ForEach(0..<9) { index in
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color.green.opacity(0.3))
                            .frame(height: 60)
                            .overlay(
                                Text("\(index + 1)")
                                    .font(AppTheme.Typography.callout)
                            )
                    }
                }
            }
            .padding()
        }
        .environmentObject(ThemeManager())
    }
    
    static var sampleCardItems: [CardItem] {
        [
            ConcreteCardItem(
                id: "1", 
                size: .large, 
                priority: 3,
                content: RoundedRectangle(cornerRadius: 12)
                    .fill(Color.purple.opacity(0.3))
                    .overlay(Text("大卡片").font(AppTheme.Typography.headline))
            ),
            ConcreteCardItem(
                id: "2", 
                size: .medium, 
                priority: 2,
                content: RoundedRectangle(cornerRadius: 12)
                    .fill(Color.orange.opacity(0.3))
                    .overlay(Text("中卡片").font(AppTheme.Typography.callout))
            ),
            ConcreteCardItem(
                id: "3", 
                size: .small, 
                priority: 1,
                content: RoundedRectangle(cornerRadius: 12)
                    .fill(Color.red.opacity(0.3))
                    .overlay(Text("小卡片").font(AppTheme.Typography.caption))
            ),
            ConcreteCardItem(
                id: "4", 
                size: .fullWidth, 
                priority: 0,
                content: RoundedRectangle(cornerRadius: 12)
                    .fill(Color.cyan.opacity(0.3))
                    .overlay(Text("全寬卡片").font(AppTheme.Typography.headline))
            )
        ]
    }
}