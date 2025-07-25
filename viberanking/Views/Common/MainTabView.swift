//
//  MainTabView.swift
//  viberanking
//
//  Created by Kiro on 2025/07/25.
//

import SwiftUI

struct MainTabView: View {
    @EnvironmentObject private var authViewModel: AuthenticationViewModel
    @State private var selectedTab: TabItem = .rating
    
    var body: some View {
        ZStack {
            // Cute starry background
            starryBackground
            
            TabView(selection: $selectedTab) {
                // Profile Tab
                ProfileTabView()
                    .tabItem {
                        TabItemView(
                            icon: "person.crop.circle.fill",
                            title: "個人",
                            isSelected: selectedTab == .profile
                        )
                    }
                    .tag(TabItem.profile)
                
                // Rating Tab (Center - Most Important)
                RatingTabView()
                    .tabItem {
                        TabItemView(
                            icon: "star.fill",
                            title: "評分",
                            isSelected: selectedTab == .rating,
                            isCenter: true
                        )
                    }
                    .tag(TabItem.rating)
                
                // Upload Tab
                UploadTabView()
                    .tabItem {
                        TabItemView(
                            icon: "plus.circle.fill",
                            title: "上傳",
                            isSelected: selectedTab == .upload
                        )
                    }
                    .tag(TabItem.upload)
            }
            .accentColor(AppTheme.Colors.accentYellow)
            .onAppear {
                setupTabBarAppearance()
            }
        }
    }
    
    // MARK: - Cute Starry Background
    private var starryBackground: some View {
        ZStack {
            // Main gradient background
            AppTheme.Colors.primaryGradient
                .ignoresSafeArea()
            
            // Floating stars and shapes
            GeometryReader { geometry in
                ForEach(0..<15, id: \.self) { index in
                    FloatingShape(
                        geometry: geometry,
                        index: index
                    )
                }
            }
            .ignoresSafeArea()
        }
    }
    
    private func setupTabBarAppearance() {
        let appearance = UITabBarAppearance()
        appearance.configureWithTransparentBackground()
        
        // Create a subtle glass effect for the tab bar
        appearance.backgroundColor = UIColor.white.withAlphaComponent(0.1)
        
        // Blur effect for modern look
        let blurEffect = UIBlurEffect(style: .systemUltraThinMaterialLight)
        appearance.backgroundEffect = blurEffect
        
        // Remove default styling
        appearance.stackedLayoutAppearance.normal.iconColor = UIColor.clear
        appearance.stackedLayoutAppearance.normal.titleTextAttributes = [.foregroundColor: UIColor.clear]
        appearance.stackedLayoutAppearance.selected.iconColor = UIColor.clear
        appearance.stackedLayoutAppearance.selected.titleTextAttributes = [.foregroundColor: UIColor.clear]
        
        UITabBar.appearance().standardAppearance = appearance
        UITabBar.appearance().scrollEdgeAppearance = appearance
        UITabBar.appearance().isTranslucent = true
    }
}

// MARK: - Tab Items
enum TabItem: CaseIterable {
    case profile, rating, upload
}



// MARK: - Custom Tab Item View
struct TabItemView: View {
    let icon: String
    let title: String
    let isSelected: Bool
    let isCenter: Bool
    
    init(icon: String, title: String, isSelected: Bool, isCenter: Bool = false) {
        self.icon = icon
        self.title = title
        self.isSelected = isSelected
        self.isCenter = isCenter
    }
    
    var body: some View {
        VStack(spacing: 4) {
            ZStack {
                if isCenter {
                    // Special cute styling for center tab (rating)
                    ZStack {
                        Circle()
                            .fill(AppTheme.Colors.accentYellow)
                            .frame(width: 56, height: 56)
                            .shadow(color: AppTheme.Colors.accentYellow.opacity(0.4), radius: 12, x: 0, y: 6)
                        
                        Circle()
                            .stroke(Color.white.opacity(0.3), lineWidth: 2)
                            .frame(width: 56, height: 56)
                        
                        Text("⭐️")
                            .font(.system(size: 28))
                            .scaleEffect(isSelected ? 1.1 : 1.0)
                    }
                    .scaleEffect(isSelected ? 1.05 : 1.0)
                } else {
                    ZStack {
                        if isSelected {
                            Circle()
                                .fill(Color.white.opacity(0.2))
                                .frame(width: 40, height: 40)
                        }
                        
                        Image(systemName: icon)
                            .font(.system(size: 22, weight: isSelected ? .semibold : .regular))
                            .foregroundColor(isSelected ? .white : Color.white.opacity(0.7))
                    }
                }
            }
            
            if !isCenter {
                Text(title)
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(isSelected ? .white : Color.white.opacity(0.7))
            }
        }
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isSelected)
    }
}

#Preview {
    MainTabView()
        .environmentObject(AuthenticationViewModel())
}