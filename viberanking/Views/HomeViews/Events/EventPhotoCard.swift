import SwiftUI

// MARK: - Event Photo Card
struct EventPhotoCard: View {
    let photo: EventPhoto
    let onTap: () -> Void
    @State private var isPressed = false
    
    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 0) {
                ZStack {
                    RoundedRectangle(cornerRadius: 16)
                        .fill(
                            LinearGradient(
                                colors: [Color.white.opacity(0.08), Color.white.opacity(0.03)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .aspectRatio(9/16, contentMode: .fit)
                        .clipped()
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
                    if let imageURL = photo.imageURL, let url = URL(string: imageURL) {
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
                                    Image(systemName: "photo.artframe")
                                        .font(.system(size: 32))
                                        .foregroundColor(.white.opacity(0.4))
                                    Text("common.event_photo".localized)
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
                            Image(systemName: "photo.artframe")
                                .font(.system(size: 32))
                                .foregroundColor(.white.opacity(0.4))
                            Text("common.event_photo".localized)
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(.white.opacity(0.4))
                        }
                    }
                    LinearGradient(
                        colors: [Color.black.opacity(0.3), Color.clear, Color.clear, Color.black.opacity(0.4)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                    .cornerRadius(16)
                    VStack {
                        HStack {
                            Spacer()
                            HStack(spacing: 4) {
                                Image(systemName: "heart.fill")
                                    .font(.system(size: 10))
                                    .foregroundColor(.pink)
                                Text("\(photo.likes)")
                                    .font(.system(size: 11, weight: .bold))
                                    .foregroundColor(.white)
                            }
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                            .background(
                                Capsule()
                                    .fill(Color.black.opacity(0.7))
                                    .overlay(
                                        Capsule()
                                            .stroke(Color.white.opacity(0.1), lineWidth: 0.5)
                                    )
                            )
                        }
                        Spacer()
                        HStack {
                            Text(timeAgo)
                                .font(.system(size: 11, weight: .medium))
                                .foregroundColor(.white.opacity(0.9))
                                .shadow(color: .black.opacity(0.5), radius: 2, x: 0, y: 1)
                            Spacer()
                        }
                    }
                    .padding(12)
                }
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
    
    private var timeAgo: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: photo.timestamp, relativeTo: Date())
    }
}


