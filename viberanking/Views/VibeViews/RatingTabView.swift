//
//  RatingTabView.swift
//  viberanking
//
//  Created by Kiro on 2025/07/25.
//

import SwiftUI
import os.log

private let ratingLogger = Logger(subsystem: "com.viberanking.app", category: "RatingTabView")

struct RatingTabView: View {
    @EnvironmentObject private var authViewModel: AuthenticationViewModel
    @EnvironmentObject private var themeManager: ThemeManager
    @StateObject private var viewModel = PhotoRatingViewModel()
    @State private var currentCardOffset: CGSize = .zero
    @State private var imageLoadStartTimes: [String: Date] = [:]
    @Binding var isVibeMode: Bool
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            if viewModel.isLoading {
                RatingLoadingView()
            } else if !viewModel.photos.isEmpty {
                cardStackView
            } else {
                RatingEmptyStateView {
                    Task {
                        await viewModel.refreshPhotos()
                    }
                }
            }
            
            // Top overlay
            RatingTopOverlay(isVibeMode: isVibeMode) {
                isVibeMode = false
            }
            
            // User info and action buttons overlay
            VStack(spacing: 10) {
                Spacer()
                
                RatingUserInfoOverlay(
                    userName: viewModel.currentPhotoUserName,
                    tags: viewModel.currentTags
                )
                
                RatingActionButtons(
                    hasCurrentPhoto: viewModel.currentPhoto != nil,
                    onRefresh: refreshPhoto,
                    onVibe: { submitRating(type: .like) },
                    onSkip: skipPhoto
                )
                .padding(.bottom, 90)
            }
            .zIndex(1000)
            .transition(.opacity.combined(with: .move(edge: .bottom)))
        }
        .task {
            if let userId = authViewModel.user?.id {
                await viewModel.loadPhotosForRating(userId: userId)
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .photoCardSwipedRight)) { _ in
            submitRating(type: .like)
        }
        .onReceive(NotificationCenter.default.publisher(for: .photoCardSwipedLeft)) { _ in
            skipPhoto()
        }
        .animation(.easeInOut(duration: 0.3), value: isVibeMode)
    }
}

// MARK: - View Components
private extension RatingTabView {
    
    var cardStackView: some View {
        GeometryReader { proxy in
            ZStack {
                if let photo = viewModel.currentPhoto {
                    PhotoCardView(
                        photo: photo,
                        index: viewModel.currentPhotoIndex,
                        isTopCard: viewModel.currentPhotoIndex == viewModel.currentPhotoIndex,
                        currentCardOffset: $currentCardOffset,
                        imageLoadStartTimes: $imageLoadStartTimes
                    )
                    .frame(width: proxy.size.width, height: proxy.size.height)
                }
            }
        }
        .ignoresSafeArea()
    }
}

// MARK: - Actions
private extension RatingTabView {
    
    func submitRating(type: RatingType) {
        // Animate card away
        withAnimation(.easeInOut(duration: 0.3)) {
            currentCardOffset = CGSize(width: type == .like ? 500 : -500, height: 0)
        }
        
        // Submit rating and reset
        Task {
            await viewModel.submitRating(type: type)
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                currentCardOffset = .zero
            }
        }
    }
    
    func refreshPhoto() {
        // 重新載入照片
        Task {
            if let userId = authViewModel.user?.id {
                await viewModel.loadPhotosForRating(userId: userId)
            }
        }
    }
    
    func skipPhoto() {
        // 跳過當前照片，移到下一張
        withAnimation(.easeInOut(duration: 0.3)) {
            currentCardOffset = CGSize(width: -500, height: 0)
        }
        
        Task {
            await viewModel.skipCurrentPhoto()
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                currentCardOffset = .zero
            }
        }
    }
}

#Preview {
    RatingTabView(isVibeMode: .constant(false))
        .environmentObject(AuthenticationViewModel())
        .environmentObject(ThemeManager())
}
