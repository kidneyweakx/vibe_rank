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
    @State private var topUserGalleries: [TopUserGallery] = []
    @State private var eventPhotos: [EventPhoto] = []
    @State private var events: [EventItem] = []
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
                        
                        // Event Photos Section (API-backed)
                        eventSection
                    }
                    .padding(.horizontal, 20)
                    .safeAreaInset(edge: .bottom) {
                        // Leave space for custom tab bar on small screens
                        Color.clear.frame(height: 90)
                    }
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
                    ForEach(topUserGalleries, id: \.userId) { gallery in
                        TopUserGalleryCard(gallery: gallery)
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
            
            if events.isEmpty {
                // Fallback to mock placeholders
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
            } else {
                LazyVGrid(columns: [
                    GridItem(.flexible(), spacing: 12),
                    GridItem(.flexible(), spacing: 12)
                ], spacing: 16) {
                    ForEach(events) { item in
                        EventItemCard(item: item) { }
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
        
        // Fetch top 1-5 ranked users and build galleries
        Task {
            do {
                let rankings = try await RateAPI().getRankings(limit: 5)
                let top = rankings.data.overall.prefix(5)
                var galleries: [TopUserGallery] = []
                for user in top {
                    // load recent photos for each user (limit 5 if backend supports; otherwise take first 5)
                    let photosResponse = try await FileAPI().getUserPhotos(userId: user.userId, page: 1, limit: 5)
                    let infos = photosResponse.data.photos
                    let previewUrls = infos.map { $0.urls.previewURL }.filter { !$0.isEmpty }
                    let avatarURL = user.avatar
                    galleries.append(TopUserGallery(userId: user.userId, name: user.name, rank: user.rank, avatarURL: avatarURL, photoURLs: Array(previewUrls.prefix(5))))
                }
                await MainActor.run {
                    self.topUserGalleries = galleries
                }
            } catch {
                // fallback: keep empty galleries
                await MainActor.run {
                    self.topUserGalleries = []
                }
            }
        }

        // Fetch events from API
        Task {
            do {
                let response = try await EventAPI().getEventList()
                await MainActor.run {
                    self.events = response.data
                    withAnimation(.easeInOut(duration: 0.25)) {
                        self.isLoaded = true
                    }
                }
            } catch {
                print("❌ HomeView: Failed to load events: \(error)")
                await MainActor.run {
                    // Fallback to mock tiles
                    self.eventPhotos = [
                        EventPhoto(id: "1", imageURL: nil, likes: 45, timestamp: Date()),
                        EventPhoto(id: "2", imageURL: nil, likes: 32, timestamp: Date()),
                        EventPhoto(id: "3", imageURL: nil, likes: 28, timestamp: Date()),
                        EventPhoto(id: "4", imageURL: nil, likes: 19, timestamp: Date()),
                        EventPhoto(id: "5", imageURL: nil, likes: 15, timestamp: Date()),
                        EventPhoto(id: "6", imageURL: nil, likes: 12, timestamp: Date())
                    ]
                    withAnimation(.easeInOut(duration: 0.25)) {
                        self.isLoaded = true
                    }
                }
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

struct TopUserGallery {
    let userId: String
    let name: String
    let rank: Int
    let avatarURL: String?
    let photoURLs: [String]
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

// MARK: - Top User Gallery Card
struct TopUserGalleryCard: View {
    let gallery: TopUserGallery
    @Environment(\.openURL) private var openURL
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 8) {
                ZStack {
                    Circle().fill(Color.white.opacity(0.08)).frame(width: 28, height: 28)
                    Text("\(gallery.rank)")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(.white)
                }
                Text(gallery.name)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.white)
                Spacer()
            }
            .padding(.horizontal, 8)
            
            // 2x3 grid of up to 6 images (we show up to 5 per spec)
            LazyVGrid(columns: [GridItem(.fixed(80)), GridItem(.fixed(80))], spacing: 8) {
                ForEach(Array(gallery.photoURLs.prefix(5).enumerated()), id: \.offset) { _, urlString in
                    RoundedRectangle(cornerRadius: 10)
                        .fill(Color.white.opacity(0.05))
                        .frame(width: 80, height: 80)
                        .overlay(
                            Group {
                                if let url = URL(string: urlString) {
                                    AsyncImage(url: url) { phase in
                                        switch phase {
                                        case .empty:
                                            ProgressView().tint(.white)
                                        case .success(let image):
                                            image.resizable().scaledToFill()
                                        case .failure:
                                            Image(systemName: "photo").foregroundColor(.white.opacity(0.6))
                                        @unknown default:
                                            Color.clear
                                        }
                                    }
                                    .clipped()
                                } else {
                                    Image(systemName: "photo").foregroundColor(.white.opacity(0.6))
                                }
                            }
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 10).stroke(Color.white.opacity(0.08), lineWidth: 1)
                        )
                }
            }
        }
        .frame(width: 180)
        .padding(10)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(Color.white.opacity(0.05))
                .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.white.opacity(0.1), lineWidth: 1))
        )
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

// MARK: - Event Item Card (API-backed)
struct EventItemCard: View {
    let item: EventItem
    let onTap: () -> Void
    @State private var isPressed = false
    @Environment(\.openURL) private var openURL

    var body: some View {
        Button(action: {
            if let link = item.linkUrl, let url = URL(string: link) {
                openURL(url)
            } else {
                onTap()
            }
        }) {
            VStack(spacing: 0) {
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.white.opacity(0.05))
                    .aspectRatio(0.8, contentMode: .fit)
                    .overlay(
                        ZStack {
                            if let urlString = item.imageUrl, let url = URL(string: urlString) {
                                AsyncImage(url: url) { phase in
                                    switch phase {
                                    case .empty:
                                        ProgressView()
                                            .progressViewStyle(.circular)
                                            .tint(.white)
                                    case .success(let image):
                                        image
                                            .resizable()
                                            .scaledToFill()
                                    case .failure:
                                        Image(systemName: "photo")
                                            .font(.system(size: 40))
                                            .foregroundColor(.white.opacity(0.6))
                                    @unknown default:
                                        Color.clear
                                    }
                                }
                            } else {
                                Image(systemName: "photo.fill")
                                    .font(.system(size: 40))
                                    .foregroundColor(.white.opacity(0.6))
                            }
                        }
                        .clipped()
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.white.opacity(0.1), lineWidth: 1)
                    )
                    .overlay(alignment: .bottom) {
                        ZStack {
                            LinearGradient(
                                colors: [Color.black.opacity(0.7), Color.black.opacity(0.0)],
                                startPoint: .bottom,
                                endPoint: .top
                            )
                            .frame(height: 42)

                            HStack {
                                Text(item.title)
                                    .font(.system(size: 12, weight: .semibold))
                                    .foregroundColor(.white)
                                    .lineLimit(1)
                                Spacer()
                            }
                            .padding(.horizontal, 8)
                            .padding(.bottom, 6)
                        }
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                    }

                HStack {
                    Text(shortDate)
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
            withAnimation(.easeInOut(duration: 0.1)) { isPressed = true }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                withAnimation(.easeInOut(duration: 0.1)) { isPressed = false }
                onTap()
            }
        }
    }

    private var shortDate: String {
        guard let startsAt = item.startsAt, !startsAt.isEmpty else { return "" }
        return String(startsAt.prefix(10))
    }
}
