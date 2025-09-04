//
//  OnboardingStepTimeInvestment.swift
//  viberanking
//
//  Created by AI Assistant on 2025/08/28.
//

import SwiftUI

struct OnboardingStepTimeInvestment: View {
    let next: (Int) -> Void
    let back: () -> Void

    @State private var hoursPerWeek: Double = 5

    var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("onb.time.title.en".localized(table: "Onboarding"))
                            .font(.system(size: 22, weight: .semibold))
                            .foregroundColor(.white)
                        Text(String(format: "onb.time.subtitle.en".localized(table: "Onboarding"), Int(hoursPerWeek)))
                            .font(.system(size: 15))
                            .foregroundColor(.white.opacity(0.75))
                    }

                    // Modern draggable pie chart
                    VStack(spacing: 16) {
                        TimePieChartView(value: hoursPerWeek / 30.0)
                            .frame(height: 200)
                        
                        Slider(value: $hoursPerWeek, in: 0...30, step: 1)
                            .accentColor(.blue)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 20)
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

                Button(action: { next(Int(hoursPerWeek)) }) {
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
        VStack(spacing: 16) {
            ZStack {
                Circle()
                    .trim(from: 0, to: 1)
                    .stroke(Color.gray.opacity(0.2), lineWidth: 20)
                    .frame(width: 160, height: 160)
                
                Circle()
                    .trim(from: 0, to: value)
                    .stroke(LinearGradient(gradient: Gradient(colors: [.blue, .purple]), startPoint: .topLeading, endPoint: .bottomTrailing), style: StrokeStyle(lineWidth: 20, lineCap: .round))
                    .rotationEffect(.degrees(-90))
                    .frame(width: 160, height: 160)

                VStack(spacing: 4) {
                    Text("\(Int(value * 30))")
                        .font(.system(size: 28, weight: .bold))
                        .foregroundColor(.white)
                    Text("hours/week")
                        .font(.system(size: 14))
                        .foregroundColor(.white.opacity(0.7))
                }
            }
            
            Text("Time invested in your vibe")
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.white.opacity(0.8))
        }
        .frame(maxWidth: .infinity)
    }
}

#Preview {
    OnboardingStepTimeInvestment(next: { _ in }, back: {})
}


