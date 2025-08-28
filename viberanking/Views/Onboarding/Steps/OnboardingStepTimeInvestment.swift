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
                VStack(alignment: .leading, spacing: 16) {
                    Text("How much time do you spend each month working on your vibe / getting ready?")
                        .font(.system(size: 18, weight: .semibold))
                    Text("Slide: \(Int(hoursPerWeek)) hours/week\n(0 = almost none, 30 = nearly every day putting in effort)")
                        .font(.system(size: 13))
                        .foregroundColor(.secondary)

                    // Modern draggable pie chart (approximation): split hours vs remaining
                    TimePieChartView(value: hoursPerWeek / 30.0)
                        .frame(height: 180)

                    VStack(alignment: .leading, spacing: 8) {
                        Text("一週花多少時間在「提升 vibe / 打扮」？")
                            .font(.system(size: 16, weight: .semibold))
                        Text("差不多 \(Int(hoursPerWeek)) 小時")
                            .font(.system(size: 14))
                            .foregroundColor(.secondary)
                    }

                    Slider(value: $hoursPerWeek, in: 0...30, step: 1)
                }
                .padding(24)
            }

            HStack(spacing: 12) {
                Button(action: back) {
                    Text("Back")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(RoundedRectangle(cornerRadius: 12).stroke(Color.gray.opacity(0.3)))
                }

                Button(action: next) {
                    Text("Next")
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(RoundedRectangle(cornerRadius: 12).fill(LinearGradient(gradient: Gradient(colors: [.blue, .purple]), startPoint: .leading, endPoint: .trailing)))
                }
            }
            .padding(20)
        }
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


