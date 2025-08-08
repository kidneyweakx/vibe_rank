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
