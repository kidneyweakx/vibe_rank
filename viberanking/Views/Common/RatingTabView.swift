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
            
            // Action buttons overlay
            VStack {
                Spacer()
                actionButtonsView
                    .padding(.bottom, 50)
            }
        }
        .task {
            if let userId = authViewModel.user?.id {
                await viewModel.loadPhotosForRating(userId: userId)
            }
        }
        .overlay {
            if showCelebration {
                celebrationOverlay
            }
        }
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
            AsyncImage(url: URL(string: photo.imageURL.highRes)) { image in
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
        .animation(.spring(response: 0.6, dampingFraction: 0.8), value: currentCardOffset)
    }
    
    var swipeIndicators: some View {
        ZStack {
            // HOT indicator (right)
            if currentCardOffset.width > 30 {
                VStack(spacing: AppTheme.Spacing.xs) {
                    Text("❤️")
                        .font(.system(size: 80))
                        .scaleEffect(1.0 + min(Double(currentCardOffset.width) / 200, 0.5))
                    
                    Text("HOT")
                        .font(.system(size: 32, weight: .black, design: .rounded))
                        .foregroundColor(.white)
                        .shadow(color: .black.opacity(0.5), radius: 3, x: 0, y: 2)
                }
                .opacity(min(Double(currentCardOffset.width) / 120, 1.0))
                .scaleEffect(0.8 + min(Double(currentCardOffset.width) / 300, 0.4))
            }
            
            // NOT indicator (left)
            if currentCardOffset.width < -30 {
                VStack(spacing: AppTheme.Spacing.xs) {
                    Text("❌")
                        .font(.system(size: 80))
                        .scaleEffect(1.0 + min(Double(-currentCardOffset.width) / 200, 0.5))
                    
                    Text("NOT")
                        .font(.system(size: 32, weight: .black, design: .rounded))
                        .foregroundColor(.white)
                        .shadow(color: .black.opacity(0.5), radius: 3, x: 0, y: 2)
                }
                .opacity(min(Double(-currentCardOffset.width) / 120, 1.0))
                .scaleEffect(0.8 + min(Double(-currentCardOffset.width) / 300, 0.4))
            }
        }
    }
    
    var actionButtonsView: some View {
        HStack(spacing: 60) {
            // NOT button
            Button {
                submitRating(isHot: false)
            } label: {
                Circle()
                    .fill(.ultraThinMaterial)
                    .frame(width: 70, height: 70)
                    .overlay(
                        Text("❌")
                            .font(.system(size: 32))
                    )
                    .shadow(color: .black.opacity(0.3), radius: 10, x: 0, y: 5)
            }
            .disabled(viewModel.currentPhoto == nil)
            .opacity(viewModel.currentPhoto == nil ? 0.5 : 1.0)
            
            // HOT button
            Button {
                submitRating(isHot: true)
            } label: {
                Circle()
                    .fill(.ultraThinMaterial)
                    .frame(width: 70, height: 70)
                    .overlay(
                        Text("❤️")
                            .font(.system(size: 32))
                    )
                    .shadow(color: .black.opacity(0.3), radius: 10, x: 0, y: 5)
            }
            .disabled(viewModel.currentPhoto == nil)
            .opacity(viewModel.currentPhoto == nil ? 0.5 : 1.0)
        }
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
                
                Text("❤️ HOT ❤️")
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
            // Swiped right - HOT
            submitRating(isHot: true)
        } else if value.translation.width < -threshold {
            // Swiped left - NOT
            submitRating(isHot: false)
        } else {
            // Return to center
            currentCardOffset = .zero
        }
    }
    
    func submitRating(isHot: Bool) {
        // Animate card away
        withAnimation(.easeInOut(duration: 0.3)) {
            currentCardOffset = CGSize(width: isHot ? 500 : -500, height: 0)
        }
        
        // Show celebration
        if isHot {
            showCelebration = true
        }
        
        // Submit rating and reset
        Task {
            await viewModel.submitRating(isHot: isHot)
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                currentCardOffset = .zero
            }
        }
    }
}

#Preview {
    RatingTabView()
        .environmentObject(AuthenticationViewModel())
        .environmentObject(ThemeManager())
}
