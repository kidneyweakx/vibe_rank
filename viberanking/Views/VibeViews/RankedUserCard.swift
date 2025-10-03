import SwiftUI

// MARK: - Ranked User Card (Circular with ranking badge)
struct RankedUserCard: View {
    let gallery: TopUserGallery

    var body: some View {
        VStack(spacing: 10) {
            ZStack(alignment: .bottomTrailing) {
                // Avatar
                if let first = gallery.photoURLs.first, let url = URL(string: first) {
                    AsyncImage(url: url) { phase in
                        switch phase {
                        case .empty:
                            Circle()
                                .fill(
                                    LinearGradient(
                                        colors: [Color.white.opacity(0.08), Color.white.opacity(0.03)],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .overlay(
                                    ProgressView()
                                        .progressViewStyle(.circular)
                                        .tint(.white.opacity(0.7))
                                        .scaleEffect(0.8)
                                )
                        case .success(let image):
                            image
                                .resizable()
                                .scaledToFill()
                                .frame(width: 80, height: 80)
                                .clipShape(Circle())
                                .overlay(
                                    Circle()
                                        .stroke(rankGradient, lineWidth: gallery.rank <= 3 ? 3 : 2)
                                )
                        case .failure:
                            Circle()
                                .fill(
                                    LinearGradient(
                                        colors: [Color.white.opacity(0.08), Color.white.opacity(0.03)],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .overlay(
                                    Image(systemName: "person.fill")
                                        .font(.system(size: 32))
                                        .foregroundColor(.white.opacity(0.4))
                                )
                        @unknown default:
                            Color.clear
                        }
                    }
                } else {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [Color.white.opacity(0.08), Color.white.opacity(0.03)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 80, height: 80)
                        .overlay(
                            Image(systemName: "person.fill")
                                .font(.system(size: 32))
                                .foregroundColor(.white.opacity(0.4))
                        )
                }

                // Rank badge
                ZStack {
                    Circle()
                        .fill(rankGradient)
                        .frame(width: 28, height: 28)
                        .shadow(color: rankColor.opacity(0.5), radius: 6, x: 0, y: 3)
                        .overlay(
                            Circle()
                                .stroke(Color.black.opacity(0.2), lineWidth: 2)
                        )

                    Text("\(gallery.rank)")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(.white)
                }
                .offset(x: 2, y: 2)
            }
            .frame(width: 80, height: 80)

            VStack(spacing: 3) {
                Text(gallery.name)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(.white)
                    .lineLimit(1)

                if gallery.rank <= 3 {
                    HStack(spacing: 3) {
                        Image(systemName: "crown.fill")
                            .font(.system(size: 9))
                            .foregroundColor(rankColor)
                        Text("#\(gallery.rank)")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(.white.opacity(0.8))
                    }
                } else {
                    Text("#\(gallery.rank)")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(.white.opacity(0.6))
                }
            }
        }
        .frame(width: 88)
    }
    
    private var rankColor: Color {
        switch gallery.rank {
        case 1: return .yellow
        case 2: return Color(red: 0.75, green: 0.75, blue: 0.75)
        case 3: return Color(red: 0.8, green: 0.5, blue: 0.2)
        default: return .blue
        }
    }
    
    private var rankGradient: LinearGradient {
        switch gallery.rank {
        case 1:
            return LinearGradient(colors: [.yellow, Color.orange], startPoint: .topLeading, endPoint: .bottomTrailing)
        case 2:
            return LinearGradient(colors: [Color(red: 0.9, green: 0.9, blue: 0.9), Color(red: 0.6, green: 0.6, blue: 0.6)], startPoint: .topLeading, endPoint: .bottomTrailing)
        case 3:
            return LinearGradient(colors: [Color(red: 1.0, green: 0.6, blue: 0.2), Color(red: 0.6, green: 0.3, blue: 0.1)], startPoint: .topLeading, endPoint: .bottomTrailing)
        default:
            return LinearGradient(colors: [.blue, Color.blue.opacity(0.7)], startPoint: .topLeading, endPoint: .bottomTrailing)
        }
    }
}


