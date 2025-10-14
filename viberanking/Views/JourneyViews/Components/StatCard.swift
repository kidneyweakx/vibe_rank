//
//  StatCard.swift
//  viberanking
//
//  Shared statistic card used across Journey views.
//  Redesigned to match HomeView style (simple dark gray cards with colored accents)
//

import SwiftUI

struct StatCards: View {
    let title: String
    let value: String
    let color: Color
    let icon: String

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            // Icon with colored background circle (like HomeView StatisticCard)
            ZStack {
                Circle()
                    .fill(color.opacity(0.2))
                    .frame(width: 44, height: 44)

                Image(systemName: icon)
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(color)
            }

            Spacer()

            // Value - Large and bold white text for WCAG compliance
            Text(value)
                .font(.system(size: 24, weight: .bold))
                .foregroundColor(.white)

            // Title - Secondary text with sufficient contrast (0.8 opacity)
            Text(title)
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(.white.opacity(0.8))
                .multilineTextAlignment(.leading)
                .lineLimit(2)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(
            // Simple dark gray background (matching HomeView)
            RoundedRectangle(cornerRadius: 14)
                .fill(Color(red: 0.1, green: 0.1, blue: 0.1))
                .overlay(
                    // Subtle colored border
                    RoundedRectangle(cornerRadius: 14)
                        .stroke(color.opacity(0.3), lineWidth: 1.5)
                )
        )
    }
}


