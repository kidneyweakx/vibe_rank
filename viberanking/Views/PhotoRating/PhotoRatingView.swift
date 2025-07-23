//
//  PhotoRatingView.swift
//  viberanking
//
//  Created by Kiro on 2025/07/23.
//

import SwiftUI

// MARK: - Photo Rating View
struct PhotoRatingView: View {
    @StateObject private var viewModel = PhotoRatingViewModel()
    @State private var showingUploadView = false
    
    let userId: String
    
    // Computed property for preloading URLs
    private var preloadUrls: [String] {
        let startIndex = viewModel.currentPhotoIndex
        let endIndex = min(startIndex + 5, viewModel.photos.count)
        return Array(viewModel.photos[startIndex..<endIndex]).map { $0.imageURL }
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Background
                LinearGradient(
                    colors: [Color.primary.opacity(0.05), Color.secondary.opacity(0.1)],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()
                
                VStack(spacing: 20) {
                    // Progress Section
                    progressSection
                    
                    // Photo Rating Section
                    photoRatingSection
                    
                    // Action Buttons
                    actionButtonsSection
                    
                    Spacer()
                }
                .padding()
                
                // Rating Feedback Overlay
                if viewModel.showRatingFeedback {
                    ratingFeedbackOverlay
                }
                
                // Image Preloader
                ImagePreloader(urls: preloadUrls)
            }
            .navigationTitle("評分照片")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    if viewModel.ratingProgress.hasUnlockedUpload {
                        Button("上傳") {
                            showingUploadView = true
                        }
                        .foregroundColor(.blue)
                    }
                }
            }
            .sheet(isPresented: $showingUploadView) {
                // Photo upload view will be implemented in another task
                Text("照片上傳功能")
                    .font(.title2)
                    .padding()
            }
            .task {
                await viewModel.loadPhotosForRating(userId: userId)
            }
            .refreshable {
                await viewModel.refreshPhotos()
            }
        }
    }
}

// MARK: - View Components
private extension PhotoRatingView {
    
    // Progress Section
    var progressSection: some View {
        VStack(spacing: 12) {
            // Progress Text
            Text(viewModel.progressText)
                .font(.headline)
                .foregroundColor(viewModel.ratingProgress.hasUnlockedUpload ? .green : .primary)
                .multilineTextAlignment(.center)
            
            // Progress Bar
            ProgressView(value: viewModel.progressPercentage)
                .progressViewStyle(LinearProgressViewStyle(tint: viewModel.ratingProgress.hasUnlockedUpload ? .green : .blue))
                .scaleEffect(y: 2)
            
            // Progress Numbers
            HStack {
                Text("\(viewModel.ratingProgress.completedRatings)")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                Text("\(viewModel.ratingProgress.requiredRatings)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.horizontal)
    }
    
    // Photo Rating Section
    var photoRatingSection: some View {
        ZStack {
            if viewModel.isLoading {
                loadingView
            } else if let photo = viewModel.currentPhoto {
                photoCardView(photo: photo)
            } else {
                emptyStateView
            }
        }
        .frame(maxWidth: .infinity, maxHeight: 500)
    }
    
    // Photo Card View
    func photoCardView(photo: Photo) -> some View {
        ZStack {
            // Background cards for depth
            ForEach(0..<min(3, viewModel.photos.count - viewModel.currentPhotoIndex), id: \.self) { index in
                if viewModel.currentPhotoIndex + index < viewModel.photos.count {
                    let cardPhoto = viewModel.photos[viewModel.currentPhotoIndex + index]
                    photoCard(photo: cardPhoto, index: index)
                }
            }
        }
    }
    
    // Individual Photo Card
    func photoCard(photo: Photo, index: Int) -> some View {
        RoundedRectangle(cornerRadius: 20)
            .fill(Color.white)
            .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 5)
            .overlay {
                CachedAsyncImage(url: photo.imageURL) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .clipped()
                } placeholder: {
                    ZStack {
                        Color.gray.opacity(0.2)
                        ProgressView()
                            .scaleEffect(1.5)
                    }
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: 20))
            .scaleEffect(index == 0 ? 1.0 : 0.95 - Double(index) * 0.05)
            .offset(
                x: index == 0 ? viewModel.dragOffset.width : 0,
                y: index == 0 ? viewModel.dragOffset.height : CGFloat(index) * 5
            )
            .rotationEffect(.degrees(index == 0 ? viewModel.rotationAngle : 0))
            .opacity(index == 0 ? 1.0 : 0.8 - Double(index) * 0.2)
            .gesture(
                index == 0 ? DragGesture()
                    .onChanged { value in
                        viewModel.handleDragGesture(value)
                    }
                    .onEnded { value in
                        Task {
                            await viewModel.handleDragEnd(value)
                        }
                    } : nil
            )
            .overlay {
                if index == 0 {
                    dragIndicatorOverlay
                }
            }
    }
    
    // Drag Indicator Overlay
    var dragIndicatorOverlay: some View {
        ZStack {
            // Hot indicator (right side)
            if viewModel.dragOffset.width > 50 {
                VStack {
                    Image(systemName: "heart.fill")
                        .font(.system(size: 40))
                        .foregroundColor(.red)
                    Text("HOT")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.red)
                }
                .opacity(min(Double(viewModel.dragOffset.width) / 150.0, 1.0))
                .scaleEffect(1.0 + min(Double(viewModel.dragOffset.width) / 300.0, 0.3))
            }
            
            // Not indicator (left side)
            if viewModel.dragOffset.width < -50 {
                VStack {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 40))
                        .foregroundColor(.blue)
                    Text("NOT")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.blue)
                }
                .opacity(min(Double(-viewModel.dragOffset.width) / 150.0, 1.0))
                .scaleEffect(1.0 + min(Double(-viewModel.dragOffset.width) / 300.0, 0.3))
            }
        }
    }
    
    // Action Buttons Section
    var actionButtonsSection: some View {
        HStack(spacing: 40) {
            // Not Button
            Button {
                Task {
                    await viewModel.submitRating(isHot: false)
                }
            } label: {
                ZStack {
                    Circle()
                        .fill(Color.blue)
                        .frame(width: 70, height: 70)
                        .shadow(color: .blue.opacity(0.3), radius: 10, x: 0, y: 5)
                    
                    Image(systemName: "xmark")
                        .font(.system(size: 30, weight: .bold))
                        .foregroundColor(.white)
                }
            }
            .disabled(viewModel.currentPhoto == nil || viewModel.isLoading)
            .scaleEffect(viewModel.isLoading ? 0.9 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: viewModel.isLoading)
            
            // Hot Button
            Button {
                Task {
                    await viewModel.submitRating(isHot: true)
                }
            } label: {
                ZStack {
                    Circle()
                        .fill(Color.red)
                        .frame(width: 70, height: 70)
                        .shadow(color: .red.opacity(0.3), radius: 10, x: 0, y: 5)
                    
                    Image(systemName: "heart.fill")
                        .font(.system(size: 30, weight: .bold))
                        .foregroundColor(.white)
                }
            }
            .disabled(viewModel.currentPhoto == nil || viewModel.isLoading)
            .scaleEffect(viewModel.isLoading ? 0.9 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: viewModel.isLoading)
        }
    }
    
    // Loading View
    var loadingView: some View {
        VStack(spacing: 20) {
            ProgressView()
                .scaleEffect(1.5)
            
            Text("載入照片中...")
                .font(.headline)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    // Empty State View
    var emptyStateView: some View {
        VStack(spacing: 20) {
            Image(systemName: "photo.stack")
                .font(.system(size: 60))
                .foregroundColor(.secondary)
            
            Text("沒有更多照片了")
                .font(.title2)
                .fontWeight(.medium)
            
            Text("請稍後再試或重新整理")
                .font(.body)
                .foregroundColor(.secondary)
            
            Button("重新載入") {
                Task {
                    await viewModel.refreshPhotos()
                }
            }
            .buttonStyle(.borderedProminent)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    // Rating Feedback Overlay
    var ratingFeedbackOverlay: some View {
        ZStack {
            Color.black.opacity(0.3)
                .ignoresSafeArea()
            
            VStack(spacing: 20) {
                Image(systemName: viewModel.lastRatingWasHot ? "heart.fill" : "xmark.circle.fill")
                    .font(.system(size: 80))
                    .foregroundColor(viewModel.lastRatingWasHot ? .red : .blue)
                
                Text(viewModel.lastRatingWasHot ? "HOT!" : "NOT!")
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundColor(viewModel.lastRatingWasHot ? .red : .blue)
            }
            .scaleEffect(1.2)
            .animation(.spring(response: 0.5, dampingFraction: 0.6), value: viewModel.showRatingFeedback)
        }
        .transition(.opacity)
    }
}

// MARK: - Preview
#Preview {
    PhotoRatingView(userId: "preview_user")
}
