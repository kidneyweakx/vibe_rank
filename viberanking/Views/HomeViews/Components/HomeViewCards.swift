//
//  HomeViewCards.swift
//  viberanking
//
//  Created by Kiro on 2025/01/27.
//

import SwiftUI

// MARK: - Announcement Card
struct AnnouncementCard: View {
    let announcement: Announcement
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: iconForType(announcement.type))
                    .foregroundColor(colorForType(announcement.type))
                    .font(.system(size: 16, weight: .semibold))
                
                Text(announcement.title)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)
                    .lineLimit(1)
                
                Spacer()
            }
            
            Text(announcement.message)
                .font(.system(size: 14))
                .foregroundColor(.white.opacity(0.8))
                .lineLimit(3)
                .multilineTextAlignment(.leading)
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(colorForType(announcement.type).opacity(0.1))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(colorForType(announcement.type).opacity(0.3), lineWidth: 1)
                )
        )
    }
    
    private func iconForType(_ type: AnnouncementType) -> String {
        switch type {
        case .info: return "info.circle.fill"
        case .warning: return "exclamationmark.triangle.fill"
        case .success: return "checkmark.circle.fill"
        case .event: return "calendar.badge.plus"
        }
    }
    
    private func colorForType(_ type: AnnouncementType) -> Color {
        switch type {
        case .info: return .blue
        case .warning: return .orange
        case .success: return .green
        case .event: return .purple
        }
    }
}

// MARK: - Statistic Card
struct StatisticCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color

    var body: some View {
        VStack(spacing: 10) {
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [color.opacity(0.3), color.opacity(0.1)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 48, height: 48)

                Image(systemName: icon)
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundColor(color)
            }

            Text(value)
                .font(.system(size: 22, weight: .bold))
                .foregroundColor(.white)

            Text(title)
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(.white.opacity(0.7))
                .multilineTextAlignment(.center)
                .lineLimit(2)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(
                    LinearGradient(
                        colors: [Color.white.opacity(0.08), Color.white.opacity(0.03)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .shadow(color: color.opacity(0.2), radius: 8, x: 0, y: 4)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(
                            LinearGradient(
                                colors: [color.opacity(0.3), color.opacity(0.1)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1
                        )
                )
        )
    }
}

// MARK: - Featured User Card
struct FeaturedUserCard: View {
    let user: FeaturedUser
    
    var body: some View {
        VStack(spacing: 8) {
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [Color.pink.opacity(0.8), Color.purple.opacity(0.6)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 60, height: 60)
                
                if let avatarURL = user.avatar, let url = URL(string: avatarURL) {
                    AsyncImage(url: url) { image in
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    } placeholder: {
                        Image(systemName: "person.fill")
                            .font(.system(size: 24))
                            .foregroundColor(.white)
                    }
                    .frame(width: 60, height: 60)
                    .clipShape(Circle())
                } else {
                    Image(systemName: "person.fill")
                        .font(.system(size: 24))
                        .foregroundColor(.white)
                }
                
                if user.isRising {
                    VStack {
                        Spacer()
                        HStack {
                            Spacer()
                            Image(systemName: "arrow.up.right.circle.fill")
                                .font(.system(size: 16))
                                .foregroundColor(.green)
                                .background(Circle().fill(Color.black))
                        }
                    }
                    .frame(width: 60, height: 60)
                }
            }
            
            VStack(spacing: 2) {
                Text(user.name)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(.white)
                    .lineLimit(1)
                
                Text("#\(user.rank)")
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(.yellow)
                
                Text(String(format: "%.1f", user.score))
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(.white.opacity(0.7))
            }
        }
        .frame(width: 100)
    }
}

// MARK: - Trending Event Card
struct TrendingEventCard: View {
    let event: TrendingEvent
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            ZStack {
                // Background image
                if let url = URL(string: event.imageURL) {
                    AsyncImage(url: url) { image in
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    } placeholder: {
                        Rectangle()
                            .fill(
                                LinearGradient(
                                    colors: [Color.purple.opacity(0.6), Color.pink.opacity(0.4)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                    }
                } else {
                    Rectangle()
                        .fill(
                            LinearGradient(
                                colors: [Color.purple.opacity(0.6), Color.pink.opacity(0.4)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                }
                
                // Gradient overlay
                LinearGradient(
                    colors: [Color.clear, Color.black.opacity(0.8)],
                    startPoint: .top,
                    endPoint: .bottom
                )
                
                // Content
                VStack(alignment: .leading, spacing: 8) {
                    Spacer()
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text(event.title)
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(.white)
                            .lineLimit(2)
                            .multilineTextAlignment(.leading)
                        
                        if let description = event.description {
                            Text(description)
                                .font(.system(size: 12))
                                .foregroundColor(.white.opacity(0.8))
                                .lineLimit(2)
                                .multilineTextAlignment(.leading)
                        }
                        
                        HStack {
                            Image(systemName: "person.3.fill")
                                .font(.system(size: 12))
                                .foregroundColor(.white.opacity(0.7))
                            
                            Text("\(event.participantCount)")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(.white.opacity(0.7))
                            
                            Spacer()
                            
                            if event.isActive {
                                Text("home.event.active".localized)
                                    .font(.system(size: 10, weight: .semibold))
                                    .foregroundColor(.green)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(
                                        RoundedRectangle(cornerRadius: 8)
                                            .fill(Color.green.opacity(0.2))
                                    )
                            }
                        }
                    }
                }
                .padding(16)
            }
        }
        .buttonStyle(PlainButtonStyle())
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}
