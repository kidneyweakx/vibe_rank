//
//  UploadTabView.swift
//  viberanking
//
//  Created by Kiro on 2025/07/25.
//

import SwiftUI
import PhotosUI

struct UploadTabView: View {
    @EnvironmentObject private var authViewModel: AuthenticationViewModel
    @EnvironmentObject private var themeManager: ThemeManager
    @StateObject private var uploadViewModel = PhotoUploadViewModel()
    @State private var selectedPhotos: [PhotosPickerItem] = []
    @State private var uploadedImages: [UIImage] = []
    @State private var isUploading = false
    @State private var showingImagePicker = false
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Cute background matching the main theme
                LinearGradient(
                    colors: [themeManager.currentTheme.colors.primary, themeManager.currentTheme.colors.secondary],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                // Floating decorative elements
//                GeometryReader { geometry in
//                    ForEach(0..<6, id: \.self) { index in
//                        FloatingShape(geometry: geometry, index: index)
//                    }
////                }
//                .ignoresSafeArea()
                
                if authViewModel.isGuest || !(authViewModel.user?.ratingProgress.hasUnlockedUpload ?? false) {
                    lockedStateView
                } else {
                    uploadContentView
                }
            }
            .navigationTitle("upload.title".localized)
            .navigationBarTitleDisplayMode(.large)
            .toolbarBackground(.hidden, for: .navigationBar)
        }
    }
}

// MARK: - View Components
private extension UploadTabView {
    
    var lockedStateView: some View {
        VStack(spacing: AppTheme.Spacing.lg) {
            // Cute lock animation
            ZStack {
                // Glow effect
                Circle()
                    .fill(themeManager.currentTheme.colors.accent.opacity(0.3))
                    .frame(width: 140, height: 140)
                    .blur(radius: 20)
                
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [themeManager.currentTheme.colors.accent, themeManager.currentTheme.colors.accent.opacity(0.8)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 120, height: 120)
                    .shadow(color: themeManager.currentTheme.colors.accent.opacity(0.4), radius: 20, x: 0, y: 10)
                
                Text("🔒")
                    .font(.system(size: 60))
                    .shadow(color: .black.opacity(0.2), radius: 2, x: 0, y: 1)
            }
            
            VStack(spacing: AppTheme.Spacing.md) {
                Text("upload.locked_title".localized)
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundColor(themeManager.currentTheme.colors.text)
                    .shadow(color: .black.opacity(0.3), radius: 2, x: 0, y: 1)
                
                if authViewModel.isGuest {
                    VStack(spacing: AppTheme.Spacing.md) {
                        Text("login.required.upload".localized)
                            .font(AppTheme.Typography.body)
                            .foregroundColor(themeManager.currentTheme.colors.text.opacity(0.9))
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, AppTheme.Spacing.md)
                            .padding(.vertical, AppTheme.Spacing.sm)
                            .background(
                                RoundedRectangle(cornerRadius: AppTheme.CornerRadius.md)
                                    .fill(.ultraThinMaterial)
                            )
                        
                        Button("guest.sign_in_now".localized) {
                            authViewModel.signOut()
                        }
                        .font(.system(size: 18, weight: .semibold, design: .rounded))
                        .foregroundColor(.white)
                        .padding(.horizontal, AppTheme.Spacing.xl)
                        .padding(.vertical, AppTheme.Spacing.md)
                        .background(
                            RoundedRectangle(cornerRadius: AppTheme.CornerRadius.lg)
                                .fill(themeManager.currentTheme.colors.accent)
                                .shadow(color: themeManager.currentTheme.colors.accent.opacity(0.4), radius: 15, x: 0, y: 8)
                        )
                    }
                } else {
                    let remaining = (authViewModel.user?.ratingProgress.requiredRatings ?? 0) - (authViewModel.user?.ratingProgress.completedRatings ?? 0)
                    
                    VStack(spacing: AppTheme.Spacing.md) {
                        Text("還需要評分 \(remaining) 張照片才能解鎖上傳功能")
                            .font(AppTheme.Typography.body)
                            .foregroundColor(.white.opacity(0.9))
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, AppTheme.Spacing.md)
                            .padding(.vertical, AppTheme.Spacing.sm)
                            .background(
                                RoundedRectangle(cornerRadius: AppTheme.CornerRadius.md)
                                    .fill(.ultraThinMaterial)
                            )
                        
                        // Enhanced progress indicator
                        VStack(spacing: AppTheme.Spacing.sm) {
                            HStack {
                                Text("進度")
                                    .font(.system(size: 16, weight: .semibold, design: .rounded))
                                    .foregroundColor(.white)
                                
                                Spacer()
                                
                                Text("\(authViewModel.user?.ratingProgress.completedRatings ?? 0)/\(authViewModel.user?.ratingProgress.requiredRatings ?? 0)")
                                    .font(.system(size: 16, weight: .semibold, design: .rounded))
                                    .foregroundColor(themeManager.currentTheme.colors.accent)
                            }
                            
                            ZStack(alignment: .leading) {
                                RoundedRectangle(cornerRadius: AppTheme.CornerRadius.sm)
                                    .fill(.white.opacity(0.2))
                                    .frame(height: 12)
                                
                                RoundedRectangle(cornerRadius: AppTheme.CornerRadius.sm)
                                    .fill(
                                        LinearGradient(
                                            colors: [themeManager.currentTheme.colors.accent, themeManager.currentTheme.colors.accent.opacity(0.8)],
                                            startPoint: .leading,
                                            endPoint: .trailing
                                        )
                                    )
                                    .frame(
                                        width: max(0, UIScreen.main.bounds.width * 0.7 * (authViewModel.user?.ratingProgress.progressPercentage ?? 0)),
                                        height: 12
                                    )
                                    .shadow(color: themeManager.currentTheme.colors.accent.opacity(0.5), radius: 5, x: 0, y: 2)
                                    .animation(.easeInOut(duration: 0.5), value: authViewModel.user?.ratingProgress.progressPercentage)
                            }
                        }
                        .padding(AppTheme.Spacing.md)
                        .background(
                            RoundedRectangle(cornerRadius: AppTheme.CornerRadius.lg)
                                .fill(.ultraThinMaterial)
                                .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 5)
                        )
                    }
                }
            }
        }
        .padding(.horizontal, AppTheme.Spacing.md)
    }
    
    var uploadContentView: some View {
        ScrollView {
            VStack(spacing: AppTheme.Spacing.lg) {
                // Upload area
                uploadArea
                
                // Selected photos grid
                if !uploadedImages.isEmpty {
                    selectedPhotosGrid
                }
                
                // Upload guidelines
                uploadGuidelines
                
                Spacer(minLength: AppTheme.Spacing.xxl)
            }
            .padding(.horizontal, AppTheme.Spacing.md)
        }
    }
    
    var uploadArea: some View {
        VStack(spacing: AppTheme.Spacing.lg) {
            // Upload icon and text
            VStack(spacing: AppTheme.Spacing.md) {
                ZStack {
                    Circle()
                        .fill(themeManager.currentTheme.colors.primary.opacity(0.2))
                        .frame(width: 100, height: 100)
                    
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 60))
                        .foregroundColor(themeManager.currentTheme.colors.primary)
                }
                
                VStack(spacing: AppTheme.Spacing.xs) {
                    Text("upload.select_photos".localized)
                        .font(AppTheme.Typography.title2)
                        .foregroundColor(themeManager.currentTheme.colors.text)
                    
                    Text("upload.select_photos_description".localized)
                        .font(AppTheme.Typography.body)
                        .foregroundColor(themeManager.currentTheme.colors.text.opacity(0.7))
                        .multilineTextAlignment(.center)
                }
            }
            
            // Photo picker button
            PhotosPicker(
                selection: $selectedPhotos,
                maxSelectionCount: 5,
                matching: .images
            ) {
                HStack(spacing: AppTheme.Spacing.sm) {
                    Image(systemName: "photo.on.rectangle.angled")
                        .font(.title3)
                    Text("upload.choose_library".localized)
                        .font(AppTheme.Typography.headline)
                }
                .foregroundColor(.white)
                .padding(.horizontal, AppTheme.Spacing.lg)
                .padding(.vertical, AppTheme.Spacing.md)
                .background(LinearGradient(
                    colors: [themeManager.currentTheme.colors.primary, themeManager.currentTheme.colors.secondary],
                    startPoint: .leading,
                    endPoint: .trailing
                ))
                .clipShape(RoundedRectangle(cornerRadius: AppTheme.CornerRadius.lg))
            }
            .onChange(of: selectedPhotos) { _, newItems in
                loadSelectedPhotos(newItems)
            }
            
            // Camera button
            Button {
                showingImagePicker = true
            } label: {
                HStack(spacing: AppTheme.Spacing.sm) {
                    Image(systemName: "camera.fill")
                        .font(.title3)
                    Text("拍攝照片")
                        .font(AppTheme.Typography.headline)
                }
            }
            .secondaryButton()
            .sheet(isPresented: $showingImagePicker) {
                ImagePicker(sourceType: .camera) { image in
                    uploadedImages.append(image)
                }
            }
        }
        .cardStyle(padding: AppTheme.Spacing.lg)
    }
    
    var selectedPhotosGrid: some View {
        VStack(spacing: AppTheme.Spacing.md) {
            HStack {
                Text(String(format: "upload.selected_photos".localized, uploadedImages.count))
                    .font(AppTheme.Typography.headline)
                    .foregroundColor(themeManager.currentTheme.colors.text)
                
                Spacer()
                
                Button("upload.clear_all".localized) {
                    uploadedImages.removeAll()
                    selectedPhotos.removeAll()
                }
                .font(AppTheme.Typography.caption)
                .foregroundColor(themeManager.currentTheme.colors.accent)
            }
            
            GeometryReader { geometry in
                let threeColumnWidth = (geometry.size.width - AppTheme.Spacing.sm * 2) / 3
                LazyVGrid(columns: [
                    GridItem(.fixed(threeColumnWidth)),
                    GridItem(.fixed(threeColumnWidth)),
                    GridItem(.fixed(threeColumnWidth))
                ], spacing: AppTheme.Spacing.sm) {
                    ForEach(Array(uploadedImages.enumerated()), id: \.offset) { index, image in
                        ZStack(alignment: .topTrailing) {
                            Image(uiImage: image)
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(width: threeColumnWidth, height: threeColumnWidth)
                                .clipShape(RoundedRectangle(cornerRadius: AppTheme.CornerRadius.md))
                            
                            Button {
                                uploadedImages.remove(at: index)
                            } label: {
                                Image(systemName: "xmark.circle.fill")
                                    .font(.title3)
                                    .foregroundColor(.white)
                                    .background(Color.black.opacity(0.6))
                                    .clipShape(Circle())
                            }
                            .padding(AppTheme.Spacing.xs)
                        }
                    }
                }
            }
            .frame(height: calculateGridHeight())


            
            // Upload button
            if !uploadedImages.isEmpty {
                Button {
                    uploadPhotos()
                } label: {
                    HStack(spacing: AppTheme.Spacing.sm) {
                        if isUploading {
                            ProgressView()
                                .scaleEffect(0.8)
                        } else {
                            Image(systemName: "icloud.and.arrow.up.fill")
                                .font(.title3)
                        }
                        
                        Text(isUploading ? "上傳中..." : "開始上傳")
                            .font(AppTheme.Typography.headline)
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, AppTheme.Spacing.md)
                    .background(.green)
                    .clipShape(RoundedRectangle(cornerRadius: AppTheme.CornerRadius.lg))
                }
                .disabled(isUploading)
            }
        }
        .cardStyle()
    }
    
    var uploadGuidelines: some View {
        VStack(spacing: AppTheme.Spacing.md) {
            HStack {
                Text("upload.guidelines_title".localized)
                    .font(AppTheme.Typography.headline)
                    .foregroundColor(themeManager.currentTheme.colors.text)
                Spacer()
            }
            
            VStack(alignment: .leading, spacing: AppTheme.Spacing.sm) {
                GuidelineRow(
                    icon: "checkmark.circle.fill",
                    text: "upload.guideline_clear_photo".localized,
                    color: themeManager.currentTheme.colors.primary
                )
                
                GuidelineRow(
                    icon: "checkmark.circle.fill",
                    text: "upload.guideline_person_photo".localized,
                    color: themeManager.currentTheme.colors.primary
                )
                
                GuidelineRow(
                    icon: "checkmark.circle.fill",
                    text: "upload.guideline_max_5_photos".localized,
                    color: themeManager.currentTheme.colors.primary
                )
                
                GuidelineRow(
                    icon: "xmark.circle.fill",
                    text: "upload.guideline_no_inappropriate_content".localized,
                    color: themeManager.currentTheme.colors.accent
                )
                
                GuidelineRow(
                    icon: "info.circle.fill",
                    text: "upload.guideline_for_rating_system".localized,
                    color: themeManager.currentTheme.colors.secondary
                )
            }
        }
        .cardStyle()
    }
    
    // MARK: - Helper Functions
    private func calculateGridHeight() -> CGFloat {
        guard !uploadedImages.isEmpty else { return 0 }
        
        let screenWidth = UIScreen.main.bounds.width
        let horizontalPadding = AppTheme.Spacing.md * 2
        let gridSpacing = AppTheme.Spacing.sm * 2
        let itemWidth = (screenWidth - horizontalPadding - gridSpacing) / 3
        let rowCount = ceil(Double(uploadedImages.count) / 3.0)
        
        return itemWidth * rowCount
    }
}

// MARK: - Supporting Views
struct GuidelineRow: View {
    let icon: String
    let text: String
    let color: Color
    
    var body: some View {
        HStack(spacing: AppTheme.Spacing.sm) {
            Image(systemName: icon)
                .font(.caption)
                .foregroundColor(color)
                .frame(width: 16)
            
            Text(text)
                .font(AppTheme.Typography.subheadline)
                .foregroundColor(Color.primary)
            
            Spacer()
        }
    }
}

// MARK: - Actions
private extension UploadTabView {
    func loadSelectedPhotos(_ items: [PhotosPickerItem]) {
        Task {
            uploadedImages.removeAll()
            
            for item in items {
                if let data = try? await item.loadTransferable(type: Data.self),
                   let image = UIImage(data: data) {
                    await MainActor.run {
                        uploadedImages.append(image)
                    }
                }
            }
        }
    }
    
    func uploadPhotos() {
        isUploading = true
        Task {
            for image in uploadedImages {
                uploadViewModel.handleSelectedImage(image)
                await uploadViewModel.performUpload(image: image, userId: authViewModel.user?.id ?? "")
            }
            
            await MainActor.run {
                isUploading = false
                uploadedImages.removeAll()
                selectedPhotos.removeAll()
            }

        }
    }
}

#Preview {
    UploadTabView()
        .environmentObject(AuthenticationViewModel())
        .environmentObject(ThemeManager())
}
