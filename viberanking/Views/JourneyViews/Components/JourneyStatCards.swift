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
                title: "整體表現",
                value: String(format: "%.0f%%", max(0, min(100, overallPerformance))),
                color: .cyan,
                icon: "chart.line.uptrend.xyaxis"
            )

            HStack(spacing: 16) {
                StatCards(
                    title: "女性吸引力",
                    value: String(format: "%.1f", max(0, min(10, femaleAttraction / 10))),
                    color: .pink,
                    icon: "heart.fill"
                )
                StatCards(
                    title: "男性吸引力",
                    value: String(format: "%.1f", max(0, min(10, maleAttraction / 10))),
                    color: .blue,
                    icon: "star.fill"
                )
            }

            // Rank block
            VStack(spacing: 12) {
                HStack {
                    Image(systemName: "trophy.fill")
                        .foregroundColor(.yellow)
                    Text("目前趴數")
                        .font(.headline)
                        .foregroundColor(.white)
                    Spacer()
                }

                HStack {
                    VStack(alignment: .leading) {
                        Text("你的排名")
                            .font(.caption)
                            .foregroundColor(.gray)
                        Text(currentRankPercentage)
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.yellow)
                    }

                    Spacer()

                    VStack(alignment: .trailing) {
                        Text("總用戶")
                            .font(.caption)
                            .foregroundColor(.gray)
                        Text(totalUsers)
                            .font(.title3)
                            .foregroundColor(.white)
                    }
                }
            }
            .padding(16)
            .background(RoundedRectangle(cornerRadius: 16).fill(Color.gray.opacity(0.1)))
        }
        .padding(.horizontal, 20)
    }
}


