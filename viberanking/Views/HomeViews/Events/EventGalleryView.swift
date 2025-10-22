import SwiftUI

struct EventGalleryView: View {
    let events: [EventItem]
    @State private var currentIndex: Int = 0

    var body: some View {
        GeometryReader { proxy in
            let cardWidth = max(0, proxy.size.width - 48) // 24 side margins total
            let itemSpacing: CGFloat = 16

            TabView(selection: $currentIndex) {
                ForEach(Array(events.enumerated()), id: \.element.id) { index, event in
                    EventItemCard(item: event, onTap: {})
                        .frame(width: cardWidth, height: proxy.size.height)
                        .tag(index)
                        .clipShape(RoundedRectangle(cornerRadius: 20))
                        .overlay(
                            RoundedRectangle(cornerRadius: 20)
                                .stroke(Color.white.opacity(0.08), lineWidth: 1)
                        )
                        .padding(.horizontal, 0)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .automatic))
            .indexViewStyle(.page(backgroundDisplayMode: .interactive))
        }
    }
}

#Preview {
    EventGalleryView(events: [
        EventItem(id: "1", title: "Autumn Street Snap Contest", description: "Post your best street style.", imageURL: nil, linkUrl: nil, startsAt: nil, endsAt: nil, startDate: nil, endDate: nil, participantCount: 0, isActive: true),
        EventItem(id: "2", title: "Night Portrait Challenge", description: "Low-light portraits.", imageURL: nil, linkUrl: nil, startsAt: nil, endsAt: nil, startDate: nil, endDate: nil, participantCount: 0, isActive: true)
    ])
    .frame(height: 340)
    .padding(.horizontal, 24)
    .background(Color.black)
}


