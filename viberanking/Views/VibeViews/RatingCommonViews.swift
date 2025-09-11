//
//  RatingCommonViews.swift
//  viberanking
//
//  Created by Kiro on 2025/07/25.
//

import SwiftUI

// MARK: - Loading View
struct RatingLoadingView: View {
    var body: some View {
        ZStack {
            Color.black.opacity(0.3)
            VStack(spacing: AppTheme.Spacing.lg) {
                ProgressView()
                    .scaleEffect(1.5)
                    .tint(.white)
                
                Text("rating.loading".localized)
                    .font(AppTheme.Typography.headline)
                    .foregroundColor(.white)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - Empty State View
struct RatingEmptyStateView: View {
    let onReload: () -> Void
    
    var body: some View {
        VStack(spacing: 24) {
            // Modern icon with gradient background
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [.purple.opacity(0.3), .pink.opacity(0.3)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 100, height: 100)
                
                Image(systemName: "photo.stack")
                    .font(.system(size: 40, weight: .medium))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.white, .white.opacity(0.8)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            }
            
            VStack(spacing: 12) {
                Text("rating.no_photos".localized)
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                
                Text("rating.try_later".localized)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.white.opacity(0.7))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
            }
            
            Button(action: onReload) {
                HStack(spacing: 8) {
                    Image(systemName: "arrow.clockwise")
                        .font(.system(size: 16, weight: .medium))
                    Text("rating.reload".localized)
                        .font(.system(size: 16, weight: .semibold))
                }
                .foregroundColor(.white)
                .padding(.horizontal, 24)
                .padding(.vertical, 14)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(
                            LinearGradient(
                                colors: [.purple, .pink],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.white.opacity(0.2), lineWidth: 1)
                )
            }
            .scaleEffect(1.0)
            .animation(.easeInOut(duration: 0.1), value: false)
        }
        .padding(.horizontal, 40)
    }
}

// MARK: - User Info Overlay
struct RatingUserInfoOverlay: View {
    let userName: String
    let tags: [Tag]
    @State private var showBlockConfirm = false
    
    var body: some View {
        VStack(spacing: 10) {
            // User name
            HStack {
                Text(userName)
                    .font(.system(size: 28, weight: .bold))
                    .foregroundColor(.white)
                    .lineLimit(1)
                    .padding(.horizontal, 20)
                Spacer()
                Menu {
                    Button(role: .destructive) { showBlockConfirm = true } label: {
                        Label("Block User", systemImage: "hand.raised.fill")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                        .font(.system(size: 18))
                        .foregroundColor(.white.opacity(0.9))
                        .padding(.trailing, 20)
                }
            }
            
            // Tags row - Fixed to prevent swipe interference
            HStack(spacing: 8) {
                if tags.isEmpty {
                    Text("common.no_tag".localized)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.white.opacity(0.8))
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.white.opacity(0.25), lineWidth: 1))
                } else {
                    ForEach(tags, id: \.id) { tag in
                        TagChipView(tag: tag, isSelected: false, onTap: {})
                    }
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.black.opacity(0.35))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(Color.white.opacity(0.08), lineWidth: 1)
            )
            .padding(.horizontal, 20)
            .frame(maxWidth: .infinity, alignment: .leading)
            .allowsHitTesting(false) // Prevent tags from interfering with card swipe gestures
        }
        .alert("Block User", isPresented: $showBlockConfirm) {
            Button("Cancel", role: .cancel) {}
            Button("Block", role: .destructive) {
                NotificationCenter.default.post(name: .requestBlockCurrentUser, object: nil)
            }
        } message: {
            Text("You will no longer see content from this user.")
        }
    }
}

// MARK: - Top Overlay
struct RatingTopOverlay: View {
    let isVibeMode: Bool
    let onBack: () -> Void
    
    var body: some View {
        VStack {
            HStack {
                if isVibeMode {
                    Button {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            onBack()
                        }
                    } label: {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 18, weight: .medium))
                            .foregroundColor(.white.opacity(0.8))
                    }
                    .padding(.leading, 20)
                }
                Spacer()
            }
            .padding(.top, 60)
            Spacer()
        }
        .zIndex(1000)
        .transition(.opacity.combined(with: .move(edge: .top)))
    }
}

#Preview {
    VStack(spacing: 20) {
        RatingLoadingView()
            .frame(height: 200)
        
        RatingEmptyStateView(onReload: {})
            .frame(height: 200)
        
        RatingUserInfoOverlay(
            userName: "John Doe",
            tags: []
        )
        .frame(height: 100)
        
        RatingTopOverlay(isVibeMode: true) {}
            .frame(height: 100)
    }
    .background(Color.black)
}
