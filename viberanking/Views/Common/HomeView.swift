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
    @State private var recommendedUsers: [RecommendedUser] = []
    @State private var eventPhotos: [EventPhoto] = []
    @State private var isLoaded = false
    
    var body: some View {
        if #available(iOS 16.0, *) {
            NavigationStack {
                mainContent
            }
        } else {
            NavigationView {
                mainContent
            }
            .navigationViewStyle(StackNavigationViewStyle())
        }
    }
    
    private var mainContent: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            if isLoaded {
                ScrollView {
                    LazyVStack(spacing: 32) {
                        // Recommended Users Section
                        recommendedSection
                        
                        // Divider
                        divider
                        
                        // Event Photos Section
                        eventSection
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 100)
                }
            } else {
                // Loading state
                VStack {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        .scaleEffect(1.2)
                    
                    Text("載入中...")
                        .foregroundColor(.white.opacity(0.7))
                        .padding(.top, 16)
                }
            }
        }
        .navigationBarHidden(true)
        .preferredColorScheme(.dark)
        .onAppear {
            if !isLoaded {
                loadData()
            }
        }
    }

    // MARK: - Recommended Section
    private var recommendedSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            sectionHeader("Recommended", subtitle: "Top ranked users")
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 16) {
                    ForEach(recommendedUsers, id: \.id) { user in
                        RecommendedUserCard(user: user) {
                            print("點擊用戶 \(user.name)")
                        }
                    }
                }
                .padding(.horizontal, 4)
            }
        }
    }
    
    // MARK: - Event Section
    private var eventSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            sectionHeader("Events", subtitle: "Latest photo submissions")
            
            LazyVGrid(columns: [
                GridItem(.flexible(), spacing: 12),
                GridItem(.flexible(), spacing: 12)
            ], spacing: 16) {
                ForEach(eventPhotos, id: \.id) { photo in
                    EventPhotoCard(photo: photo) {
                        print("點擊照片 \(photo.id)")
                    }
                }
            }
        }
    }
    
    // MARK: - Divider
    private var divider: some View {
        Rectangle()
            .fill(Color.white.opacity(0.1))
            .frame(height: 1)
            .padding(.horizontal, 20)
    }

    // MARK: - Helper Methods
    private func sectionHeader(_ title: String, subtitle: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.system(size: 24, weight: .bold))
                .foregroundColor(.white)
            
            Text(subtitle)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.white.opacity(0.6))
        }
    }
    
    private func loadData() {
        print("🔄 HomeView: Starting to load data...")
        
        // Simulate loading delay for better UX
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            print("📊 HomeView: Loading mock data...")
            
            // Load recommended users (mock data)
            recommendedUsers = [
                RecommendedUser(id: "1", name: "Alice", rank: 1, score: 9.8, avatarURL: nil),
                RecommendedUser(id: "2", name: "Bob", rank: 2, score: 9.5, avatarURL: nil),
                RecommendedUser(id: "3", name: "Charlie", rank: 3, score: 9.2, avatarURL: nil),
                RecommendedUser(id: "4", name: "Diana", rank: 4, score: 8.9, avatarURL: nil),
                RecommendedUser(id: "5", name: "Eve", rank: 5, score: 8.7, avatarURL: nil)
            ]
            
            // Load event photos (mock data)
            eventPhotos = [
                EventPhoto(id: "1", imageURL: nil, likes: 45, timestamp: Date()),
                EventPhoto(id: "2", imageURL: nil, likes: 32, timestamp: Date()),
                EventPhoto(id: "3", imageURL: nil, likes: 28, timestamp: Date()),
                EventPhoto(id: "4", imageURL: nil, likes: 19, timestamp: Date()),
                EventPhoto(id: "5", imageURL: nil, likes: 15, timestamp: Date()),
                EventPhoto(id: "6", imageURL: nil, likes: 12, timestamp: Date())
            ]
            
            print("✅ HomeView: Mock data loaded, showing UI...")
            withAnimation(.easeInOut(duration: 0.3)) {
                isLoaded = true
            }
        }
    }
}

// MARK: - Preview
#Preview {
    HomeView()
        .environmentObject(ThemeManager())
        .environmentObject(AuthenticationViewModel())
}


// MARK: - Data Models
struct RecommendedUser {
    let id: String
    let name: String
    let rank: Int
    let score: Double
    let avatarURL: String?
}

struct EventPhoto {
    let id: String
    let imageURL: String?
    let likes: Int
    let timestamp: Date
}

// MARK: - Recommended User Card
struct RecommendedUserCard: View {
    let user: RecommendedUser
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 12) {
                // Rank badge
                ZStack {
                    Circle()
                        .fill(rankColor)
                        .frame(width: 24, height: 24)
                    
                    Text("\(user.rank)")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(.white)
                }
                .offset(x: 60, y: 12)
                .zIndex(1)
                
                // Avatar
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [Color.pink.opacity(0.8), Color.purple.opacity(0.6)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 80, height: 80)
                    .overlay(
                        Image(systemName: "person.fill")
                            .font(.system(size: 32))
                            .foregroundColor(.white)
                    )
                
                // User info
                VStack(spacing: 4) {
                    Text(user.name)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white)
                    
                    HStack(spacing: 4) {
                        Image(systemName: "star.fill")
                            .font(.system(size: 12))
                            .foregroundColor(.yellow)
                        
                        Text(String(format: "%.1f", user.score))
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.white.opacity(0.8))
                    }
                }
            }
            .frame(width: 120)
            .padding(.vertical, 16)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.white.opacity(0.05))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(Color.white.opacity(0.1), lineWidth: 1)
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private var rankColor: Color {
        switch user.rank {
        case 1: return .yellow
        case 2: return .gray
        case 3: return Color.orange
        default: return .blue
        }
    }
}

// MARK: - Event Photo Card
struct EventPhotoCard: View {
    let photo: EventPhoto
    let onTap: () -> Void
    @State private var isPressed = false
    
    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 0) {
                // Photo area
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.white.opacity(0.05))
                    .aspectRatio(0.8, contentMode: .fit)
                    .overlay(
                        VStack(spacing: 8) {
                            Image(systemName: "photo.fill")
                                .font(.system(size: 40))
                                .foregroundColor(.white.opacity(0.6))
                            
                            Text("Event Photo")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(.white.opacity(0.6))
                        }
                    )
                    .overlay(
                        // Like badge
                        VStack {
                            HStack {
                                Spacer()
                                HStack(spacing: 4) {
                                    Image(systemName: "heart.fill")
                                        .font(.system(size: 10))
                                        .foregroundColor(.pink)
                                    
                                    Text("\(photo.likes)")
                                        .font(.system(size: 11, weight: .semibold))
                                        .foregroundColor(.white)
                                }
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(
                                    Capsule()
                                        .fill(Color.black.opacity(0.7))
                                )
                            }
                            Spacer()
                        }
                        .padding(8)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.white.opacity(0.1), lineWidth: 1)
                    )
                
                // Time info
                HStack {
                    Text(timeAgo)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.white.opacity(0.6))
                    
                    Spacer()
                }
                .padding(.top, 8)
            }
        }
        .buttonStyle(PlainButtonStyle())
        .scaleEffect(isPressed ? 0.95 : 1.0)
        .onTapGesture {
            withAnimation(.easeInOut(duration: 0.1)) {
                isPressed = true
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                withAnimation(.easeInOut(duration: 0.1)) {
                    isPressed = false
                }
                onTap()
            }
        }
    }
    
    private var timeAgo: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: photo.timestamp, relativeTo: Date())
    }
}
