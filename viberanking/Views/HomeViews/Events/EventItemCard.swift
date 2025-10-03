import SwiftUI

// MARK: - Event Item Card (API-backed)
struct EventItemCard: View {
    let item: EventItem
    let onTap: () -> Void
    @State private var isPressed = false
    @Environment(\.openURL) private var openURL

    var body: some View {
        Button(action: {
            if let link = item.linkUrl, let url = URL(string: link) {
                openURL(url)
            } else {
                onTap()
            }
        }) {
            ZStack(alignment: .topTrailing) {
                // Main card content
                ZStack {
                    // Background gradient
                    LinearGradient(
                        colors: [Color.white.opacity(0.08), Color.white.opacity(0.03)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )

                    // Image
                    if let urlString = item.imageURL, let url = URL(string: urlString) {
                        AsyncImage(url: url) { phase in
                            switch phase {
                            case .empty:
                                VStack(spacing: 12) {
                                    ProgressView()
                                        .progressViewStyle(.circular)
                                        .tint(.white.opacity(0.7))
                                        .scaleEffect(0.8)
                                }
                            case .success(let image):
                                image
                                    .resizable()
                                    .scaledToFill()
                            case .failure:
                                VStack(spacing: 12) {
                                    Image(systemName: "calendar.badge.exclamationmark")
                                        .font(.system(size: 32))
                                        .foregroundColor(.white.opacity(0.4))
                                    Text("common.event".localized)
                                        .font(.system(size: 12, weight: .medium))
                                        .foregroundColor(.white.opacity(0.4))
                                }
                            @unknown default:
                                Color.clear
                            }
                        }
                    } else {
                        VStack(spacing: 12) {
                            Image(systemName: "calendar.badge.plus")
                                .font(.system(size: 32))
                                .foregroundColor(.white.opacity(0.4))
                            Text("common.event".localized)
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(.white.opacity(0.4))
                        }
                    }

                    // Bottom gradient overlay
                    VStack {
                        Spacer()
                        LinearGradient(
                            colors: [Color.clear, Color.black.opacity(0.4), Color.black.opacity(0.8)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                        .frame(height: 120)
                    }

                    // Event info at bottom
                    VStack {
                        Spacer()
                        VStack(alignment: .leading, spacing: 6) {
                            Text(item.title)
                                .font(.system(size: 16, weight: .bold))
                                .foregroundColor(.white)
                                .lineLimit(2)
                                .multilineTextAlignment(.leading)

                            if let description = item.description, !description.isEmpty {
                                Text(description)
                                    .font(.system(size: 13, weight: .regular))
                                    .foregroundColor(.white.opacity(0.85))
                                    .lineLimit(2)
                                    .multilineTextAlignment(.leading)
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(16)
                    }
                }
                .clipShape(RoundedRectangle(cornerRadius: 20))
                .shadow(color: .black.opacity(0.3), radius: 12, x: 0, y: 6)

                // Partner badge (positioned correctly with padding)
                HStack(spacing: 6) {
                    Image(systemName: "star.fill")
                        .font(.system(size: 9, weight: .bold))
                        .foregroundColor(.yellow)
                    Text("common.partner_event".localized)
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(.white)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(
                    Capsule()
                        .fill(
                            LinearGradient(
                                colors: [Color.purple.opacity(0.95), Color.pink.opacity(0.85)],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .shadow(color: .purple.opacity(0.4), radius: 8, x: 0, y: 4)
                )
                .padding([.top, .trailing], 12)
            }
        }
        .buttonStyle(PlainButtonStyle())
        .scaleEffect(isPressed ? 0.96 : 1.0)
        .animation(.easeInOut(duration: 0.15), value: isPressed)
        .onTapGesture {
            withAnimation(.easeInOut(duration: 0.1)) { isPressed = true }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                withAnimation(.easeInOut(duration: 0.1)) { isPressed = false }
                onTap()
            }
        }
    }

    private var introLine: String {
        if let desc = item.description, !desc.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return desc
        }
        if let startsAt = item.startsAt, !startsAt.isEmpty {
            return "於 \(String(startsAt.prefix(10))) 開跑 — \(item.title)"
        }
        return "立即參加「\(item.title)」，展現你的風格！"
    }
}


