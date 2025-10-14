//
//  LatestPhotoCard.swift
//  viberanking
//
//  Redesigned to match HomeView style (simple and clean)
//

import SwiftUI
import Kingfisher

struct LatestPhotoCard: View {
    let photo: PhotoInfo?
    let score: Double

    // Black-Red theme
    private let primaryRed = Color(red: 255/255, green: 0/255, blue: 92/255) // #FF005C

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header - Black-red theme
            HStack {
                Image(systemName: "photo.fill.on.rectangle.fill")
                    .foregroundColor(primaryRed)
                    .font(.system(size: 16, weight: .semibold))

                Text("journey.latest_photo.title".localized)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)

                Spacer()
            }

            // Photo with score overlay
            if let photo = photo {
                GeometryReader { geometry in
                    ZStack {
                        // Photo
                        KFImage(URL(string: photo.urls.bestAvailableURL))
                            .placeholder {
                                Rectangle()
                                    .fill(
                                        LinearGradient(
                                            colors: [
                                                Color(red: 94/255, green: 205/255, blue: 200/255).opacity(0.3),
                                                Color(red: 255/255, green: 139/255, blue: 148/255).opacity(0.2)
                                            ],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                    )
                                    .overlay(
                                        ProgressView()
                                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                    )
                            }
                            .resizable()
                            .aspectRatio(3/4, contentMode: .fill)
                            .frame(width: geometry.size.width, height: geometry.size.width * 4/3)
                            .clipped()
                            .opacity(0.85)

                        // Gradient overlay
                        LinearGradient(
                            colors: [
                                Color.clear,
                                Color.black.opacity(0.3),
                                Color.black.opacity(0.7)
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )

                        // Score overlay - Simplified
                        VStack {
                            Spacer()
                            VStack(spacing: 6) {
                                Text("journey.latest_photo.overall_score".localized)
                                    .font(.system(size: 13, weight: .medium))
                                    .foregroundColor(.white.opacity(0.9))

                                Text(String(format: "%.1f", score))
                                    .font(.system(size: 52, weight: .bold))
                                    .foregroundColor(.white)
                            }
                            .padding(.bottom, 24)
                        }
                    }
                    .frame(width: geometry.size.width, height: geometry.size.width * 4/3)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
                    .overlay(
                        // Red border (black-red theme)
                        RoundedRectangle(cornerRadius: 14)
                            .stroke(primaryRed.opacity(0.4), lineWidth: 1.5)
                    )
                }
                .aspectRatio(3/4, contentMode: .fit)
            } else {
                // Empty state (matching HomeView empty state style)
                VStack(spacing: 12) {
                    Image(systemName: "photo.badge.plus")
                        .font(.system(size: 44))
                        .foregroundColor(.white.opacity(0.3))

                    Text("journey.latest_photo.no_photo".localized)
                        .font(.system(size: 14))
                        .foregroundColor(.white.opacity(0.7))
                }
                .frame(maxWidth: .infinity)
                .frame(height: 280)
                .background(
                    // Simple dark gray card
                    RoundedRectangle(cornerRadius: 14)
                        .fill(Color(red: 0.1, green: 0.1, blue: 0.1))
                )
            }
        }
        // Padding removed - handled by parent
    }
}
