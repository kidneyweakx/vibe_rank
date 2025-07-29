//
//  MainTabView.swift
//  viberanking
//
//  Created by Kiro on 2025/07/25.
//

import SwiftUI

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
            .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
            
            if !isVibeMode {
                CustomTikTokTabBar(
                    selectedTab: $selectedTab,
                    onUploadTap: {
                        if canUpload {
                            showingUploadMenu = true
                        }
                    }
                )
            }
        }
        .preferredColorScheme(.dark)
        .sheet(isPresented: $showingUploadMenu) {
            UploadMenuView(
                showingImagePicker: $showingImagePicker,
                showingPhotoPicker: $showingPhotoPicker
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
                selectedImage = image
                showingImagePreview = true
            }
        }
        .fullScreenCover(isPresented: $showingImagePreview) {
            if let image = selectedImage {
                ImagePreviewView(image: image) {
                    selectedImage = nil
                }
            }
        }
    }
    
    private var canUpload: Bool {
        !authViewModel.isGuest && (authViewModel.user?.ratingProgress.hasUnlockedUpload ?? false)
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
    
    var body: some View {
        HStack(spacing: 0) {
            // Rating Tab
            TabBarButton(
                icon: "heart.fill",
                title: "Vibe",
                isSelected: selectedTab == .rating
            ) {
                selectedTab = .rating
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
            Button(action: onUploadTap) {
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
        .padding(.bottom, 34)
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
