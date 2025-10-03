//
//  LatestPhotoCard.swift
//  viberanking
//
//  Created by Assistant on 2025/10/03.
//

import SwiftUI
import Kingfisher

struct LatestPhotoCard: View {
    let photo: PhotoInfo?
    let score: Double

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header
            HStack {
                Image(systemName: "photo.fill.on.rectangle.fill")
                    .foregroundStyle(
                        LinearGradient(
                            colors: [
                                Color(red: 255/255, green: 139/255, blue: 148/255),
                                Color(red: 94/255, green: 205/255, blue: 200/255)
                            ],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                Text("journey.latest_photo.title".localized)
                    .font(.headline)
                    .foregroundStyle(
                        LinearGradient(
                            colors: [
                                Color(red: 255/255, green: 139/255, blue: 148/255),
                                Color.white
                            ],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                Spacer()
            }
            .padding(.horizontal, 20)

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

                        // Score overlay
                        VStack {
                            Spacer()
                            VStack(spacing: 8) {
                                Text("journey.latest_photo.overall_score".localized)
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(.white.opacity(0.8))

                                Text(String(format: "%.1f", score))
                                    .font(.system(size: 64, weight: .bold))
                                    .foregroundStyle(
                                        LinearGradient(
                                            colors: [
                                                Color(red: 255/255, green: 139/255, blue: 148/255),
                                                Color(red: 94/255, green: 205/255, blue: 200/255)
                                            ],
                                            startPoint: .leading,
                                            endPoint: .trailing
                                        )
                                    )
                                    .shadow(color: Color(red: 94/255, green: 205/255, blue: 200/255).opacity(0.5), radius: 12, x: 0, y: 0)
                            }
                            .padding(.bottom, 32)
                        }
                    }
                    .frame(width: geometry.size.width, height: geometry.size.width * 4/3)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(
                                LinearGradient(
                                    colors: [
                                        Color(red: 255/255, green: 139/255, blue: 148/255).opacity(0.3),
                                        Color(red: 94/255, green: 205/255, blue: 200/255).opacity(0.3)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 1
                            )
                    )
                }
                .aspectRatio(3/4, contentMode: .fit)
                .padding(.horizontal, 20)
            } else {
                // Empty state
                VStack(spacing: 16) {
                    Image(systemName: "photo.badge.plus")
                        .font(.system(size: 48))
                        .foregroundColor(.white.opacity(0.3))

                    Text("journey.latest_photo.no_photo".localized)
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(0.6))
                }
                .frame(maxWidth: .infinity)
                .frame(height: 300)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color.white.opacity(0.05))
                )
                .padding(.horizontal, 20)
            }
        }
    }
}
