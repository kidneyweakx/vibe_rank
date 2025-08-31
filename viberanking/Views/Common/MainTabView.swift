//
//  MainTabView.swift
//  viberanking
//
//  Created by Kiro on 2025/07/25.
//

import SwiftUI
import AVFoundation

struct MainTabView: View {
    @EnvironmentObject private var authViewModel: AuthenticationViewModel
    @EnvironmentObject private var themeManager: ThemeManager
    @State private var selectedTab: TabItem = .home
    @State private var isVibeMode = false
    @State private var showingUploadMenu = false
    @State private var showingImagePicker = false
    @State private var showingPhotoPicker = false
    @State private var showingImagePreview = false
    @State private var selectedImage: UIImage?
    @State private var showingUploadAlert = false
    @State private var uploadAlertMessage = ""
    @State private var showingCameraAlert = false
    @State private var cameraAlertMessage = ""
    @AppStorage("has_seen_main_spotlight") var hasSeenMainSpotlight: Bool = false
    @State var showSpotlight: Bool = false
    @State private var currentSpotlightIndex: Int = 0
    @State private var spotlightFrames: [String: CGRect] = [:]
    @State var overrideSpotlightStep: SpotlightStepModel?
    private let spotlightStepsModels: [SpotlightStepModel] = SpotlightScripts.mainSteps
    @AppStorage("has_seen_spotlight_rating_page") var hasSeenRatingPageSpotlight: Bool = false
    @AppStorage("has_seen_spotlight_trend_page") var hasSeenTrendPageSpotlight: Bool = false
    @AppStorage("has_seen_spotlight_journey_page") var hasSeenJourneyPageSpotlight: Bool = false
    @AppStorage("has_seen_spotlight_profile_page") var hasSeenProfilePageSpotlight: Bool = false
    
    // Computed property to check if current user has seen spotlight
    private var currentUserHasSeenSpotlight: Bool {
        guard let userId = authViewModel.user?.id else { return false }
        let userSpotlightKey = "has_seen_spotlight_user_\(userId)"
        return UserDefaults.standard.bool(forKey: userSpotlightKey)
    }
    
    var body: some View {
        ZStack(alignment: .bottom) {
            TabView(selection: $selectedTab) {
                RatingTabView(isVibeMode: $isVibeMode)
                    .tag(TabItem.rating)
                
                HomeView()
                    .tag(TabItem.home)
                
                JourneyTabView()
                    .tag(TabItem.journey)
                
                ProfileTabView()
                    .tag(TabItem.profile)
            }
            // Use default tab view style to DISABLE horizontal swipe between pages
            .tabViewStyle(DefaultTabViewStyle())
            // Hide the native tab bar; we render a custom one
            .toolbar(.hidden, for: .tabBar)
            .ignoresSafeArea(.all) // 讓內容填滿整個螢幕
            
            CustomTikTokTabBar(
                selectedTab: $selectedTab,
                onUploadTap: {
                    if canUpload {
                        showingUploadMenu = true
                    } else {
                        if authViewModel.isGuest {
                            uploadAlertMessage = "auth.login_required".localized
                            showingUploadAlert = true
                        } else {
                            let remaining = authViewModel.user?.ratingProgress.remainingRatings ?? 20
                            uploadAlertMessage = "progress.rating_needed".localized(with: remaining)
                            showingUploadAlert = true
                        }
                    }
                },
                onVibeTap: {
                    // 點擊 Vibe tab 直接進入 vibe 模式
                    withAnimation(.easeInOut(duration: 0.3)) {
                        selectedTab = .rating
                        isVibeMode = true
                    }
                }
            )

            // Spotlight overlay layer
            if showSpotlight {
                if let override = overrideSpotlightStep,
                   let frame = spotlightFrames[override.id], !frame.isNull, !frame.isEmpty, frame.width > 1, frame.height > 1 {
                    SpotlightOverlay(
                        targetFrame: frame,
                        cornerRadius: override.cornerRadius,
                        titleKey: override.titleKey,
                        messageKey: override.messageKey,
                        position: override.position,
                        onNext: {
                            markCurrentPageSpotlightSeen(for: selectedTab)
                            overrideSpotlightStep = nil
                            withAnimation { showSpotlight = false }
                        },
                        onSkip: {
                            markCurrentPageSpotlightSeen(for: selectedTab)
                            overrideSpotlightStep = nil
                            withAnimation { showSpotlight = false }
                        }
                    )
                    .transition(.opacity)
                } else if currentSpotlightIndex < spotlightStepsModels.count {
                    let step = spotlightStepsModels[currentSpotlightIndex]
                    if let frame = spotlightFrames[step.id], !frame.isNull, !frame.isEmpty, frame.width > 1, frame.height > 1 {
                        SpotlightOverlay(
                            targetFrame: frame,
                            cornerRadius: step.cornerRadius,
                            titleKey: step.titleKey,
                            messageKey: step.messageKey,
                            position: step.position,
                            onNext: {
                                if currentSpotlightIndex < spotlightStepsModels.count - 1 {
                                    currentSpotlightIndex += 1
                                } else {
                                    hasSeenMainSpotlight = true
                                    // Mark that current user has seen spotlight globally
                                    markCurrentUserSpotlightSeen()
                                    withAnimation { showSpotlight = false }
                                }
                            },
                            onSkip: {
                                hasSeenMainSpotlight = true
                                // Mark that current user has seen spotlight globally
                                markCurrentUserSpotlightSeen()
                                withAnimation { showSpotlight = false }
                            }
                        )
                        .transition(.opacity)
                    }
                }
            }
        }
        .coordinateSpace(name: "spotlight")
        .onPreferenceChange(SpotlightPreferenceKey.self) { value in
            spotlightFrames = value
            print("🔄 Spotlight frames updated: \(value.keys)")
            for (id, frame) in value {
                print("  - \(id): \(frame)")
            }
        }
        .preferredColorScheme(.dark)
        .sheet(isPresented: $showingUploadMenu) {
            UploadMenuView(
                onCameraSelected: {
                    Task {
                        if !CameraPermissionHelper.isCameraAvailable {
                            cameraAlertMessage = "permission.camera.unavailable".localized
                            showingCameraAlert = true
                            return
                        }

                        switch CameraPermissionHelper.cameraAuthorizationStatus {
                        case .authorized:
                            showingImagePicker = true
                        case .notDetermined:
                            let granted = await CameraPermissionHelper.requestCameraPermission()
                            if granted {
                                showingImagePicker = true
                            } else {
                                cameraAlertMessage = "permission.camera.message".localized
                                showingCameraAlert = true
                            }
                        case .denied, .restricted:
                            cameraAlertMessage = "permission.camera.message".localized
                            showingCameraAlert = true
                        @unknown default:
                            cameraAlertMessage = "permission.camera.unknown".localized
                            showingCameraAlert = true
                        }
                    }
                },
                onPhotoLibrarySelected: {
                    showingPhotoPicker = true
                }
            )
            .presentationDetents([.height(200)])
            .presentationDragIndicator(.visible)
        }
        .sheet(isPresented: $showingImagePicker) {
            ImagePicker(sourceType: .camera) { image in
                selectedImage = image
                showingImagePreview = true
            }
        }
        .sheet(isPresented: $showingPhotoPicker) {
            PhotoPickerView { image in
                print("📸 MainTabView 收到圖片 - 尺寸: \(image.size)")
                selectedImage = image
                print("🔄 延遲設置 showingImagePreview = true")
                // 延遲一點時間確保 selectedImage 被正確設置
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    showingImagePreview = true
                    print("✅ MainTabView 圖片處理完成")
                }
            }
        }
        .fullScreenCover(isPresented: $showingImagePreview) {
            Group {
                if let image = selectedImage {
                    ImagePreviewView(image: image) {
                        print("❌ ImagePreviewView 取消，重置 selectedImage")
                        selectedImage = nil
                    }
                    .onAppear {
                        print("🖼️ 顯示 ImagePreviewView - 圖片尺寸: \(image.size)")
                    }
                } else {
                    Text("common.image_load_failed".localized)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .background(Color.black)
                        .onAppear {
                            print("❌ selectedImage 為 nil，無法顯示 ImagePreviewView")
                            print("❌ 當前 showingImagePreview: \(showingImagePreview)")
                        }
                }
            }
        }
        .alert("upload.unavailable".localized, isPresented: $showingUploadAlert) {
            Button("common.ok".localized, role: .cancel) { }
        } message: {
            Text(uploadAlertMessage)
        }
        .alert("permission.camera.title".localized, isPresented: $showingCameraAlert) {
            Button("common.ok".localized, role: .cancel) { }
        } message: {
            Text(cameraAlertMessage)
        }
        .onChange(of: selectedImage) { newImage in
            if let image = newImage {
                print("🔄 selectedImage 更新 - 尺寸: \(image.size)")
            } else {
                print("🔄 selectedImage 被重置為 nil")
            }
        }
        .onChange(of: showingImagePreview) { isShowing in
            print("🔄 showingImagePreview 變更: \(isShowing)")
            if isShowing {
                print("🔄 當前 selectedImage 是否為 nil: \(selectedImage == nil)")
            }
        }
        .onChange(of: selectedTab) { newTab in
            maybeShowPerPageSpotlight(for: newTab)
        }
        .onAppear {
            print("🔄 MainTabView onAppear - hasSeenMainSpotlight: \(hasSeenMainSpotlight)")
            print("🔄 Current user has seen spotlight: \(currentUserHasSeenSpotlight)")
            
            // Show main spotlight if current user hasn't seen it before
            // hasSeenMainSpotlight is global, but currentUserHasSeenSpotlight is user-specific
            if !currentUserHasSeenSpotlight {
                print("🔄 Showing main spotlight after delay...")
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    print("🔄 Setting currentSpotlightIndex to 0 and showing spotlight")
                    currentSpotlightIndex = 0
                    withAnimation { showSpotlight = true }
                }
            } else {
                print("ℹ️ Current user has already seen main spotlight")
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
                print("🔄 Checking per-page spotlight for tab: \(selectedTab)")
                maybeShowPerPageSpotlight(for: selectedTab)
            }
        }
    }
    
    private var canUpload: Bool {
        // @TODO: limit only logined user can upload files
        return true
        
        // 原本的邏輯：
        // !authViewModel.isGuest && (authViewModel.user?.ratingProgress.hasUnlockedUpload ?? false)
    }
    
    /// Reset spotlight state for testing purposes
    func resetSpotlightForTesting() {
        print("🧪 Resetting spotlight state for testing...")
        hasSeenMainSpotlight = false
        hasSeenRatingPageSpotlight = false
        hasSeenTrendPageSpotlight = false
        hasSeenJourneyPageSpotlight = false
        hasSeenProfilePageSpotlight = false
        currentSpotlightIndex = 0
        showSpotlight = false
        overrideSpotlightStep = nil
        
        // Also reset user-specific spotlight state if available
        if let userId = getCurrentUserId() {
            let userSpotlightKey = "has_seen_spotlight_user_\(userId)"
            UserDefaults.standard.set(false, forKey: userSpotlightKey)
            print("🧪 Reset user-specific spotlight state for user: \(userId)")
        }
        
        print("✅ Spotlight state reset complete")
    }
    
    /// Check current spotlight state for debugging
    func debugSpotlightState() {
        print("🔍 Current Spotlight State:")
        print("  - hasSeenMainSpotlight: \(hasSeenMainSpotlight)")
        print("  - hasSeenRatingPageSpotlight: \(hasSeenRatingPageSpotlight)")
        print("  - hasSeenTrendPageSpotlight: \(hasSeenTrendPageSpotlight)")
        print("  - hasSeenJourneyPageSpotlight: \(hasSeenJourneyPageSpotlight)")
        print("  - hasSeenProfilePageSpotlight: \(hasSeenProfilePageSpotlight)")
        print("  - currentSpotlightIndex: \(currentSpotlightIndex)")
        print("  - showSpotlight: \(showSpotlight)")
        print("  - overrideSpotlightStep: \(overrideSpotlightStep?.id ?? "nil")")
        print("  - selectedTab: \(selectedTab)")
    }
    
    /// Force show spotlight for testing purposes
    func forceShowSpotlight() {
        print("🧪 Force showing spotlight...")
        hasSeenMainSpotlight = false
        currentSpotlightIndex = 0
        showSpotlight = false
        overrideSpotlightStep = nil
        
        // Also reset user-specific spotlight state if available
        if let userId = getCurrentUserId() {
            let userSpotlightKey = "has_seen_spotlight_user_\(userId)"
            UserDefaults.standard.set(false, forKey: userSpotlightKey)
            print("🧪 Reset user-specific spotlight state for user: \(userId)")
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            print("🧪 Showing main spotlight...")
            self.currentSpotlightIndex = 0
            withAnimation { self.showSpotlight = true }
        }
        
        print("✅ Spotlight state reset complete")
    }
    
    // MARK: - Public Spotlight Methods for Extension
    
    /// Check if current user has seen spotlight globally
    func hasCurrentUserSeenSpotlight() -> Bool {
        guard let userId = authViewModel.user?.id else { return false }
        let userSpotlightKey = "has_seen_spotlight_user_\(userId)"
        return UserDefaults.standard.bool(forKey: userSpotlightKey)
    }
    
    /// Mark current user as having seen spotlight globally
    func markCurrentUserSpotlightSeen() {
        if let userId = authViewModel.user?.id {
            let userSpotlightKey = "has_seen_spotlight_user_\(userId)"
            UserDefaults.standard.set(true, forKey: userSpotlightKey)
            print("🔄 Marked user \(userId) as having seen spotlight globally")
        }
    }
    
    /// Get current user ID for spotlight operations
    func getCurrentUserId() -> String? {
        return authViewModel.user?.id
    }
}


#Preview {
    MainTabView()
        .environmentObject(AuthenticationViewModel())
        .environmentObject(ThemeManager())
}
