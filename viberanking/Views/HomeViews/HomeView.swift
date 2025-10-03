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
            // Subtle gradient background instead of pure black
            LinearGradient(
                colors: [
                    Color(red: 0.06, green: 0.06, blue: 0.08),
                    Color(red: 0.04, green: 0.04, blue: 0.06),
                    Color.black
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

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
                    // Announcements section
                    if !announcements.isEmpty {
                        announcementsSection
                            .padding(.top, 12)
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
                        divider
                    }

                    // AdMob Banner section
                    VStack(alignment: .leading, spacing: 16) {
                        sectionHeader("home.ads.title".localized, subtitle: "home.ads.subtitle".localized)
                            .padding(.horizontal, 20)

                        AdMobAdaptiveBannerView()
                            .frame(height: 90)
                            .background(
                                RoundedRectangle(cornerRadius: 16)
                                    .fill(
                                        LinearGradient(
                                            colors: [Color.white.opacity(0.05), Color.white.opacity(0.02)],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                    )
                            )
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                            .overlay(
                                RoundedRectangle(cornerRadius: 16)
                                    .stroke(Color.white.opacity(0.1), lineWidth: 1)
                            )
                            .padding(.horizontal, 20)
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

// MARK: - Lifecycle helpers
extension HomeView {
    private func loadDataIfNeeded() {
        // Only start when user is ready (align with JourneyTabView behavior)
        guard authViewModel.user?.id != nil else {
            // Wait for auth then onChange will trigger
            return
        }
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


