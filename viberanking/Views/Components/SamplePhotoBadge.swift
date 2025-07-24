//
//  SamplePhotoBadge.swift
//  viberanking
//
//  Created by Kiro on 2025/07/23.
//

import SwiftUI

// MARK: - Sample Photo Badge View
struct SamplePhotoBadge: View {
    
    // MARK: - Properties
    let isVisible: Bool
    
    // MARK: - Animation State
    @State private var animateGlow = false
    
    // MARK: - Body
    var body: some View {
        if isVisible {
            badgeContent
                .onAppear {
                    startGlowAnimation()
                }
        }
    }
}

// MARK: - View Components
private extension SamplePhotoBadge {
    
    /// Badge content
    var badgeContent: some View {
        HStack(spacing: 6) {
            Image(systemName: "photo.badge.plus")
                .font(.caption2)
                .foregroundColor(.white)
            
            Text("示例照片")
                .font(.caption2)
                .fontWeight(.medium)
                .foregroundColor(.white)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(
            Capsule()
                .fill(
                    LinearGradient(
                        colors: [Color.blue, Color.purple],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .shadow(
                    color: animateGlow ? .blue.opacity(0.6) : .clear,
                    radius: animateGlow ? 8 : 0
                )
        )
        .animation(.easeInOut(duration: 2).repeatForever(autoreverses: true), value: animateGlow)
    }
}

// MARK: - Helper Methods
private extension SamplePhotoBadge {
    
    /// Start glow animation
    func startGlowAnimation() {
        withAnimation(.easeInOut(duration: 2).repeatForever(autoreverses: true)) {
            animateGlow = true
        }
    }
}

// MARK: - Preview
#Preview {
    VStack(spacing: 20) {
        SamplePhotoBadge(isVisible: true)
        SamplePhotoBadge(isVisible: false)
    }
    .padding()
    .background(Color.gray.opacity(0.1))
}