//
//  HomeView.swift
//  viberanking
//
//  Created by Kiro on 2025/07/25.
//

import SwiftUI

struct HomeView: View {
    @EnvironmentObject private var themeManager: ThemeManager
    @EnvironmentObject private var authViewModel: AuthenticationViewModel
    @State var recommendedUsers: [RecommendedUser] = []
    @State var topUserGalleries: [TopUserGallery] = []
    @State var eventPhotos: [EventPhoto] = []
    @State var events: [EventItem] = []
    @State var homeInfo: HomeInfoData?
    @State var announcements: [Announcement] = []
    @State var statistics: HomeStatistics?
    @State var isLoaded = false
    @State var isLoading = false
    
    var body: some View {
        if #available(iOS 16.0, *) {
            NavigationStack { mainContent }
        } else {
            NavigationView { mainContent }
            .navigationViewStyle(StackNavigationViewStyle())
        }
    }
    
    private var mainContent: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            if isLoaded { loadedContent } else { loadingContent }
        }
        .navigationBarHidden(true)
        .preferredColorScheme(.dark)
        .onAppear { 
            if !isLoaded { 
                Task { await loadHomeInfo() }
            } 
        }
    }

    private var loadedContent: some View {
        ScrollView {
            LazyVStack(spacing: 32) {
                // Announcements section
                if !announcements.isEmpty {
                    announcementsSection
                    divider
                }
                
                // Statistics section
                if let stats = statistics {
                    statisticsSection(stats)
                    divider
                }
                
                // Featured users section (using topUserGalleries from API)
                if !topUserGalleries.isEmpty {
                    recommendedSection
                    divider
                }
                
                // Events section (using events from API)
                if !events.isEmpty {
                    eventSection
                }
            }
            .padding(.horizontal, 20)
            .safeAreaInset(edge: .bottom) { Color.clear.frame(height: 90) }
        }
        .refreshable {
            await loadHomeInfo()
        }
    }

    private var loadingContent: some View {
        VStack {
            ProgressView()
                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                .scaleEffect(1.2)
            Text("common.loading".localized)
                .foregroundColor(.white.opacity(0.7))
                .padding(.top, 16)
        }
    }
}

// MARK: - Preview
#Preview {
    HomeView()
        .environmentObject(ThemeManager())
        .environmentObject(AuthenticationViewModel())
}


