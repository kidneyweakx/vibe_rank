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
                        // 顯示為什麼不能上傳的提示
                        if authViewModel.isGuest {
                            uploadAlertMessage = "請先登入才能上傳照片"
                            showingUploadAlert = true
                        } else {
                            let remaining = authViewModel.user?.ratingProgress.remainingRatings ?? 20
                            uploadAlertMessage = "還需要完成 \(remaining) 個評分才能解鎖上傳功能"
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
        }
        .preferredColorScheme(.dark)
        .sheet(isPresented: $showingUploadMenu) {
            UploadMenuView(
                onCameraSelected: {
                    Task {
                        if !CameraPermissionHelper.isCameraAvailable {
                            cameraAlertMessage = "此裝置沒有相機可用"
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
                                cameraAlertMessage = "請到「設定 > 隱私權 > 相機」允許本 App 使用相機"
                                showingCameraAlert = true
                            }
                        case .denied, .restricted:
                            cameraAlertMessage = "請到「設定 > 隱私權 > 相機」允許本 App 使用相機"
                            showingCameraAlert = true
                        @unknown default:
                            cameraAlertMessage = "相機權限狀態未知，請稍後再試"
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
                    Text("圖片加載失敗")
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
        .alert("無法上傳", isPresented: $showingUploadAlert) {
            Button("確定", role: .cancel) { }
        } message: {
            Text(uploadAlertMessage)
        }
        .alert("無法使用相機", isPresented: $showingCameraAlert) {
            Button("確定", role: .cancel) { }
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
    }
    
    private var canUpload: Bool {
        // @TODO: limit only logined user can upload files
        return true
        
        // 原本的邏輯：
        // !authViewModel.isGuest && (authViewModel.user?.ratingProgress.hasUnlockedUpload ?? false)
    }
}

// MARK: - Tab Items
enum TabItem: CaseIterable {
    case rating, home, journey, profile
}

// MARK: - Custom TikTok Style Tab Bar
struct CustomTikTokTabBar: View {
    @Binding var selectedTab: TabItem
    let onUploadTap: () -> Void
    let onVibeTap: () -> Void
    
    var body: some View {
        HStack(spacing: 0) {
            // Rating Tab (Vibe)
            TabBarButton(
                icon: "heart.fill",
                title: "Vibe",
                isSelected: selectedTab == .rating
            ) {
                onVibeTap() // 直接調用 vibe 模式
            }
            
            Spacer()
            
            // Trend Tab
            TabBarButton(
                icon: "flame.fill",
                title: "Trend",
                isSelected: selectedTab == .home
            ) {
                selectedTab = .home
            }
            
            Spacer()
            
            // Plus
            Button(action: {
                onUploadTap()
            }) {
                ZStack {
                    Circle()
                        .fill(Color.red)
                        .frame(width: 56, height: 56)
                    Image(systemName: "plus")
                        .font(.system(size: 22, weight: .bold))
                        .foregroundColor(.white)
                }
            }
            .offset(y: -10)
            
            Spacer()
            
            // Journey Tab
            TabBarButton(
                icon: "sparkles",
                title: "Journey",
                isSelected: selectedTab == .journey
            ) {
                selectedTab = .journey
            }
            
            Spacer()
            
            // Profile Tab
            TabBarButton(
                icon: "person.circle.fill",
                title: "Profile",
                isSelected: selectedTab == .profile
            ) {
                selectedTab = .profile
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 8)
        .padding(.bottom, 8) // 減少底部 padding，避免黑邊
        .background(
            Color.black
                .ignoresSafeArea(edges: .bottom)
        )
    }
}

// MARK: - Tab Bar Button
struct TabBarButton: View {
    let icon: String
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 20))
                    .foregroundColor(isSelected ? .red : .gray)
                
                Text(title)
                    .font(.system(size: 10))
                    .foregroundColor(isSelected ? .red : .gray)
            }
        }
        .frame(width: 60, height: 50)
    }
}

#Preview {
    MainTabView()
        .environmentObject(AuthenticationViewModel())
        .environmentObject(ThemeManager())
}
