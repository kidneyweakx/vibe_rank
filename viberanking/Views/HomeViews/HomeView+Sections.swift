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

            GeometryReader { geometry in
                let isCompact = geometry.size.width < 600

                if isCompact {
                    // Compact layout (phone): 2x2 grid
                    VStack(spacing: 16) {
                        HStack(spacing: 16) {
                            StatisticCard(
                                title: "home.statistics.users".localized,
                                value: "\(stats.totalUsers)",
                                icon: "person.3.fill",
                                color: Color(red: 255/255, green: 139/255, blue: 148/255) // Coral
                            )

                            StatisticCard(
                                title: "home.statistics.photos".localized,
                                value: "\(stats.totalPhotos)",
                                icon: "photo.fill",
                                color: Color(red: 184/255, green: 152/255, blue: 156/255) // Rose
                            )
                        }

                        HStack(spacing: 16) {
                            StatisticCard(
                                title: "home.statistics.ratings".localized,
                                value: "\(stats.totalRatings)",
                                icon: "star.fill",
                                color: Color(red: 152/255, green: 161/255, blue: 159/255) // Gray
                            )

                            StatisticCard(
                                title: "home.statistics.events".localized,
                                value: "\(stats.activeEvents)",
                                icon: "calendar.fill",
                                color: Color(red: 94/255, green: 205/255, blue: 200/255) // Turquoise
                            )
                        }
                    }
                } else {
                    // Expanded layout (iPad): single row
                    HStack(spacing: 16) {
                        StatisticCard(
                            title: "home.statistics.users".localized,
                            value: "\(stats.totalUsers)",
                            icon: "person.3.fill",
                            color: Color(red: 255/255, green: 139/255, blue: 148/255) // Coral
                        )

                        StatisticCard(
                            title: "home.statistics.photos".localized,
                            value: "\(stats.totalPhotos)",
                            icon: "photo.fill",
                            color: Color(red: 184/255, green: 152/255, blue: 156/255) // Rose
                        )

                        StatisticCard(
                            title: "home.statistics.ratings".localized,
                            value: "\(stats.totalRatings)",
                            icon: "star.fill",
                            color: Color(red: 152/255, green: 161/255, blue: 159/255) // Gray
                        )

                        StatisticCard(
                            title: "home.statistics.events".localized,
                            value: "\(stats.activeEvents)",
                            icon: "calendar.fill",
                            color: Color(red: 94/255, green: 205/255, blue: 200/255) // Turquoise
                        )
                    }
                }
            }
            .frame(height: 140)
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
                .padding(.horizontal, 20)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(topUserGalleries, id: \.userId) { gallery in
                        RankedUserCard(gallery: gallery)
                            .frame(width: 88)
                    }
                }
                .padding(.horizontal, 4)
            }
            .padding(.horizontal, 20)
        }
    }

    var eventSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            sectionHeader("home.events.title".localized, subtitle: "home.events.subtitle".localized)
                .padding(.horizontal, 20)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(events) { item in
                        EventItemCard(item: item) { }
                            .frame(width: 200)
                            .aspectRatio(9/16, contentMode: .fit)
                    }
                }
                .padding(.horizontal, 4)
            }
            .padding(.horizontal, 20)
        }
    }

    var divider: some View {
        Rectangle()
            .fill(
                LinearGradient(
                    colors: [
                        Color.clear,
                        Color.white.opacity(0.15),
                        Color.clear
                    ],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .frame(height: 1)
            .padding(.horizontal, 20)
    }

    func sectionHeader(_ title: String, subtitle: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.system(size: 22, weight: .bold))
                .foregroundStyle(
                    LinearGradient(
                        colors: [
                            Color(red: 255/255, green: 139/255, blue: 148/255),
                            Color.white
                        ],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
            Text(subtitle)
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(.white.opacity(0.7))
        }
    }
}


