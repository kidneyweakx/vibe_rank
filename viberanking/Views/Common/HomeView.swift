//
//  HomeView.swift
//  viberanking
//
//  Created by Kiro on 2025/07/25.
//

import SwiftUI

struct HomeView: View {
    @EnvironmentObject private var themeManager: ThemeManager
    @EnvironmentObject private var authViewModel: AuthenticationViewModel
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Trend Chart Section
                    trendChartSection
                    
                    // Quick Actions - Function Cards
                    quickActionsSection
                }
                .padding()
            }
            .background(Color.black)
            .navigationBarTitleDisplayMode(.large)
            .preferredColorScheme(.dark)
        }
    }

    // MARK: - Photo Gallery Section
    private var trendChartSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 16) {
                    ForEach(0..<5, id: \.self) { index in
                        PhotoGalleryCard(
                            imageName: "photo\(index + 1)",
                            title: "照片 \(index + 1)",
                            rating: Double.random(in: 7.0...9.5),
                            onTap: {
                                print("點擊照片 \(index + 1)")
                            }
                        )
                    }
                }
                .padding(.horizontal)
            }
            .padding(.horizontal, -16)
        }
    }
    
    // MARK: - Quick Actions Section
    private var quickActionsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            sectionHeader("快速操作")
            
            LazyVGrid(columns: [
                GridItem(.flexible(), spacing: AppTheme.Spacing.sm),
                GridItem(.flexible(), spacing: AppTheme.Spacing.sm)
            ], spacing: AppTheme.Spacing.md) {
                QuickActionCard(
                    title: "開始評分",
                    icon: "star.fill",
                    color: themeManager.currentTheme.colors.primary,
                    onTap: {
                        print("導航到評分頁面")
                    }
                )
                
                QuickActionCard(
                    title: "上傳照片",
                    icon: "camera.fill",
                    color: .green,
                    onTap: {
                        print("導航到上傳頁面")
                    }
                )
                
                QuickActionCard(
                    title: "個人資料",
                    icon: "person.circle.fill",
                    color: .purple,
                    onTap: {
                        print("導航到個人資料頁面")
                    }
                )
                
                QuickActionCard(
                    title: "排行榜",
                    icon: "trophy.fill",
                    color: .orange,
                    onTap: {
                        print("導航到排行榜頁面")
                    }
                )
            }
        }
    }
    

    
    // MARK: - Helper Methods
    private func sectionHeader(_ title: String) -> some View {
        HStack {
            Text(title)
                .font(AppTheme.Typography.title2)
                .fontWeight(.bold)
                .foregroundColor(.white)
            
            Spacer()
        }
        .padding(.top, 8)
    }
}

// MARK: - Preview
struct HomeView_Previews: PreviewProvider {
    static var previews: some View {
        HomeView()
            .environmentObject(ThemeManager())
            .environmentObject(AuthenticationViewModel())
    }
}


// MARK: - Photo Gallery Card Component
struct PhotoGalleryCard: View {
    let imageName: String
    let title: String
    let rating: Double
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 0) {
                // 圖片區域
                RoundedRectangle(cornerRadius: 12)
                    .fill(
                        LinearGradient(
                            colors: [
                                Color.gray.opacity(0.8),
                                Color.black.opacity(0.9),
                                Color.gray.opacity(0.7)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 140, height: 200)
                    .overlay(
                        VStack {
                            Image(systemName: "photo.fill")
                                .font(.system(size: 30))
                                .foregroundColor(.white)
                            
                            Text(title)
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(.white)
                                .padding(.top, 4)
                        }
                    )
                    .overlay(
                        // 評分標籤
                        VStack {
                            HStack {
                                Spacer()
                                HStack(spacing: 4) {
                                    Image(systemName: "star.fill")
                                        .font(.system(size: 10))
                                        .foregroundColor(.yellow)
                                    
                                    Text(String(format: "%.1f", rating))
                                        .font(.system(size: 11, weight: .semibold))
                                        .foregroundColor(.white)
                                }
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(
                                    Capsule()
                                        .fill(.black.opacity(0.8))
                                )
                            }
                            Spacer()
                        }
                        .padding(8)
                    )
            }
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Quick Action Card Component
struct QuickActionCard: View {
    let title: String
    let icon: String
    let color: Color
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 12) {
                Circle()
                    .fill(color.opacity(0.2))
                    .frame(width: 50, height: 50)
                    .overlay(
                        Image(systemName: icon)
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundColor(color)
                    )
                
                Text(title)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 100)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.gray.opacity(0.2))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                    )
                    .shadow(color: .black.opacity(0.3), radius: 4, x: 0, y: 2)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}
