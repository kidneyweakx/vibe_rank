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
    @State var isLoaded = false
    
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
        .onAppear { if !isLoaded { loadData() } }
    }

    private var loadedContent: some View {
                ScrollView {
            LazyVStack(spacing: 32) {
                recommendedSection
                divider
                eventSection
            }
            .padding(.horizontal, 20)
            .safeAreaInset(edge: .bottom) { Color.clear.frame(height: 90) }
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


