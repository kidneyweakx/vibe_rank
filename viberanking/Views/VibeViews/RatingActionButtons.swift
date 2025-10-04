//
//  RatingActionButtons.swift
//  viberanking
//
//  Created by Kiro on 2025/07/25.
//

import SwiftUI

struct RatingActionButtons: View {
    let hasCurrentPhoto: Bool
    let onRefresh: () -> Void
    let onVibe: () -> Void
    let onSkip: () -> Void
    
    @State private var likeButtonPressed = false
    @State private var refreshButtonPressed = false
    @State private var skipButtonPressed = false
    
    var body: some View {
        HStack(spacing: 40) {
            // SKIP button (X - 左滑)
            Button {
                skipPhoto()
            } label: {
                Circle()
                    .fill(.white.opacity(0.12))
                    .frame(width: 50, height: 50)
                    .overlay(
                        Image(systemName: "xmark")
                            .font(.system(size: 20, weight: .medium))
                            .foregroundColor(.white.opacity(0.7))
                    )
            }
            .disabled(!hasCurrentPhoto)
            .opacity(hasCurrentPhoto ? 1.0 : 0.3)
            .scaleEffect(skipButtonPressed ? 0.9 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: skipButtonPressed)
            .buttonStyle(PlainButtonStyle()) // Prevent gesture conflicts
            
            // VIBE button (火焰 - 中間主要按鈕 - 右滑)
            Button {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                    likeButtonPressed = true
                }
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    likeButtonPressed = false
                }
                
                onVibe()
            } label: {
                Circle()
                    .fill(Color.white.opacity(0.35)) // 奶白色感
                    .frame(width: 70, height: 70)
                    .overlay(
                        Image(systemName: "flame.fill")
                            .font(.system(size: 28, weight: .medium))
                            .foregroundColor(likeButtonPressed ? .orange : .black.opacity(0.8))
                    )
            }
            .disabled(!hasCurrentPhoto)
            .opacity(hasCurrentPhoto ? 1.0 : 0.3)
            .scaleEffect(likeButtonPressed ? 1.3 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.6), value: likeButtonPressed)
            .buttonStyle(PlainButtonStyle()) // Prevent gesture conflicts
            
            // LIKE button (勾勾 - 右滑)
            Button {
                onVibe() // Same as vibe button - both are right swipe (like)
            } label: {
                Circle()
                    .fill(.white.opacity(0.12))
                    .frame(width: 50, height: 50)
                    .overlay(
                        Image(systemName: "checkmark")
                            .font(.system(size: 18, weight: .medium))
                            .foregroundColor(.white.opacity(0.7))
                    )
            }
            .disabled(!hasCurrentPhoto)
            .opacity(hasCurrentPhoto ? 1.0 : 0.3)
            .scaleEffect(skipButtonPressed ? 0.9 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: skipButtonPressed)
            .buttonStyle(PlainButtonStyle()) // Prevent gesture conflicts
        }
    }
    
    // MARK: - Private Methods
    private func refreshPhoto() {
        withAnimation(.easeInOut(duration: 0.1)) {
            refreshButtonPressed = true
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            refreshButtonPressed = false
        }
        
        onRefresh()
    }
    
    private func skipPhoto() {
        withAnimation(.easeInOut(duration: 0.1)) {
            skipButtonPressed = true
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            skipButtonPressed = false
        }
        
        onSkip()
    }
}

#Preview {
    RatingActionButtons(
        hasCurrentPhoto: true,
        onRefresh: {},
        onVibe: {},
        onSkip: {}
    )
    .background(Color.black)
}
