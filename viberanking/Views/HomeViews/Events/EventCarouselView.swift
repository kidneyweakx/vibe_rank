//
//  EventCarouselView.swift
//  viberanking
//
//  Created by Assistant on 2025/10/15.
//

import SwiftUI

struct EventCarouselView: View {
    let events: [EventItem]
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @Environment(\.openURL) private var openURL

    var body: some View {
        let horizontalPadding: CGFloat = 26
        let screenWidth = UIScreen.main.bounds.width
        let contentWidth = screenWidth - (horizontalPadding * 2)
        let minHeight: CGFloat = horizontalSizeClass == .regular ? 640 : 440
        let cardWidth = contentWidth
        let aspectHeight = cardWidth * 9 / 16
        let cardHeight = max(aspectHeight, minHeight) // ensure full info area is visible

        HStack {
            Spacer(minLength: 0)
            TabView {
                ForEach(events, id: \.id) { event in
                    EventLargeCard(event: event)
                        .frame(width: cardWidth, height: cardHeight)
                }
            }
            .tabViewStyle(PageTabViewStyle(indexDisplayMode: .automatic))
            .frame(width: cardWidth, height: cardHeight)
            Spacer(minLength: 0)
        }
        .padding(.horizontal, horizontalPadding)
    }
}

private struct EventLargeCard: View {
    let event: EventItem
    @Environment(\.openURL) private var openURL

    var body: some View {
        ZStack(alignment: .bottomLeading) {
            if let imageURL = event.imageURL, let url = URL(string: imageURL) {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .success(let image):
                        image
                            .resizable()
                            .scaledToFill()
                    case .empty:
                        Rectangle().fill(Color.gray.opacity(0.3))
                            .overlay(
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            )
                    case .failure:
                        Rectangle()
                            .fill(Color.gray.opacity(0.3))
                            .overlay(
                                Image(systemName: "calendar.badge.exclamationmark")
                                    .font(.system(size: 48))
                                    .foregroundColor(.white.opacity(0.5))
                            )
                    @unknown default:
                        Color.clear
                    }
                }
            }

            LinearGradient(
                colors: [
                    Color.clear,
                    Color.black.opacity(0.4),
                    Color.black.opacity(0.8)
                ],
                startPoint: .top,
                endPoint: .bottom
            )

            VStack(alignment: .leading, spacing: 12) {
                HStack(spacing: 6) {
                    Image(systemName: "star.fill")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(Color(red: 255/255, green: 0/255, blue: 92/255))
                    Text("Partner Event")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(.white)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(
                    Capsule()
                        .fill(Color(red: 255/255, green: 0/255, blue: 92/255).opacity(0.9))
                )

                Text(event.title)
                    .font(.system(size: 28, weight: .bold))
                    .foregroundColor(.white)
                    .lineLimit(2)

                if let description = event.description, !description.isEmpty {
                    Text(description)
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.white.opacity(0.9))
                        .lineLimit(3)
                        .fixedSize(horizontal: false, vertical: true)
                }

                HStack {
                    HStack(spacing: 6) {
                        Image(systemName: "heart")
                            .font(.system(size: 16))
                        Text("1.2k")
                            .font(.system(size: 14))
                    }
                    .foregroundColor(.white)

                    Spacer()

                    Button(action: {
                        if let linkUrl = event.linkUrl, let url = URL(string: linkUrl) { openURL(url) }
                    }) {
                        Text("Get Tickets")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.white)
                            .padding(.horizontal, 20)
                            .padding(.vertical, 10)
                            .background(
                                Capsule()
                                    .fill(Color.white.opacity(0.3))
                            )
                    }
                }
                .padding(.top, 8)
            }
            .padding(EdgeInsets(top: 24, leading: 24, bottom: 56, trailing: 24))
        }
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .shadow(color: .black.opacity(0.4), radius: 16, x: 0, y: 8)
    }
}


