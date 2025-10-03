//
//  EventCardStack.swift
//  viberanking
//
//  Created by Assistant on 2025/10/03.
//

import SwiftUI

struct EventCardStack: View {
    let events: [EventItem]
    @State private var currentIndex: Int = 0
    @State private var dragOffset: CGSize = .zero

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                ForEach(Array(events.prefix(3).enumerated()), id: \.element.id) { index, event in
                    EventStackCard(event: event, index: index, currentIndex: currentIndex)
                        .frame(width: geometry.size.width, height: geometry.size.height)
                        .offset(y: offsetForCard(at: index))
                        .scaleEffect(scaleForCard(at: index))
                        .opacity(opacityForCard(at: index))
                        .zIndex(Double(3 - index))
                        .gesture(
                            index == 0 ?
                            DragGesture()
                                .onChanged { value in
                                    dragOffset = value.translation
                                }
                                .onEnded { value in
                                    handleSwipe(translation: value.translation)
                                }
                            : nil
                        )
                        .offset(x: index == 0 ? dragOffset.width : 0, y: index == 0 ? dragOffset.height : 0)
                        .rotationEffect(.degrees(index == 0 ? Double(dragOffset.width / 20) : 0))
                }
            }
        }
    }

    private func offsetForCard(at index: Int) -> CGFloat {
        let adjustedIndex = index - currentIndex
        if adjustedIndex < 0 { return 0 }
        return CGFloat(adjustedIndex) * 20
    }

    private func scaleForCard(at index: Int) -> CGFloat {
        let adjustedIndex = index - currentIndex
        if adjustedIndex < 0 { return 1.0 }
        return 1.0 - (CGFloat(adjustedIndex) * 0.05)
    }

    private func opacityForCard(at index: Int) -> Double {
        let adjustedIndex = index - currentIndex
        if adjustedIndex < 0 { return 0 }
        if adjustedIndex > 2 { return 0 }
        return 1.0 - (Double(adjustedIndex) * 0.2)
    }

    private func handleSwipe(translation: CGSize) {
        let threshold: CGFloat = 100

        withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
            if abs(translation.width) > threshold || abs(translation.height) > threshold {
                // Swiped away - move to next card
                if currentIndex < events.count - 1 {
                    currentIndex += 1
                }
            }
            dragOffset = .zero
        }
    }
}

// MARK: - Event Stack Card
struct EventStackCard: View {
    let event: EventItem
    let index: Int
    let currentIndex: Int
    @Environment(\.openURL) private var openURL

    var body: some View {
        ZStack(alignment: .bottomLeading) {
            // Event image
            if let imageURL = event.imageURL, let url = URL(string: imageURL) {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .success(let image):
                        image
                            .resizable()
                            .scaledToFill()
                    case .empty:
                        Rectangle()
                            .fill(Color.gray.opacity(0.3))
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

            // Gradient overlay
            LinearGradient(
                colors: [
                    Color.clear,
                    Color.black.opacity(0.4),
                    Color.black.opacity(0.8)
                ],
                startPoint: .top,
                endPoint: .bottom
            )

            // Event info
            VStack(alignment: .leading, spacing: 12) {
                // Partner badge
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
                        .lineLimit(1)
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
                        if let linkUrl = event.linkUrl, let url = URL(string: linkUrl) {
                            openURL(url)
                        }
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
            .padding(24)
        }
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .shadow(color: .black.opacity(0.4), radius: 16, x: 0, y: 8)
    }
}
