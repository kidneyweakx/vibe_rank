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
                VStack(alignment: .leading, spacing: 20) {
                    // Simple placeholder charts
                    HStack(spacing: 16) {
                        GrowthChartView(title: "Growth")
                        SpendChartView(title: "Spend ↓")
                    }
                    .frame(height: 160)

                    Group {
                        Text("You think new clothes, more skincare, endless outfits make you better.\nBut the truth is—70% of your money is wasted on a vibe that doesn’t even fit you.")
                        Text("We makes it clear:")
                        Text("✨ See exactly what’s worth spending on, and what’s not")
                        Text("✨ Stop blind shopping and getting played by marketing")
                        Text("✨ Grow 1% every day, double your confidence in 30 days")
                        Text("👉 Stop burning cash on the wrong vibe. Start investing in the real you.")
                    }
                    .font(.system(size: 14))
                    .foregroundColor(.secondary)

                    Group {
                        Text("你以為每天換衣服、補保養、試穿不同風格是在變好，\n但真相是——70% 的錢都丟在不適合你的 vibe 上。")
                        Text("幫你算清楚：")
                        Text("✨ 哪些錢花得值得，哪些完全沒必要")
                        Text("✨ 停止盲目亂買，別再買不適合自己的東西")
                        Text("✨ 每天 vibe +1%，30 天後自信翻倍")
                        Text("👉 別再亂花錢，找到自己最佳的 vibe。")
                    }
                    .font(.system(size: 14))
                    .foregroundColor(.secondary)
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
                    Text("GOT IT")
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


