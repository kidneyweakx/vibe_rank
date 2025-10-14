//
//  JourneyAchievementBadge.swift
//  viberanking
//
//  Redesigned to match HomeView style (simple and clean)
//

import SwiftUI

struct JourneyAchievementBadge: View {
    let level: JourneyLevel
    let overallPerformance: Double

    // Black-Red theme
    private let primaryRed = Color(red: 255/255, green: 0/255, blue: 92/255) // #FF005C

    var body: some View {
        HStack(spacing: 16) {
            // Red icon with background
            ZStack {
                Circle()
                    .fill(primaryRed.opacity(0.2))
                    .frame(width: 64, height: 64)

                Image(systemName: level.icon)
                    .font(.system(size: 28, weight: .semibold))
                    .foregroundColor(primaryRed)
            }

            VStack(alignment: .leading, spacing: 6) {
                // Simple white text (WCAG compliant)
                Text(level.titleLocalized)
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(.white)

                Text(level.subtitleLocalized)
                    .font(.system(size: 14))
                    .foregroundColor(.white.opacity(0.8))

                // Performance indicator - red theme
                HStack(spacing: 6) {
                    Image(systemName: "chart.line.uptrend.xyaxis")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(primaryRed)
                    Text("\(Int(overallPerformance))%")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(primaryRed)
                }
            }

            Spacer()
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
        // Padding removed - handled by parent
    }
}


