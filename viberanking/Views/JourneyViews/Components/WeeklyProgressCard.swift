//
//  WeeklyProgressCard.swift
//  viberanking
//
//  本週戰績卡片 - Journey Page 的核心激勵組件
//

import SwiftUI

struct WeeklyProgressCard: View {
    let scoreChange: Double
    let currentScore: Double
    let lastScore: Double
    let rankChange: Int
    let newRatings: Int

    // Black-Red theme
    private let primaryRed = Color(red: 255/255, green: 0/255, blue: 92/255) // #FF005C

    var isPositiveChange: Bool {
        scoreChange > 0
    }

    var changeColor: Color {
        isPositiveChange ? primaryRed : .white.opacity(0.5)
    }

    var body: some View {
        VStack(spacing: 20) {
            // Header
            HStack {
                Text("journey.weekly_progress.title".localized)
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(.white)
                Spacer()
                Image(systemName: isPositiveChange ? "flame.fill" : "chart.line.flattrend.xyaxis")
                    .foregroundColor(isPositiveChange ? primaryRed : .white.opacity(0.5))
                    .font(.system(size: 20))
            }

            // Main score change - HUGE
            VStack(spacing: 8) {
                HStack(alignment: .firstTextBaseline, spacing: 8) {
                    // Giant score change
                    Text(scoreChange >= 0 ? "+\(String(format: "%.1f", abs(scoreChange)))" : "\(String(format: "%.1f", scoreChange))")
                        .font(.system(size: 72, weight: .bold))
                        .foregroundColor(changeColor)

                    // Label
                    VStack(alignment: .leading, spacing: 2) {
                        Text("journey.weekly_progress.points".localized)
                            .font(.system(size: 18, weight: .medium))
                            .foregroundColor(.white)
                        Text("journey.weekly_progress.this_week_improvement".localized)
                            .font(.system(size: 12))
                            .foregroundColor(.white.opacity(0.7))
                    }
                }

                // Score comparison arrow
                HStack(spacing: 12) {
                    Text(String(format: "%.1f", lastScore))
                        .font(.system(size: 24, weight: .semibold))
                        .foregroundColor(.white.opacity(0.5))

                    Image(systemName: isPositiveChange ? "arrow.right" : "arrow.forward")
                        .foregroundColor(changeColor)
                        .font(.system(size: 18, weight: .bold))

                    Text(String(format: "%.1f", currentScore))
                        .font(.system(size: 28, weight: .bold))
                        .foregroundColor(.white)
                }
            }

            // Divider
            Divider().background(Color.white.opacity(0.1))

            // Other achievements (neutralized)
            VStack(alignment: .leading, spacing: 8) {
                // Removed rank change messaging to avoid comparative framing

                // New ratings
                if newRatings > 0 {
                    HStack {
                        Image(systemName: "hand.thumbsup.fill")
                            .foregroundColor(primaryRed)
                        Text(String(format: "journey.weekly_progress.new_ratings".localized, newRatings))
                            .foregroundColor(.white.opacity(0.9))
                    }
                }

                // Empty state message
                if newRatings == 0 {
                    HStack {
                        Image(systemName: "sparkles")
                            .foregroundColor(.white.opacity(0.5))
                        Text("journey.weekly_progress.keep_going".localized)
                            .foregroundColor(.white.opacity(0.7))
                    }
                }
            }
            .font(.system(size: 14, weight: .medium))
        }
        .padding(24)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(red: 0.1, green: 0.1, blue: 0.1))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(
                            LinearGradient(
                                colors: [
                                    isPositiveChange ? primaryRed : Color.white.opacity(0.2),
                                    isPositiveChange ? primaryRed.opacity(0.3) : Color.white.opacity(0.1)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: isPositiveChange ? 2 : 1
                        )
                )
        )
    }
}

#Preview {
    VStack(spacing: 20) {
        // Positive change
        WeeklyProgressCard(
            scoreChange: 5.3,
            currentScore: 83.2,
            lastScore: 77.9,
            rankChange: 12,
            newRatings: 89
        )
        .padding()

        // Negative change
        WeeklyProgressCard(
            scoreChange: -2.1,
            currentScore: 75.8,
            lastScore: 77.9,
            rankChange: -5,
            newRatings: 23
        )
        .padding()
    }
    .background(Color.black)
}
