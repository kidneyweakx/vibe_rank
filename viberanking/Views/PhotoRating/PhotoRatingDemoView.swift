//
//  PhotoRatingDemoView.swift
//  viberanking
//
//  Created by Kiro on 2025/07/23.
//

import SwiftUI

// MARK: - Photo Rating Demo View
struct PhotoRatingDemoView: View {
    
    // MARK: - Properties
    @StateObject private var photoRatingService = PhotoRatingService()
    @State private var photos: [Photo] = []
    @State private var currentPhotoIndex = 0
    @State private var showSampleNotification = false
    @State private var hasShownSampleNotification = false
    
    // MARK: - Body
    var body: some View {
        ZStack {
            // Background
            backgroundView
            
            // Main content
            VStack(spacing: 0) {
                // Header
                headerView
                
                // Photo rating area
                photoRatingArea
                
                // Rating buttons
                ratingButtons
                
                Spacer()
            }
            
            // Sample photo notification
            SamplePhotoNotificationView(
                isVisible: $showSampleNotification,
                onDismiss: {
                    hasShownSampleNotification = true
                }
            )
        }
        .task {
            await loadPhotos()
        }
    }
}

// MARK: - View Components
private extension PhotoRatingDemoView {
    
    /// Background gradient
    var backgroundView: some View {
        LinearGradient(
            colors: [Color.blue.opacity(0.1), Color.purple.opacity(0.1)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .ignoresSafeArea()
    }
    
    /// Header view
    var headerView: some View {
        VStack(spacing: 8) {
            Text("rating.title".localized)
                .font(.largeTitle)
                .fontWeight(.bold)
                .foregroundColor(.primary)
            
            Text("rating.subtitle".localized)
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .padding(.top, 20)
        .padding(.bottom, 30)
    }
    
    /// Photo rating area
    var photoRatingArea: some View {
        VStack(spacing: 16) {
            if !photos.isEmpty && currentPhotoIndex < photos.count {
                let currentPhoto = photos[currentPhotoIndex]
                
                // Photo card
                photoCard(for: currentPhoto)
                
                // Progress indicator
                progressIndicator
                
            } else if photoRatingService.isLoading {
                loadingView
            } else {
                emptyStateView
            }
        }
        .padding(.horizontal, 20)
    }
    
    /// Photo card
    func photoCard(for photo: Photo) -> some View {
        ZStack {
            // Photo image
            AsyncImage(url: URL(string: photo.imageURL)) { image in
                image
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } placeholder: {
                Rectangle()
                    .fill(Color.gray.opacity(0.3))
                    .overlay(
                        ProgressView()
                            .scaleEffect(1.5)
                    )
            }
            .frame(width: 300, height: 400)
            .clipShape(RoundedRectangle(cornerRadius: 20))
            
            // Sample photo badge
            VStack {
                HStack {
                    Spacer()
                    SamplePhotoBadge(isVisible: photo.isSample)
                        .padding(.top, 12)
                        .padding(.trailing, 12)
                }
                Spacer()
            }
        }
        .shadow(color: .black.opacity(0.2), radius: 15, x: 0, y: 8)
    }
    
    /// Progress indicator
    var progressIndicator: some View {
        HStack(spacing: 8) {
            Text("\(currentPhotoIndex + 1)")
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundColor(.primary)
            
            ProgressView(value: Double(currentPhotoIndex + 1), total: Double(photos.count))
                .progressViewStyle(LinearProgressViewStyle(tint: .accentColor))
                .frame(height: 4)
            
            Text("\(photos.count)")
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundColor(.secondary)
        }
        .padding(.horizontal, 20)
    }
    
    /// Rating buttons
    var ratingButtons: some View {
        HStack(spacing: 40) {
            // Not button
            ratingButton(
                title: "Not",
                icon: "hand.thumbsdown.fill",
                color: .red,
                action: { submitRating(isHot: false) }
            )
            
            // Hot button
            ratingButton(
                title: "Hot",
                icon: "hand.thumbsup.fill",
                color: .green,
                action: { submitRating(isHot: true) }
            )
        }
        .padding(.top, 40)
        .padding(.bottom, 20)
    }
    
    /// Individual rating button
    func ratingButton(title: String, icon: String, color: Color, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(.white)
                
                Text(title)
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
            }
            .frame(width: 100, height: 80)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(color)
                    .shadow(color: color.opacity(0.3), radius: 8, x: 0, y: 4)
            )
        }
        .disabled(photos.isEmpty)
        .scaleEffect(photos.isEmpty ? 0.9 : 1.0)
        .opacity(photos.isEmpty ? 0.6 : 1.0)
    }
    
    /// Loading view
    var loadingView: some View {
        VStack(spacing: 20) {
            ProgressView()
                .scaleEffect(1.5)
            
            Text("rating.loading".localized)
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .frame(height: 400)
    }
    
    /// Empty state view
    var emptyStateView: some View {
        VStack(spacing: 20) {
            Image(systemName: "photo.badge.plus")
                .font(.system(size: 60))
                .foregroundColor(.gray)
            
            Text("rating.no_photos".localized)
                .font(.headline)
                .foregroundColor(.primary)
            
            Text("rating.try_later".localized)
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            Button("rating.reload".localized) {
                Task {
                    await loadPhotos()
                }
            }
            .buttonStyle(.borderedProminent)
        }
        .frame(height: 400)
    }
}

// MARK: - Helper Methods
private extension PhotoRatingDemoView {
    
    /// Load photos for rating
    func loadPhotos() async {
        do {
            let fetchedPhotos = try await photoRatingService.fetchPhotosForRating(excludingUser: "current_user_id")
            
            await MainActor.run {
                photos = fetchedPhotos
                currentPhotoIndex = 0
                
                // Show notification if using sample photos
                let hasSamplePhotos = fetchedPhotos.contains { $0.isSample }
                if hasSamplePhotos && !hasShownSampleNotification {
                    showSampleNotification = true
                }
            }
            
        } catch {
            print("Failed to load photos: \(error)")
        }
    }
    
    /// Submit rating for current photo
    func submitRating(isHot: Bool) {
        guard currentPhotoIndex < photos.count else { return }
        
        let currentPhoto = photos[currentPhotoIndex]
        let rating = Rating(
            photoId: currentPhoto.id,
            raterId: "current_user_id",
            isHot: isHot
        )
        
        Task {
            do {
                try await photoRatingService.submitRating(rating)
                
                await MainActor.run {
                    // Move to next photo
                    if currentPhotoIndex < photos.count - 1 {
                        currentPhotoIndex += 1
                    } else {
                        // Reload photos when reaching the end
                        Task {
                            await loadPhotos()
                        }
                    }
                }
                
            } catch {
                print("Failed to submit rating: \(error)")
            }
        }
    }
}

// MARK: - Preview
#Preview {
    PhotoRatingDemoView()
}