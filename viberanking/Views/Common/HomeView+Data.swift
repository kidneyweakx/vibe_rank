import SwiftUI

// MARK: - Data & Layout Helpers
extension HomeView {
    func calculateGridConfiguration(for availableWidth: CGFloat) -> (columns: [GridItem], spacing: CGFloat, cardWidth: CGFloat) {
        let spacing: CGFloat = 16
        let columnsCount: Int
        if availableWidth >= 350 {
            columnsCount = 3
        } else if availableWidth >= 250 {
            columnsCount = 2
        } else {
            columnsCount = 1
        }
        let cardWidth = (availableWidth - spacing * CGFloat(columnsCount - 1)) / CGFloat(columnsCount)
        let columns = Array(repeating: GridItem(.flexible(), spacing: spacing, alignment: .top), count: columnsCount)
        return (columns: columns, spacing: spacing, cardWidth: cardWidth)
    }

    func loadData() {
        print("🔄 HomeView: Starting to load data...")
        Task {
            async let rankingsGalleries: [TopUserGallery] = fetchTopUserGalleries()
            async let fetchedEvents: [EventItem] = fetchEvents()
            let galleries = await rankingsGalleries
            let eventsData = await fetchedEvents
            await MainActor.run {
                self.topUserGalleries = galleries
                self.events = eventsData
                self.eventPhotos = []
                withAnimation(.easeInOut(duration: 0.25)) { self.isLoaded = true }
            }
        }
    }

    func fetchTopUserGalleries() async -> [TopUserGallery] {
        do {
            let rankings = try await RateAPI().getRankings(limit: 5)
            let top = rankings.data.overall.prefix(5)
            var galleries: [TopUserGallery] = []
            await withTaskGroup(of: TopUserGallery?.self) { group in
                for user in top {
                    group.addTask {
                        do {
                            let photosResponse = try await FileAPI().getUserPhotos(userId: user.userId, page: 1, limit: 5)
                            let infos = photosResponse.data.photos
                            let urls = infos.map { $0.urls.bestAvailableURL }.filter { !$0.isEmpty }
                            let chosen = Array(urls.prefix(5))
                            return TopUserGallery(
                                userId: user.userId,
                                name: user.name,
                                rank: user.rank,
                                avatarURL: user.avatar,
                                photoURLs: !chosen.isEmpty ? chosen : (user.avatar != nil ? [user.avatar!] : [])
                            )
                        } catch {
                            if let avatar = user.avatar, !avatar.isEmpty {
                                return TopUserGallery(
                                    userId: user.userId,
                                    name: user.name,
                                    rank: user.rank,
                                    avatarURL: avatar,
                                    photoURLs: [avatar]
                                )
                            }
                            return TopUserGallery(
                                userId: user.userId,
                                name: user.name,
                                rank: user.rank,
                                avatarURL: nil,
                                photoURLs: []
                            )
                        }
                    }
                }
                for await gallery in group { if let gallery = gallery { galleries.append(gallery) } }
            }
            let final = galleries
                .filter { !$0.photoURLs.isEmpty || $0.avatarURL != nil }
                .sorted { $0.rank < $1.rank }
            return final.isEmpty ? generateRandomUsers() : final
        } catch {
            return generateRandomUsers()
        }
    }

    func fetchEvents() async -> [EventItem] {
        do {
            let response = try await EventAPI().getEventList()
            return response.data
        } catch {
            print("❌ HomeView: Failed to load events: \(error)")
            return []
        }
    }

    // @TODO: delete or replace random users
    func generateRandomUsers() -> [TopUserGallery] {
        let names = ["Alex Chen", "Sarah Kim", "Mike Johnson", "Emma Liu", "David Park"]
        let sampleImages = [
            "https://picsum.photos/400/600?random=1",
            "https://picsum.photos/400/600?random=2",
            "https://picsum.photos/400/600?random=3",
            "https://picsum.photos/400/600?random=4",
            "https://picsum.photos/400/600?random=5"
        ]
        return names.enumerated().map { index, name in
            TopUserGallery(
                userId: "random_\(index)",
                name: name,
                rank: index + 1,
                avatarURL: "https://picsum.photos/100/100?random=\(index + 10)",
                photoURLs: Array(sampleImages.shuffled().prefix(3))
            )
        }
    }
}


