//
//  JourneyTrendChart.swift
//  viberanking
//
//  Created by Assistant on 2025/09/02.
//

import SwiftUI

struct JourneyTrendChart: View {
    let data: [ChartDataPoint]

    var body: some View {
        VStack(spacing: 16) {
            // Header
            HStack {
                Label("journey.trend.title".localized, systemImage: "chart.line.uptrend.xyaxis")
                    .labelStyle(IconTitleLabelStyle())
                    .foregroundColor(.white)
                Spacer()
                Text("journey.trend.range_7d".localized)
                    .font(.caption)
                    .foregroundColor(.gray)
            }
            .padding(.horizontal, 20)

            // Line Chart
            VStack(spacing: 12) {
                GeometryReader { geo in
                    ZStack {
                        // Grid
                        gridBackground(in: geo.size)

                        // Area fill under line
                        lineAreaPath(in: geo.size)
                            .fill(
                                LinearGradient(
                                    colors: [Color.blue.opacity(0.35), Color.purple.opacity(0.12)],
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            )

                        // Line stroke
                        linePath(in: geo.size)
                            .stroke(
                                LinearGradient(
                                    colors: [Color.blue, Color.purple],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                ),
                                style: StrokeStyle(lineWidth: 3, lineCap: .round, lineJoin: .round)
                            )
                            .shadow(color: Color.purple.opacity(0.25), radius: 8, x: 0, y: 6)

                        // Points
                        pointsOverlay(in: geo.size)
                    }
                }
                .frame(height: 200)
                .padding(.horizontal, 16)

                // Trend note
                HStack(spacing: 8) {
                    Image(systemName: "arrow.up.right")
                        .font(.caption)
                        .foregroundColor(.green)
                    Text("journey.trend.overall_up".localized)
                        .font(.caption)
                        .foregroundColor(.green)
                    Spacer()
                }
                .padding(.horizontal, 16)
            }
            .padding(.vertical, 16)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.gray.opacity(0.05))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(Color.gray.opacity(0.1), lineWidth: 1)
                    )
            )
            .padding(.horizontal, 20)
        }
    }

    // MARK: - Drawing Helpers

    private func normalizedPoints(in size: CGSize) -> [CGPoint] {
        guard !data.isEmpty else { return [] }
        let padding: CGFloat = 4
        let width = max(1, size.width - padding * 2)
        let height = max(1, size.height - padding * 2)

        let maxScore: Double = 100
        let minScore: Double = 0
        let count = data.count
        let stepX = width / CGFloat(max(count - 1, 1))

        return data.enumerated().map { (idx, point) in
            let x = padding + CGFloat(idx) * stepX
            let clamped = max(minScore, min(maxScore, point.score))
            let yRatio = (clamped - minScore) / (maxScore - minScore)
            let y = padding + height * CGFloat(1.0 - yRatio)
            return CGPoint(x: x, y: y)
        }
    }

    private func linePath(in size: CGSize) -> Path {
        var path = Path()
        let pts = normalizedPoints(in: size)
        guard let first = pts.first else { return path }
        path.move(to: first)
        for p in pts.dropFirst() { path.addLine(to: p) }
        return path
    }

    private func lineAreaPath(in size: CGSize) -> Path {
        var path = Path()
        let pts = normalizedPoints(in: size)
        guard let first = pts.first, let last = pts.last else { return path }
        path.move(to: CGPoint(x: first.x, y: size.height))
        path.addLine(to: first)
        for p in pts.dropFirst() { path.addLine(to: p) }
        path.addLine(to: CGPoint(x: last.x, y: size.height))
        path.closeSubpath()
        return path
    }

    private func pointsOverlay(in size: CGSize) -> some View {
        let pts = normalizedPoints(in: size)
        return ZStack {
            ForEach(Array(pts.enumerated()), id: \.offset) { idx, p in
                Circle()
                    .fill(Color.white)
                    .frame(width: 6, height: 6)
                    .position(p)
                    .shadow(color: Color.black.opacity(0.25), radius: 3, x: 0, y: 2)
                    .overlay(
                        Circle()
                            .stroke(Color.white.opacity(0.6), lineWidth: 1)
                            .frame(width: 10, height: 10)
                            .position(p)
                    )
                    .animation(.spring(response: 0.6, dampingFraction: 0.8).delay(Double(idx) * 0.05), value: p)
            }
        }
    }

    private func gridBackground(in size: CGSize) -> some View {
        let rows = 4
        return ZStack {
            ForEach(0...rows, id: \.self) { i in
                let y = size.height * CGFloat(i) / CGFloat(rows)
                Path { p in
                    p.move(to: CGPoint(x: 0, y: y))
                    p.addLine(to: CGPoint(x: size.width, y: y))
                }
                .stroke(Color.white.opacity(0.06), lineWidth: 1)
            }
        }
    }
}

// Icon+Title label style to unify with RatingTabView aesthetics
struct IconTitleLabelStyle: LabelStyle {
    func makeBody(configuration: Configuration) -> some View {
        HStack(spacing: 8) {
            configuration.icon
                .foregroundColor(.white)
            configuration.title
                .font(.headline)
        }
    }
}


