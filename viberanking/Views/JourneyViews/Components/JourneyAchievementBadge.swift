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
                            colors: [
                                Color(red: 255/255, green: 139/255, blue: 148/255).opacity(0.85),
                                Color(red: 94/255, green: 205/255, blue: 200/255).opacity(0.45)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 64, height: 64)
                    .shadow(color: Color(red: 94/255, green: 205/255, blue: 200/255).opacity(0.4), radius: 12, x: 0, y: 4)

                Image(systemName: level.icon)
                    .font(.system(size: 26, weight: .bold))
                    .foregroundColor(.white)
            }

            VStack(alignment: .leading, spacing: 6) {
                Text(level.titleLocalized)
                    .font(.title2)
                    .fontWeight(.bold)
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

                Text(level.subtitleLocalized)
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.7))

                HStack(spacing: 6) {
                    Image(systemName: "chart.line.uptrend.xyaxis")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(Color(red: 94/255, green: 205/255, blue: 200/255))
                    Text("\(Int(overallPerformance))")
                        .font(.caption)
                        .foregroundColor(Color(red: 94/255, green: 205/255, blue: 200/255))
                }
            }

            Spacer()
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(
                    LinearGradient(
                        colors: [Color.white.opacity(0.08), Color.white.opacity(0.03)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(
                            LinearGradient(
                                colors: [
                                    Color(red: 255/255, green: 139/255, blue: 148/255).opacity(0.3),
                                    Color(red: 94/255, green: 205/255, blue: 200/255).opacity(0.3)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1.5
                        )
                )
        )
        .padding(.horizontal, 20)
    }
}


