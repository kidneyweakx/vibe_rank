//
//  ContentView.swift
//  viberanking
//
//  Created by kidneyweak on 2025/07/23.
//

import SwiftUI

struct ContentView: View {
    @EnvironmentObject private var firebaseService: FirebaseService
    @State private var isAuthenticated = false
    
    var body: some View {
        Group {
            if firebaseService.isInitialized {
                if isAuthenticated {
                    MainTabView()
                } else {
                    // Will be replaced with actual authentication view
                    AuthenticationPlaceholderView()
                }
            } else {
                // Loading view while Firebase initializes
                SplashScreenView()
            }
        }
        .onReceive(firebaseService.$isInitialized) { initialized in
            if initialized {
                // Check authentication status
                isAuthenticated = firebaseService.isAuthenticated
            }
        }
        .onReceive(firebaseService.$isAuthenticated) { authenticated in
            isAuthenticated = authenticated
        }
    }
}

// Placeholder views until we implement the actual views
struct MainTabView: View {
    @EnvironmentObject private var firebaseService: FirebaseService
    
    var body: some View {
        TabView {
            // Rating tab - available for all users
            PhotoRatingPlaceholderView()
                .tabItem {
                    Label("評分", systemImage: "star.fill")
                }
            
            // Upload tab - restricted for guests
            if firebaseService.isGuest {
                GuestRestrictedView(feature: "上傳照片")
                    .tabItem {
                        Label("上傳", systemImage: "square.and.arrow.up")
                    }
            } else {
                Text("上傳")
                    .tabItem {
                        Label("上傳", systemImage: "square.and.arrow.up")
                    }
            }
            
            // Report tab - restricted for guests
            if firebaseService.isGuest {
                GuestRestrictedView(feature: "風格報告")
                    .tabItem {
                        Label("報告", systemImage: "chart.bar.fill")
                    }
            } else {
                Text("報告")
                    .tabItem {
                        Label("報告", systemImage: "chart.bar.fill")
                    }
            }
            
            // Profile tab - shows guest info or regular profile
            ProfilePlaceholderView()
                .tabItem {
                    Label("個人", systemImage: "person.fill")
                }
        }
    }
}

struct PhotoRatingPlaceholderView: View {
    @EnvironmentObject private var firebaseService: FirebaseService
    
    var body: some View {
        VStack {
            if firebaseService.isGuest {
                Text("🎯 評分功能")
                    .font(.title2)
                    .padding()
                
                Text("訪客模式下您可以評分照片，但評分記錄不會被保存")
                    .multilineTextAlignment(.center)
                    .foregroundColor(.secondary)
                    .padding()
            } else {
                Text("🎯 評分功能")
                    .font(.title2)
                    .padding()
                
                Text("開始評分照片來解鎖上傳功能")
                    .multilineTextAlignment(.center)
                    .foregroundColor(.secondary)
                    .padding()
            }
            
            Button("開始評分") {
                // TODO: Navigate to rating view
            }
            .buttonStyle(.borderedProminent)
        }
    }
}

struct GuestRestrictedView: View {
    let feature: String
    @EnvironmentObject private var firebaseService: FirebaseService
    
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "lock.circle")
                .resizable()
                .scaledToFit()
                .frame(width: 60, height: 60)
                .foregroundColor(.secondary)
            
            Text("需要登入才能使用\(feature)")
                .font(.headline)
                .multilineTextAlignment(.center)
            
            Text("訪客模式下此功能不可用")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            
            Button("立即登入") {
                firebaseService.signOut() // This will return to login screen
            }
            .buttonStyle(.borderedProminent)
        }
        .padding()
    }
}

struct ProfilePlaceholderView: View {
    @EnvironmentObject private var firebaseService: FirebaseService
    
    var body: some View {
        VStack(spacing: 20) {
            // Profile image
            Image(systemName: firebaseService.isGuest ? "person.crop.circle.badge.questionmark" : "person.crop.circle")
                .resizable()
                .scaledToFit()
                .frame(width: 80, height: 80)
                .foregroundColor(firebaseService.isGuest ? .orange : .blue)
            
            // User info
            if let user = firebaseService.currentUser {
                Text(user.name)
                    .font(.title2)
                    .fontWeight(.semibold)
                
                if firebaseService.isGuest {
                    Text("訪客模式")
                        .font(.caption)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 4)
                        .background(Color.orange.opacity(0.2))
                        .foregroundColor(.orange)
                        .cornerRadius(12)
                }
                
                Text(user.email)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                // Rating progress
                VStack(alignment: .leading, spacing: 8) {
                    Text("評分進度")
                        .font(.headline)
                        .padding(.top)
                    
                    HStack {
                        Text("已評分: \(user.ratingProgress.completedRatings)")
                        Spacer()
                        Text("目標: \(user.ratingProgress.requiredRatings)")
                    }
                    .font(.subheadline)
                    
                    ProgressView(value: user.ratingProgress.progressPercentage)
                        .progressViewStyle(LinearProgressViewStyle())
                    
                    if firebaseService.isGuest {
                        Text("⚠️ 訪客模式下進度不會被保存")
                            .font(.caption)
                            .foregroundColor(.orange)
                    }
                }
                .padding()
                .background(Color.gray.opacity(0.1))
                .cornerRadius(12)
            }
            
            Spacer()
            
            // Sign out button
            Button(firebaseService.isGuest ? "退出訪客模式" : "登出") {
                firebaseService.signOut()
            }
            .foregroundColor(.red)
        }
        .padding()
    }
}

struct AuthenticationPlaceholderView: View {
    @EnvironmentObject private var firebaseService: FirebaseService
    @State private var showingGuestModeAlert = false
    
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "person.crop.circle.badge.checkmark")
                .resizable()
                .scaledToFit()
                .frame(width: 100, height: 100)
                .foregroundColor(.blue)
            
            Text("數位頂尖社交評價平台")
                .font(.title)
                .fontWeight(.bold)
            
            Text("登入以開始評分和獲取個人風格分析")
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            VStack(spacing: 12) {
                Button(action: {
                    // TODO: Implement Google Sign In
                }) {
                    HStack {
                        Image(systemName: "g.circle.fill")
                        Text("使用 Google 登入")
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(8)
                }
                
                Button(action: {
                    // TODO: Implement Apple Sign In
                }) {
                    HStack {
                        Image(systemName: "applelogo")
                        Text("使用 Apple 登入")
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.black)
                    .foregroundColor(.white)
                    .cornerRadius(8)
                }
                
                // Skip login button
                Button(action: {
                    showingGuestModeAlert = true
                }) {
                    Text("跳過登入 (訪客模式)")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .underline()
                }
                .padding(.top, 8)
            }
            .padding(.horizontal)
            
            Text("訪客模式下部分功能將受限")
                .font(.caption)
                .foregroundColor(.secondary)
                .padding(.top, 8)
        }
        .padding()
        .alert("進入訪客模式", isPresented: $showingGuestModeAlert) {
            Button("取消", role: .cancel) { }
            Button("確認") {
                enterGuestMode()
            }
        } message: {
            Text("在訪客模式下，您可以瀏覽和評分照片，但無法上傳照片或保存個人資料。")
        }
    }
    
    private func enterGuestMode() {
        // Create a temporary guest user
        let guestUser = User(
            id: "guest_\(UUID().uuidString)",
            name: "訪客用戶",
            email: "guest@example.com",
            profileImageURL: nil,
            gender: nil
        )
        
        // Set authentication status to true with guest user
        // In a real implementation, this would be handled by the authentication service
        firebaseService.setGuestMode(user: guestUser)
    }
}

struct SplashScreenView: View {
    var body: some View {
        VStack {
            Image(systemName: "star.circle.fill")
                .resizable()
                .scaledToFit()
                .frame(width: 100, height: 100)
                .foregroundColor(.blue)
            
            Text("數位頂尖社交評價平台")
                .font(.title2)
                .padding()
            
            ProgressView()
                .progressViewStyle(CircularProgressViewStyle())
        }
    }
}

#Preview {
    ContentView()
        .environmentObject(FirebaseService.shared)
}
