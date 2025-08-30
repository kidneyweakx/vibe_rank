import SwiftUI

// MARK: - Sections
extension HomeView {
    var recommendedSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            sectionHeader("home.recommended.title".localized, subtitle: "home.recommended.subtitle".localized)
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 16) {
                    ForEach(topUserGalleries, id: \.userId) { gallery in
                        RankedUserCard(gallery: gallery)
                            .frame(width: 100)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.trailing, 20)
            }
        }
    }

    var eventSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            sectionHeader("home.events.title".localized, subtitle: "home.events.subtitle".localized)
            GeometryReader { proxy in
                let gridConfig = calculateGridConfiguration(for: proxy.size.width)
                ScrollView {
                    LazyVGrid(columns: gridConfig.columns, spacing: gridConfig.spacing) {
                        ForEach(events) { item in
                            EventItemCard(item: item) { }
                                .frame(width: gridConfig.cardWidth)
                                .aspectRatio(9/16, contentMode: .fit)
                                .clipShape(RoundedRectangle(cornerRadius: 16))
                        }
                    }
                    .padding(.bottom, 20)
                }
            }
            .frame(minHeight: 400)
        }
    }

    var divider: some View {
        Rectangle()
            .fill(Color.white.opacity(0.1))
            .frame(height: 1)
            .padding(.horizontal, 20)
    }

    func sectionHeader(_ title: String, subtitle: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.system(size: 24, weight: .bold))
                .foregroundColor(.white)
            Text(subtitle)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.white.opacity(0.6))
        }
    }
}


