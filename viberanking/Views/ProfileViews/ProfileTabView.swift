//
//  ProfileTabView.swift
//  viberanking
//
//  Created by Kiro on 2025/07/25.
//

import SwiftUI

struct ProfileTabView: View {
    @EnvironmentObject private var authViewModel: AuthenticationViewModel
    @EnvironmentObject private var themeManager: ThemeManager
    @StateObject private var viewModel = ProfileViewModel()
    @State private var showingImagePicker = false
    @State private var showingQRCode = false
    @State private var showingSettings = false
    @State private var isUploadingProfilePicture = false
    @State private var uploadProgress: Double = 0.0
    @State private var showingActionSheet = false
    @State private var showingUploadMenu = false
    @State private var showingPhotoPicker = false
    @State private var showingRegularImagePicker = false
    @State private var showingRegularPhotoPicker = false
    @State private var showingRegularImagePreview = false
    @State private var selectedRegularImage: UIImage?
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.black.ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Profile Header
                    profileHeader
                        .padding(.horizontal, 20)
                        .padding(.top, 20)
                    
                    // Weekly Photos ScrollView
                    weeklyPhotosScrollView
                        .padding(.top, 24)
                }
            }
            .navigationBarHidden(true)
        }
        // NOTE: removed duplicate sheet for showingImagePicker (photoLibrary)
        .sheet(isPresented: $showingQRCode) {
            QRCodeShareView(
                userId: authViewModel.user?.id ?? "",
                isPresented: $showingQRCode
            )
        }
        .fullScreenCover(isPresented: $showingSettings, onDismiss: {
            Task { await viewModel.refreshData() }
        }) {
            SettingsView(onResetSpotlight: {
                // Reset all spotlight flags
                UserDefaults.standard.set(false, forKey: "has_seen_main_spotlight")
                UserDefaults.standard.set(false, forKey: "has_seen_spotlight_rating_page")
                UserDefaults.standard.set(false, forKey: "has_seen_spotlight_trend_page")
                UserDefaults.standard.set(false, forKey: "has_seen_spotlight_journey_page")
                UserDefaults.standard.set(false, forKey: "has_seen_spotlight_profile_page")
                
                // Also reset user-specific spotlight state if available
                if let userId = authViewModel.user?.id {
                    let userSpotlightKey = "has_seen_spotlight_user_\(userId)"
                    UserDefaults.standard.set(false, forKey: userSpotlightKey)
                    print("🔄 Reset user-specific spotlight state for user: \(userId)")
                }
                
                print("🔄 Spotlight state reset from settings")
            })
        }
        .task {
            if let userId = authViewModel.user?.id {
                await viewModel.loadUserProfile(userId: userId)
            }
        }
        .refreshable {
            await viewModel.refreshData()
        }

        .actionSheet(isPresented: $showingActionSheet) {
            ActionSheet(
                title: Text("profile.edit_profile".localized),
                buttons: [
                    .default(Text("upload.take_photo".localized)) {
                        showingImagePicker = true
                    },
                    .default(Text("upload.menu.library".localized)) {
                        showingPhotoPicker = true
                    },
                    .cancel(Text("common.cancel".localized))
                ]
            )
        }
        .sheet(isPresented: $showingUploadMenu) {
            UploadMenuView(
                onCameraSelected: {
                    showingRegularImagePicker = true
                },
                onPhotoLibrarySelected: {
                    showingRegularPhotoPicker = true
                }
            )
            .presentationDetents([.height(200)])
            .presentationDragIndicator(.visible)
        }
        .sheet(isPresented: $showingImagePicker) {
            ImagePicker(sourceType: .camera) { image in
                uploadProfileImage(image)
            }
        }
        .sheet(isPresented: $showingPhotoPicker) {
            PhotoPickerView { image in
                print("📸 ProfileTabView: PhotoPickerView returned image with size: \(image.size)")
                uploadProfileImage(image)
            }
        }
        .sheet(isPresented: $showingRegularImagePicker) {
            ImagePicker(sourceType: .camera) { image in
                print("📸 ProfileTabView: Camera returned image size: \(image.size)")
                selectedRegularImage = image
                // Delay to avoid race with sheet dismissal
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    showingRegularImagePreview = true
                }
            }
        }
        .sheet(isPresented: $showingRegularPhotoPicker) {
            PhotoPickerView { image in
                print("📸 ProfileTabView: PhotoPickerView returned image size: \(image.size)")
                selectedRegularImage = image
                // Delay to avoid race with sheet dismissal
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    showingRegularImagePreview = true
                }
            }
        }
        .fullScreenCover(isPresented: $showingRegularImagePreview) {
            Group {
                if let image = selectedRegularImage {
                    ImagePreviewView(image: image) {
                        selectedRegularImage = nil
                    }
                } else {
                    Text("common.image_load_failed".localized)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .background(Color.black)
                        .onAppear {
                            print("❌ ProfileTabView: selectedRegularImage is nil while presenting preview")
                            print("❌ ProfileTabView: showingRegularImagePreview = \(showingRegularImagePreview)")
                        }
                }
            }
        }
        .onChange(of: selectedRegularImage) { newImage in
            if let image = newImage {
                print("🔄 ProfileTabView: selectedRegularImage updated size: \(image.size)")
            } else {
                print("🔄 ProfileTabView: selectedRegularImage reset to nil")
            }
        }
        .onChange(of: showingRegularImagePreview) { isShowing in
            print("🔄 ProfileTabView: showingRegularImagePreview changed: \(isShowing)")
        }

    }
    
    private func uploadProfileImage(_ image: UIImage) {
        guard let userId = authViewModel.user?.id else { 
            print("❌ ProfileTabView: No user ID available for upload")
            return 
        }
        
        print("📸 ProfileTabView: Starting profile picture upload")
        print("  - User ID: \(userId)")
        print("  - Image Size: \(image.size)")
        
        Task {
            await MainActor.run {
                isUploadingProfilePicture = true
                uploadProgress = 0.0
            }
            
            do {
                // Compress image to reduce upload size
                guard let imageData = image.jpegData(compressionQuality: 0.8) else {
                    print("❌ ProfileTabView: Failed to compress image to JPEG")
                    throw APIError.invalidResponse
                }
                
                print("📸 ProfileTabView: Image compressed successfully")
                print("  - Compressed size: \(imageData.count) bytes")
                
                // Simulate progress updates
                for progress in stride(from: 0.0, through: 0.9, by: 0.1) {
                    await MainActor.run {
                        uploadProgress = progress
                    }
                    try await Task.sleep(nanoseconds: 100_000_000) // 0.1 second
                }
                
                print("📸 ProfileTabView: Calling UserAPI.uploadProfilePicture")
                // Upload the image using /api/user/profilePicture
                let response = try await UserAPI().uploadProfilePicture(userId: userId, imageData: imageData)
                
                print("✅ ProfileTabView: Upload successful!")
                print("  - Response success: \(response.success)")
                print("  - Avatar URL: \(response.data.avatar)")
                
                await MainActor.run {
                    // Update the user's profile image URL by creating a new User instance
                    if let currentUser = authViewModel.user {
                        let updatedUser = User(
                            id: currentUser.id,
                            name: currentUser.name,
                            email: currentUser.email,
                            profileImageURL: response.data.avatar,
                            gender: currentUser.gender
                        )
                        // Copy over the mutable properties
                        var newUser = updatedUser
                        newUser.lastActivityAt = currentUser.lastActivityAt
                        newUser.ratingProgress = currentUser.ratingProgress
                        newUser.uploadedPhotos = currentUser.uploadedPhotos
                        authViewModel.user = newUser
                        
                        print("✅ ProfileTabView: User profile updated with new avatar URL")
                    }
                    uploadProgress = 1.0
                    isUploadingProfilePicture = false
                }
                
                // Refresh profile data
                print("🔄 ProfileTabView: Refreshing profile data")
                await viewModel.refreshData()
                
            } catch {
                await MainActor.run {
                    isUploadingProfilePicture = false
                    uploadProgress = 0.0
                }
                print("❌ ProfileTabView: Failed to upload profile picture")
                print("  - Error: \(error)")
                print("  - Error Type: \(type(of: error))")
                
                if let apiError = error as? APIError {
                    print("  - API Error: \(apiError)")
                }
                
                // TODO: Show error alert to user
            }
        }
    }
}

// MARK: - View Components
private extension ProfileTabView {
    
    var profileHeader: some View {
        VStack(spacing: 20) {
            // Top row: Avatar and basic info
            HStack(spacing: 16) {
                Button(action: {
                    if !isUploadingProfilePicture {
                        // Show action sheet for camera/photo library selection
                        showingActionSheet = true
                    }
                }) {
                    ZStack {
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [Color.pink.opacity(0.8), Color.purple.opacity(0.6)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 80, height: 80)
                            .overlay(
                                Group {
                                    // 優先使用 ProfileViewModel 中的 userBasicInfo，如果沒有則使用 authViewModel
                                    let profileImageURL = viewModel.userBasicInfo?.avatar ?? authViewModel.user?.profileImageURL
                                    
                                    if let profileImageURL = profileImageURL,
                                       let url = URL(string: profileImageURL) {
                                        AsyncImage(url: url) { phase in
                                            switch phase {
                                            case .empty:
                                                ProgressView().tint(.white)
                                            case .success(let image):
                                                image
                                                    .resizable()
                                                    .scaledToFill()
                                                    .frame(width: 80, height: 80)
                                                    .clipShape(Circle())
                                            case .failure:
                                                Image(systemName: "person.fill")
                                                    .font(.system(size: 32))
                                                    .foregroundColor(.white)
                                            @unknown default:
                                                Color.clear
                                            }
                                        }
                                    } else {
                                        Image(systemName: "person.fill")
                                            .font(.system(size: 32))
                                            .foregroundColor(.white)
                                    }
                                }
                            )
                            .overlay(
                                Circle()
                                    .stroke(Color.white.opacity(0.2), lineWidth: 2)
                            )
                            .onAppear {
                                // Debug avatar display logic
                                let profileImageURL = viewModel.userBasicInfo?.avatar ?? authViewModel.user?.profileImageURL
                                print("🖼️ ProfileTabView: Avatar display logic")
                                print("   - ProfileViewModel userBasicInfo.avatar: \(viewModel.userBasicInfo?.avatar ?? "nil")")
                                print("   - AuthViewModel user.profileImageURL: \(authViewModel.user?.profileImageURL ?? "nil")")
                                print("   - Final profileImageURL: \(profileImageURL ?? "nil")")
                            }
                        
                        // Upload progress overlay
                        if isUploadingProfilePicture {
                            Circle()
                                .stroke(Color.white.opacity(0.3), lineWidth: 3)
                                .frame(width: 80, height: 80)
                            
                            Circle()
                                .trim(from: 0, to: uploadProgress)
                                .stroke(
                                    LinearGradient(
                                        colors: [Color.blue, Color.green],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    ),
                                    style: StrokeStyle(lineWidth: 3, lineCap: .round)
                                )
                                .frame(width: 80, height: 80)
                                .rotationEffect(.degrees(-90))
                                .animation(.easeInOut(duration: 0.3), value: uploadProgress)
                            
                            if uploadProgress < 1.0 {
                                Image(systemName: "arrow.up.circle.fill")
                                    .font(.system(size: 24))
                                    .foregroundColor(.white)
                                    .background(Circle().fill(Color.blue))
                            } else {
                                Image(systemName: "checkmark.circle.fill")
                                    .font(.system(size: 24))
                                    .foregroundColor(.white)
                                    .background(Circle().fill(Color.green))
                            }
                        }
                    }
                }
                .disabled(isUploadingProfilePicture)
                
                VStack(alignment: .leading, spacing: 8) {
                    Text(authViewModel.user?.name ?? "profile.unknown_user".localized)
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(.white)
                    
                    Text("@\(String((authViewModel.user?.id ?? "user").prefix(8)))")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.white.opacity(0.6))
                    
                    // Simple stats
                    HStack(spacing: 16) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("\(viewModel.likeCount)")
                                .font(.system(size: 16, weight: .bold))
                                .foregroundColor(.pink)
                            Text("profile.likes".localized)
                                .font(.system(size: 12))
                                .foregroundColor(.white.opacity(0.6))
                        }
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text("#\(viewModel.overallRank)")
                                .font(.system(size: 16, weight: .bold))
                                .foregroundColor(.yellow)
                            Text("profile.rank".localized)
                                .font(.system(size: 12))
                                .foregroundColor(.white.opacity(0.6))
                        }
                    }
                }
                
                Spacer()
            }
            
            // Action buttons
            VStack(spacing: 12) {
                HStack(spacing: 12) {
                    Button("profile.share_profile".localized) {
                        showingQRCode = true
                    }
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 48)
                    .background(
                        RoundedRectangle(cornerRadius: 24)
                            .fill(Color.blue)
                    )
                    
                    Button("profile.edit_profile".localized) {
                        showingSettings = true
                    }
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 48)
                    .background(
                        RoundedRectangle(cornerRadius: 24)
                            .fill(Color.white.opacity(0.1))
                            .overlay(
                                RoundedRectangle(cornerRadius: 24)
                                    .stroke(Color.white.opacity(0.3), lineWidth: 1)
                            )
                    )
                }
                
            }
        }
    }
    
    var weeklyPhotosScrollView: some View {
        ScrollView {
            LazyVStack(spacing: 24) {
                ForEach(getRecentWeeks(), id: \.weekNumber) { week in
                    WeeklyPhotoSection(week: week, onPhotoTap: {
                        // This should trigger the regular photo upload flow (like + button)
                        showingUploadMenu = true
                    })
                }
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 100)
        }
    }
    
    func getRecentWeeks() -> [WeekData] {
        let calendar = Calendar.current
        let today = Date()
        // Start from current week's start
        let startOfThisWeek = calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: today)) ?? today
        // Map user's photos by day (startOfDay)
        var photosByDay: [Date: [PhotoInfo]] = [:]
        for info in viewModel.userPhotoInfos {
            let dayStart = calendar.startOfDay(for: info.uploadedAt)
            photosByDay[dayStart, default: []].append(info)
        }
        
        print("📸 ProfileTabView: Building weekly photo grid")
        print("  - Total photos: \(viewModel.userPhotoInfos.count)")
        print("  - Photos by day: \(photosByDay.count) days")
        
        var resultWeeks: [WeekData] = []
        
        for i in 0..<5 {
            guard let weekStart = calendar.date(byAdding: .weekOfYear, value: -i, to: startOfThisWeek) else { continue }
            let weekNumber = calendar.component(.weekOfYear, from: weekStart)
            var days: [DayData] = []
            for j in 0..<7 {
                guard let dayDate = calendar.date(byAdding: .day, value: j, to: weekStart) else { continue }
                let dayStart = calendar.startOfDay(for: dayDate)
                let list = photosByDay[dayStart] ?? []
                let dayNumber = calendar.component(.day, from: dayDate)
                let monthName = DateFormatter().shortMonthSymbols[calendar.component(.month, from: dayDate) - 1]
                let weekdayName = DateFormatter().shortWeekdaySymbols[calendar.component(.weekday, from: dayDate) - 1]
                let urls: [String] = list
                    .map { $0.urls.bestAvailableURL }  // 使用最佳可用URL而不是縮略圖
                    .filter { !$0.isEmpty }
                
                if !urls.isEmpty {
                    print("📸 Day \(dayNumber): \(urls.count) photos")
                }
                
                days.append(DayData(
                    date: dayDate,
                    dayNumber: dayNumber,
                    monthName: monthName,
                    weekdayName: weekdayName,
                    photoURLs: urls
                ))
            }
            resultWeeks.append(WeekData(weekNumber: weekNumber, days: days))
        }
        return resultWeeks
    }
    

}

// MARK: - Supporting Views


#Preview {
    ProfileTabView()
        .environmentObject(AuthenticationViewModel())
        .environmentObject(ThemeManager())
}
