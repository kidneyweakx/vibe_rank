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
    @Published var lastRatingWasHot: Bool = false
    @Published var showUnlockCelebration: Bool = false
    
    // MARK: - Private Properties
    private let photoRatingService: PhotoRatingServiceProtocol
    private let userRepository: UserRepositoryProtocol
    private let ratingProgressService: RatingProgressServiceProtocol
    private var cancellables = Set<AnyCancellable>()
    private var currentUserId: String = ""
    private var userRatings: [Rating] = []
    
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
    init(photoRatingService: PhotoRatingServiceProtocol, 
         userRepository: UserRepositoryProtocol,
         ratingProgressService: RatingProgressServiceProtocol) {
        self.photoRatingService = photoRatingService
        self.userRepository = userRepository
        self.ratingProgressService = ratingProgressService
        super.init()
        setupBindings()
    }
    
    override convenience init() {
        self.init(
            photoRatingService: PhotoRatingService(),
            userRepository: UserRepository(),
            ratingProgressService: RatingProgressService(
                userRepository: UserRepository(),
                ratingRepository: RatingRepository()
            )
        )
    }
    
    // MARK: - Setup
    private func setupBindings() {
        // Observe photo rating service loading state
        if let service = photoRatingService as? PhotoRatingService {
            service.$isLoading
                .receive(on: DispatchQueue.main)
                .assign(to: \.isLoading, on: self)
                .store(in: &cancellables)
        }
    }
    
    // MARK: - Public Methods
    
    /// Load photos for rating
    func loadPhotosForRating(userId: String) async {
        currentUserId = userId
        await performAsyncTask {
            // Load user's current rating progress
            if let user = try await self.userRepository.getUser(by: userId) {
                self.ratingProgress = user.ratingProgress
            }
            
            // Fetch photos for rating
            let fetchedPhotos = try await self.photoRatingService.fetchPhotosForRating(excludingUser: userId)
            self.photos = fetchedPhotos
            self.currentPhotoIndex = 0
            
            // Start preloading images
            await self.preloadImages()
        }
    }
    
    /// Submit rating with gesture animation
    func submitRating(isHot: Bool, withAnimation: Bool = true) async {
        guard let photo = currentPhoto else { return }
        
        let rating = Rating(
            photoId: photo.id,
            raterId: currentUserId,
            isHot: isHot
        )
        
        await performAsyncTask {
            // Submit rating through photo rating service
            try await self.photoRatingService.submitRating(rating)
            
            // Check if this will unlock the feature
            let wasLocked = !self.ratingProgress.hasUnlockedUpload
            
            // Update progress through rating progress service
            self.ratingProgress = try await self.ratingProgressService.updateRatingProgress(
                userId: self.currentUserId, 
                rating: rating
            )
            
            // Show unlock celebration if just unlocked
            if wasLocked && self.ratingProgress.hasUnlockedUpload {
                self.showUnlockCelebration = true
                
                // Provide haptic feedback for unlock
                #if canImport(UIKit)
                let notificationFeedback = UINotificationFeedbackGenerator()
                notificationFeedback.notificationOccurred(.success)
                #endif
                
                // Hide celebration after delay
                DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                    self.showUnlockCelebration = false
                }
            }
            
            // Update local state
            self.userRatings.append(rating)
            
            // Show feedback animation
            if withAnimation {
                self.lastRatingWasHot = isHot
                self.showRatingFeedback = true
                
                // Hide feedback after delay
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    self.showRatingFeedback = false
                }
            }
            
            // Move to next photo
            await self.moveToNextPhoto()
            
            // Check if sync is needed for offline ratings
            if self.ratingProgressService.needsSync(userId: self.currentUserId) {
                try await self.ratingProgressService.syncLocalRatings(userId: self.currentUserId)
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
            let isHot = dragDistance > 0
            
            // Animate card off screen
            withAnimation(.easeOut(duration: 0.3)) {
                dragOffset = CGSize(width: dragDistance > 0 ? 400 : -400, height: 0)
                rotationAngle = dragDistance > 0 ? 15 : -15
            }
            
            // Submit rating after animation
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                Task {
                    await self.submitRating(isHot: isHot, withAnimation: false)
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
    
    /// Sync any pending offline ratings
    func syncPendingRatings() async {
        await performAsyncTask {
            if self.ratingProgressService.needsSync(userId: self.currentUserId) {
                try await self.ratingProgressService.syncLocalRatings(userId: self.currentUserId)
                
                // Refresh progress after sync
                self.ratingProgress = try await self.ratingProgressService.getRatingProgress(userId: self.currentUserId)
            }
        }
    }
    
    /// Get pending ratings count for UI display
    var pendingRatingsCount: Int {
        return ratingProgressService.getPendingRatingsCount(userId: currentUserId)
    }
    
    /// Check if user needs to sync
    var needsSync: Bool {
        return ratingProgressService.needsSync(userId: currentUserId)
    }
}

// MARK: - Private Methods
private extension PhotoRatingViewModel {
    
    /// Move to next photo
    func moveToNextPhoto() async {
        if hasMorePhotos {
            currentPhotoIndex += 1
            await preloadImages()
        } else {
            // Load more photos if needed
            await loadMorePhotos()
        }
    }
    
    /// Load more photos when running low
    func loadMorePhotos() async {
        await performAsyncTask {
            let newPhotos = try await self.photoRatingService.fetchPhotosForRating(excludingUser: self.currentUserId)
            self.photos.append(contentsOf: newPhotos)
        }
    }
    
    /// Preload images for smooth experience
    func preloadImages() async {
        isPreloading = true
        defer { isPreloading = false }
        
        let startIndex = currentPhotoIndex
        let endIndex = min(startIndex + preloadCount, photos.count)
        
        let urlsToPreload = Array(photos[startIndex..<endIndex]).map { $0.imageURL.highRes }
        
        await MainActor.run {
            ImageCache.shared.preloadImages(urls: urlsToPreload)
        }
    }
}