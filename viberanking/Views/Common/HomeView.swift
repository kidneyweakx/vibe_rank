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
                        RankedUserCard(gallery: gallery)
                    }
                }
                .padding(.horizontal, 4)
            }
        }
    }
    
    // MARK: - Event Section
    private var eventSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            sectionHeader("Events", subtitle: "Latest event submissions")
            
            // Two columns tuned to avoid overlap on small screens
                LazyVGrid(columns: [
                GridItem(.adaptive(minimum: 120), spacing: 12, alignment: .top)
            ], spacing: 16) {
                    ForEach(events) { item in
                        EventItemCard(item: item) { }
                            .frame(maxWidth: .infinity)
                            .aspectRatio(3/4, contentMode: .fit)
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
        
        Task {
            // Run both APIs concurrently
            async let rankingsGalleries: [TopUserGallery] = fetchTopUserGalleries()
            async let fetchedEvents: [EventItem] = fetchEvents()

            let galleries = await rankingsGalleries
            let eventsData = await fetchedEvents

            await MainActor.run {
                self.topUserGalleries = galleries
                self.events = eventsData
                self.eventPhotos = []
                withAnimation(.easeInOut(duration: 0.25)) {
                    self.isLoaded = true
                }
            }
        }
    }

    private func fetchTopUserGalleries() async -> [TopUserGallery] {
            do {
                let rankings = try await RateAPI().getRankings(limit: 5)
                let top = rankings.data.overall.prefix(5)
                var galleries: [TopUserGallery] = []
            await withTaskGroup(of: TopUserGallery?.self) { group in
                for user in top {
                    group.addTask {
                        do {
                    let photosResponse = try await FileAPI().getUserPhotos(userId: user.userId, page: 1, limit: 5)
                    let infos = photosResponse.data.photos
                            let urls = infos.map { $0.urls.bestAvailableURL }.filter { !$0.isEmpty }
                            let chosen = Array(urls.prefix(5))
                            return TopUserGallery(
                                userId: user.userId,
                                name: user.name,
                                rank: user.rank,
                                avatarURL: user.avatar,
                                photoURLs: !chosen.isEmpty ? chosen : (user.avatar != nil ? [user.avatar!] : [])
                            )
                        } catch {
                            // Fallback to avatar only for this user
                            if let avatar = user.avatar, !avatar.isEmpty {
                                return TopUserGallery(
                                    userId: user.userId,
                                    name: user.name,
                                    rank: user.rank,
                                    avatarURL: avatar,
                                    photoURLs: [avatar]
                                )
                            }
                            return TopUserGallery(
                                userId: user.userId,
                                name: user.name,
                                rank: user.rank,
                                avatarURL: nil,
                                photoURLs: []
                            )
                        }
                    }
                }
                for await gallery in group {
                    if let gallery = gallery { galleries.append(gallery) }
                }
            }
            let final = galleries
                .filter { !$0.photoURLs.isEmpty || $0.avatarURL != nil }
                .sorted { $0.rank < $1.rank }
            return final.isEmpty ? generateRandomUsers() : final
        } catch {
            // If rankings fail entirely, recommend some random users
            return generateRandomUsers()
        }
    }

    private func fetchEvents() async -> [EventItem] {
            do {
                let response = try await EventAPI().getEventList()
            return response.data
            } catch {
                print("❌ HomeView: Failed to load events: \(error)")
            return []
        }
    }
    
    private func generateRandomUsers() -> [TopUserGallery] {
        let names = ["Alex Chen", "Sarah Kim", "Mike Johnson", "Emma Liu", "David Park"]
        let sampleImages = [
            "https://picsum.photos/400/600?random=1",
            "https://picsum.photos/400/600?random=2",
            "https://picsum.photos/400/600?random=3",
            "https://picsum.photos/400/600?random=4",
            "https://picsum.photos/400/600?random=5"
        ]
        
        return names.enumerated().map { index, name in
            TopUserGallery(
                userId: "random_\(index)",
                name: name,
                rank: index + 1,
                avatarURL: "https://picsum.photos/100/100?random=\(index + 10)",
                photoURLs: Array(sampleImages.shuffled().prefix(3))
            )
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
                                            image
                                                .resizable()
                                                .scaledToFill()
                                                .frame(width: 80, height: 80)
                                                .clipped()
                                        case .failure:
                                            Image(systemName: "photo").foregroundColor(.white.opacity(0.6))
                                        @unknown default:
                                            Color.clear
                                        }
                                    }
                                    .frame(width: 80, height: 80)
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
                // Photo area with 9:16 aspect ratio (vertical)
                ZStack {
                    RoundedRectangle(cornerRadius: 16)
                        .fill(
                            LinearGradient(
                                colors: [Color.white.opacity(0.08), Color.white.opacity(0.03)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .aspectRatio(9/16, contentMode: .fit)
                        .clipped()
                    .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(
                                    LinearGradient(
                                        colors: [Color.white.opacity(0.2), Color.white.opacity(0.05)],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    ),
                                    lineWidth: 1
                                )
                        )
                    
                    if let imageURL = photo.imageURL, let url = URL(string: imageURL) {
                        AsyncImage(url: url) { phase in
                            switch phase {
                            case .empty:
                                VStack(spacing: 12) {
                                    ProgressView()
                                        .progressViewStyle(.circular)
                                        .tint(.white.opacity(0.7))
                                        .scaleEffect(0.8)
                                }
                            case .success(let image):
                                image
                                    .resizable()
                                    .scaledToFill()
                                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                                    .clipped()
                            case .failure:
                                VStack(spacing: 12) {
                                    Image(systemName: "photo.artframe")
                                        .font(.system(size: 32))
                                        .foregroundColor(.white.opacity(0.4))
                                    Text("Event Photo")
                                        .font(.system(size: 12, weight: .medium))
                                        .foregroundColor(.white.opacity(0.4))
                                }
                            @unknown default:
                                Color.clear
                            }
                        }
                        .clipped()
                    } else {
                        VStack(spacing: 12) {
                            Image(systemName: "photo.artframe")
                                .font(.system(size: 32))
                                .foregroundColor(.white.opacity(0.4))
                            Text("Event Photo")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(.white.opacity(0.4))
                        }
                    }
                    
                    // Gradient overlay for better badge visibility
                    LinearGradient(
                        colors: [Color.black.opacity(0.3), Color.clear, Color.clear, Color.black.opacity(0.4)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                    .cornerRadius(16)
                    
                        // Like badge
                        VStack {
                            HStack {
                                Spacer()
                                HStack(spacing: 4) {
                                    Image(systemName: "heart.fill")
                                        .font(.system(size: 10))
                                        .foregroundColor(.pink)
                                    
                                    Text("\(photo.likes)")
                                    .font(.system(size: 11, weight: .bold))
                                        .foregroundColor(.white)
                                }
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                                .background(
                                    Capsule()
                                        .fill(Color.black.opacity(0.7))
                                    .overlay(
                                        Capsule()
                                            .stroke(Color.white.opacity(0.1), lineWidth: 0.5)
                                    )
                            )
                        }
                        Spacer()
                        
                        // Time info at bottom
                        HStack {
                            Text(timeAgo)
                                .font(.system(size: 11, weight: .medium))
                                .foregroundColor(.white.opacity(0.9))
                                .shadow(color: .black.opacity(0.5), radius: 2, x: 0, y: 1)
                            Spacer()
                        }
                    }
                    .padding(12)
                }
            }
        }
        .buttonStyle(PlainButtonStyle())
        .scaleEffect(isPressed ? 0.96 : 1.0)
        .animation(.easeInOut(duration: 0.15), value: isPressed)
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
                // Event image with enforced 9:16 aspect ratio and hard clipping to rounded rect
                ZStack {
                    // Background subtle gradient
                    LinearGradient(
                        colors: [Color.white.opacity(0.08), Color.white.opacity(0.03)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                    
                    if let urlString = item.imageURL, let url = URL(string: urlString) {
                        AsyncImage(url: url) { phase in
                            switch phase {
                            case .empty:
                                VStack(spacing: 12) {
                                    ProgressView()
                                        .progressViewStyle(.circular)
                                        .tint(.white.opacity(0.7))
                                        .scaleEffect(0.8)
                                }
                            case .success(let image):
                                image
                                    .resizable()
                                    .scaledToFill()
                                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                                    .clipped()
                            case .failure:
                                VStack(spacing: 12) {
                                    Image(systemName: "calendar.badge.exclamationmark")
                                        .font(.system(size: 32))
                                        .foregroundColor(.white.opacity(0.4))
                                    Text("Event")
                                        .font(.system(size: 12, weight: .medium))
                                        .foregroundColor(.white.opacity(0.4))
                                }
                            @unknown default:
                                Color.clear
                            }
                        }
                        .clipped()
                    } else {
                        VStack(spacing: 12) {
                            Image(systemName: "calendar.badge.plus")
                                .font(.system(size: 32))
                                .foregroundColor(.white.opacity(0.4))
                            Text("Event")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(.white.opacity(0.4))
                        }
                    }
                    
                    // Gradient overlay for better text readability
                    LinearGradient(
                        colors: [Color.clear, Color.clear, Color.black.opacity(0.7)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                    
                    // Event info overlay removed (no title/date text)
                    VStack { Spacer() }
                    
                    // "LIVE" badge for active events
                    VStack {
                        HStack {
                            Spacer()
                            HStack(spacing: 4) {
                                Circle()
                                    .fill(Color.red)
                                    .frame(width: 6, height: 6)
                                Text("LIVE")
                                    .font(.system(size: 10, weight: .bold))
                                    .foregroundColor(.white)
                            }
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Capsule().fill(Color.black.opacity(0.7)))
                        }
                        Spacer()
                    }
                    .padding(12)
                }
                .aspectRatio(9/16, contentMode: .fit)
                .clipped()
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(
                            LinearGradient(
                                colors: [Color.white.opacity(0.2), Color.white.opacity(0.05)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1
                        )
                )
            }
            
            // No intro line
        }
        .buttonStyle(PlainButtonStyle())
        .scaleEffect(isPressed ? 0.96 : 1.0)
        .animation(.easeInOut(duration: 0.15), value: isPressed)
        .onTapGesture {
            withAnimation(.easeInOut(duration: 0.1)) { isPressed = true }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                withAnimation(.easeInOut(duration: 0.1)) { isPressed = false }
                onTap()
            }
        }
    }

    private var introLine: String {
        if let desc = item.description, !desc.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return desc
        }
        if let startsAt = item.startsAt, !startsAt.isEmpty {
            return "於 \(String(startsAt.prefix(10))) 開跑 — \(item.title)"
        }
        return "立即參加「\(item.title)」，展現你的風格！"
    }
}

// MARK: - Ranked User Card (9:16 portrait)
struct RankedUserCard: View {
    let gallery: TopUserGallery

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            // Rank badge with gradient
            HStack {
                ZStack {
                    Circle()
                        .fill(rankGradient)
                        .frame(width: 28, height: 28)
                        .shadow(color: rankColor.opacity(0.3), radius: 4, x: 0, y: 2)
                    Text("\(gallery.rank)")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(.white)
                }
                Spacer()
                if gallery.rank <= 3 {
                    Image(systemName: "crown.fill")
                        .font(.system(size: 16))
                        .foregroundColor(rankColor)
                }
            }

            // Main photo with 9:16 portrait ratio
            ZStack {
                RoundedRectangle(cornerRadius: 16)
                    .fill(
                        LinearGradient(
                            colors: [Color.white.opacity(0.08), Color.white.opacity(0.03)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                
                if let first = gallery.photoURLs.first, let url = URL(string: first) {
                    AsyncImage(url: url) { phase in
                        switch phase {
                        case .empty:
                            ProgressView()
                                .progressViewStyle(.circular)
                                .tint(.white.opacity(0.7))
                                .scaleEffect(0.8)
                        case .success(let image):
                            image
                                .resizable()
                                .scaledToFill()
                                .frame(width: 160)
                                .aspectRatio(9/16, contentMode: .fill)
                                .clipped()
                        case .failure:
                            VStack(spacing: 8) {
                                Image(systemName: "photo.artframe")
                                    .font(.system(size: 32))
                                    .foregroundColor(.white.opacity(0.4))
                                Text("Photo")
                                    .font(.system(size: 12, weight: .medium))
                                    .foregroundColor(.white.opacity(0.4))
                            }
                        @unknown default:
                            Color.clear
                        }
                    }
                    .frame(width: 160)
                    .aspectRatio(9/16, contentMode: .fit)
                    .clipped()
                } else {
                    VStack(spacing: 8) {
                        Image(systemName: "photo.artframe")
                            .font(.system(size: 32))
                            .foregroundColor(.white.opacity(0.4))
                        Text("No Photos")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.white.opacity(0.4))
                    }
                }
            }
            .frame(width: 160)
            .aspectRatio(9/16, contentMode: .fit)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(
                        LinearGradient(
                            colors: [Color.white.opacity(0.2), Color.white.opacity(0.05)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1
                    )
            )

            // Name under the image
            Text(gallery.name)
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(.white)
                .lineLimit(1)
        }
        .frame(width: 160)
        .padding(.vertical, 8)
    }
    
    private var rankColor: Color {
        switch gallery.rank {
        case 1: return .yellow
        case 2: return Color(red: 0.75, green: 0.75, blue: 0.75) // Silver
        case 3: return Color(red: 0.8, green: 0.5, blue: 0.2) // Bronze
        default: return .blue
        }
    }
    
    private var rankGradient: LinearGradient {
        switch gallery.rank {
        case 1:
            return LinearGradient(colors: [.yellow, Color.orange], startPoint: .topLeading, endPoint: .bottomTrailing)
        case 2:
            return LinearGradient(colors: [Color(red: 0.9, green: 0.9, blue: 0.9), Color(red: 0.6, green: 0.6, blue: 0.6)], startPoint: .topLeading, endPoint: .bottomTrailing)
        case 3:
            return LinearGradient(colors: [Color(red: 1.0, green: 0.6, blue: 0.2), Color(red: 0.6, green: 0.3, blue: 0.1)], startPoint: .topLeading, endPoint: .bottomTrailing)
        default:
            return LinearGradient(colors: [.blue, Color.blue.opacity(0.7)], startPoint: .topLeading, endPoint: .bottomTrailing)
        }
    }
}
