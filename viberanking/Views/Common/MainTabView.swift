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
    @State private var selectedTab: TabItem = .rating
    
    var body: some View {
        TabView(selection: $selectedTab) {
            // Profile Tab
            ProfileTabView()
                .tabItem {
                    Image(systemName: "person.crop.circle.fill")
                    Text(NSLocalizedString("tab.main.profile", comment: "Profile tab title"))
                }
                .tag(TabItem.profile)
            
            // Rating Tab (Center - Most Important)
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
        }
        .modifier(CustomTabBar())
    }
}

// MARK: - Tab Items
enum TabItem: CaseIterable {
    case profile, rating, upload
}

#Preview {
    MainTabView()
        .environmentObject(AuthenticationViewModel())
        .environmentObject(ThemeManager())
}
