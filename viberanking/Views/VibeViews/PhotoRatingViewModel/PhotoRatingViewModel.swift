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
    @Published var photoUserNames: [String: String] = [:] // photoId -> userName
    
    // MARK: - Private Properties
    private let rateAPI = RateAPI()
    private let tagsAPI = TagsAPI()
    private var cancellables = Set<AnyCancellable>()
    private let r2UrlBuilder = R2PhotoURLBuilder()
    private let r2ImageService = R2ImageService.shared
    private let samplePhotoService = SamplePhotoService()
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

    var currentPhotoUserName: String {
        guard let id = currentPhoto?.id else { return "" }
        return photoUserNames[id] ?? ""
    }
    
    // MARK: - Initialization
    override init() {
        super.init()
    }
    
    // MARK: - Public Methods
    
    /// Load photos for rating
    func loadPhotosForRating(userId: String) async {
        currentUserId = userId
        isLoading = true
        
        do {
            // 在背景線程請求 API
            let response = try await Task.detached(priority: .userInitiated) {
                try await self.rateAPI.getRandomPhotos(userId: userId, limit: 20)
            }.value
            
            let built = try await self.buildPhotosResolvingURLs(from: response.data)
            
            // 回到主線程更新 UI
            await MainActor.run {
                self.photos = built
                self.photoUserNames = Dictionary(uniqueKeysWithValues: response.data.map { ($0.id, $0.user.name) })
                self.currentPhotoIndex = 0
                self.isLoading = false
            }
            
            await fetchTagsForCurrentPhoto()
            Task.detached { await self.preloadImages() }
            
            print("✅ Successfully loaded \(built.count) photos for rating")
            
        } catch {
            await MainActor.run {
                self.photos = []
                self.currentPhotoIndex = 0
                self.isLoading = false
            }
            print("❌ API 錯誤: \(error)")
            
            // Fallback to sample photos for offline/demo resilience
            do {
                let samples = try await Task.detached(priority: .userInitiated) {
                    try await self.samplePhotoService.getSamplePhotos()
                }.value
                
                await MainActor.run {
                    self.photos = samples
                    self.currentPhotoIndex = 0
                    self.currentTags = []
                }
                
                Task.detached { await self.preloadImages() }
                print("🧪 Using sample photos fallback: count=\(samples.count)")
            } catch {
                await MainActor.run {
                    self.photos = []
                    self.currentPhotoIndex = 0
                }
            }
        }
    }
    
    /// Submit rating with gesture animation
    func submitRating(type: RatingType, withAnimation: Bool = true) async {
        guard let photo = currentPhoto else { return }
        
        // Submit rating through API without blocking UI
        Task.detached(priority: .background) {
            do {
                let response = try await self.rateAPI.ratePhoto(
                    raterId: self.currentUserId,
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
        
        // Show feedback animation immediately (don't wait for API)
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
        
        // Move to next photo immediately (don't wait for API)
        await self.moveToNextPhoto()
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
    
    /// Get journey info for journey/profile
    func getJourneyInfo() async -> JourneyInfo? {
        guard !currentUserId.isEmpty else { return nil }
        
        do {
            // Request API in background thread
            let response = try await Task.detached(priority: .userInitiated) {
                try await self.rateAPI.getJourneyInfo(userId: self.currentUserId)
            }.value
            
            return response.success ? response.data : nil
        } catch {
            print("Failed to get user stats: \(error)")
            return nil
        }
    }
}

// MARK: - Private Methods
private extension PhotoRatingViewModel {
    nonisolated static func isR2DirectURL(_ url: String) -> Bool {
        return url.contains(".r2.cloudflarestorage.com/")
    }
    nonisolated static func parseR2Key(from urlString: String) -> String? {
        guard let url = URL(string: urlString) else { return nil }
        // URL path looks like /<bucket>/<key>
        var path = url.path
        if path.hasPrefix("/") { path.removeFirst() }
        let components = path.split(separator: "/", maxSplits: 1, omittingEmptySubsequences: true)
        guard components.count == 2 else { return nil }
        return String(components[1])
    }
    
    /// Move to next photo
    func moveToNextPhoto() async {
        // Ensure we switch to a different user than the current one
        let currentUser = currentPhoto?.userId
        // Find next index with a different userId
        func nextDifferentUserIndex(startingFrom index: Int) -> Int? {
            guard !photos.isEmpty else { return nil }
            var i = index + 1
            while i < photos.count {
                if photos[i].userId != currentUser { return i }
                i += 1
            }
            return nil
        }

        if let nextIndex = nextDifferentUserIndex(startingFrom: currentPhotoIndex) {
            currentPhotoIndex = nextIndex
            await fetchTagsForCurrentPhoto()
            await preloadImages()
            return
        }

        // No different user ahead; try loading more
        await loadMorePhotos()
        if let nextIndex = nextDifferentUserIndex(startingFrom: currentPhotoIndex) {
            currentPhotoIndex = nextIndex
        } else if hasMorePhotos {
            // Fallback: move forward even if same user (avoid dead-end)
            currentPhotoIndex += 1
        }
        await fetchTagsForCurrentPhoto()
        await preloadImages()
    }
    
    /// Load more photos when running low
    func loadMorePhotos() async {
        do {
            // 在背景線程請求 API
            let response = try await Task.detached(priority: .userInitiated) {
                try await self.rateAPI.getRandomPhotos(userId: self.currentUserId, limit: 10)
            }.value
            
            let newPhotos = try await self.buildPhotosResolvingURLs(from: response.data)
            
            // 回到主線程更新 UI
            await MainActor.run {
                self.photos.append(contentsOf: newPhotos)
                // Extend name mapping for newly loaded items
                for item in response.data { 
                    self.photoUserNames[item.id] = item.user.name 
                }
            }
        } catch {
            // Append a few sample photos as a soft fallback
            do {
                let samples = try await Task.detached(priority: .userInitiated) {
                    try await self.samplePhotoService.getSamplePhotos()
                }.value
                
                // take first 5 to avoid large append
                let slice = Array(samples.prefix(5))
                await MainActor.run {
                    self.photos.append(contentsOf: slice)
                }
                print("🧪 loadMorePhotos fallback appended sample count=\(slice.count)")
            } catch {
                // ignore
            }
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
            // 在背景線程請求 API
            let response = try await Task.detached(priority: .userInitiated) {
                try await self.tagsAPI.getTagsForPhoto(photoId: photo.id)
            }.value
            
            // 回到主線程更新 UI
            await MainActor.run { 
                self.currentTags = response.data 
            }
        } catch {
            await MainActor.run { 
                self.currentTags = [] 
            }
        }
    }

    /// Build `Photo` array using API-provided origin URLs when available
    public func buildPhotosResolvingURLs(from items: [RatingPhoto]) async throws -> [Photo] {
        // Resolve signed URL in parallel for entries with key
        return try await withThrowingTaskGroup(of: Photo.self) { group in
            for ratingPhoto in items {
                group.addTask { [r2UrlBuilder, r2ImageService] in
                    let urls: PhotoURLs
                    // Use origin URL provided by API directly
                    if !ratingPhoto.url.isEmpty {
                        urls = PhotoURLs(original: ratingPhoto.url)
                    } else if let key = ratingPhoto.key, !key.isEmpty {
                        // URL missing but key present
                        if AppConfiguration.R2.publicDomain.contains("r2.cloudflarestorage.com") {
                            let signedURL = await r2ImageService.resolveLoadableURL(for: key)
                            urls = PhotoURLs(original: signedURL.absoluteString)
                        } else {
                            urls = r2UrlBuilder.buildURLs(forKey: key)
                        }
                    } else {
                        urls = PhotoURLs(original: "")
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
