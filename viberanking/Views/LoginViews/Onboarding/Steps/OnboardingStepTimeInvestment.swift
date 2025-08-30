//
//  OnboardingStepTimeInvestment.swift
//  viberanking
//
//  Created by AI Assistant on 2025/08/28.
//

import SwiftUI

struct OnboardingStepTimeInvestment: View {
    let next: () -> Void
    let back: () -> Void

    @State private var hoursPerWeek: Double = 5

    var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    Text("onb.time.title.en".localized(table: "Onboarding"))
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundColor(.white)
                    Text(String(format: NSLocalizedString("onb.time.subtitle.en", tableName: "Onboarding", comment: ""), Int(hoursPerWeek)))
                        .font(.system(size: 14))
                        .foregroundColor(.white.opacity(0.75))

                    // Modern draggable pie chart (approximation): split hours vs remaining
                    TimePieChartView(value: hoursPerWeek / 30.0)
                        .frame(height: 180)

                    VStack(alignment: .leading, spacing: 8) {
                        Text("onb.time.title.zh".localized(table: "Onboarding"))
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(.white)
                        Text(String(format: NSLocalizedString("onb.time.subtitle.zh", tableName: "Onboarding", comment: ""), Int(hoursPerWeek)))
                            .font(.system(size: 15))
                            .foregroundColor(.white.opacity(0.75))
                    }

                    Slider(value: $hoursPerWeek, in: 0...30, step: 1)
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
                    Text("common.next".localized(table: "Onboarding"))
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

private struct TimePieChartView: View {
    let value: Double // 0...1 representing portion

    var body: some View {
        GeometryReader { proxy in
            ZStack {
                Circle()
                    .trim(from: 0, to: 1)
                    .stroke(Color.gray.opacity(0.2), lineWidth: 18)
                Circle()
                    .trim(from: 0, to: value)
                    .stroke(LinearGradient(gradient: Gradient(colors: [.blue, .purple]), startPoint: .topLeading, endPoint: .bottomTrailing), style: StrokeStyle(lineWidth: 18, lineCap: .round))
                    .rotationEffect(.degrees(-90))

                VStack(spacing: 4) {
                    Text("\(Int(value * 30))h / week")
                        .font(.system(size: 16, weight: .semibold))
                    Text("Time invested")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
    }
}

#Preview {
    OnboardingStepTimeInvestment(next: {}, back: {})
}


