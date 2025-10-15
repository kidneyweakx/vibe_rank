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
    @State private var loadTask: Task<Void, Never>? = nil
    
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
            // Pure black background (simplified)
            Color.black.ignoresSafeArea()

            if isLoaded {
                loadedContent
            } else {
                // Initial full-screen loading (align with JourneyTabView)
                VStack {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        .scaleEffect(1.2)
                    Text("home.loading_data".localized)
                        .foregroundColor(.white.opacity(0.7))
                        .padding(.top, 12)
                }
            }
        }
        .navigationBarHidden(true)
        .preferredColorScheme(.dark)
        .onAppear { loadDataIfNeeded() }
        .onDisappear { loadTask?.cancel(); loadTask = nil }
        .onChange(of: authViewModel.user?.id) { _ in
            // Reload when user changes/available
            isLoaded = false
            loadTask?.cancel()
            loadTask = nil
            loadDataIfNeeded()
        }
    }

    private var loadedContent: some View {
        ZStack {
            ScrollView {
                LazyVStack(spacing: 28) {
                    // Discover Header with notification
                    HStack {
                        Text("Discover")
                            .font(.system(size: 32, weight: .bold))
                            .foregroundColor(.white)
                        Spacer()
                        NavigationLink {
                            NotificationsListView()
                        } label: {
                            ZStack(alignment: .topTrailing) {
                                Image(systemName: "bell.fill")
                                    .font(.system(size: 24))
                                    .foregroundColor(.white.opacity(0.8))
                                if AppNotificationsService.shared.hasRecent {
                                    Circle()
                                        .fill(Color(red: 255/255, green: 0/255, blue: 92/255))
                                        .frame(width: 10, height: 10)
                                        .offset(x: 4, y: -4)
                                }
                            }
                        }
                    }
                    .padding(.top, 12)

                    // Featured users section (using topUserGalleries from API)
                    if !topUserGalleries.isEmpty {
                        topCreatorsSection
                    }

                    // Events section with card stack (using events from API)
                    if !events.isEmpty {
                        upcomingEventsSection
                    }

                    // Statistics section
                    if let stats = statistics {
                        statisticsSection(stats)
                        divider
                    }

                    // Announcements section
                    if !announcements.isEmpty {
                        announcementsSection
                        divider
                    }

                    // AdMob Banner section (unified black-red style)
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Sponsors")
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundColor(.white)
                        GeometryReader { proxy in
                            AdMobAdaptiveBannerView(containerWidth: proxy.size.width)
                                .frame(height: 90)
                                .background(
                                    RoundedRectangle(cornerRadius: 16)
                                        .fill(Color(red: 0.1, green: 0.1, blue: 0.1))
                                )
                                .clipShape(RoundedRectangle(cornerRadius: 16))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 16)
                                        .stroke(Color(red: 255/255, green: 0/255, blue: 92/255).opacity(0.3), lineWidth: 1)
                                )
                        }
                        .frame(height: 90)
                    }
                    .padding(.horizontal, 20)

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

// MARK: - Lifecycle helpers
extension HomeView {
    private func loadDataIfNeeded() {
        guard !isLoading, !isLoaded else { return }

        // Debounce slightly to avoid rapid-fire loads when navigating quickly
        loadTask?.cancel()
        loadTask = Task {
            try? await Task.sleep(nanoseconds: 150_000_000)
            if Task.isCancelled { return }
            await loadHomeInfo()
        }
    }
}


