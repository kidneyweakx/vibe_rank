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
    @Binding var currentCardOffset: CGSize
    @Binding var imageLoadStartTimes: [String: Date]
    
    var body: some View {
        let urlString = photo.imageURL.bestAvailableURL
        
        return ZStack {
            // 16:9 Card container
            ZStack {
                AsyncImage(url: URL(string: urlString)) { phase in
                    switch phase {
                    case .empty:
                        loadingPlaceholder
                            .onAppear {
                                imageLoadStartTimes[urlString] = Date()
                                photoCardLogger.debug("Image load start [index=\(index)] [photoId=\(photo.id)] url=\(urlString)")
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
                                    photoCardLogger.debug("Image load success [index=\(index)] [photoId=\(photo.id)] url=\(urlString) elapsed=\(elapsedMs)ms")
                                } else {
                                    photoCardLogger.debug("Image load success [index=\(index)] [photoId=\(photo.id)] url=\(urlString) elapsed=unknown")
                                }
                            }
                    case .failure(let error):
                        errorPlaceholder
                            .onAppear {
                                let elapsedMs = finishImageLoad(for: urlString)
                                if let elapsedMs {
                                    photoCardLogger.error("Image load failure [index=\(index)] [photoId=\(photo.id)] url=\(urlString) elapsed=\(elapsedMs)ms error=\(error.localizedDescription)")
                                } else {
                                    photoCardLogger.error("Image load failure [index=\(index)] [photoId=\(photo.id)] url=\(urlString) elapsed=unknown error=\(error.localizedDescription)")
                                }
                            }
                    @unknown default:
                        Color.gray.opacity(0.3)
                            .onAppear {
                                let elapsedMs = finishImageLoad(for: urlString)
                                if let elapsedMs {
                                    photoCardLogger.error("Image load unknown phase [index=\(index)] [photoId=\(photo.id)] url=\(urlString) elapsed=\(elapsedMs)ms")
                                } else {
                                    photoCardLogger.error("Image load unknown phase [index=\(index)] [photoId=\(photo.id)] url=\(urlString) elapsed=unknown")
                                }
                            }
                    }
                }
            }
            .frame(maxWidth: .infinity)
            .aspectRatio(16/9, contentMode: .fit)
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            .shadow(color: .black.opacity(0.3), radius: 10, x: 0, y: 6)
            
            // Swipe indicators
            if isTopCard {
                swipeIndicators
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
        .frame(maxWidth: .infinity, maxHeight: .infinity)
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
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    private var swipeIndicators: some View {
        Group {
            // Right swipe indicator (flame)
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
            
            // Left swipe indicator (x)
            if currentCardOffset.width < -30 {
                Circle()
                    .fill(.white.opacity(0.2))
                    .frame(width: 80, height: 80)
                    .overlay(
                        Image(systemName: "xmark")
                            .font(.system(size: 30, weight: .medium))
                            .foregroundColor(.white)
                    )
                    .opacity(min(Double(-currentCardOffset.width) / 120.0, 1.0))
                    .scaleEffect(0.9 + min(Double(-currentCardOffset.width) / 400.0, 0.2))
            }
        }
    }
    
    // MARK: - Private Methods
    private func finishImageLoad(for urlString: String) -> Int? {
        let now = Date()
        guard let start = imageLoadStartTimes.removeValue(forKey: urlString) else {
            return nil
        }
        let elapsedMs = Int(now.timeIntervalSince(start) * 1000)
        return elapsedMs
    }
    
    private func handleSwipeEnd(_ value: DragGesture.Value) {
        let threshold: CGFloat = 100
        
        if value.translation.width > threshold {
            // Swiped right - LIKE
            NotificationCenter.default.post(name: .photoCardSwipedRight, object: nil)
        } else if value.translation.width < -threshold {
            // Swiped left - SKIP
            NotificationCenter.default.post(name: .photoCardSwipedLeft, object: nil)
        } else {
            // Return to center
            withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                currentCardOffset = .zero
            }
        }
    }
}

// MARK: - Notification Names
extension Notification.Name {
    static let photoCardSwipedRight = Notification.Name("photoCardSwipedRight")
    static let photoCardSwipedLeft = Notification.Name("photoCardSwipedLeft")
}

#Preview {
    PhotoCardView(
        photo: Photo(id: "1", userId: "user1", imageURL: PhotoURLs(original: "test")),
        index: 0,
        isTopCard: true,
        currentCardOffset: .constant(.zero),
        imageLoadStartTimes: .constant([:])
    )
    .background(Color.black)
}
