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
    @State private var nextCardOffset: CGSize = .zero
    @State private var showCelebration = false
    
    var body: some View {
        ZStack {
            // Background
            themeManager.currentTheme.colors.background
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Header with cute star
//                headerView
                
                // Progress section
                progressSection
                
                // Card stack
                cardStackView
                
                // Action buttons
                actionButtonsView
                
                Spacer()
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
    
    var headerView: some View {
        VStack(spacing: AppTheme.Spacing.sm) {
            // Cute animated star with floating effect
            ZStack {
                // Glow effect
                Circle()
                    .fill(themeManager.currentTheme.colors.accent.opacity(0.3))
                    .frame(width: 80, height: 80)
                    .blur(radius: 10)
                
                Circle()
                    .fill(themeManager.currentTheme.colors.accent)
                    .frame(width: 60, height: 60)
                    .shadow(color: themeManager.currentTheme.colors.accent.opacity(0.4), radius: 15, x: 0, y: 8)
                
                Text("⭐️")
                    .font(.system(size: 30))
                    .scaleEffect(showCelebration ? 1.3 : 1.0)
                    .rotationEffect(.degrees(showCelebration ? 10 : -10))
                    .animation(
                        .easeInOut(duration: 2.0)
                        .repeatForever(autoreverses: true),
                        value: showCelebration
                    )
            }
            .onAppear {
                showCelebration = true
            }
            
            Text("rating.title".localized)
                .font(AppTheme.Typography.title2)
                .fontWeight(.bold)
                .foregroundColor(themeManager.currentTheme.colors.text)
                .shadow(color: .black.opacity(0.3), radius: 2, x: 0, y: 1)
            
            HStack(spacing: AppTheme.Spacing.xs) {
                Text("👈")
                    .font(.system(size: 16))
                Text("rating.not".localized)
                    .font(AppTheme.Typography.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(themeManager.currentTheme.colors.secondary)
                
                Text("•")
                    .foregroundColor(themeManager.currentTheme.colors.text.opacity(0.7))
                
                Text("rating.hot".localized)
                    .font(AppTheme.Typography.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(themeManager.currentTheme.colors.accent)
                Text("👉")
                    .font(.system(size: 16))
            }
            .padding(.horizontal, AppTheme.Spacing.md)
            .padding(.vertical, AppTheme.Spacing.xs)
            .background(
                Capsule()
                    .fill(.ultraThinMaterial)
                    .shadow(color: .black.opacity(0.1), radius: 5, x: 0, y: 2)
            )
        }
        .padding(.top, AppTheme.Spacing.lg)
        .padding(.bottom, AppTheme.Spacing.md)
    }
    
    var progressSection: some View {
        VStack(spacing: AppTheme.Spacing.sm) {
            HStack {
                Image(systemName: viewModel.ratingProgress.hasUnlockedUpload ? "lock.open.fill" : "lock.fill")
                    .foregroundColor(viewModel.ratingProgress.hasUnlockedUpload ? .green : .orange)
                    .font(.title3)
                
                Text(viewModel.progressText)
                    .font(AppTheme.Typography.headline)
                    .foregroundColor(themeManager.currentTheme.colors.text)
                
                Spacer()
            }
            
            // Progress bar
            ZStack(alignment: .leading) {
                RoundedRectangle(cornerRadius: AppTheme.CornerRadius.sm)
                    .fill(themeManager.currentTheme.colors.text.opacity(0.2))
                    .frame(height: 8)
                
                RoundedRectangle(cornerRadius: AppTheme.CornerRadius.sm)
                    .fill(LinearGradient(
                        colors: [themeManager.currentTheme.colors.primary, themeManager.currentTheme.colors.secondary],
                        startPoint: .leading,
                        endPoint: .trailing
                    ))
                    .frame(width: max(0, UIScreen.main.bounds.width * 0.8 * viewModel.progressPercentage), height: 8)
                    .animation(.easeInOut(duration: 0.3), value: viewModel.progressPercentage)
            }
            
            HStack {
                Text("\(viewModel.ratingProgress.completedRatings)")
                    .font(AppTheme.Typography.caption)
                    .foregroundColor(themeManager.currentTheme.colors.text.opacity(0.7))
                
                Spacer()
                
                Text("\(viewModel.ratingProgress.requiredRatings)")
                    .font(AppTheme.Typography.caption)
                    .foregroundColor(themeManager.currentTheme.colors.text.opacity(0.7))
            }
        }
        .cardStyle()
        .padding(.horizontal, AppTheme.Spacing.md)
    }
    
    var cardStackView: some View {
        ZStack {
            if viewModel.isLoading {
                loadingView
            } else if !viewModel.photos.isEmpty {
                photoCardsStack
            } else {
                emptyStateView
            }
        }
        .frame(height: 400)
        .padding(.horizontal, AppTheme.Spacing.md)
        .padding(.vertical, AppTheme.Spacing.lg)
    }
    
    var photoCardsStack: some View {
        ZStack {
            ForEach(viewModel.photos.indices, id: \.self) { index in
                photoCard(photo: viewModel.photos[index], index: index)
            }
        }
    }
    
    func photoCard(photo: Photo, index: Int) -> some View {
        let isTopCard = index == viewModel.currentPhotoIndex
        
        return ZStack {
            // Card background with modern glass effect
            RoundedRectangle(cornerRadius: AppTheme.CornerRadius.xl)
                .fill(.ultraThinMaterial)
                .background(
                    RoundedRectangle(cornerRadius: AppTheme.CornerRadius.xl)
                        .fill(
                            LinearGradient(
                                colors: [.white.opacity(0.9), .white.opacity(0.7)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                )
                .shadow(color: .black.opacity(0.1), radius: 20, x: 0, y: 10)
                .shadow(color: .black.opacity(0.05), radius: 5, x: 0, y: 2)
            
            // Photo content with rounded corners
            AsyncImage(url: URL(string: photo.imageURL.highRes)) { image in
                image
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .clipShape(RoundedRectangle(cornerRadius: AppTheme.CornerRadius.lg))
                    .padding(8)
            } placeholder: {
                ZStack {
                    RoundedRectangle(cornerRadius: AppTheme.CornerRadius.lg)
                        .fill(
                            LinearGradient(
                                colors: [
                                    themeManager.currentTheme.colors.primary.opacity(0.1),
                                    themeManager.currentTheme.colors.secondary.opacity(0.1)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .padding(8)
                    
                    VStack(spacing: AppTheme.Spacing.sm) {
                        ZStack {
                            Circle()
                                .fill(themeManager.currentTheme.colors.accent.opacity(0.3))
                                .frame(width: 60, height: 60)
                            
                            Text("📷")
                                .font(.system(size: 30))
                        }
                        
                        Text("載入中...")
                            .font(AppTheme.Typography.caption)
                            .foregroundColor(themeManager.currentTheme.colors.text.opacity(0.7))
                            .fontWeight(.medium)
                        
                        ProgressView()
                            .scaleEffect(0.8)
                            .tint(themeManager.currentTheme.colors.primary)
                    }
                }
            }
            
            // Swipe indicators with enhanced animations
            if isTopCard {
                swipeIndicators
            }
            
            // Card border highlight
            RoundedRectangle(cornerRadius: AppTheme.CornerRadius.xl)
                .stroke(
                    LinearGradient(
                        colors: [.white.opacity(0.5), .clear],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1
                )
        }
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.CornerRadius.xl))
        .offset(x: isTopCard ? currentCardOffset.width : 0, y: 0)
        .scaleEffect(isTopCard ? 1.0 : 0.9)
        .rotationEffect(.degrees(isTopCard ? Double(currentCardOffset.width) / 25.0 : 0))
        .offset(y: CGFloat(index - viewModel.currentPhotoIndex) * 10)
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
            // HOT indicator (right) - More cute and animated
            if currentCardOffset.width > 30 {
                VStack(spacing: AppTheme.Spacing.xs) {
                    ZStack {
                        // Glow effect
                        Circle()
                            .fill(themeManager.currentTheme.colors.accent.opacity(0.3))
                            .frame(width: 100, height: 100)
                            .blur(radius: 20)
                        
                        // Heart with bounce animation
                        Text("❤️")
                            .font(.system(size: 60))
                            .scaleEffect(1.0 + min(Double(currentCardOffset.width) / 200, 0.5))
                            .rotationEffect(.degrees(Double(currentCardOffset.width) / 10))
                    }
                    
                    Text("HOT")
                        .font(.system(size: 28, weight: .black, design: .rounded))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [themeManager.currentTheme.colors.accent, themeManager.currentTheme.colors.primary],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .shadow(color: themeManager.currentTheme.colors.accent.opacity(0.5), radius: 5, x: 0, y: 2)
                }
                .opacity(min(Double(currentCardOffset.width) / 120, 1.0))
                .scaleEffect(0.8 + min(Double(currentCardOffset.width) / 300, 0.4))
                .animation(.spring(response: 0.3, dampingFraction: 0.6), value: currentCardOffset.width)
            }
            
            // NOT indicator (left) - More cute and animated
            if currentCardOffset.width < -30 {
                VStack(spacing: AppTheme.Spacing.xs) {
                    ZStack {
                        // Glow effect
                        Circle()
                            .fill(themeManager.currentTheme.colors.secondary.opacity(0.3))
                            .frame(width: 100, height: 100)
                            .blur(radius: 20)
                        
                        // X with bounce animation
                        Text("❌")
                            .font(.system(size: 60))
                            .scaleEffect(1.0 + min(Double(-currentCardOffset.width) / 200, 0.5))
                            .rotationEffect(.degrees(Double(currentCardOffset.width) / 10))
                    }
                    
                    Text("NOT")
                        .font(.system(size: 28, weight: .black, design: .rounded))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [themeManager.currentTheme.colors.secondary, themeManager.currentTheme.colors.primary],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .shadow(color: themeManager.currentTheme.colors.secondary.opacity(0.5), radius: 5, x: 0, y: 2)
                }
                .opacity(min(Double(-currentCardOffset.width) / 120, 1.0))
                .scaleEffect(0.8 + min(Double(-currentCardOffset.width) / 300, 0.4))
                .animation(.spring(response: 0.3, dampingFraction: 0.6), value: currentCardOffset.width)
            }
        }
    }
    
    var actionButtonsView: some View {
        HStack(spacing: AppTheme.Spacing.xl) {
            // NOT button - Enhanced cute design
            Button {
                submitRating(isHot: false)
            } label: {
                ZStack {
                    // Outer glow
                    Circle()
                        .fill(themeManager.currentTheme.colors.secondary.opacity(0.3))
                        .frame(width: 85, height: 85)
                        .blur(radius: 10)
                    
                    // Main button
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [themeManager.currentTheme.colors.secondary, themeManager.currentTheme.colors.primary],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 70, height: 70)
                        .shadow(color: themeManager.currentTheme.colors.secondary.opacity(0.4), radius: 15, x: 0, y: 8)
                    
                    // Inner highlight
                    Circle()
                        .stroke(
                            LinearGradient(
                                colors: [.white.opacity(0.6), .clear],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 2
                        )
                        .frame(width: 70, height: 70)
                    
                    Text("❌")
                        .font(.system(size: 32))
                        .shadow(color: .black.opacity(0.2), radius: 2, x: 0, y: 1)
                }
            }
            .disabled(viewModel.currentPhoto == nil)
            .scaleEffect(viewModel.isLoading ? 0.85 : 1.0)
            .opacity(viewModel.currentPhoto == nil ? 0.5 : 1.0)
            
            // HOT button - Enhanced cute design
            Button {
                submitRating(isHot: true)
            } label: {
                ZStack {
                    // Outer glow
                    Circle()
                        .fill(themeManager.currentTheme.colors.accent.opacity(0.3))
                        .frame(width: 85, height: 85)
                        .blur(radius: 10)
                    
                    // Main button
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [themeManager.currentTheme.colors.accent, themeManager.currentTheme.colors.primary],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 70, height: 70)
                        .shadow(color: themeManager.currentTheme.colors.accent.opacity(0.4), radius: 15, x: 0, y: 8)
                    
                    // Inner highlight
                    Circle()
                        .stroke(
                            LinearGradient(
                                colors: [themeManager.currentTheme.colors.text.opacity(0.6), .clear],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 2
                        )
                        .frame(width: 70, height: 70)
                    
                    Text("❤️")
                        .font(.system(size: 32))
                        .shadow(color: .black.opacity(0.2), radius: 2, x: 0, y: 1)
                }
            }
            .disabled(viewModel.currentPhoto == nil)
            .scaleEffect(viewModel.isLoading ? 0.85 : 1.0)
            .opacity(viewModel.currentPhoto == nil ? 0.5 : 1.0)
        }
        .padding(.horizontal, AppTheme.Spacing.md)
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: viewModel.isLoading)
    }
    
    var loadingView: some View {
        VStack(spacing: AppTheme.Spacing.lg) {
            ProgressView()
                .scaleEffect(1.5)
            
            Text("rating.loading".localized)
                .font(AppTheme.Typography.headline)
                .foregroundColor(themeManager.currentTheme.colors.text.opacity(0.7))
        }
        .cardStyle()
    }
    
    var emptyStateView: some View {
        VStack(spacing: AppTheme.Spacing.lg) {
            Text("📷")
                .font(.system(size: 60))
            
            Text("rating.no_photos".localized)
                .font(AppTheme.Typography.title2)
                .foregroundColor(themeManager.currentTheme.colors.text)
            
            Text("rating.try_later".localized)
                .font(AppTheme.Typography.body)
                .foregroundColor(themeManager.currentTheme.colors.text.opacity(0.7))
            
            Button("rating.reload".localized) {
                Task {
                    await viewModel.refreshPhotos()
                }
            }
            .primaryButton()
        }
        .cardStyle()
    }
    
    var celebrationOverlay: some View {
        ZStack {
            // Animated background
            Color.black.opacity(0.3)
                .ignoresSafeArea()
                .onTapGesture {
                    showCelebration = false
                }
            
            VStack(spacing: AppTheme.Spacing.lg) {
                // Animated celebration elements
                ZStack {
                    // Sparkles around the main emoji
                    ForEach(0..<8, id: \.self) { index in
                        Text("✨")
                            .font(.system(size: 20))
                            .offset(
                                x: cos(Double(index) * .pi / 4) * 80,
                                y: sin(Double(index) * .pi / 4) * 80
                            )
                            .scaleEffect(showCelebration ? 1.2 : 0.3)
                            .opacity(showCelebration ? 1.0 : 0.0)
                            .animation(
                                .spring(response: 0.6, dampingFraction: 0.7)
                                .delay(Double(index) * 0.1),
                                value: showCelebration
                            )
                    }
                    
                    // Main celebration emoji
                    Text("🎉")
                        .font(.system(size: 120))
                        .scaleEffect(showCelebration ? 1.0 : 0.3)
                        .rotationEffect(.degrees(showCelebration ? 360 : 0))
                        .animation(
                            .spring(response: 0.8, dampingFraction: 0.6),
                            value: showCelebration
                        )
                }
                
                VStack(spacing: AppTheme.Spacing.sm) {
                    Text("太棒了！")
                        .font(.system(size: 32, weight: .bold, design: .rounded))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [.white, themeManager.currentTheme.colors.accent],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .shadow(color: .black.opacity(0.3), radius: 5, x: 0, y: 2)
                    
                    Text("❤️ HOT ❤️")
                        .font(.system(size: 18, weight: .semibold, design: .rounded))
                        .foregroundColor(.white.opacity(0.9))
                        .padding(.horizontal, AppTheme.Spacing.lg)
                        .padding(.vertical, AppTheme.Spacing.sm)
                        .background(
                            Capsule()
                                .fill(.ultraThinMaterial)
                                .shadow(color: .black.opacity(0.2), radius: 10, x: 0, y: 5)
                        )
                }
                .scaleEffect(showCelebration ? 1.0 : 0.5)
                .opacity(showCelebration ? 1.0 : 0.0)
                .animation(
                    .spring(response: 0.6, dampingFraction: 0.7)
                    .delay(0.3),
                    value: showCelebration
                )
            }
        }
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
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
