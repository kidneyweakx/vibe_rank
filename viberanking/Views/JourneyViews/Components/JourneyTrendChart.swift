//
//  JourneyTrendChart.swift
//  viberanking
//
//  Created by Assistant on 2025/09/02.
//

import SwiftUI

struct JourneyTrendChart: View {
    let data: [ChartDataPoint]

    var averageScore: Double {
        guard !data.isEmpty else { return 0 }
        return data.reduce(0) { $0 + $1.score } / Double(data.count)
    }

    var body: some View {
        VStack(spacing: 16) {
            // Header
            HStack {
                Image(systemName: "chart.pie.fill")
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
                Text("journey.trend.title".localized)
                    .font(.headline)
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
                Spacer()
                Text("journey.trend.range_7d".localized)
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.6))
            }
            .padding(.horizontal, 20)

            // Circular Progress Chart
            VStack(spacing: 20) {
                ZStack {
                    // Background circle
                    Circle()
                        .stroke(
                            Color.white.opacity(0.1),
                            lineWidth: 20
                        )
                        .frame(width: 200, height: 200)

                    // Progress circle
                    Circle()
                        .trim(from: 0, to: min(averageScore / 100, 1.0))
                        .stroke(
                            LinearGradient(
                                colors: [
                                    Color(red: 255/255, green: 139/255, blue: 148/255),
                                    Color(red: 184/255, green: 152/255, blue: 156/255),
                                    Color(red: 152/255, green: 161/255, blue: 159/255),
                                    Color(red: 94/255, green: 205/255, blue: 200/255)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            style: StrokeStyle(lineWidth: 20, lineCap: .round)
                        )
                        .frame(width: 200, height: 200)
                        .rotationEffect(.degrees(-90))
                        .shadow(color: Color(red: 94/255, green: 205/255, blue: 200/255).opacity(0.5), radius: 10, x: 0, y: 0)

                    // Center text
                    VStack(spacing: 4) {
                        Text(String(format: "%.0f", averageScore))
                            .font(.system(size: 56, weight: .bold))
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

                        Text("journey.trend.avg_score".localized)
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.7))
                    }
                }
                .padding(.vertical, 20)

                // Trend indicators
                HStack(spacing: 24) {
                    VStack(spacing: 4) {
                        HStack(spacing: 4) {
                            Image(systemName: "arrow.up.right")
                                .font(.caption2)
                            Text(String(format: "%.0f", data.max(by: { $0.score < $1.score })?.score ?? 0))
                                .font(.system(size: 16, weight: .semibold))
                        }
                        .foregroundColor(Color(red: 94/255, green: 205/255, blue: 200/255))

                        Text("journey.trend.peak".localized)
                            .font(.caption2)
                            .foregroundColor(.white.opacity(0.6))
                    }

                    Rectangle()
                        .fill(Color.white.opacity(0.2))
                        .frame(width: 1, height: 30)

                    VStack(spacing: 4) {
                        HStack(spacing: 4) {
                            Image(systemName: "arrow.down.right")
                                .font(.caption2)
                            Text(String(format: "%.0f", data.min(by: { $0.score < $1.score })?.score ?? 0))
                                .font(.system(size: 16, weight: .semibold))
                        }
                        .foregroundColor(Color(red: 255/255, green: 139/255, blue: 148/255))

                        Text("journey.trend.low".localized)
                            .font(.caption2)
                            .foregroundColor(.white.opacity(0.6))
                    }
                }
            }
            .padding(.vertical, 16)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(
                        LinearGradient(
                            colors: [
                                Color.white.opacity(0.08),
                                Color.white.opacity(0.03)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(
                                LinearGradient(
                                    colors: [
                                        Color(red: 255/255, green: 139/255, blue: 148/255).opacity(0.2),
                                        Color(red: 94/255, green: 205/255, blue: 200/255).opacity(0.2)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 1
                            )
                    )
            )
            .padding(.horizontal, 20)
        }
    }

}


