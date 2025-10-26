//
//  PhotoCardView.swift
//  viberanking
//
//  Created by Kiro on 2025/07/25.
//

import SwiftUI
import os.log

private let photoCardLogger = Logger(subsystem: "com.viberanking.app", category: "PhotoCardView")

struct PhotoCardView: View {
    let photo: Photo
    let index: Int
    let isTopCard: Bool
    let cardOffset: CGSize
    let onSwipe: (SwipeDirection) -> Void
    
    // Image loading state
    @State private var imageLoadState: ImageLoadState = .loading
    @State private var cachedImage: UIImage?
    
    var body: some View {
        let urlString = photo.imageURL.bestAvailableURL
        
        return ZStack {
            // 9:16 Card container (portrait)
            GeometryReader { proxy in
                ZStack {
                    // Show cached image first if available
                    if let cachedImage = cachedImage {
                        imageView(image: cachedImage, size: proxy.size)
                    } else {
                        optimizedImageLoader(urlString: urlString, size: proxy.size)
                    }
                }
                .frame(width: proxy.size.width, height: proxy.size.height)
            }
            .frame(maxWidth: .infinity)
            .aspectRatio(9/16, contentMode: .fit)
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            .shadow(color: .black.opacity(0.3), radius: 10, x: 0, y: 6)
            
            // Swipe indicators only for top card
            if isTopCard {
                swipeIndicators
            }
        }
        .offset(x: cardOffset.width, y: cardOffset.height)
        .scaleEffect(1.0 - abs(cardOffset.width) / 1000) // Slight scale effect
        .rotationEffect(.degrees(Double(cardOffset.width) / 25.0))
        .zIndex(isTopCard ? 10 : Double(10 - index)) // Stack cards by z-index
        .animation(.easeInOut(duration: 0.2).speed(1.0), value: cardOffset) // Add explicit animation
        .gesture(
            DragGesture()
                .onChanged { value in
                    // Only allow gesture on top card
                    if isTopCard {
                        onSwipe(.dragging(value.translation))
                    }
                }
                .onEnded { value in
                    if isTopCard {
                        onSwipe(.ended(value.translation))
                    }
                }
        )
        .allowsHitTesting(isTopCard)
        .onAppear {
            preloadImage(urlString: urlString)
        }
    }
    
    // MARK: - Optimized Image Loader
    @ViewBuilder
    private func optimizedImageLoader(urlString: String, size: CGSize) -> some View {
        switch imageLoadState {
        case .loading:
            loadingPlaceholder
                .frame(width: size.width, height: size.height)
                .onAppear {
                    startImageLoad(urlString: urlString)
                }
        case .success(let image):
            imageView(image: image, size: size)
        case .failure:
            errorPlaceholder
                .frame(width: size.width, height: size.height)
        }
    }

    /// Centralized image rendering with optional blur based on safety setting
    @ViewBuilder
    private func imageView(image: UIImage, size: CGSize) -> some View {
        let blurEnabled = UserDefaults.standard.bool(forKey: "safety_blur_enabled")
        Image(uiImage: image)
            .resizable()
            .frame(width: size.width, height: size.height)
            .clipped()
            .if(blurEnabled) { view in
                view.blur(radius: 10)
                    .overlay(
                        VStack(spacing: 8) {
                            Image(systemName: "eye.slash.fill").font(.system(size: 22)).foregroundColor(.white)
                            Text("Sensitive content hidden").font(.system(size: 14, weight: .medium)).foregroundColor(.white)
                            Text("Tap and hold to reveal").font(.system(size: 12)).foregroundColor(.white.opacity(0.8))
                        }
                        .padding(12)
                    )
                    .gesture(LongPressGesture(minimumDuration: 0.4).onChanged { _ in
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                        UserDefaults.standard.set(false, forKey: "safety_blur_enabled")
                    })
            }
            .transition(.opacity.animation(.easeInOut(duration: 0.2).speed(1.0)))
    }
    
    // MARK: - Private Views
    private var loadingPlaceholder: some View {
        ZStack {
            Color.black.opacity(0.3)
            VStack(spacing: AppTheme.Spacing.sm) {
                ProgressView()
                    .scaleEffect(1.2)
                    .tint(.white)
                Text("common.loading".localized)
                    .font(AppTheme.Typography.body)
                    .foregroundColor(.white)
            }
        }
    }
    
    private var errorPlaceholder: some View {
        ZStack {
            Color.black.opacity(0.3)
            VStack(spacing: AppTheme.Spacing.sm) {
                Text("⚠️")
                    .font(.system(size: 60))
                Text("common.image_load_failed".localized)
                    .font(AppTheme.Typography.body)
                    .foregroundColor(.white)
            }
        }
    }
    
    private var swipeIndicators: some View {
        Group {
            // Right swipe indicator (flame)
            if cardOffset.width > 30 {
                Circle()
                    .fill(.white.opacity(0.2))
                    .frame(width: 80, height: 80)
                    .overlay(
                        Image(systemName: "flame.fill")
                            .font(.system(size: 34, weight: .medium))
                            .foregroundColor(.white)
                    )
                    .opacity(min(Double(cardOffset.width) / 120.0, 1.0))
                    .scaleEffect(0.9 + min(Double(cardOffset.width) / 400.0, 0.2))
            }
            
            // Left swipe indicator (x)
            if cardOffset.width < -30 {
                Circle()
                    .fill(.white.opacity(0.2))
                    .frame(width: 80, height: 80)
                    .overlay(
                        Image(systemName: "xmark")
                            .font(.system(size: 30, weight: .medium))
                            .foregroundColor(.white)
                    )
                    .opacity(min(Double(-cardOffset.width) / 120.0, 1.0))
                    .scaleEffect(0.9 + min(Double(-cardOffset.width) / 400.0, 0.2))
            }
        }
    }
    
    // MARK: - Private Methods
    private func startImageLoad(urlString: String) {
        photoCardLogger.debug("Image load start [index=\(index)] [photoId=\(photo.id)] url=\(urlString)")
        
        Task {
            await loadImage(urlString: urlString)
        }
    }
    
    private func loadImage(urlString: String) async {
        // Use the enhanced image cache service
        if let image = await ImageCache.shared.getImage(from: urlString) {
            await MainActor.run {
                cachedImage = image
                imageLoadState = .success(image)
                photoCardLogger.debug("Image load success [index=\(index)] [photoId=\(photo.id)] url=\(urlString)")
            }
        } else {
            await MainActor.run {
                imageLoadState = .failure
                photoCardLogger.error("Image load failure [index=\(index)] [photoId=\(photo.id)] url=\(urlString)")
            }
        }
    }
    
    private func preloadImage(urlString: String) {
        // Preload next images for better performance
        ImageCache.shared.preloadImages(urls: [urlString])
    }
}

// MARK: - Swipe Direction
enum SwipeDirection {
    case dragging(CGSize)
    case ended(CGSize)
}

// MARK: - Image Load State
enum ImageLoadState: Equatable {
    case loading
    case success(UIImage)
    case failure
}

#Preview {
    PhotoCardView(
        photo: Photo(id: "1", userId: "user1", imageURL: PhotoURLs(original: "test")),
        index: 0,
        isTopCard: true,
        cardOffset: .zero,
        onSwipe: { _ in }
    )
    .background(Color.black)
}
