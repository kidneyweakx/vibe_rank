//
//  ContentView.swift
//  viberanking
//
//  Created by kidneyweak on 2025/07/23.
//

import SwiftUI

struct ContentView: View {
    @EnvironmentObject private var viewModel: AuthenticationViewModel
    
    var body: some View {
        Group {
            if viewModel.isAuthenticated {
                MainTabView()
            } else {
                LoginView()
            }
        }
    }
}

// Placeholder views until we implement the actual views
struct MainTabView: View {
    @EnvironmentObject private var viewModel: AuthenticationViewModel
    
    var body: some View {
        TabView {
            // Rating tab - available for all users
            PhotoRatingTabView()
                .tabItem {
                    Label("評分", systemImage: "star.fill")
                }
            
            // Upload tab - restricted for guests
            Text("上傳")
                .tabItem {
                    Label("上傳", systemImage: "square.and.arrow.up")
                }
            
            
            // Report tab - restricted for guests
            Text("報告")
                .tabItem {
                    Label("報告", systemImage: "chart.bar.fill")
                }
            
            
            // Profile tab - shows guest info or regular profile
            ProfilePlaceholderView()
                .tabItem {
                    Label("個人", systemImage: "person.fill")
                }
        }
    }
}

struct PhotoRatingTabView: View {
    @EnvironmentObject private var viewModel: AuthenticationViewModel
    
    var body: some View {
        Group {
            if let currentUser = viewModel.user {
                PhotoRatingView(userId: currentUser.id)
            } else {
                VStack {
                    Text("🎯 評分功能")
                        .font(.title2)
                        .padding()
                    
                    Text("請先登入以使用評分功能")
                        .multilineTextAlignment(.center)
                        .foregroundColor(.secondary)
                        .padding()
                }
            }
        }
    }
}

struct GuestRestrictedView: View {
    let feature: String
    @EnvironmentObject private var viewModel: AuthenticationViewModel
    
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
                viewModel.signOut() // This will return to login screen
            }
            .buttonStyle(.borderedProminent)
        }
        .padding()
    }
}

struct ProfilePlaceholderView: View {
    @EnvironmentObject private var viewModel: AuthenticationViewModel
    
    var body: some View {
        VStack(spacing: 20) {
            // Profile image
            Image(systemName: "person.crop.circle")
                .resizable()
                .scaledToFit()
                .frame(width: 80, height: 80)
                .foregroundColor(.blue)
            
            // User info
            if let user = viewModel.user {
                Text(user.name)
                    .font(.title2)
                    .fontWeight(.semibold)
                
                
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
                    
                }
                .padding()
                .background(Color.gray.opacity(0.1))
                .cornerRadius(12)
            }
            
            Spacer()
            
            // Sign out button
            Button("登出") {
                viewModel.signOut()
            }
            .foregroundColor(.red)
        }
        .padding()
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
        .environmentObject(AuthenticationViewModel())
}
