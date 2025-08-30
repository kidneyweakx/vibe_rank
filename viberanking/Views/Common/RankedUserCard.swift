import SwiftUI

// MARK: - Ranked User Card (9:16 portrait)
struct RankedUserCard: View {
    let gallery: TopUserGallery

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                ZStack {
                    Circle()
                        .fill(rankGradient)
                        .frame(width: 28, height: 28)
                        .shadow(color: rankColor.opacity(0.3), radius: 4, x: 0, y: 2)
                    Text("\(gallery.rank)")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(.white)
                }
                Spacer()
                if gallery.rank <= 3 {
                    Image(systemName: "crown.fill")
                        .font(.system(size: 16))
                        .foregroundColor(rankColor)
                }
            }

            ZStack {
                RoundedRectangle(cornerRadius: 16)
                    .fill(
                        LinearGradient(
                            colors: [Color.white.opacity(0.08), Color.white.opacity(0.03)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                if let first = gallery.photoURLs.first, let url = URL(string: first) {
                    AsyncImage(url: url) { phase in
                        switch phase {
                        case .empty:
                            ProgressView()
                                .progressViewStyle(.circular)
                                .tint(.white.opacity(0.7))
                                .scaleEffect(0.8)
                        case .success(let image):
                            image
                                .resizable()
                                .scaledToFill()
                                .frame(width: 100)
                                .aspectRatio(9/16, contentMode: .fill)
                                .clipShape(RoundedRectangle(cornerRadius: 16))
                        case .failure:
                            VStack(spacing: 8) {
                                Image(systemName: "photo.artframe")
                                    .font(.system(size: 32))
                                    .foregroundColor(.white.opacity(0.4))
                                Text("common.photo".localized)
                                    .font(.system(size: 12, weight: .medium))
                                    .foregroundColor(.white.opacity(0.4))
                            }
                        @unknown default:
                            Color.clear
                        }
                    }
                    .frame(width: 100)
                    .aspectRatio(9/16, contentMode: .fit)
                    .clipped()
                } else {
                    VStack(spacing: 8) {
                        Image(systemName: "photo.artframe")
                            .font(.system(size: 32))
                            .foregroundColor(.white.opacity(0.4))
                        Text("common.no_photos".localized)
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.white.opacity(0.4))
                    }
                }
            }
            .frame(width: 100)
            .aspectRatio(9/16, contentMode: .fit)
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

            Text(gallery.name)
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(.white)
                .lineLimit(1)
        }
        .frame(width: 100)
        .padding(.vertical, 8)
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


