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
        .sheet(isPresented: $showingImagePicker) {
            ImagePicker(sourceType: .photoLibrary) { image in
                uploadProfileImage(image)
            }
        }
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
    }
    
    private func uploadProfileImage(_ image: UIImage) {
        guard let userId = authViewModel.user?.id else { return }
        
        Task {
            await MainActor.run {
                isUploadingProfilePicture = true
                uploadProgress = 0.0
            }
            
            do {
                // Compress image to reduce upload size
                guard let imageData = image.jpegData(compressionQuality: 0.8) else {
                    throw APIError.invalidResponse
                }
                
                // Simulate progress updates
                for progress in stride(from: 0.0, through: 0.9, by: 0.1) {
                    await MainActor.run {
                        uploadProgress = progress
                    }
                    try await Task.sleep(nanoseconds: 100_000_000) // 0.1 second
                }
                
                // Upload the image
                let response = try await UserAPI().uploadProfilePicture(userId: userId, imageData: imageData)
                
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
                    }
                    uploadProgress = 1.0
                    isUploadingProfilePicture = false
                }
                
                // Refresh profile data
                await viewModel.refreshData()
                
            } catch {
                await MainActor.run {
                    isUploadingProfilePicture = false
                    uploadProgress = 0.0
                }
                print("❌ ProfileTabView: Failed to upload profile picture: \(error)")
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
                        showingImagePicker = true
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
                                    if let profileImageURL = authViewModel.user?.profileImageURL,
                                       let url = URL(string: profileImageURL) {
                                        AsyncImage(url: url) { image in
                                            image
                                                .resizable()
                                                .aspectRatio(contentMode: .fill)
                                        } placeholder: {
                                            Image(systemName: "person.fill")
                                                .font(.system(size: 32))
                                                .foregroundColor(.white)
                                        }
                                        .clipShape(Circle())
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
                        } else {
                            // Camera icon overlay
                            VStack {
                                Spacer()
                                HStack {
                                    Spacer()
                                    Image(systemName: "camera.fill")
                                        .font(.system(size: 16))
                                        .foregroundColor(.white)
                                        .padding(6)
                                        .background(Circle().fill(Color.blue))
                                }
                            }
                            .frame(width: 80, height: 80)
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
                    WeeklyPhotoSection(week: week)
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
                let firstURL = list.first?.urls.thumbnailURL
                let urlString: String? = {
                    if let firstURL, !firstURL.isEmpty { return firstURL }
                    return nil
                }()
                days.append(DayData(
                    date: dayDate,
                    dayNumber: dayNumber,
                    monthName: monthName,
                    weekdayName: weekdayName,
                    photoURL: urlString
                ))
            }
            resultWeeks.append(WeekData(weekNumber: weekNumber, days: days))
        }
        return resultWeeks
    }
    

}

// MARK: - Data Models
struct WeekData {
    let weekNumber: Int
    let days: [DayData]
}

struct DayData {
    let date: Date
    let dayNumber: Int
    let monthName: String
    let weekdayName: String
    let photoURL: String?
    var hasPhoto: Bool { photoURL != nil }
}

// MARK: - Supporting Views
struct WeeklyPhotoSection: View {
    let week: WeekData
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(String(format: "profile.week".localized, week.weekNumber))
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.white)
                
                Spacer()
                
                Button(action: {
                    // More options
                }) {
                    Image(systemName: "ellipsis")
                        .font(.system(size: 16))
                        .foregroundColor(.gray)
                }
            }
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(Array(week.days.enumerated()), id: \.offset) { index, day in
                        DayPhotoCard(day: day)
                    }
                }
                .padding(.horizontal, 4)
            }
        }
    }
}

struct DayPhotoCard: View {
    let day: DayData
    @State private var isPressed = false
    
    var body: some View {
        Button(action: {
            // Handle photo tap - could open photo viewer or add photo
        }) {
            VStack(spacing: 8) {
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.gray.opacity(0.1))
                    .frame(width: 120, height: 160)
                    .overlay(
                        Group {
                            if let urlString = day.photoURL, let url = URL(string: urlString) {
                                AsyncImage(url: url) { phase in
                                    switch phase {
                                    case .empty:
                                        ProgressView().tint(.white)
                                    case .success(let image):
                                        image.resizable().scaledToFill()
                                    case .failure:
                                        Image(systemName: "photo").foregroundColor(.gray)
                                    @unknown default:
                                        Color.clear
                                    }
                                }
                                .clipped()
                            } else {
                                VStack(spacing: 8) {
                                    Image(systemName: "plus.circle.dashed")
                                        .font(.system(size: 32))
                                        .foregroundColor(.gray.opacity(0.5))
                                    Text("profile.add_photo".localized)
                                        .font(.system(size: 12, weight: .medium))
                                        .foregroundColor(.gray.opacity(0.7))
                                }
                            }
                        }
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(day.hasPhoto ? Color.white.opacity(0.2) : Color.gray.opacity(0.1), lineWidth: 1)
                    )
                
                VStack(spacing: 4) {
                    Text(day.monthName)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.gray)
                    Text("\(day.dayNumber)")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.white)
                    Text(day.weekdayName)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.gray)
                }
            }
        }
        .frame(width: 120)
        .scaleEffect(isPressed ? 0.95 : 1.0)
        .animation(.easeInOut(duration: 0.1), value: isPressed)
        .onLongPressGesture(minimumDuration: 0) { pressing in
            isPressed = pressing
        } perform: {
            // Long press action
        }
    }
}

// MARK: - Supporting Views


#Preview {
    ProfileTabView()
        .environmentObject(AuthenticationViewModel())
        .environmentObject(ThemeManager())
}
