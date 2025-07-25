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
    @State private var selectedPhotos: [PhotosPickerItem] = []
    @State private var uploadedImages: [UIImage] = []
    @State private var isUploading = false
    @State private var showingImagePicker = false
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Cute background matching the main theme
                AppTheme.Colors.primaryGradient
                    .ignoresSafeArea()
                
                // Floating decorative elements
                GeometryReader { geometry in
                    ForEach(0..<6, id: \.self) { index in
                        FloatingShape(geometry: geometry, index: index)
                    }
                }
                .ignoresSafeArea()
                
                if authViewModel.isGuest || !(authViewModel.user?.ratingProgress.hasUnlockedUpload ?? false) {
                    lockedStateView
                } else {
                    uploadContentView
                }
            }
            .navigationTitle("上傳照片")
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
                    .fill(AppTheme.Colors.warning.opacity(0.3))
                    .frame(width: 140, height: 140)
                    .blur(radius: 20)
                
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [AppTheme.Colors.warning, AppTheme.Colors.warning.opacity(0.8)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 120, height: 120)
                    .shadow(color: AppTheme.Colors.warning.opacity(0.4), radius: 20, x: 0, y: 10)
                
                Text("🔒")
                    .font(.system(size: 60))
                    .shadow(color: .black.opacity(0.2), radius: 2, x: 0, y: 1)
            }
            
            VStack(spacing: AppTheme.Spacing.md) {
                Text("功能尚未解鎖")
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                    .shadow(color: .black.opacity(0.3), radius: 2, x: 0, y: 1)
                
                if authViewModel.isGuest {
                    VStack(spacing: AppTheme.Spacing.md) {
                        Text("請先註冊帳號以使用上傳功能")
                            .font(AppTheme.Typography.body)
                            .foregroundColor(.white.opacity(0.9))
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, AppTheme.Spacing.md)
                            .padding(.vertical, AppTheme.Spacing.sm)
                            .background(
                                RoundedRectangle(cornerRadius: AppTheme.CornerRadius.md)
                                    .fill(.ultraThinMaterial)
                            )
                        
                        Button("註冊帳號") {
                            authViewModel.signOut()
                        }
                        .font(.system(size: 18, weight: .semibold, design: .rounded))
                        .foregroundColor(.white)
                        .padding(.horizontal, AppTheme.Spacing.xl)
                        .padding(.vertical, AppTheme.Spacing.md)
                        .background(
                            RoundedRectangle(cornerRadius: AppTheme.CornerRadius.lg)
                                .fill(AppTheme.Colors.accentYellow)
                                .shadow(color: AppTheme.Colors.accentYellow.opacity(0.4), radius: 15, x: 0, y: 8)
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
                                    .foregroundColor(AppTheme.Colors.accentYellow)
                            }
                            
                            ZStack(alignment: .leading) {
                                RoundedRectangle(cornerRadius: AppTheme.CornerRadius.sm)
                                    .fill(.white.opacity(0.2))
                                    .frame(height: 12)
                                
                                RoundedRectangle(cornerRadius: AppTheme.CornerRadius.sm)
                                    .fill(
                                        LinearGradient(
                                            colors: [AppTheme.Colors.accentYellow, AppTheme.Colors.accentYellow.opacity(0.8)],
                                            startPoint: .leading,
                                            endPoint: .trailing
                                        )
                                    )
                                    .frame(
                                        width: max(0, UIScreen.main.bounds.width * 0.7 * (authViewModel.user?.ratingProgress.progressPercentage ?? 0)),
                                        height: 12
                                    )
                                    .shadow(color: AppTheme.Colors.accentYellow.opacity(0.5), radius: 5, x: 0, y: 2)
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
                        .fill(AppTheme.Colors.primaryBlue.opacity(0.2))
                        .frame(width: 100, height: 100)
                    
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 60))
                        .foregroundColor(AppTheme.Colors.primaryBlue)
                }
                
                VStack(spacing: AppTheme.Spacing.xs) {
                    Text("選擇照片上傳")
                        .font(AppTheme.Typography.title2)
                        .foregroundColor(AppTheme.Colors.textPrimary)
                    
                    Text("點擊選擇或拖拽照片到此處")
                        .font(AppTheme.Typography.body)
                        .foregroundColor(AppTheme.Colors.textSecondary)
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
                    Text("從相簿選擇")
                        .font(AppTheme.Typography.headline)
                }
                .foregroundColor(.white)
                .padding(.horizontal, AppTheme.Spacing.lg)
                .padding(.vertical, AppTheme.Spacing.md)
                .background(AppTheme.Colors.primaryGradient)
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
                Text("已選擇的照片 (\(uploadedImages.count))")
                    .font(AppTheme.Typography.headline)
                    .foregroundColor(AppTheme.Colors.textPrimary)
                
                Spacer()
                
                Button("清除全部") {
                    uploadedImages.removeAll()
                    selectedPhotos.removeAll()
                }
                .font(AppTheme.Typography.caption)
                .foregroundColor(AppTheme.Colors.error)
            }
            
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: AppTheme.Spacing.sm) {
                ForEach(Array(uploadedImages.enumerated()), id: \.offset) { index, image in
                    ZStack(alignment: .topTrailing) {
                        Image(uiImage: image)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(height: 120)
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
                    .background(AppTheme.Colors.success)
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
                Text("上傳須知")
                    .font(AppTheme.Typography.headline)
                    .foregroundColor(AppTheme.Colors.textPrimary)
                Spacer()
            }
            
            VStack(alignment: .leading, spacing: AppTheme.Spacing.sm) {
                GuidelineRow(
                    icon: "checkmark.circle.fill",
                    text: "照片需清晰，光線充足",
                    color: AppTheme.Colors.success
                )
                
                GuidelineRow(
                    icon: "checkmark.circle.fill",
                    text: "建議上傳人物照片",
                    color: AppTheme.Colors.success
                )
                
                GuidelineRow(
                    icon: "checkmark.circle.fill",
                    text: "每次最多上傳 5 張照片",
                    color: AppTheme.Colors.success
                )
                
                GuidelineRow(
                    icon: "xmark.circle.fill",
                    text: "不得上傳不當內容",
                    color: AppTheme.Colors.error
                )
                
                GuidelineRow(
                    icon: "info.circle.fill",
                    text: "上傳的照片將用於評分系統",
                    color: AppTheme.Colors.info
                )
            }
        }
        .cardStyle()
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
                .foregroundColor(AppTheme.Colors.textPrimary)
            
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
        
        // TODO: Implement actual upload logic
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            isUploading = false
            uploadedImages.removeAll()
            selectedPhotos.removeAll()
            
            // Show success message
        }
    }
}

#Preview {
    UploadTabView()
        .environmentObject(AuthenticationViewModel())
}