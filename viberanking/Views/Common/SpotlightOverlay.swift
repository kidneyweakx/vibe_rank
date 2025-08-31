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
    let titleKey: String
    let messageKey: String
    let position: SpotlightPosition
    let onNext: () -> Void
    let onSkip: () -> Void

    var body: some View {
        ZStack {
            // Modern dim background with blur effect
            Color.black.opacity(0.4)
                .ignoresSafeArea()
                .background(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                        .frame(width: targetFrame.width + 16, height: targetFrame.height + 16)
                        .position(x: targetFrame.midX, y: targetFrame.midY)
                        .blendMode(.destinationOut)
                )
                .compositingGroup()

            // Enhanced highlight ring with gradient
            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .stroke(
                    LinearGradient(
                        colors: [Color.white.opacity(0.9), Color.white.opacity(0.6)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 3
                )
                .frame(width: targetFrame.width + 20, height: targetFrame.height + 20)
                .position(x: targetFrame.midX, y: targetFrame.midY)
                .shadow(color: .white.opacity(0.3), radius: 8, x: 0, y: 0)

            // Modern tooltip content positioned in center
            VStack(spacing: 16) {
                // Title with modern typography
                Text(titleKey.localized)
                    .font(.system(size: 20, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                
                // Message with better formatting
                Text(messageKey.localized)
                    .font(.system(size: 15, weight: .medium, design: .rounded))
                    .foregroundColor(.white.opacity(0.9))
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
            }
            .padding(20)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [
                                Color.black.opacity(0.85),
                                Color.black.opacity(0.75)
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(
                                LinearGradient(
                                    colors: [
                                        Color.white.opacity(0.2),
                                        Color.white.opacity(0.1)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 1
                            )
                    )
                    .shadow(color: .black.opacity(0.3), radius: 20, x: 0, y: 10)
            )
            .frame(maxWidth: 320)
            .position(tooltipPosition(for: targetFrame, position: position))

            // Enhanced bottom controls with modern design
            VStack {
                Spacer()
                HStack(spacing: 16) {
                    // Skip button with subtle design
                    Button(action: onSkip) {
                        Text("spotlight.skip".localized)
                            .font(.system(size: 16, weight: .semibold, design: .rounded))
                            .foregroundColor(.white.opacity(0.8))
                            .padding(.horizontal, 20)
                            .padding(.vertical, 12)
                            .background(
                                Capsule()
                                    .fill(Color.white.opacity(0.15))
                                    .overlay(
                                        Capsule()
                                            .stroke(Color.white.opacity(0.2), lineWidth: 1)
                                    )
                            )
                    }
                    
                    // Next button with prominent design
                    Button(action: onNext) {
                        Text("spotlight.next".localized)
                            .font(.system(size: 16, weight: .bold, design: .rounded))
                            .foregroundColor(.black)
                            .padding(.horizontal, 20)
                            .padding(.vertical, 12)
                            .background(
                                Capsule()
                                    .fill(
                                        LinearGradient(
                                            colors: [Color.white, Color.white.opacity(0.9)],
                                            startPoint: .top,
                                            endPoint: .bottom
                                        )
                                    )
                                    .shadow(color: .white.opacity(0.3), radius: 8, x: 0, y: 4)
                            )
                    }
                }
                .padding(.bottom, 32)
            }
            .ignoresSafeArea()
        }
        .transition(.opacity.combined(with: .scale))
        .animation(.easeInOut(duration: 0.3), value: targetFrame)
    }

    // MARK: - Private Helpers

    /// Places the tooltip based on the specified position preference
    private func tooltipPosition(for frame: CGRect, position: SpotlightPosition) -> CGPoint {
        let screen = UIScreen.main.bounds
        
        switch position {
        case .center:
            // Center the tooltip in the screen
            return CGPoint(x: screen.midX, y: screen.midY)
        case .above:
            // Place above target if there's room
            let preferredY = frame.minY - 80
            if preferredY > 120 {
                return CGPoint(x: frame.midX, y: frame.minY - 70)
            } else {
                // Fall back to below if not enough space above
                let y = min(frame.maxY + 70, screen.height - 140)
                return CGPoint(x: frame.midX, y: y)
            }
        case .below:
            // Place below target
            let y = min(frame.maxY + 70, screen.height - 140)
            return CGPoint(x: frame.midX, y: y)
        case .adaptive:
            // Smart positioning based on available space
            let preferredYAbove = frame.minY - 80
            if preferredYAbove > 120 {
                return CGPoint(x: frame.midX, y: frame.minY - 70)
            } else {
                let y = min(frame.maxY + 70, screen.height - 140)
                return CGPoint(x: frame.midX, y: y)
            }
        }
    }
}


