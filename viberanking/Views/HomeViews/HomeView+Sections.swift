import SwiftUI

// MARK: - Sections
extension HomeView {
    var announcementsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            sectionHeader("home.announcements.title".localized, subtitle: "home.announcements.subtitle".localized)
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 16) {
                    ForEach(announcements, id: \.id) { announcement in
                        AnnouncementCard(announcement: announcement)
                            .frame(width: 280)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.trailing, 20)
            }
        }
    }
    
    func statisticsSection(_ stats: HomeStatistics) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            sectionHeader("home.statistics.title".localized, subtitle: "home.statistics.subtitle".localized)
            HStack(spacing: 16) {
                StatisticCard(
                    title: "home.statistics.users".localized,
                    value: "\(stats.totalUsers)",
                    icon: "person.3.fill",
                    color: .blue
                )
                
                StatisticCard(
                    title: "home.statistics.photos".localized,
                    value: "\(stats.totalPhotos)",
                    icon: "photo.fill",
                    color: .green
                )
                
                StatisticCard(
                    title: "home.statistics.ratings".localized,
                    value: "\(stats.totalRatings)",
                    icon: "star.fill",
                    color: .yellow
                )
                
                StatisticCard(
                    title: "home.statistics.events".localized,
                    value: "\(stats.activeEvents)",
                    icon: "calendar.fill",
                    color: .purple
                )
            }
            .padding(.horizontal, 20)
        }
    }
    
    func featuredUsersSection(_ users: [FeaturedUser]) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            sectionHeader("home.featured.title".localized, subtitle: "home.featured.subtitle".localized)
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 16) {
                    ForEach(users, id: \.id) { user in
                        FeaturedUserCard(user: user)
                            .frame(width: 120)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.trailing, 20)
            }
        }
    }
    
    func trendingEventsSection(_ events: [TrendingEvent]) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            sectionHeader("home.trending_events.title".localized, subtitle: "home.trending_events.subtitle".localized)
            GeometryReader { proxy in
                let gridConfig = calculateGridConfiguration(for: proxy.size.width)
                ScrollView {
                    LazyVGrid(columns: gridConfig.columns, spacing: gridConfig.spacing) {
                        ForEach(events, id: \.id) { event in
                            TrendingEventCard(event: event) { }
                                .frame(width: gridConfig.cardWidth)
                                .aspectRatio(9/16, contentMode: .fit)
                                .clipShape(RoundedRectangle(cornerRadius: 16))
                        }
                    }
                    .padding(.bottom, 20)
                }
            }
            .frame(minHeight: 400)
        }
    }
    
    var recommendedSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            sectionHeader("home.recommended.title".localized, subtitle: "home.recommended.subtitle".localized)
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 16) {
                    ForEach(topUserGalleries, id: \.userId) { gallery in
                        RankedUserCard(gallery: gallery)
                            .frame(width: 100)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.trailing, 20)
            }
        }
    }

    var eventSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            sectionHeader("home.events.title".localized, subtitle: "home.events.subtitle".localized)
            GeometryReader { proxy in
                let gridConfig = calculateGridConfiguration(for: proxy.size.width)
                ScrollView {
                    LazyVGrid(columns: gridConfig.columns, spacing: gridConfig.spacing) {
                        ForEach(events) { item in
                            EventItemCard(item: item) { }
                                .frame(width: gridConfig.cardWidth)
                                .aspectRatio(9/16, contentMode: .fit)
                                .clipShape(RoundedRectangle(cornerRadius: 16))
                        }
                    }
                    .padding(.bottom, 20)
                }
            }
            .frame(minHeight: 400)
        }
    }

    var divider: some View {
        Rectangle()
            .fill(Color.white.opacity(0.1))
            .frame(height: 1)
            .padding(.horizontal, 20)
    }

    func sectionHeader(_ title: String, subtitle: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.system(size: 24, weight: .bold))
                .foregroundColor(.white)
            Text(subtitle)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.white.opacity(0.6))
        }
    }
}


