//
//  RatingTabView.swift
//  viberanking
//
//  Created by Kiro on 2025/07/25.
//

import SwiftUI

struct RatingTabView: View {
    @EnvironmentObject private var authViewModel: AuthenticationViewModel
    @EnvironmentObject private var themeManager: ThemeManager
    @StateObject private var viewModel = PhotoRatingViewModel()
    @State private var currentCardOffset: CGSize = .zero
    @State private var showCelebration = false
    @State private var likeButtonPressed = false
    @State private var refreshButtonPressed = false
    @State private var skipButtonPressed = false
    @Binding var isVibeMode: Bool
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            if viewModel.isLoading {
                loadingView
            } else if !viewModel.photos.isEmpty {
                cardStackView
            } else {
                emptyStateView
            }
            
            // Top overlay with exit button (only in vibe mode)
            if isVibeMode {
                VStack {
                    HStack {
                        Button {
                            withAnimation(.easeInOut(duration: 0.3)) {
                                isVibeMode = false
                            }
                        } label: {
                            Image(systemName: "xmark")
                                .font(.system(size: 18, weight: .medium))
                                .foregroundColor(.white.opacity(0.8))
                        }
                        .padding(.leading, 20)
                        
                        Spacer()
                    }
                    .padding(.top, 60) // 增加頂部間距，避免超出安全區域
                    
                    Spacer()
                }
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
            
            // Action buttons overlay
            VStack {
                Spacer()
                actionButtonsView
                    .padding(.bottom, isVibeMode ? 50 : 120) // 在非 vibe 模式下留更多空間給 tab bar
            }
            .transition(.opacity.combined(with: .move(edge: .bottom)))
            

        }
        .task {
            if let userId = authViewModel.user?.id {
                await viewModel.loadPhotosForRating(userId: userId)
            }
        }
        .onAppear {
            // 當進入 rating tab 時，如果還沒在 vibe 模式，就自動進入
            if !isVibeMode {
                withAnimation(.easeInOut(duration: 0.3)) {
                    isVibeMode = true
                }
            }
        }
        .overlay {
            if showCelebration {
                celebrationOverlay
            }
        }
        .statusBarHidden(isVibeMode)
        .animation(.easeInOut(duration: 0.3), value: isVibeMode)
    }
}

// MARK: - View Components
private extension RatingTabView {
    
    var cardStackView: some View {
        ZStack {
            ForEach(viewModel.photos.indices, id: \.self) { index in
                photoCard(photo: viewModel.photos[index], index: index)
            }
        }
        .ignoresSafeArea()
    }
    
    func photoCard(photo: Photo, index: Int) -> some View {
        let isTopCard = index == viewModel.currentPhotoIndex
        
        return ZStack {
            // Full screen photo
            AsyncImage(url: URL(string: photo.imageURL.bestAvailableURL)) { image in
                image
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .clipped()
            } placeholder: {
                ZStack {
                    Color.gray.opacity(0.3)
                    
                    VStack(spacing: AppTheme.Spacing.sm) {
                        Text("📷")
                            .font(.system(size: 60))
                        
                        Text("載入中...")
                            .font(AppTheme.Typography.body)
                            .foregroundColor(.white)
                        
                        ProgressView()
                            .tint(.white)
                    }
                }
            }
            
            // Swipe indicators
            if isTopCard {
                swipeIndicators
            }
        }
        .offset(x: isTopCard ? currentCardOffset.width : 0, y: 0)
        .scaleEffect(isTopCard ? 1.0 : 0.95)
        .rotationEffect(.degrees(isTopCard ? Double(currentCardOffset.width) / 25.0 : 0))
        .offset(y: CGFloat(index - viewModel.currentPhotoIndex) * 5)
        .zIndex(Double(viewModel.photos.count - index))
        .gesture(
            isTopCard ? DragGesture()
                .onChanged { value in
                    withAnimation(.interactiveSpring(response: 0.3, dampingFraction: 0.8)) {
                        currentCardOffset = value.translation
                    }
                }
                .onEnded { value in
                    handleSwipeEnd(value)
                } : nil
        )
        .allowsHitTesting(isTopCard)
        .animation(.spring(response: 0.6, dampingFraction: 0.8), value: currentCardOffset)
    }
    
    var swipeIndicators: some View {
        ZStack {
            // LIKE indicator (right)
            if currentCardOffset.width > 30 {
                VStack(spacing: 8) {
                    Circle()
                        .fill(.white.opacity(0.2))
                        .frame(width: 100, height: 100)
                        .overlay(
                            Image(systemName: "heart.fill")
                                .font(.system(size: 40, weight: .medium))
                                .foregroundColor(.white)
                        )
                        .scaleEffect(1.0 + min(Double(currentCardOffset.width) / 300, 0.3))
                    
                    Text("LIKE")
                        .font(.system(size: 24, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(.white.opacity(0.2))
                        .cornerRadius(20)
                }
                .opacity(min(Double(currentCardOffset.width) / 120, 1.0))
                .scaleEffect(0.8 + min(Double(currentCardOffset.width) / 400, 0.2))
            }
            
            // SKIP indicator (left)
            if currentCardOffset.width < -30 {
                VStack(spacing: 8) {
                    Circle()
                        .fill(.white.opacity(0.2))
                        .frame(width: 100, height: 100)
                        .overlay(
                            Image(systemName: "xmark")
                                .font(.system(size: 35, weight: .medium))
                                .foregroundColor(.white)
                        )
                        .scaleEffect(1.0 + min(Double(-currentCardOffset.width) / 300, 0.3))
                    
                    Text("SKIP")
                        .font(.system(size: 24, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(.white.opacity(0.2))
                        .cornerRadius(20)
                }
                .opacity(min(Double(-currentCardOffset.width) / 120, 1.0))
                .scaleEffect(0.8 + min(Double(-currentCardOffset.width) / 400, 0.2))
            }
        }
    }
    
    var actionButtonsView: some View {
        HStack(spacing: 40) {
            // REFRESH button (更換)
            Button {
                refreshPhoto()
            } label: {
                Circle()
                    .fill(.white.opacity(0.15))
                    .frame(width: 50, height: 50)
                    .overlay(
                        Image(systemName: "arrow.clockwise")
                            .font(.system(size: 20, weight: .medium))
                            .foregroundColor(.white.opacity(0.9))
                    )
            }
            .disabled(viewModel.currentPhoto == nil)
            .opacity(viewModel.currentPhoto == nil ? 0.3 : 1.0)
            .scaleEffect(refreshButtonPressed ? 0.9 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: refreshButtonPressed)
            
            // LIKE button (愛心 - 中間主要按鈕)
            Button {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                    likeButtonPressed = true
                }
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    likeButtonPressed = false
                }
                
                submitRating(type: .like)
            } label: {
                Circle()
                    .fill(.white.opacity(0.2))
                    .frame(width: 70, height: 70)
                    .overlay(
                        Image(systemName: "heart.fill")
                            .font(.system(size: 28, weight: .medium))
                            .foregroundColor(.white.opacity(0.8))
                    )
            }
            .disabled(viewModel.currentPhoto == nil)
            .opacity(viewModel.currentPhoto == nil ? 0.3 : 1.0)
            .scaleEffect(likeButtonPressed ? 1.3 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.6), value: likeButtonPressed)
            
            // SKIP button (跳過)
            Button {
                skipPhoto()
            } label: {
                Circle()
                    .fill(.white.opacity(0.15))
                    .frame(width: 50, height: 50)
                    .overlay(
                        Image(systemName: "xmark")
                            .font(.system(size: 18, weight: .medium))
                            .foregroundColor(.white.opacity(0.9))
                    )
            }
            .disabled(viewModel.currentPhoto == nil)
            .opacity(viewModel.currentPhoto == nil ? 0.3 : 1.0)
            .scaleEffect(skipButtonPressed ? 0.9 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: skipButtonPressed)
        }
        .animation(.easeInOut(duration: 0.3), value: isVibeMode)
    }
    
    var loadingView: some View {
        VStack(spacing: AppTheme.Spacing.lg) {
            ProgressView()
                .scaleEffect(1.5)
                .tint(.white)
            
            Text("rating.loading".localized)
                .font(AppTheme.Typography.headline)
                .foregroundColor(.white)
        }
    }
    
    var emptyStateView: some View {
        VStack(spacing: AppTheme.Spacing.lg) {
            Text("📷")
                .font(.system(size: 60))
            
            Text("rating.no_photos".localized)
                .font(AppTheme.Typography.title2)
                .foregroundColor(.white)
            
            Text("rating.try_later".localized)
                .font(AppTheme.Typography.body)
                .foregroundColor(.white.opacity(0.7))
            
            Button("rating.reload".localized) {
                Task {
                    await viewModel.refreshPhotos()
                }
            }
            .foregroundColor(.white)
            .padding()
            .background(.ultraThinMaterial)
            .cornerRadius(12)
        }
    }
    
    var celebrationOverlay: some View {
        ZStack {
            Color.black.opacity(0.5)
                .ignoresSafeArea()
                .onTapGesture {
                    showCelebration = false
                }
            
            VStack(spacing: AppTheme.Spacing.lg) {
                Text("🎉")
                    .font(.system(size: 120))
                    .scaleEffect(showCelebration ? 1.0 : 0.3)
                    .animation(.spring(response: 0.8, dampingFraction: 0.6), value: showCelebration)
                
                Text("❤️ LIKE ❤️")
                    .font(.system(size: 24, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                    .padding(.horizontal, AppTheme.Spacing.lg)
                    .padding(.vertical, AppTheme.Spacing.sm)
                    .background(.ultraThinMaterial)
                    .cornerRadius(20)
            }
        }
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                withAnimation(.easeOut(duration: 0.3)) {
                    showCelebration = false
                }
            }
        }
    }
}

// MARK: - Actions
private extension RatingTabView {
    func handleSwipeEnd(_ value: DragGesture.Value) {
        let threshold: CGFloat = 100
        
        if value.translation.width > threshold {
            // Swiped right - LIKE
            submitRating(type: .like)
        } else if value.translation.width < -threshold {
            // Swiped left - SKIP
            skipPhoto()
        } else {
            // Return to center
            currentCardOffset = .zero
        }
    }
    
    func submitRating(type: RatingType) {
        // Animate card away
        withAnimation(.easeInOut(duration: 0.3)) {
            currentCardOffset = CGSize(width: type == .like ? 500 : -500, height: 0)
        }
        
        // Show celebration
        if type == .like {
            showCelebration = true
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
        withAnimation(.easeInOut(duration: 0.1)) {
            refreshButtonPressed = true
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            refreshButtonPressed = false
        }
        
        // 重新載入照片
        Task {
            if let userId = authViewModel.user?.id {
                await viewModel.loadPhotosForRating(userId: userId)
            }
        }
    }
    
    func skipPhoto() {
        withAnimation(.easeInOut(duration: 0.1)) {
            skipButtonPressed = true
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            skipButtonPressed = false
        }
        
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
