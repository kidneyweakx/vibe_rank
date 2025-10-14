//
//  JourneyStatCards.swift
//  viberanking
//
//  Redesigned with weekly change indicators
//

import SwiftUI

struct JourneyStatCards: View {
    let femaleAttraction: Double
    let maleAttraction: Double
    let femaleChange: Double // Weekly change
    let maleChange: Double   // Weekly change
    let currentRankPercentage: String
    let totalUsers: String

    // Black-Red theme
    private let primaryRed = Color(red: 255/255, green: 0/255, blue: 92/255) // #FF005C
    private let lightRed = Color(red: 255/255, green: 100/255, blue: 120/255) // Lighter red
    private let darkRed = Color(red: 200/255, green: 0/255, blue: 70/255) // Darker red

    var body: some View {
        VStack(spacing: 16) {
            // Gender attraction - Two cards side by side with weekly change
            HStack(spacing: 16) {
                GenderAttractionCard(
                    title: "journey.stats.female_attraction".localized,
                    value: femaleAttraction,
                    weeklyChange: femaleChange,
                    color: lightRed,
                    icon: "heart.fill"
                )

                GenderAttractionCard(
                    title: "journey.stats.male_attraction".localized,
                    value: maleAttraction,
                    weeklyChange: maleChange,
                    color: darkRed,
                    icon: "star.fill"
                )
            }

            // Ranking card - Black-red theme
            VStack(spacing: 12) {
                HStack {
                    Image(systemName: "trophy.fill")
                        .foregroundColor(primaryRed)
                        .font(.system(size: 16, weight: .semibold))

                    Text("journey.stats.current_percentage".localized)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white)

                    Spacer()
                }

                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("journey.stats.your_ranking".localized)
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(.white.opacity(0.7))
                        Text(currentRankPercentage)
                            .font(.system(size: 22, weight: .bold))
                            .foregroundColor(.white)
                    }

                    Spacer()

                    VStack(alignment: .trailing, spacing: 4) {
                        Text("journey.stats.total_users".localized)
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(.white.opacity(0.7))
                        Text(totalUsers)
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(.white.opacity(0.9))
                    }
                }
            }
            .padding(16)
            .background(
                // Black-red theme card
                RoundedRectangle(cornerRadius: 14)
                    .fill(Color(red: 0.1, green: 0.1, blue: 0.1))
                    .overlay(
                        RoundedRectangle(cornerRadius: 14)
                            .stroke(primaryRed.opacity(0.4), lineWidth: 1.5)
                    )
            )
        }
        // Padding removed - will be handled by parent JourneyTabView
    }
}

// MARK: - Gender Attraction Card with Weekly Change
struct GenderAttractionCard: View {
    let title: String
    let value: Double
    let weeklyChange: Double
    let color: Color
    let icon: String

    var isPositive: Bool {
        weeklyChange > 0
    }

    var body: some View {
        VStack(spacing: 10) {
            // Icon with background circle
            ZStack {
                Circle()
                    .fill(color.opacity(0.2))
                    .frame(width: 48, height: 48)

                Image(systemName: icon)
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundColor(color)
            }

            Spacer()

            // Value
            Text(String(format: "%.0f", value))
                .font(.system(size: 26, weight: .bold))
                .foregroundColor(.white)

            // Weekly change indicator
            if weeklyChange != 0 {
                HStack(spacing: 3) {
                    Image(systemName: isPositive ? "arrow.up" : "arrow.down")
                        .font(.system(size: 9, weight: .bold))
                    Text(String(format: "%.1f", abs(weeklyChange)))
                        .font(.system(size: 11, weight: .semibold))
                }
                .foregroundColor(isPositive ? color : .white.opacity(0.5))
            } else {
                Text("—")
                    .font(.system(size: 11))
                    .foregroundColor(.white.opacity(0.5))
            }

            // Title
            Text(title)
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(.white.opacity(0.8))
                .multilineTextAlignment(.center)
                .lineLimit(2)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 18)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(Color(red: 0.1, green: 0.1, blue: 0.1))
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .stroke(color.opacity(0.3), lineWidth: 1.5)
                )
        )
    }
}


