//
//  JourneyStatCards.swift
//  viberanking
//
//  Created by Assistant on 2025/09/02.
//

import SwiftUI

struct JourneyStatCards: View {
    let overallPerformance: Double
    let femaleAttraction: Double
    let maleAttraction: Double
    let currentRankPercentage: String
    let totalUsers: String

    var body: some View {
        VStack(spacing: 16) {
            StatCards(
                title: "journey.stats.overall_performance".localized,
                value: String(format: "%.0f%%", max(0, min(100, overallPerformance))),
                color: Color(red: 94/255, green: 205/255, blue: 200/255), // Turquoise
                icon: "chart.line.uptrend.xyaxis"
            )

            HStack(spacing: 16) {
                StatCards(
                    title: "journey.stats.female_attraction".localized,
                    value: String(format: "%.0f%%", max(0, min(100, femaleAttraction))),
                    color: Color(red: 255/255, green: 139/255, blue: 148/255), // Coral
                    icon: "heart.fill"
                )
                StatCards(
                    title: "journey.stats.male_attraction".localized,
                    value: String(format: "%.0f%%", max(0, min(100, maleAttraction))),
                    color: Color(red: 152/255, green: 161/255, blue: 159/255), // Gray
                    icon: "star.fill"
                )
            }

            // Rank block
            VStack(spacing: 12) {
                HStack {
                    Image(systemName: "trophy.fill")
                        .foregroundStyle(
                            LinearGradient(
                                colors: [
                                    Color(red: 255/255, green: 139/255, blue: 148/255),
                                    Color(red: 94/255, green: 205/255, blue: 200/255)
                                ],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                    Text("journey.stats.current_percentage".localized)
                        .font(.headline)
                        .foregroundColor(.white)
                    Spacer()
                }

                HStack {
                    VStack(alignment: .leading) {
                        Text("journey.stats.your_ranking".localized)
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.6))
                        Text(currentRankPercentage)
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [
                                        Color(red: 255/255, green: 139/255, blue: 148/255),
                                        Color(red: 94/255, green: 205/255, blue: 200/255)
                                    ],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                    }

                    Spacer()

                    VStack(alignment: .trailing) {
                        Text("journey.stats.total_users".localized)
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.6))
                        Text(totalUsers)
                            .font(.title3)
                            .fontWeight(.semibold)
                            .foregroundColor(.white)
                    }
                }
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(
                        LinearGradient(
                            colors: [Color.white.opacity(0.08), Color.white.opacity(0.03)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 14)
                            .stroke(
                                LinearGradient(
                                    colors: [
                                        Color(red: 255/255, green: 139/255, blue: 148/255).opacity(0.3),
                                        Color(red: 94/255, green: 205/255, blue: 200/255).opacity(0.3)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 1
                            )
                    )
            )
        }
        .padding(.horizontal, 20)
    }
}


