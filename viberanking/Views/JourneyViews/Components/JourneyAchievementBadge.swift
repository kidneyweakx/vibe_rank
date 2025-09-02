//
//  JourneyAchievementBadge.swift
//  viberanking
//
//  Created by Assistant on 2025/09/02.
//

import SwiftUI

struct JourneyAchievementBadge: View {
    let level: JourneyLevel
    let overallPerformance: Double

    var body: some View {
        HStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [level.color.opacity(0.85), level.color.opacity(0.45)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 60, height: 60)

                Image(systemName: level.icon)
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(.white)
            }

            VStack(alignment: .leading, spacing: 6) {
                Text(level.titleLocalized)
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.white)

                Text(level.subtitleLocalized)
                    .font(.subheadline)
                    .foregroundColor(.gray)

                HStack(spacing: 6) {
                    Image(systemName: "chart.line.uptrend.xyaxis")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(level.color)
                    Text("\(Int(overallPerformance))")
                        .font(.caption)
                        .foregroundColor(level.color)
                }
            }

            Spacer()
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.gray.opacity(0.1))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(level.color.opacity(0.3), lineWidth: 1)
                )
        )
        .padding(.horizontal, 20)
    }
}


