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
                        Image(systemName: "person.crop.circle.fill")
                        Text("個人")
                    }
                    .tag(TabItem.profile)
                
                // Rating Tab (Center - Most Important)
                RatingTabView()
                    .tabItem {
                        Image(systemName: "star.fill")
                        Text("評分")
                    }
                    .tag(TabItem.rating)
                
                // Upload Tab
                UploadTabView()
                    .tabItem {
                        Image(systemName: "plus.circle.fill")
                        Text("上傳")
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
        
        // Style for normal state
        appearance.stackedLayoutAppearance.normal.iconColor = UIColor.white.withAlphaComponent(0.7)
        appearance.stackedLayoutAppearance.normal.titleTextAttributes = [
            .foregroundColor: UIColor.white.withAlphaComponent(0.7),
            .font: UIFont.systemFont(ofSize: 10, weight: .medium)
        ]
        
        // Style for selected state
        appearance.stackedLayoutAppearance.selected.iconColor = UIColor.white
        appearance.stackedLayoutAppearance.selected.titleTextAttributes = [
            .foregroundColor: UIColor.white,
            .font: UIFont.systemFont(ofSize: 10, weight: .semibold)
        ]
        
        UITabBar.appearance().standardAppearance = appearance
        UITabBar.appearance().scrollEdgeAppearance = appearance
        UITabBar.appearance().isTranslucent = true
    }
}

// MARK: - Tab Items
enum TabItem: CaseIterable {
    case profile, rating, upload
}





#Preview {
    MainTabView()
        .environmentObject(AuthenticationViewModel())
}
