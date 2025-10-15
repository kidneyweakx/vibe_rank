import SwiftUI

// MARK: - Ranked User Card (Full-bleed gallery presentation)
struct RankedUserCard: View {
    let gallery: TopUserGallery
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass

    var body: some View {
        GeometryReader { geometry in
            let isRegular = horizontalSizeClass == .regular || geometry.size.width > 480
            let cornerRadius: CGFloat = isRegular ? 26 : 20

            ZStack(alignment: .bottomLeading) {
                cardImage
                    .frame(width: geometry.size.width, height: geometry.size.height)
                    .clipped()

                LinearGradient(
                    colors: [
                        Color.black.opacity(0.05),
                        Color.black.opacity(0.25),
                        Color.black.opacity(isRegular ? 0.85 : 0.78)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )

                VStack(alignment: .leading, spacing: isRegular ? 14 : 10) {
                    Spacer(minLength: 0)

                    VStack(alignment: .leading, spacing: isRegular ? 6 : 4) {
                        Text(gallery.name)
                            .font(.system(size: isRegular ? 26 : 22, weight: .semibold))
                            .foregroundColor(.white)
                            .lineLimit(1)

                        HStack(spacing: 8) {
                            if gallery.rank <= 3 {
                                Image(systemName: "crown.fill")
                                    .font(.system(size: isRegular ? 14 : 12))
                                    .foregroundColor(rankColor)
                            }

                            Text("#\(gallery.rank)")
                                .font(.system(size: isRegular ? 14 : 13, weight: .medium))
                                .foregroundColor(.white.opacity(0.78))
                        }
                    }

                    if photoCountText != nil {
                        Text(photoCountText!)
                            .font(.system(size: isRegular ? 13 : 12, weight: .semibold))
                            .kerning(1.0)
                            .foregroundColor(.white.opacity(0.7))
                    }
                }
                .padding(.horizontal, isRegular ? 26 : 20)
                .padding(.vertical, isRegular ? 28 : 22)
            }
            .frame(width: geometry.size.width, height: geometry.size.height)
            .background(Color.white.opacity(0.04))
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .stroke(Color.white.opacity(0.12), lineWidth: 1)
            )
            .overlay(alignment: .topTrailing) {
                rankBadge(isRegular: isRegular)
                    .padding(isRegular ? 22 : 16)
            }
            .shadow(color: Color.black.opacity(0.32), radius: isRegular ? 24 : 18, x: 0, y: isRegular ? 14 : 12)
        }
        .aspectRatio(3/4, contentMode: .fit)
    }

    private var cardImage: some View {
        Group {
            if let first = gallery.photoURLs.first, let url = URL(string: first) {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .empty:
                        placeholder
                    case .success(let image):
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    case .failure:
                        fallback
                    @unknown default:
                        placeholder
                    }
                }
            } else if let avatar = gallery.avatarURL, let url = URL(string: avatar) {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .empty:
                        placeholder
                    case .success(let image):
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    case .failure:
                        fallback
                    @unknown default:
                        placeholder
                    }
                }
            } else {
                placeholder
            }
        }
    }

    private var photoCountText: String? {
        let count = gallery.photoURLs.count
        guard count > 1 else { return nil }
        return "VIEW \(count) PHOTOS"
    }

    private func rankBadge(isRegular: Bool) -> some View {
        HStack(spacing: 8) {
            Text("Rank")
                .font(.system(size: isRegular ? 13 : 12, weight: .medium))
                .foregroundColor(.white.opacity(0.7))

            Text("#\(gallery.rank)")
                .font(.system(size: isRegular ? 16 : 15, weight: .bold))
                .foregroundColor(.white)
        }
        .padding(.horizontal, isRegular ? 16 : 14)
        .padding(.vertical, isRegular ? 10 : 8)
        .background(
            Capsule(style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [Color(red: 0.12, green: 0.12, blue: 0.14).opacity(0.8), Color.black.opacity(0.4)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
        )
        .overlay(
            Capsule(style: .continuous)
                .stroke(Color.white.opacity(0.18), lineWidth: 1)
        )
    }

    private var placeholder: some View {
        LinearGradient(
            colors: [Color(red: 0.14, green: 0.14, blue: 0.16), Color(red: 0.08, green: 0.08, blue: 0.1)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .overlay(
            ProgressView()
                .progressViewStyle(.circular)
                .tint(.white.opacity(0.7))
        )
    }

    private var fallback: some View {
        LinearGradient(
            colors: [Color(red: 0.18, green: 0.18, blue: 0.2), Color(red: 0.08, green: 0.08, blue: 0.1)],
            startPoint: .top,
            endPoint: .bottom
        )
        .overlay(
            Image(systemName: "person.fill")
                .font(.system(size: 42))
                .foregroundColor(.white.opacity(0.35))
        )
    }
    
    private var rankColor: Color {
        switch gallery.rank {
        case 1: return .yellow
        case 2: return Color(red: 0.75, green: 0.75, blue: 0.75)
        case 3: return Color(red: 0.8, green: 0.5, blue: 0.2)
        default: return Color(red: 94/255, green: 205/255, blue: 200/255) // Turquoise from logo
        }
    }

}


