//
//  JourneyTrendChart.swift
//  viberanking
//
//  Redesigned with curved line chart and black-red theme
//

import SwiftUI

struct JourneyTrendChart: View {
    let data: [ChartDataPoint]

    // Black-Red theme
    private let primaryRed = Color(red: 255/255, green: 0/255, blue: 92/255) // #FF005C

    var averageScore: Double {
        guard !data.isEmpty else { return 0 }
        return data.reduce(0) { $0 + $1.score } / Double(data.count)
    }

    var maxScore: Double {
        data.max(by: { $0.score < $1.score })?.score ?? 0
    }

    var minScore: Double {
        data.min(by: { $0.score < $1.score })?.score ?? 0
    }

    var body: some View {
        VStack(spacing: 12) {
            // Header
            HStack {
                Image(systemName: "chart.xyaxis.line")
                    .foregroundColor(primaryRed)
                    .font(.system(size: 16, weight: .semibold))

                Text("journey.trend.title".localized)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)

                Spacer()

                Text("journey.trend.range_7d".localized)
                    .font(.system(size: 11))
                    .foregroundColor(.white.opacity(0.7))
            }

            // Curved Line Chart
            VStack(spacing: 16) {
                // Chart area
                GeometryReader { geometry in
                    ZStack(alignment: .bottomLeading) {
                        // Background grid lines (subtle)
                        VStack(spacing: 0) {
                            ForEach(0..<5) { i in
                                Divider()
                                    .background(Color.white.opacity(0.05))
                                Spacer()
                            }
                        }

                        // Curved line path
                        if data.count > 1 {
                            CurvedLineShape(dataPoints: normalizedDataPoints(in: geometry.size))
                                .stroke(
                                    LinearGradient(
                                        colors: [
                                            primaryRed,
                                            primaryRed.opacity(0.8)
                                        ],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    ),
                                    style: StrokeStyle(lineWidth: 3, lineCap: .round, lineJoin: .round)
                                )

                            // Fill gradient under curve
                            CurvedLineShape(dataPoints: normalizedDataPoints(in: geometry.size), closePath: true)
                                .fill(
                                    LinearGradient(
                                        colors: [
                                            primaryRed.opacity(0.3),
                                            primaryRed.opacity(0.05),
                                            Color.clear
                                        ],
                                        startPoint: .top,
                                        endPoint: .bottom
                                    )
                                )

                            // Data points
                            ForEach(Array(normalizedDataPoints(in: geometry.size).enumerated()), id: \.offset) { index, point in
                                Circle()
                                    .fill(primaryRed)
                                    .frame(width: 6, height: 6)
                                    .position(point)
                            }
                        } else {
                            // Empty state
                            Text("No data")
                                .font(.system(size: 14))
                                .foregroundColor(.white.opacity(0.5))
                                .frame(maxWidth: .infinity, maxHeight: .infinity)
                        }
                    }
                }
                .frame(height: 160)
                .padding(.horizontal, 12)
                .padding(.vertical, 16)

                // Stats row
                HStack(spacing: 20) {
                    // Average
                    VStack(spacing: 4) {
                        Text(String(format: "%.0f", averageScore))
                            .font(.system(size: 20, weight: .bold))
                            .foregroundColor(.white)
                        Text("journey.trend.avg_score".localized)
                            .font(.system(size: 10))
                            .foregroundColor(.white.opacity(0.7))
                    }
                    .frame(maxWidth: .infinity)

                    Rectangle()
                        .fill(Color.white.opacity(0.15))
                        .frame(width: 1, height: 32)

                    // Peak
                    VStack(spacing: 4) {
                        HStack(spacing: 4) {
                            Image(systemName: "arrow.up.right")
                                .font(.system(size: 10))
                            Text(String(format: "%.0f", maxScore))
                                .font(.system(size: 15, weight: .semibold))
                        }
                        .foregroundColor(primaryRed)

                        Text("journey.trend.peak".localized)
                            .font(.system(size: 10))
                            .foregroundColor(.white.opacity(0.7))
                    }
                    .frame(maxWidth: .infinity)

                    Rectangle()
                        .fill(Color.white.opacity(0.15))
                        .frame(width: 1, height: 32)

                    // Low
                    VStack(spacing: 4) {
                        HStack(spacing: 4) {
                            Image(systemName: "arrow.down.right")
                                .font(.system(size: 10))
                            Text(String(format: "%.0f", minScore))
                                .font(.system(size: 15, weight: .semibold))
                        }
                        .foregroundColor(.white.opacity(0.7))

                        Text("journey.trend.low".localized)
                            .font(.system(size: 10))
                            .foregroundColor(.white.opacity(0.7))
                    }
                    .frame(maxWidth: .infinity)
                }
                .padding(.bottom, 8)
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(Color(red: 0.1, green: 0.1, blue: 0.1))
                    .overlay(
                        RoundedRectangle(cornerRadius: 14)
                            .stroke(primaryRed.opacity(0.3), lineWidth: 1.5)
                    )
            )
        }
    }

    // Normalize data points to fit in the chart area
    private func normalizedDataPoints(in size: CGSize) -> [CGPoint] {
        guard !data.isEmpty else { return [] }

        let maxValue = data.map { $0.score }.max() ?? 100
        let minValue = data.map { $0.score }.min() ?? 0
        let range = maxValue - minValue

        let padding: CGFloat = 20
        let chartWidth = size.width - padding * 2
        let chartHeight = size.height - padding * 2

        return data.enumerated().map { index, point in
            let x = padding + (chartWidth / CGFloat(max(data.count - 1, 1))) * CGFloat(index)
            let normalizedValue = range > 0 ? (point.score - minValue) / range : 0.5
            let y = size.height - padding - (chartHeight * normalizedValue)
            return CGPoint(x: x, y: y)
        }
    }
}

// Curved line shape using quadratic bezier curves
struct CurvedLineShape: Shape {
    let dataPoints: [CGPoint]
    let closePath: Bool

    init(dataPoints: [CGPoint], closePath: Bool = false) {
        self.dataPoints = dataPoints
        self.closePath = closePath
    }

    func path(in rect: CGRect) -> Path {
        var path = Path()
        guard dataPoints.count > 1 else { return path }

        path.move(to: dataPoints[0])

        for i in 0..<dataPoints.count - 1 {
            let current = dataPoints[i]
            let next = dataPoints[i + 1]

            // Calculate control points for smooth curve
            let controlPointX = (current.x + next.x) / 2
            let controlPoint1 = CGPoint(x: controlPointX, y: current.y)
            let controlPoint2 = CGPoint(x: controlPointX, y: next.y)

            path.addCurve(to: next, control1: controlPoint1, control2: controlPoint2)
        }

        // Close path for fill gradient
        if closePath, let last = dataPoints.last, let first = dataPoints.first {
            path.addLine(to: CGPoint(x: last.x, y: rect.maxY))
            path.addLine(to: CGPoint(x: first.x, y: rect.maxY))
            path.closeSubpath()
        }

        return path
    }
}


