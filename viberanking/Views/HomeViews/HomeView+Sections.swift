import SwiftUI

// MARK: - Sections
extension HomeView {
    var announcementsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Announcements")
                .font(.system(size: 20, weight: .semibold))
                .foregroundColor(.white)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 16) {
                    ForEach(announcements, id: \.id) { announcement in
                        AnnouncementCard(announcement: announcement)
                            .frame(width: 280)
                    }
                }
                .padding(.horizontal, 20)
            }
        }
    }
    
    func statisticsSection(_ stats: HomeStatistics) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Community Stats")
                .font(.system(size: 20, weight: .semibold))
                .foregroundColor(.white)
                .padding(.horizontal, 20)

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
                                color: Color(red: 255/255, green: 0/255, blue: 92/255) // Primary red
                            )

                            StatisticCard(
                                title: "home.statistics.photos".localized,
                                value: "\(stats.totalPhotos)",
                                icon: "photo.fill",
                                color: Color.white
                            )
                        }

                        HStack(spacing: 16) {
                            StatisticCard(
                                title: "home.statistics.ratings".localized,
                                value: "\(stats.totalRatings)",
                                icon: "star.fill",
                                color: Color.white
                            )

                            StatisticCard(
                                title: "home.statistics.events".localized,
                                value: "\(stats.activeEvents)",
                                icon: "calendar.fill",
                                color: Color(red: 255/255, green: 0/255, blue: 92/255) // Primary red
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
                            color: Color(red: 255/255, green: 0/255, blue: 92/255) // Primary red
                        )

                        StatisticCard(
                            title: "home.statistics.photos".localized,
                            value: "\(stats.totalPhotos)",
                            icon: "photo.fill",
                            color: Color.white
                        )

                        StatisticCard(
                            title: "home.statistics.ratings".localized,
                            value: "\(stats.totalRatings)",
                            icon: "star.fill",
                            color: Color.white
                        )

                        StatisticCard(
                            title: "home.statistics.events".localized,
                            value: "\(stats.activeEvents)",
                            icon: "calendar.fill",
                            color: Color(red: 255/255, green: 0/255, blue: 92/255) // Primary red
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
    
    var topCreatorsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Top Creators")
                .font(.system(size: 20, weight: .semibold))
                .foregroundColor(.white)
                .padding(.horizontal, 20)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 16) {
                    ForEach(Array(topUserGalleries.prefix(5).enumerated()), id: \.element.userId) { index, gallery in
                        VStack(spacing: 8) {
                            ZStack(alignment: .bottomTrailing) {
                                // Hexagon image
                                if let avatarURL = gallery.avatarURL, let url = URL(string: avatarURL) {
                                    AsyncImage(url: url) { phase in
                                        switch phase {
                                        case .success(let image):
                                            image
                                                .resizable()
                                                .scaledToFill()
                                                .frame(width: 80, height: 80)
                                                .clipShape(Hexagon())
                                        case .failure:
                                            Hexagon()
                                                .fill(Color.gray.opacity(0.3))
                                                .frame(width: 80, height: 80)
                                                .overlay(
                                                    Image(systemName: "person.fill")
                                                        .foregroundColor(.gray)
                                                        .font(.system(size: 28))
                                                )
                                        case .empty:
                                            Hexagon()
                                                .fill(Color.gray.opacity(0.3))
                                                .frame(width: 80, height: 80)
                                                .overlay(
                                                    ProgressView()
                                                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                                )
                                        @unknown default:
                                            Hexagon()
                                                .fill(Color.gray.opacity(0.3))
                                                .frame(width: 80, height: 80)
                                                .overlay(
                                                    Image(systemName: "person.fill")
                                                        .foregroundColor(.gray)
                                                )
                                        }
                                    }
                                } else {
                                    // No avatar URL
                                    Hexagon()
                                        .fill(Color.gray.opacity(0.3))
                                        .frame(width: 80, height: 80)
                                        .overlay(
                                            Image(systemName: "person.fill")
                                                .foregroundColor(.white.opacity(0.5))
                                                .font(.system(size: 28))
                                        )
                                }

                                // Rank badge
                                Circle()
                                    .fill(index == 0 ? Color(red: 255/255, green: 0/255, blue: 92/255) : Color.gray)
                                    .frame(width: 24, height: 24)
                                    .overlay(
                                        Text("\(index + 1)")
                                            .font(.system(size: 11, weight: .bold))
                                            .foregroundColor(.white)
                                    )
                                    .offset(x: 8, y: 8)
                            }

                            Text(gallery.name)
                                .font(.system(size: 13, weight: .medium))
                                .foregroundColor(.white)
                                .lineLimit(1)
                        }
                        .frame(width: 90)
                    }
                }
                .padding(.horizontal, 24)
            }
        }
    }

    var upcomingEventsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Upcoming Events")
                .font(.system(size: 20, weight: .semibold))
                .foregroundColor(.white)
                .padding(.horizontal, 24)

            EventCardStack(events: events)
                .frame(height: 500)
                .padding(.horizontal, 20)
        }
    }

    var divider: some View {
        Rectangle()
            .fill(Color.white.opacity(0.1))
            .frame(height: 1)
            .padding(.horizontal, 20)
    }

    func sectionHeader(_ title: String, subtitle: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.system(size: 20, weight: .semibold))
                .foregroundColor(.white)
            Text(subtitle)
                .font(.system(size: 13, weight: .regular))
                .foregroundColor(.white.opacity(0.6))
        }
    }
}


