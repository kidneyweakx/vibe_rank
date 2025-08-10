//
//  PhotoRatingViewModel.swift
//  viberanking
//
//  Created by Kiro on 2025/07/23.
//

import Foundation
import SwiftUI
import Combine

// MARK: - Photo Rating ViewModel
@MainActor
class PhotoRatingViewModel: BaseViewModel {
    
    // MARK: - Published Properties
    @Published var photos: [Photo] = []
    @Published var currentPhotoIndex: Int = 0
    @Published var ratingProgress: RatingProgress = RatingProgress()
    @Published var isPreloading: Bool = false
    @Published var dragOffset: CGSize = .zero
    @Published var rotationAngle: Double = 0
    @Published var showRatingFeedback: Bool = false
    @Published var lastRatingType: RatingType = .normal
    @Published var showUnlockCelebration: Bool = false
    @Published var currentTags: [Tag] = []
    
    // MARK: - Private Properties
    private let rateAPI = RateAPI()
    private let tagsAPI = TagsAPI()
    private var cancellables = Set<AnyCancellable>()
    private let r2UrlBuilder = R2PhotoURLBuilder()
    private let r2ImageService = R2ImageService.shared
    private var currentUserId: String = ""
    
    // Preloading configuration
    private let preloadCount = 3
    private let maxDragDistance: CGFloat = 150
    private let rotationMultiplier: Double = 0.1
    
    // MARK: - Computed Properties
    var currentPhoto: Photo? {
        guard currentPhotoIndex < photos.count else { return nil }
        return photos[currentPhotoIndex]
    }
    
    var hasMorePhotos: Bool {
        return currentPhotoIndex < photos.count - 1
    }
    
    var progressText: String {
        let remaining = ratingProgress.remainingRatings
        if remaining > 0 {
            return "progress.rating_needed".localized(with: remaining)
        } else {
            return "progress.upload_unlocked".localized
        }
    }
    
    var progressPercentage: Double {
        return ratingProgress.progressPercentage
    }
    
    // MARK: - Initialization
    override init() {
        super.init()
    }
    
    // MARK: - Public Methods
    
    /// Load photos for rating
    func loadPhotosForRating(userId: String) async {
        currentUserId = userId
        await performAsyncTask {
            do {
                // Fetch random photos for rating from API
                let response = try await self.rateAPI.getRandomPhotos(userId: userId, limit: 20)
                
                // Build photos resolving signed URLs when needed
                let built = try await self.buildPhotosResolvingURLs(from: response.data)
                self.photos = built
                
                self.currentPhotoIndex = 0
                await self.fetchTagsForCurrentPhoto()
                
                // Start preloading images
                await self.preloadImages()
                
                print("✅ Successfully loaded \(self.photos.count) photos for rating")
            } catch {
                print("❌ Failed to load photos for rating: \(error)")
                // Set empty photos array on error
                self.photos = []
                self.currentPhotoIndex = 0
            }
        }
    }
    
    /// Submit rating with gesture animation
    func submitRating(type: RatingType, withAnimation: Bool = true) async {
        guard let photo = currentPhoto else { return }
        
        await performAsyncTask {
            // Submit rating through API
            let response = try await self.rateAPI.ratePhoto(
                raterId: self.currentUserId,
                photoId: photo.id,
                type: type
            )
            
            if response.success {
                // Show feedback animation
                if withAnimation {
                    self.lastRatingType = type
                    self.showRatingFeedback = true
                    
                    // Provide haptic feedback
                    #if canImport(UIKit)
                    let impactFeedback = UIImpactFeedbackGenerator(style: type == .like ? .heavy : .medium)
                    impactFeedback.impactOccurred()
                    #endif
                    
                    // Hide feedback after delay
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        self.showRatingFeedback = false
                    }
                }
                
                // Move to next photo
                await self.moveToNextPhoto()
            }
        }
    }
    
    /// Handle drag gesture
    func handleDragGesture(_ value: DragGesture.Value) {
        dragOffset = value.translation
        rotationAngle = Double(value.translation.width) * rotationMultiplier
        
        // Provide haptic feedback at threshold
        #if canImport(UIKit)
        if abs(value.translation.width) > maxDragDistance * 0.7 {
            let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
            impactFeedback.impactOccurred()
        }
        #endif
    }
    
    /// Handle drag gesture end
    func handleDragEnd(_ value: DragGesture.Value) async {
        let dragDistance = value.translation.width
        
        if abs(dragDistance) > maxDragDistance {
            // Determine rating based on drag direction
            let ratingType: RatingType = dragDistance > 0 ? .like : .normal
            
            // Animate card off screen
            withAnimation(.easeOut(duration: 0.3)) {
                dragOffset = CGSize(width: dragDistance > 0 ? 400 : -400, height: 0)
                rotationAngle = dragDistance > 0 ? 15 : -15
            }
            
            // Submit rating after animation
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                Task {
                    await self.submitRating(type: ratingType, withAnimation: false)
                    await MainActor.run {
                        self.resetCardPosition()
                    }
                }
            }
        } else {
            // Snap back to center
            withAnimation(.spring()) {
                resetCardPosition()
            }
        }
    }
    
    /// Reset card position
    func resetCardPosition() {
        dragOffset = .zero
        rotationAngle = 0
    }
    
    /// Refresh photos
    func refreshPhotos() async {
        await loadPhotosForRating(userId: currentUserId)
    }
    
    /// Skip current photo without rating
    func skipCurrentPhoto() async {
        await moveToNextPhoto()
    }
    
    /// Get user stats for journey/profile
    func getUserStats() async -> UserStats? {
        guard !currentUserId.isEmpty else { return nil }
        
        do {
            let response = try await rateAPI.getUserStats(userId: currentUserId)
            return response.success ? response.data : nil
        } catch {
            print("Failed to get user stats: \(error)")
            return nil
        }
    }
}

// MARK: - Private Methods
private extension PhotoRatingViewModel {
    
    /// Move to next photo
    func moveToNextPhoto() async {
        if hasMorePhotos {
            currentPhotoIndex += 1
            await fetchTagsForCurrentPhoto()
            await preloadImages()
        } else {
            // Load more photos if needed
            await loadMorePhotos()
            await fetchTagsForCurrentPhoto()
        }
    }
    
    /// Load more photos when running low
    func loadMorePhotos() async {
        await performAsyncTask {
            let response = try await self.rateAPI.getRandomPhotos(userId: self.currentUserId, limit: 10)
            
            let newPhotos = try await self.buildPhotosResolvingURLs(from: response.data)
            
            self.photos.append(contentsOf: newPhotos)
        }
    }
    
    /// Preload images for smooth experience
    func preloadImages() async {
        isPreloading = true
        defer { isPreloading = false }
        
        let startIndex = currentPhotoIndex
        let endIndex = min(startIndex + preloadCount, photos.count)
        
        let urlsToPreload = Array(photos[startIndex..<endIndex]).map { $0.imageURL.bestAvailableURL }
        
        await MainActor.run {
            ImageCache.shared.preloadImages(urls: urlsToPreload)
        }
    }

    /// Fetch tags for the current photo
    func fetchTagsForCurrentPhoto() async {
        guard let photo = currentPhoto else {
            await MainActor.run { self.currentTags = [] }
            return
        }
        do {
            let response = try await tagsAPI.getTagsForPhoto(photoId: photo.id)
            await MainActor.run { self.currentTags = response.data }
        } catch {
            await MainActor.run { self.currentTags = [] }
        }
    }

    /// Build `Photo` array resolving signed URLs for private S3 endpoints
    func buildPhotosResolvingURLs(from items: [RatingPhoto]) async throws -> [Photo] {
        // Resolve signed URL in parallel for entries with key
        return try await withThrowingTaskGroup(of: Photo.self) { group in
            for ratingPhoto in items {
                group.addTask { [r2UrlBuilder, r2ImageService] in
                    let urls: PhotoURLs
                    if let key = ratingPhoto.key, !key.isEmpty {
                        if AppConfiguration.R2.publicDomain.contains("r2.cloudflarestorage.com") {
                            // Resolve a signed URL for original
                            let signedURL = await r2ImageService.resolveLoadableURL(for: key)
                            urls = PhotoURLs(original: signedURL.absoluteString)
                        } else {
                            urls = r2UrlBuilder.buildURLs(forKey: key)
                        }
                    } else {
                        urls = PhotoURLs(original: ratingPhoto.url)
                    }
                    return Photo(
                        id: ratingPhoto.id,
                        userId: ratingPhoto.userId,
                        imageURL: urls
                    )
                }
            }
            var results: [Photo] = []
            results.reserveCapacity(items.count)
            for try await photo in group {
                results.append(photo)
            }
            return results
        }
    }
}
