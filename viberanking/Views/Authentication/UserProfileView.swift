//
//  UserProfileView.swift
//  viberanking
//
//  Created by Kiro on 2025/07/23.
//

import SwiftUI

/// View for displaying and managing user profile information
struct UserProfileView: View {
    @EnvironmentObject private var authViewModel: AuthenticationViewModel
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.dismiss) private var dismiss
    
    @State private var showingDeleteConfirmation = false
    @State private var showingSignOutConfirmation = false
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Profile Header
                    ProfileHeaderView(user: authViewModel.user)
                    
                    // Rating Progress Section
                    RatingProgressSection(
                        progress: authViewModel.ratingProgress,
                        hasUnlockedUpload: authViewModel.hasUnlockedUpload
                    )
                    
                    // Account Actions Section
                    AccountActionsSection(
                        onSignOut: { showingSignOutConfirmation = true },
                        onDeleteAccount: { showingDeleteConfirmation = true },
                        onRefreshData: { authViewModel.refreshUserData() }
                    )
                    
                    Spacer(minLength: 50)
                }
                .padding(.horizontal, 20)
                .padding(.top, 20)
            }
            .background(
                LinearGradient(
                    gradient: Gradient(
                        colors: colorScheme == .dark 
                            ? [Color(hex: "1A1A2E"), Color(hex: "16213E")]
                            : [Color(hex: "F5F7FA"), Color(hex: "E4E9F2")]
                    ),
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()
            )
            .navigationTitle("profile.title".localized)
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("common.done".localized) {
                        dismiss()
                    }
                    .foregroundColor(.blue)
                }
            }
        }
        .alert("profile.confirm_sign_out".localized, isPresented: $showingSignOutConfirmation) {
            Button("common.cancel".localized, role: .cancel) { }
            Button("profile.sign_out_title".localized, role: .destructive) {
                authViewModel.signOut()
            }
        } message: {
            Text("profile.sign_out_message".localized)
        }
        .alert("profile.delete_account_title".localized, isPresented: $showingDeleteConfirmation) {
            Button("common.cancel".localized, role: .cancel) { }
            Button("profile.delete".localized, role: .destructive) {
                authViewModel.deleteAccount()
            }
        } message: {
            Text("profile.delete_account_message".localized)
        }
        .overlay {
            if authViewModel.isLoading {
                LoadingOverlay()
            }
        }
    }
}

// MARK: - Profile Header View
struct ProfileHeaderView: View {
    let user: User?
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        VStack(spacing: 16) {
            // Profile Image
            AsyncImage(url: URL(string: user?.profileImageURL ?? "")) { image in
                image
                    .resizable()
                    .scaledToFill()
            } placeholder: {
                Image(systemName: "person.circle.fill")
                    .font(.system(size: 60))
                    .foregroundColor(.gray)
            }
            .frame(width: 80, height: 80)
            .clipShape(Circle())
            .overlay(
                Circle()
                    .stroke(
                        colorScheme == .dark ? Color.white.opacity(0.2) : Color.black.opacity(0.1),
                        lineWidth: 2
                    )
            )
            
            // User Info
            VStack(spacing: 4) {
                Text(user?.name ?? "profile.unknown_user".localized)
                    .font(.title2)
                    .fontWeight(.semibold)
                    .foregroundColor(colorScheme == .dark ? .white : .black)
                
                Text(user?.email ?? "no-email@example.com")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                if let createdAt = user?.createdAt {
                    Text("加入於 \(createdAt, formatter: dateFormatter)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .padding(.top, 2)
                }
            }
        }
        .padding(.vertical, 20)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(colorScheme == .dark ? Color(hex: "2D2D2D") : .white)
                .shadow(
                    color: colorScheme == .dark ? Color.black.opacity(0.3) : Color.gray.opacity(0.2),
                    radius: 8,
                    x: 0,
                    y: 2
                )
        )
    }
    
    private var dateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter
    }
}

// MARK: - Rating Progress Section
struct RatingProgressSection: View {
    let progress: RatingProgress
    let hasUnlockedUpload: Bool
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("評分進度")
                .font(.headline)
                .foregroundColor(colorScheme == .dark ? .white : .black)
            
            VStack(spacing: 12) {
                // Progress Bar
                ProgressView(value: progress.progressPercentage)
                    .progressViewStyle(LinearProgressViewStyle(tint: hasUnlockedUpload ? .green : .blue))
                    .scaleEffect(x: 1, y: 2, anchor: .center)
                
                // Progress Text
                HStack {
                    Text("\(progress.completedRatings) / \(progress.requiredRatings) 評分完成")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    if hasUnlockedUpload {
                        HStack(spacing: 4) {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.green)
                            Text("已解鎖上傳")
                                .font(.subheadline)
                                .foregroundColor(.green)
                        }
                    } else {
                        Text("還需 \(progress.remainingRatings) 個評分")
                            .font(.subheadline)
                            .foregroundColor(.blue)
                    }
                }
            }
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(colorScheme == .dark ? Color(hex: "2D2D2D") : .white)
                .shadow(
                    color: colorScheme == .dark ? Color.black.opacity(0.3) : Color.gray.opacity(0.2),
                    radius: 8,
                    x: 0,
                    y: 2
                )
        )
    }
}

// MARK: - Account Actions Section
struct AccountActionsSection: View {
    let onSignOut: () -> Void
    let onDeleteAccount: () -> Void
    let onRefreshData: () -> Void
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        VStack(spacing: 12) {
            Text("帳戶管理")
                .font(.headline)
                .foregroundColor(colorScheme == .dark ? .white : .black)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            VStack(spacing: 1) {
                // Refresh Data Button
                ActionButton(
                    title: "重新整理資料",
                    icon: "arrow.clockwise",
                    action: onRefreshData,
                    style: .normal
                )
                
                Divider()
                    .background(colorScheme == .dark ? Color.gray.opacity(0.3) : Color.gray.opacity(0.2))
                
                // Sign Out Button
                ActionButton(
                    title: "登出",
                    icon: "rectangle.portrait.and.arrow.right",
                    action: onSignOut,
                    style: .normal
                )
                
                Divider()
                    .background(colorScheme == .dark ? Color.gray.opacity(0.3) : Color.gray.opacity(0.2))
                
                // Delete Account Button
                ActionButton(
                    title: "profile.delete_account".localized,
                    icon: "trash",
                    action: onDeleteAccount,
                    style: .destructive
                )
            }
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(colorScheme == .dark ? Color(hex: "2D2D2D") : .white)
                    .shadow(
                        color: colorScheme == .dark ? Color.black.opacity(0.3) : Color.gray.opacity(0.2),
                        radius: 8,
                        x: 0,
                        y: 2
                    )
            )
        }
    }
}

// MARK: - Action Button
struct ActionButton: View {
    let title: String
    let icon: String
    let action: () -> Void
    let style: ActionButtonStyle
    @Environment(\.colorScheme) private var colorScheme
    
    enum ActionButtonStyle {
        case normal
        case destructive
    }
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(foregroundColor)
                    .frame(width: 20)
                
                Text(title)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(foregroundColor)
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.secondary)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
            .contentShape(Rectangle())
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private var foregroundColor: Color {
        switch style {
        case .normal:
            return colorScheme == .dark ? .white : .black
        case .destructive:
            return .red
        }
    }
}

// MARK: - Loading Overlay
struct LoadingOverlay: View {
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        ZStack {
            Color.black.opacity(0.3)
                .ignoresSafeArea()
            
            VStack(spacing: 16) {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    .scaleEffect(1.2)
                
                Text("處理中...")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.white)
            }
            .padding(24)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.black.opacity(0.8))
            )
        }
    }
}

// Color extension already defined in LoginView

// MARK: - Preview
struct UserProfileView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            UserProfileView()
                .environmentObject(UserProfilePreviewAuthenticationViewModel())
                .preferredColorScheme(.light)
                .previewDisplayName("Light Mode")
            
            UserProfileView()
                .environmentObject(UserProfilePreviewAuthenticationViewModel())
                .preferredColorScheme(.dark)
                .previewDisplayName("Dark Mode")
        }
    }
}

// Preview helper
class UserProfilePreviewAuthenticationViewModel: AuthenticationViewModel {
    nonisolated init() {
        super.init()
        
        Task { @MainActor in
            self.user = User(
                id: "preview_id",
                name: "測試用戶",
                email: "test@example.com",
                profileImageURL: nil
            )
            self.isAuthenticated = true
            self.authState = .signedIn
        }
    }
}