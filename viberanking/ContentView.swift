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
        .localized()
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
                    Label("tab.rating".localized, systemImage: "star.fill")
                }
            
            // Upload tab - restricted for guests
            if viewModel.isGuest {
                GuestRestrictedView(feature: "tab.upload".localized)
                    .tabItem {
                        Label("tab.upload".localized, systemImage: "square.and.arrow.up")
                    }
            } else {
                PhotoUploadTabView()
                    .tabItem {
                        Label("tab.upload".localized, systemImage: "square.and.arrow.up")
                    }
            }
            
            
            // Report tab - restricted for guests
            if viewModel.isGuest {
                GuestRestrictedView(feature: "tab.report".localized)
                    .tabItem {
                        Label("tab.report".localized, systemImage: "chart.bar.fill")
                    }
            } else {
                StyleReportTabView()
                    .tabItem {
                        Label("tab.report".localized, systemImage: "chart.bar.fill")
                    }
            }
            
            
            // Profile tab - shows guest info or regular profile
            ProfilePlaceholderView()
                .tabItem {
                    Label("tab.profile".localized, systemImage: "person.fill")
                }
            
            // Firebase Test Tab
            FirebaseTestView()
                .tabItem {
                    Label("tab.test".localized, systemImage: "arrow.up.circle.fill")
                }
            
            // Localization Test Tab (for development)
            #if DEBUG
            LocalizationTestView()
                .tabItem {
                    Label("Language", systemImage: "globe")
                }
            #endif
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
                    Text("feature.rating".localized)
                        .font(.title2)
                        .padding()
                    
                    Text("login.required.rating".localized)
                        .multilineTextAlignment(.center)
                        .foregroundColor(.secondary)
                        .padding()
                }
            }
        }
    }
}

struct PhotoUploadTabView: View {
    @EnvironmentObject private var viewModel: AuthenticationViewModel
    
    var body: some View {
        Group {
            if let currentUser = viewModel.user {
                PhotoUploadView()
            } else {
                VStack {
                    Text("feature.upload".localized)
                        .font(.title2)
                        .padding()
                    
                    Text("login.required.upload".localized)
                        .multilineTextAlignment(.center)
                        .foregroundColor(.secondary)
                        .padding()
                }
            }
        }
    }
}

struct StyleReportTabView: View {
    @EnvironmentObject private var viewModel: AuthenticationViewModel
    
    var body: some View {
        Group {
            if let currentUser = viewModel.user {
                StyleReportView(userId: currentUser.id)
            } else {
                VStack {
                    Text("feature.style_report".localized)
                        .font(.title2)
                        .padding()
                    
                    Text("login.required.report".localized)
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
            
            Text("guest.login_required".localized(with: feature))
                .font(.headline)
                .multilineTextAlignment(.center)
            
            Text("guest.feature_unavailable".localized)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            
            Button("guest.sign_in_now".localized) {
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
            Image(systemName: viewModel.isGuest ? "person.crop.circle.badge.questionmark" : "person.crop.circle")
                .resizable()
                .scaledToFit()
                .frame(width: 80, height: 80)
                .foregroundColor(viewModel.isGuest ? .orange : .blue)
            
            // User info
            if let user = viewModel.user {
                Text(user.name)
                    .font(.title2)
                    .fontWeight(.semibold)
                
                if viewModel.isGuest {
                    Text("guest.mode".localized)
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
                    Text("profile.rating_progress".localized)
                        .font(.headline)
                        .padding(.top)
                    
                    HStack {
                        Text("profile.completed_ratings".localized(with: user.ratingProgress.completedRatings))
                        Spacer()
                        Text("profile.target_ratings".localized(with: user.ratingProgress.requiredRatings))
                    }
                    .font(.subheadline)
                    
                    ProgressView(value: user.ratingProgress.progressPercentage)
                        .progressViewStyle(LinearProgressViewStyle())
                    
                    if viewModel.isGuest {
                        Text("guest.progress_not_saved".localized)
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
            Button(viewModel.isGuest ? "guest.exit_guest_mode".localized : "profile.sign_out".localized) {
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
            
            Text("auth.title".localized)
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
