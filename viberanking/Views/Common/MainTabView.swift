//
//  MainTabView.swift
//  viberanking
//
//  Created by Kiro on 2025/07/25.
//

import SwiftUI

struct MainTabView: View {
    @EnvironmentObject private var authViewModel: AuthenticationViewModel
    @EnvironmentObject private var themeManager: ThemeManager
    @State private var selectedTab: TabItem = .home
    
    var body: some View {
        TabView(selection: $selectedTab) {
            // Home Tab (New - Main Dashboard)
            HomeView()
                .tabItem {
                    Image(systemName: "house.fill")
                    Text("首頁")
                }
                .tag(TabItem.home)
            
            // Rating Tab
            RatingTabView()
                .tabItem {
                    Image(systemName: "star.fill")
                    Text(NSLocalizedString("tab.main.rating", comment: "Rating tab title"))
                }
                .tag(TabItem.rating)
            
            // Upload Tab
            UploadTabView()
                .tabItem {
                    Image(systemName: "plus.circle.fill")
                    Text(NSLocalizedString("tab.main.upload", comment: "Upload tab title"))
                }
                .tag(TabItem.upload)
            
            // Profile Tab
            ProfileTabView()
                .tabItem {
                    Image(systemName: "person.crop.circle.fill")
                    Text(NSLocalizedString("tab.main.profile", comment: "Profile tab title"))
                }
                .tag(TabItem.profile)
        }
        .modifier(CustomTabBar())
    }
}

// MARK: - Tab Items
enum TabItem: CaseIterable {
    case home, rating, upload, profile
}

#Preview {
    MainTabView()
        .environmentObject(AuthenticationViewModel())
        .environmentObject(ThemeManager())
}
