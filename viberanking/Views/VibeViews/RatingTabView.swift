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
    @State private var cardOffsets: [Int: CGSize] = [:]
    @Binding var isVibeMode: Bool
    
    // Card stack configuration
    private let maxVisibleCards = 3
    private let cardSpacing: CGFloat = 8
    private let swipeThreshold: CGFloat = 100
    
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
            
            // Top overlay with report button
            VStack {
                HStack {
                    if isVibeMode {
                        Button {
                            withAnimation(.easeInOut(duration: 0.3)) {
                                isVibeMode = false
                            }
                        } label: {
                            Image(systemName: "chevron.left")
                                .font(.system(size: 18, weight: .medium))
                                .foregroundColor(.white.opacity(0.8))
                        }
                        .padding(.leading, 20)
                    }
                    
                    Spacer()
                    
                    // Report button
                    ReportButton()
                        .padding(.trailing, 20)
                }
                .padding(.top, 60)
                Spacer()
            }
            .zIndex(1000)
            .transition(.opacity.combined(with: .move(edge: .top)))
            
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
                    onVibe: { submitRating(type: .like, for: viewModel.currentPhotoIndex) },
                    onSkip: { skipPhoto(for: viewModel.currentPhotoIndex) }
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
        .onChange(of: viewModel.currentPhotoIndex) { _ in
            // Preload next images for better performance
            preloadNextImages(currentIndex: viewModel.currentPhotoIndex)
        }
        .animation(.easeInOut(duration: 0.3), value: isVibeMode)
    }
}

// MARK: - View Components
private extension RatingTabView {
    
    var cardStackView: some View {
        GeometryReader { proxy in
            ZStack {
                // Show multiple cards in stack
                ForEach(Array(visibleCardIndices.enumerated()), id: \.element) { stackIndex, photoIndex in
                    if let photo = viewModel.photos[safe: photoIndex] {
                        let cardOffset = cardOffsets[photoIndex] ?? .zero
                        let isTopCard = photoIndex == viewModel.currentPhotoIndex
                        
                        PhotoCardView(
                            photo: photo,
                            index: photoIndex,
                            isTopCard: isTopCard,
                            cardOffset: cardOffset,
                            onSwipe: { direction in
                                handleSwipe(direction: direction, for: photoIndex)
                            }
                        )
                        .frame(width: proxy.size.width, height: proxy.size.height)
                        .offset(y: CGFloat(stackIndex) * cardSpacing)
                        .scaleEffect(1.0 - CGFloat(stackIndex) * 0.05)
                        .opacity(1.0 - CGFloat(stackIndex) * 0.1)
                    }
                }
            }
        }
        .ignoresSafeArea()
    }
    
    // Get indices of visible cards (current + next few)
    private var visibleCardIndices: [Int] {
        let currentIndex = viewModel.currentPhotoIndex
        let maxIndex = min(currentIndex + maxVisibleCards, viewModel.photos.count)
        return Array(currentIndex..<maxIndex)
    }
}

// MARK: - Actions
private extension RatingTabView {
    
    func handleSwipe(direction: SwipeDirection, for photoIndex: Int) {
        switch direction {
        case .dragging(let translation):
            // Update card position while dragging
            cardOffsets[photoIndex] = translation
            
        case .ended(let translation):
            let swipeDistance = abs(translation.width)
            
            if swipeDistance > swipeThreshold {
                // Swipe completed - determine direction
                if translation.width > 0 {
                    // Swiped right - LIKE
                    submitRating(type: .like, for: photoIndex)
                } else {
                    // Swiped left - SKIP
                    skipPhoto(for: photoIndex)
                }
            } else {
                // Swipe not far enough - return to center
                withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                    cardOffsets[photoIndex] = .zero
                }
            }
        }
    }
    
    func submitRating(type: RatingType, for photoIndex: Int? = nil) {
        let targetIndex = photoIndex ?? viewModel.currentPhotoIndex
        
        // Animate card away
        withAnimation(.easeInOut(duration: 0.3)) {
            cardOffsets[targetIndex] = CGSize(width: type == .like ? 500 : -500, height: 0)
        }
        
        // Submit rating API call only (don't reload photos)
        Task {
            await submitRatingAPI(type: type, for: targetIndex)
            
            // Clear offset and move to next photo
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                cardOffsets.removeValue(forKey: targetIndex)
                // Move to next photo without reloading
                moveToNextPhoto()
                // Preload next images
                preloadNextImages(currentIndex: viewModel.currentPhotoIndex)
            }
        }
    }
    
    // Submit rating to API without reloading photos
    private func submitRatingAPI(type: RatingType, for photoIndex: Int) async {
        guard let photo = viewModel.photos[safe: photoIndex] else { return }
        
        do {
            // Call rating API directly
            let rateAPI = RateAPI()
            let response = try await rateAPI.ratePhoto(
                raterId: authViewModel.user?.id ?? "",
                photoId: photo.id,
                type: type
            )
            
            if response.success {
                print("✅ Rating submitted successfully: \(type)")
            } else {
                print("❌ Rating failed: Unknown error")
            }
        } catch {
            print("❌ Rating error: \(error.localizedDescription)")
        }
    }
    
    func refreshPhoto() {
        // 重新載入照片
        Task {
            if let userId = authViewModel.user?.id {
                await viewModel.loadPhotosForRating(userId: userId)
                // Clear all card offsets
                cardOffsets.removeAll()
            }
        }
    }
    
    func skipPhoto(for photoIndex: Int? = nil) {
        let targetIndex = photoIndex ?? viewModel.currentPhotoIndex
        
        // 跳過當前照片，移到下一張
        withAnimation(.easeInOut(duration: 0.3)) {
            cardOffsets[targetIndex] = CGSize(width: -500, height: 0)
        }
        
        // Clear offset and move to next photo
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            cardOffsets.removeValue(forKey: targetIndex)
            // Move to next photo without reloading
            moveToNextPhoto()
            // Preload next images
            preloadNextImages(currentIndex: viewModel.currentPhotoIndex)
        }
    }
    
    func preloadNextImages(currentIndex: Int) {
        // Preload next 2-3 images for better performance
        let preloadCount = 3
        var urlsToPreload: [String] = []
        
        for i in 1...preloadCount {
            let nextIndex = currentIndex + i
            if nextIndex < viewModel.photos.count {
                let photo = viewModel.photos[nextIndex]
                urlsToPreload.append(photo.imageURL.bestAvailableURL)
            }
        }
        
        if !urlsToPreload.isEmpty {
            ImageCache.shared.preloadImages(urls: urlsToPreload)
        }
    }
    
    // Move to next photo without reloading
    private func moveToNextPhoto() {
        if viewModel.currentPhotoIndex < viewModel.photos.count - 1 {
            viewModel.currentPhotoIndex += 1
        } else {
            // No more photos, refresh the list
            Task {
                await refreshPhoto()
            }
        }
    }
}

// MARK: - Array Extension
extension Array {
    subscript(safe index: Int) -> Element? {
        return indices.contains(index) ? self[index] : nil
    }
}

#Preview {
    RatingTabView(isVibeMode: .constant(false))
        .environmentObject(AuthenticationViewModel())
        .environmentObject(ThemeManager())
}
