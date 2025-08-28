//
//  OnboardingStepValue.swift
//  viberanking
//
//  Created by AI Assistant on 2025/08/28.
//

import SwiftUI

struct OnboardingStepValue: View {
    let next: () -> Void
    let back: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(alignment: .leading, spacing: 22) {
                    // Simple placeholder charts
                    HStack(spacing: 16) {
                        GrowthChartView(title: "onb.value.chart.growth".localized(table: "Onboarding"))
                        SpendChartView(title: "onb.value.chart.spend".localized(table: "Onboarding"))
                    }
                    .frame(height: 160)

                    Group {
                        Text("onb.value.p1".localized(table: "Onboarding"))
                        Text("onb.value.p2".localized(table: "Onboarding"))
                        Text("onb.value.p3".localized(table: "Onboarding"))
                        Text("onb.value.p4".localized(table: "Onboarding"))
                        Text("onb.value.p5".localized(table: "Onboarding"))
                        Text("onb.value.p6".localized(table: "Onboarding"))
                    }
                    .font(.system(size: 16))
                    .foregroundColor(.white.opacity(0.8))
                }
                .padding(24)
            }

            HStack(spacing: 12) {
                Button(action: back) {
                    Text("common.back".localized(table: "Onboarding"))
                        .frame(maxWidth: .infinity)
                        .padding()
                        .foregroundColor(.white)
                        .background(RoundedRectangle(cornerRadius: 12).stroke(Color.white.opacity(0.25)))
                }

                Button(action: next) {
                    Text("onb.value.cta.gotit".localized(table: "Onboarding"))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(RoundedRectangle(cornerRadius: 12).fill(LinearGradient(gradient: Gradient(colors: [.blue, .purple]), startPoint: .leading, endPoint: .trailing)))
                }
            }
            .padding(20)
        }
        .background(Color.black)
        .preferredColorScheme(.dark)
    }
}

private struct GrowthChartView: View {
    let title: String
    @State private var points: [CGFloat] = [0.1, 0.15, 0.2, 0.23, 0.26, 0.32, 0.4]

    var body: some View {
        GeometryReader { proxy in
            ZStack(alignment: .bottomLeading) {
                RoundedRectangle(cornerRadius: 14)
                    .fill(Color.blue.opacity(0.12))

                Path { path in
                    let w = proxy.size.width
                    let h = proxy.size.height
                    let step = w / CGFloat(max(points.count - 1, 1))
                    path.move(to: CGPoint(x: 0, y: h * (1 - points.first!)))
                    for (index, value) in points.enumerated() {
                        let x = CGFloat(index) * step
                        let y = h * (1 - value)
                        path.addLine(to: CGPoint(x: x, y: y))
                    }
                }
                .stroke(LinearGradient(gradient: Gradient(colors: [.blue, .purple]), startPoint: .leading, endPoint: .trailing), style: StrokeStyle(lineWidth: 3, lineJoin: .round))

                Text(title)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(8)
            }
        }
    }
}

private struct SpendChartView: View {
    let title: String
    @State private var points: [CGFloat] = [0.8, 0.7, 0.6, 0.52, 0.45, 0.38, 0.3]

    var body: some View {
        GeometryReader { proxy in
            ZStack(alignment: .bottomLeading) {
                RoundedRectangle(cornerRadius: 14)
                    .fill(Color.green.opacity(0.12))

                Path { path in
                    let w = proxy.size.width
                    let h = proxy.size.height
                    let step = w / CGFloat(max(points.count - 1, 1))
                    path.move(to: CGPoint(x: 0, y: h * (1 - points.first!)))
                    for (index, value) in points.enumerated() {
                        let x = CGFloat(index) * step
                        let y = h * (1 - value)
                        path.addLine(to: CGPoint(x: x, y: y))
                    }
                }
                .stroke(LinearGradient(gradient: Gradient(colors: [.green, .mint]), startPoint: .leading, endPoint: .trailing), style: StrokeStyle(lineWidth: 3, lineJoin: .round))

                Text(title)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(8)
            }
        }
    }
}

#Preview {
    OnboardingStepValue(next: {}, back: {})
}


