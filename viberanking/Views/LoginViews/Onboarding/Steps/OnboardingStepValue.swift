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
                VStack(alignment: .leading, spacing: 24) {
                    // Combined chart showing both growth and spending trends
                    CombinedChartView()
                        .frame(height: 200)

                    Group {
                        Text("onb.value.p1".localized(table: "Onboarding"))
                        Text("onb.value.p2".localized(table: "Onboarding"))
                        Text("onb.value.p3".localized(table: "Onboarding"))
                        Text("onb.value.p4".localized(table: "Onboarding"))
                        Text("onb.value.p5".localized(table: "Onboarding"))
                        Text("onb.value.p6".localized(table: "Onboarding"))
                    }
                    .font(.system(size: 16))
                    .foregroundColor(.white.opacity(0.85))
                }
                .padding(24)
            }

            // Divider
            Rectangle()
                .fill(Color.white.opacity(0.1))
                .frame(height: 1)

            HStack(spacing: 12) {
                Button(action: back) {
                    Text("common.back".localized(table: "Onboarding"))
                        .font(.system(size: 17, weight: .medium))
                        .frame(maxWidth: .infinity)
                        .padding()
                        .foregroundColor(.white)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.white.opacity(0.25), lineWidth: 1.5)
                        )
                }

                Button(action: next) {
                    Text("onb.value.cta.gotit".localized(table: "Onboarding"))
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(
                                    LinearGradient(
                                        gradient: Gradient(colors: [.blue, .purple]),
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                        )
                }
            }
            .padding(20)
        }
        .background(Color.black.ignoresSafeArea())
        .preferredColorScheme(.dark)
    }
}

private struct CombinedChartView: View {
    @State private var growthPoints: [CGFloat] = [0.1, 0.15, 0.2, 0.23, 0.26, 0.32, 0.4]
    @State private var spendPoints: [CGFloat] = [0.8, 0.7, 0.6, 0.52, 0.45, 0.38, 0.3]

    var body: some View {
        VStack(spacing: 16) {
            // Chart container
            GeometryReader { proxy in
                ZStack(alignment: .bottomLeading) {
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color.white.opacity(0.05))
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(Color.white.opacity(0.1), lineWidth: 1)
                        )

                    // Growth line
                    Path { path in
                        let w = proxy.size.width - 32
                        let h = proxy.size.height - 40
                        let step = w / CGFloat(max(growthPoints.count - 1, 1))
                        path.move(to: CGPoint(x: 16, y: 20 + h * (1 - growthPoints.first!)))
                        for (index, value) in growthPoints.enumerated() {
                            let x = 16 + CGFloat(index) * step
                            let y = 20 + h * (1 - value)
                            path.addLine(to: CGPoint(x: x, y: y))
                        }
                    }
                    .stroke(LinearGradient(gradient: Gradient(colors: [.blue, .purple]), startPoint: .leading, endPoint: .trailing), style: StrokeStyle(lineWidth: 3, lineJoin: .round))

                    // Spending line
                    Path { path in
                        let w = proxy.size.width - 32
                        let h = proxy.size.height - 40
                        let step = w / CGFloat(max(spendPoints.count - 1, 1))
                        path.move(to: CGPoint(x: 16, y: 20 + h * (1 - spendPoints.first!)))
                        for (index, value) in spendPoints.enumerated() {
                            let x = 16 + CGFloat(index) * step
                            let y = 20 + h * (1 - value)
                            path.addLine(to: CGPoint(x: x, y: y))
                        }
                    }
                    .stroke(LinearGradient(gradient: Gradient(colors: [.green, .mint]), startPoint: .leading, endPoint: .trailing), style: StrokeStyle(lineWidth: 3, lineJoin: .round))

                    // Legend
                    VStack(alignment: .leading, spacing: 8) {
                        HStack(spacing: 8) {
                            Circle()
                                .fill(LinearGradient(gradient: Gradient(colors: [.blue, .purple]), startPoint: .leading, endPoint: .trailing))
                                .frame(width: 12, height: 12)
                            Text("onb.value.chart.growth".localized(table: "Onboarding"))
                                .font(.caption)
                                .foregroundColor(.white.opacity(0.8))
                        }
                        
                        HStack(spacing: 8) {
                            Circle()
                                .fill(LinearGradient(gradient: Gradient(colors: [.green, .mint]), startPoint: .leading, endPoint: .trailing))
                                .frame(width: 12, height: 12)
                            Text("onb.value.chart.spend".localized(table: "Onboarding"))
                                .font(.caption)
                                .foregroundColor(.white.opacity(0.8))
                        }
                    }
                    .padding(12)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color.black.opacity(0.6))
                    )
                    .padding(.top, 8)
                    .padding(.leading, 8)
                }
            }
        }
    }
}

#Preview {
    OnboardingStepValue(next: {}, back: {})
}


