//
//  SpotlightOverlay.swift
//  viberanking
//
//  Created by AI Assistant on 2025/08/29.
//

import SwiftUI

// MARK: - Preference Key & View Modifier

/// Collects frames of spotlight targets in a named coordinate space
struct SpotlightPreferenceKey: PreferenceKey {
    static var defaultValue: [String: CGRect] = [:]
    static func reduce(value: inout [String: CGRect], nextValue: () -> [String: CGRect]) {
        // Merge values; later values override earlier ones for same id
        value.merge(nextValue(), uniquingKeysWith: { _, new in new })
    }
}

extension View {
    /// Marks a view as a spotlight target and records its frame in the `"spotlight"` coordinate space.
    func spotlightTarget(id: String) -> some View {
        background(
            GeometryReader { proxy in
                Color.clear.preference(
                    key: SpotlightPreferenceKey.self,
                    value: [id: proxy.frame(in: .named("spotlight"))]
                )
            }
        )
    }
}

// MARK: - Spotlight Overlay

struct SpotlightOverlay: View {
    let targetFrame: CGRect
    let cornerRadius: CGFloat
    let title: String
    let message: String
    let onNext: () -> Void
    let onSkip: () -> Void

    var body: some View {
        ZStack {
            // Dim background with cutout at target
            Color.black.opacity(0.6)
                .ignoresSafeArea()
                .overlay(
                    RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                        .frame(width: targetFrame.width + 12, height: targetFrame.height + 12)
                        .position(x: targetFrame.midX, y: targetFrame.midY)
                        .blendMode(.destinationOut)
                )
                .compositingGroup()

            // Highlight ring around the target
            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .stroke(Color.white.opacity(0.9), lineWidth: 2)
                .frame(width: targetFrame.width + 18, height: targetFrame.height + 18)
                .position(x: targetFrame.midX, y: targetFrame.midY)

            // Tooltip content positioned relative to target
            VStack(spacing: 12) {
                Text(title)
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                Text(message)
                    .font(.system(size: 14, weight: .regular))
                    .foregroundColor(.white.opacity(0.9))
                    .multilineTextAlignment(.center)
            }
            .padding(14)
            .background(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(Color.black.opacity(0.75))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.white.opacity(0.12), lineWidth: 1)
                    )
            )
            .frame(maxWidth: 320)
            .position(tooltipPosition(for: targetFrame))

            // Bottom controls
            VStack {
                Spacer()
                HStack(spacing: 12) {
                    Button(action: onSkip) {
                        Text("跳過")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.white)
                            .padding(.horizontal, 18)
                            .padding(.vertical, 10)
                            .background(Color.white.opacity(0.12))
                            .clipShape(Capsule())
                    }
                    Button(action: onNext) {
                        Text("下一步")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(.black)
                            .padding(.horizontal, 18)
                            .padding(.vertical, 10)
                            .background(Color.white)
                            .clipShape(Capsule())
                    }
                }
                .padding(.bottom, 28)
            }
            .ignoresSafeArea()
        }
        .transition(.opacity.combined(with: .scale))
        .animation(.easeInOut(duration: 0.25), value: targetFrame)
    }

    // MARK: - Private Helpers

    /// Places the tooltip above the target if there's room, otherwise below.
    private func tooltipPosition(for frame: CGRect) -> CGPoint {
        let screen = UIScreen.main.bounds
        let preferredYAbove = frame.minY - 80
        if preferredYAbove > 120 {
            // Place above target
            return CGPoint(x: frame.midX, y: frame.minY - 70)
        } else {
            // Place below target
            let y = min(frame.maxY + 70, screen.height - 140)
            return CGPoint(x: frame.midX, y: y)
        }
    }
}


