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
    @State private var currentIndex = 0

    var body: some View {
        GeometryReader { geometry in
            let width = geometry.size.width
            let padding = horizontalPadding(for: width)
            let cardWidth = cardWidth(for: width, horizontalPadding: padding)
            let cardHeight = cardHeight(for: cardWidth)

            VStack(spacing: 20) {
                TabView(selection: $currentIndex) {
                    ForEach(Array(events.enumerated()), id: \.1.id) { index, event in
                        EventLargeCard(
                            event: event,
                            cardSize: CGSize(width: cardWidth, height: cardHeight),
                            isRegular: horizontalSizeClass == .regular
                        )
                        .tag(index)
                    }
                }
                .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
                .frame(width: cardWidth, height: cardHeight)

                if events.count > 1 {
                    EventCarouselIndicator(count: events.count, currentIndex: currentIndex)
                        .padding(.top, 4)
                        .animation(.easeInOut(duration: 0.3), value: currentIndex)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            .padding(.horizontal, padding)
            .padding(.vertical, horizontalSizeClass == .regular ? 16 : 8)
            .onChange(of: events.count) { newValue in
                currentIndex = min(currentIndex, max(newValue - 1, 0))
            }
        }
        .frame(height: horizontalSizeClass == .regular ? 700 : 520)
    }

    private func horizontalPadding(for width: CGFloat) -> CGFloat {
        switch width {
        case 0...480:
            return 16
        case 481...760:
            return 22
        case 761...980:
            return 40
        case 981...1200:
            return 56
        default:
            return 72
        }
    }

    private func cardWidth(for width: CGFloat, horizontalPadding: CGFloat) -> CGFloat {
        let proposed = width - (horizontalPadding * 2)
        return min(proposed, 820)
    }

    private func cardHeight(for width: CGFloat) -> CGFloat {
        let base = width * 9 / 16
        return max(base, horizontalSizeClass == .regular ? 520 : 430)
    }
}

private struct EventLargeCard: View {
    let event: EventItem
    let cardSize: CGSize
    let isRegular: Bool
    @Environment(\.openURL) private var openURL

    private var cornerRadius: CGFloat { isRegular ? 28 : 22 }

    var body: some View {
        ZStack(alignment: .bottomLeading) {
            eventImage

            LinearGradient(
                colors: [
                    Color.black.opacity(0.05),
                    Color.black.opacity(0.35),
                    Color.black.opacity(isRegular ? 0.92 : 0.88)
                ],
                startPoint: .top,
                endPoint: .bottom
            )

            VStack(alignment: .leading, spacing: 0) {
                partnerBadge
                    .padding(.bottom, isRegular ? 18 : 14)

                Spacer(minLength: 0)

                VStack(alignment: .leading, spacing: isRegular ? 16 : 12) {
                    Text(event.title)
                        .font(.system(size: isRegular ? 32 : 26, weight: .bold))
                        .foregroundColor(.white)
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)

                    if let dateRange = formattedDateRange {
                        Text(dateRange.uppercased())
                            .font(.system(size: isRegular ? 13 : 12, weight: .semibold))
                            .kerning(1.2)
                            .foregroundColor(.white.opacity(0.7))
                    }

                    if let description = event.description, !description.isEmpty {
                        Text(description)
                            .font(.system(size: isRegular ? 17 : 15, weight: .medium))
                            .foregroundColor(.white.opacity(0.88))
                            .lineLimit(3)
                            .fixedSize(horizontal: false, vertical: true)
                    }

                    infoRow
                }
            }
            .padding(.horizontal, isRegular ? 34 : 24)
            .padding(.vertical, isRegular ? 36 : 26)
        }
        .frame(width: cardSize.width, height: cardSize.height)
        .background(Color.white.opacity(0.04))
        .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .stroke(Color.white.opacity(0.14), lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(0.35), radius: isRegular ? 28 : 20, x: 0, y: isRegular ? 18 : 14)
    }

    private var eventImage: some View {
        Group {
            if let imageURL = event.imageURL, let url = URL(string: imageURL) {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .success(let image):
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    case .empty:
                        placeholder
                    case .failure:
                        failurePlaceholder
                    @unknown default:
                        placeholder
                    }
                }
            } else {
                placeholder
            }
        }
        .frame(width: cardSize.width, height: cardSize.height)
        .clipped()
    }

    private var infoRow: some View {
        HStack(spacing: 16) {
            HStack(spacing: 8) {
                Image(systemName: "person.3.fill")
                    .font(.system(size: isRegular ? 17 : 15, weight: .semibold))
                Text(formattedParticipants)
                    .font(.system(size: isRegular ? 15 : 14, weight: .medium))
            }
            .foregroundColor(.white.opacity(0.9))
            .padding(.horizontal, 16)
            .padding(.vertical, 9)
            .background(
                Capsule()
                    .fill(Color.white.opacity(0.14))
            )

            Spacer(minLength: 0)

            if let link = event.linkUrl, URL(string: link) != nil {
                Button(action: openTicket) {
                    HStack(spacing: 10) {
                        Text("Get Tickets")
                            .font(.system(size: isRegular ? 15 : 14, weight: .semibold))
                        Image(systemName: "arrow.right")
                            .font(.system(size: isRegular ? 14 : 13, weight: .semibold))
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, 22)
                    .padding(.vertical, 12)
                    .background(
                        Capsule()
                            .fill(
                                LinearGradient(
                                    colors: [Color(red: 1, green: 0.1, blue: 0.36), Color(red: 1, green: 0.4, blue: 0.3)],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                    )
                    .shadow(color: Color(red: 1, green: 0.1, blue: 0.36).opacity(0.4), radius: 10, x: 0, y: 6)
                }
                .buttonStyle(.plain)
            }
        }
    }

    private var partnerBadge: some View {
        HStack(spacing: 10) {
            Image(systemName: "sparkles")
                .font(.system(size: isRegular ? 14 : 12, weight: .semibold))
                .foregroundColor(.white)

            Text("Partner Event")
                .font(.system(size: isRegular ? 14 : 12, weight: .semibold))
                .foregroundColor(.white)
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 10)
        .background(
            Capsule(style: .continuous)
                .fill(Color.white.opacity(0.16))
                .background(
                    Capsule(style: .continuous)
                        .fill(LinearGradient(
                            colors: [Color(red: 1, green: 0, blue: 0.36).opacity(0.85), Color(red: 0.6, green: 0, blue: 0.6).opacity(0.7)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ))
                        .blur(radius: 14)
                )
        )
        .overlay(
            Capsule()
                .stroke(Color.white.opacity(0.22), lineWidth: 1)
        )
        .compositingGroup()
        .shadow(color: Color.black.opacity(0.25), radius: 12, x: 0, y: 6)
    }

    private var formattedParticipants: String {
        let participants = max(event.participantCount, 0)
        if participants >= 1000 {
            return String(format: "%.1fk", Double(participants) / 1000).replacingOccurrences(of: ".0", with: "")
        }
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.locale = Locale.current
        return formatter.string(from: NSNumber(value: participants)) ?? "\(participants)"
    }

    private var formattedDateRange: String? {
        guard let start = event.startDate else { return nil }
        let end = event.endDate ?? start
        let formatter = DateFormatter.eventCardDateFormatter

        if Calendar.current.isDate(start, inSameDayAs: end) {
            return formatter.string(from: start)
        }

        return "\(formatter.string(from: start))  –  \(formatter.string(from: end))"
    }

    private var placeholder: some View {
        Rectangle()
            .fill(LinearGradient(
                colors: [Color(red: 0.16, green: 0.16, blue: 0.18), Color(red: 0.08, green: 0.08, blue: 0.1)],
                startPoint: .top,
                endPoint: .bottom
            ))
            .overlay(
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
            )
    }

    private var failurePlaceholder: some View {
        Rectangle()
            .fill(Color.black.opacity(0.6))
            .overlay(
                VStack(spacing: 10) {
                    Image(systemName: "calendar.badge.exclamationmark")
                        .font(.system(size: isRegular ? 42 : 36))
                        .foregroundColor(.white.opacity(0.4))
                    Text("Image Unavailable")
                        .font(.system(size: isRegular ? 15 : 14, weight: .medium))
                        .foregroundColor(.white.opacity(0.4))
                }
            )
    }

    private func openTicket() {
        guard let link = event.linkUrl, let url = URL(string: link) else { return }
        openURL(url)
    }
}

private struct EventCarouselIndicator: View {
    let count: Int
    let currentIndex: Int

    var body: some View {
        GeometryReader { geometry in
            let totalSpacing: CGFloat = CGFloat(max(count - 1, 0)) * 6
            let indicatorWidth = (geometry.size.width - totalSpacing) / CGFloat(max(count, 1))

            HStack(spacing: 6) {
                ForEach(0..<count, id: \.self) { index in
                    Capsule()
                        .fill(Color.white.opacity(index == currentIndex ? 0.9 : 0.25))
                        .frame(width: indicatorWidth, height: 4)
                        .overlay(
                            Capsule()
                                .stroke(Color.white.opacity(0.35), lineWidth: index == currentIndex ? 1 : 0.5)
                        )
                        .shadow(color: Color.black.opacity(0.25), radius: 3, x: 0, y: 2)
                }
            }
        }
        .frame(height: 6)
        .frame(maxWidth: 320)
    }
}

private extension DateFormatter {
    static let eventCardDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        formatter.locale = Locale(identifier: Locale.current.identifier)
        return formatter
    }()
}



