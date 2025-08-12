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
    @State private var likeButtonPressed = false
    @State private var refreshButtonPressed = false
    @State private var skipButtonPressed = false
    @State private var imageLoadStartTimes: [String: Date] = [:]
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
            
            // Top overlay: optional back button only
            VStack {
                HStack {
                    if isVibeMode {
                        Button {
                            withAnimation(.easeInOut(duration: 0.3)) { isVibeMode = false }
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
            
            // Action buttons overlay
            VStack(spacing: 10) {
                Spacer()
                // User name
                HStack {
                    Text(viewModel.currentPhotoUserName)
                        .font(.system(size: 28, weight: .bold))
                        .foregroundColor(.white)
                        .lineLimit(1)
                        .padding(.horizontal, 20)
                    Spacer()
                }
                // Tags row (show "No tag" if empty)
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        if viewModel.currentTags.isEmpty {
                            Text("No tag")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(.white.opacity(0.8))
                                .padding(.horizontal, 10)
                                .padding(.vertical, 6)
                                .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.white.opacity(0.25), lineWidth: 1))
                        } else {
                            ForEach(viewModel.currentTags, id: \.id) { tag in
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
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                actionButtonsView
                    .padding(.bottom, 90) // 更靠近底部但保留 tab bar 空間
            }
            .zIndex(1000)
            .transition(.opacity.combined(with: .move(edge: .bottom)))
            

        }
        .task {
            if let userId = authViewModel.user?.id {
                await viewModel.loadPhotosForRating(userId: userId)
            }
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
                    photoCard(photo: photo, index: viewModel.currentPhotoIndex)
                        .frame(width: proxy.size.width, height: proxy.size.height)
                }
            }
        }
        .ignoresSafeArea()
    }
    
    func photoCard(photo: Photo, index: Int) -> some View {
        let isTopCard = index == viewModel.currentPhotoIndex
        let urlString = photo.imageURL.bestAvailableURL
        
        return ZStack {
            // 16:9 Card container
            ZStack {
                AsyncImage(url: URL(string: urlString)) { phase in
                    switch phase {
                    case .empty:
                        ZStack {
                            Color.gray.opacity(0.3)
                            VStack(spacing: AppTheme.Spacing.sm) {
                                Text("📷").font(.system(size: 60))
                                Text("載入中...")
                                    .font(AppTheme.Typography.body)
                                    .foregroundColor(.white)
                                ProgressView().tint(.white)
                            }
                        }
                        .onAppear {
                            imageLoadStartTimes[urlString] = Date()
                            ratingLogger.debug("Image load start [index=\(index)] [photoId=\(photo.id)] url=\(urlString)")
                        }
                    case .success(let image):
                        image
                            .resizable()
                            .scaledToFill()
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                            .clipped()
                            .onAppear {
                                let elapsedMs = finishImageLoad(for: urlString)
                                if let elapsedMs {
                                    ratingLogger.debug("Image load success [index=\(index)] [photoId=\(photo.id)] url=\(urlString) elapsed=\(elapsedMs)ms")
                                } else {
                                    ratingLogger.debug("Image load success [index=\(index)] [photoId=\(photo.id)] url=\(urlString) elapsed=unknown")
                                }
                            }
                    case .failure(let error):
                        ZStack {
                            Color.gray.opacity(0.3)
                            VStack(spacing: AppTheme.Spacing.sm) {
                                Text("⚠️").font(.system(size: 60))
                                Text("無法載入圖片")
                                    .font(AppTheme.Typography.body)
                                    .foregroundColor(.white)
                            }
                        }
                        .onAppear {
                            let elapsedMs = finishImageLoad(for: urlString)
                            if let elapsedMs {
                                ratingLogger.error("Image load failure [index=\(index)] [photoId=\(photo.id)] url=\(urlString) elapsed=\(elapsedMs)ms error=\(error.localizedDescription)")
                            } else {
                                ratingLogger.error("Image load failure [index=\(index)] [photoId=\(photo.id)] url=\(urlString) elapsed=unknown error=\(error.localizedDescription)")
                            }
                        }
                    @unknown default:
                        Color.gray.opacity(0.3)
                            .onAppear {
                                let elapsedMs = finishImageLoad(for: urlString)
                                if let elapsedMs {
                                    ratingLogger.error("Image load unknown phase [index=\(index)] [photoId=\(photo.id)] url=\(urlString) elapsed=\(elapsedMs)ms")
                                } else {
                                    ratingLogger.error("Image load unknown phase [index=\(index)] [photoId=\(photo.id)] url=\(urlString) elapsed=unknown")
                                }
                            }
                    }
                }
            }
            .frame(maxWidth: .infinity)
            .aspectRatio(16/9, contentMode: .fit)
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            .shadow(color: .black.opacity(0.3), radius: 10, x: 0, y: 6)
            
            // Minimal swipe indicators (right: flame, left: x)
            if isTopCard {
                if currentCardOffset.width > 30 {
                    Circle()
                        .fill(.white.opacity(0.2))
                        .frame(width: 80, height: 80)
                        .overlay(
                            Image(systemName: "flame.fill")
                                .font(.system(size: 34, weight: .medium))
                                .foregroundColor(.white)
                        )
                        .opacity(min(Double(currentCardOffset.width) / 120.0, 1.0))
                        .scaleEffect(0.9 + min(Double(currentCardOffset.width) / 400.0, 0.2))
                }
                if currentCardOffset.width < -30 {
                    Circle()
                        .fill(.white.opacity(0.2))
                        .frame(width: 80, height: 80)
                        .overlay(
                            Image(systemName: "arrow.clockwise")
                                .font(.system(size: 30, weight: .medium))
                                .foregroundColor(.white)
                        )
                        .opacity(min(Double(-currentCardOffset.width) / 120.0, 1.0))
                        .scaleEffect(0.9 + min(Double(-currentCardOffset.width) / 400.0, 0.2))
                }
            }
        }
        .offset(x: currentCardOffset.width, y: 0)
        .scaleEffect(1.0)
        .rotationEffect(.degrees(Double(currentCardOffset.width) / 25.0))
        .zIndex(10)
        .gesture(
            DragGesture()
                .onChanged { value in
                    withAnimation(.interactiveSpring(response: 0.3, dampingFraction: 0.8)) {
                        currentCardOffset = value.translation
                    }
                }
                .onEnded { value in
                    handleSwipeEnd(value)
                }
        )
        .allowsHitTesting(true)
        .animation(.spring(response: 0.6, dampingFraction: 0.8), value: currentCardOffset)
    }
    
    // Removed swipeIndicators view
    
    var actionButtonsView: some View {
        HStack(spacing: 40) {
            // REFRESH button (更換)
            Button {
                refreshPhoto()
            } label: {
                Circle()
                    .fill(.white.opacity(0.12))
                    .frame(width: 50, height: 50)
                    .overlay(
                        Image(systemName: "arrow.clockwise")
                            .font(.system(size: 20, weight: .medium))
                            .foregroundColor(.white.opacity(0.7))
                    )
            }
            .disabled(viewModel.currentPhoto == nil)
            .opacity(viewModel.currentPhoto == nil ? 0.3 : 1.0)
            .scaleEffect(refreshButtonPressed ? 0.9 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: refreshButtonPressed)
            
            // VIBE button (火焰 - 中間主要按鈕)
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
                    .fill(Color.white.opacity(0.35)) // 奶白色感
                    .frame(width: 70, height: 70)
                    .overlay(
                        Image(systemName: "flame.fill")
                            .font(.system(size: 28, weight: .medium))
                            .foregroundColor(likeButtonPressed ? .orange : .black.opacity(0.8))
                    )
            }
            .disabled(viewModel.currentPhoto == nil)
            .opacity(viewModel.currentPhoto == nil ? 0.3 : 1.0)
            .scaleEffect(likeButtonPressed ? 1.3 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.6), value: likeButtonPressed)
            
            // FIX button (修正)
            Button {
                skipPhoto()
            } label: {
                Circle()
                    .fill(.white.opacity(0.12))
                    .frame(width: 50, height: 50)
                    .overlay(
                        Image(systemName: "wrench")
                            .font(.system(size: 18, weight: .medium))
                            .foregroundColor(.white.opacity(0.7))
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
    
    // celebration overlay removed
}

// MARK: - Actions
private extension RatingTabView {
    func finishImageLoad(for urlString: String) -> Int? {
        let now = Date()
        guard let start = imageLoadStartTimes.removeValue(forKey: urlString) else {
            return nil
        }
        let elapsedMs = Int(now.timeIntervalSince(start) * 1000)
        return elapsedMs
    }
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
