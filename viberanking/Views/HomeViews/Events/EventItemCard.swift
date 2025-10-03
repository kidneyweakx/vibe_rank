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
            VStack(spacing: 0) {
                ZStack {
                    LinearGradient(
                        colors: [Color.white.opacity(0.08), Color.white.opacity(0.03)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
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
                                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                                    .clipped()
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
                        .clipped()
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
                    LinearGradient(
                        colors: [Color.clear, Color.clear, Color.black.opacity(0.7)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                    VStack { Spacer() }
                    VStack {
                        HStack {
                            Spacer()
                            HStack(spacing: 6) {
                                Image(systemName: "star.fill")
                                    .font(.system(size: 8, weight: .bold))
                                    .foregroundColor(.yellow)
                                Text("common.partner_event".localized)
                                    .font(.system(size: 10, weight: .semibold))
                                    .foregroundColor(.white)
                            }
                            .padding(.horizontal, 10)
                            .padding(.vertical, 5)
                            .background(
                                Capsule()
                                    .fill(
                                        LinearGradient(
                                            colors: [Color.purple.opacity(0.8), Color.pink.opacity(0.7)],
                                            startPoint: .leading,
                                            endPoint: .trailing
                                        )
                                    )
                                    .shadow(color: .black.opacity(0.3), radius: 2, x: 0, y: 1)
                            )
                        }
                        Spacer()
                    }
                    .padding(12)
                }
                .aspectRatio(9/16, contentMode: .fit)
                .clipped()
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(
                            LinearGradient(
                                colors: [Color.white.opacity(0.2), Color.white.opacity(0.05)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1
                        )
                )
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


