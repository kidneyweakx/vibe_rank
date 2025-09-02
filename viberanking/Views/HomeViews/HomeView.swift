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
            loadedContent
        }
        .navigationBarHidden(true)
        .preferredColorScheme(.dark)
        .onAppear { 
            Task { await loadHomeInfo() }
        }
    }

    private var loadedContent: some View {
        ZStack {
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
                    
                    // Empty state when no data
                    if topUserGalleries.isEmpty && events.isEmpty && announcements.isEmpty {
                        emptyStateView
                    }
                }
                .padding(.horizontal, 20)
                .safeAreaInset(edge: .bottom) { Color.clear.frame(height: 90) }
            }
            .refreshable {
                await loadHomeInfo()
            }
            
            // Loading indicator overlay
            if isLoading {
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            .scaleEffect(0.8)
                            .padding(.trailing, 20)
                            .padding(.bottom, 100)
                    }
                }
            }
        }
    }

    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Image(systemName: "house.fill")
                .font(.system(size: 50))
                .foregroundColor(.white.opacity(0.3))
            
            Text("home.empty_state.title".localized)
                .font(.title2)
                .fontWeight(.semibold)
                .foregroundColor(.white)
            
            Text("home.empty_state.subtitle".localized)
                .font(.body)
                .foregroundColor(.white.opacity(0.7))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
        }
        .padding(.vertical, 60)
    }
}

// MARK: - Preview
#Preview {
    HomeView()
        .environmentObject(ThemeManager())
        .environmentObject(AuthenticationViewModel())
}


