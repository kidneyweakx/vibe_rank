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


    
    @MainActor
    func loadHomeInfo() async {
        guard !isLoading else { return }
        isLoading = true
        
        do {
            let response = try await HomeInfoAPI().getHomeInfo()
            self.homeInfo = response.data
            self.announcements = [] // No announcements in current API response
            self.statistics = nil // No statistics in current API response
            
            // Convert top users to top user galleries for compatibility
            self.topUserGalleries = response.data.topUsers.overall.prefix(5).map { user in
                TopUserGallery(
                    userId: user.userId,
                    name: user.name,
                    rank: user.rank,
                    avatarURL: user.avatar,
                    photoURLs: user.avatar != nil ? [user.avatar!] : []
                )
            }
            
            // Convert recent events to event items for compatibility
            self.events = response.data.recentEvents.map { event in
                EventItem(
                    id: event.id,
                    title: event.title,
                    description: event.description,
                    imageURL: event.imageUrl,
                    linkUrl: event.url,
                    startsAt: event.startsAt,
                    endsAt: event.endsAt,
                    startDate: nil, // Will be parsed from startsAt string
                    endDate: nil,   // Will be parsed from endsAt string
                    participantCount: 0, // Not available in current API
                    isActive: true // Assume active for now
                )
            }
            
            withAnimation(.easeInOut(duration: 0.25)) { 
                self.isLoaded = true 
            }
        } catch {
            // Handle different types of errors
            if let urlError = error as? URLError {
                switch urlError.code {
                case .cancelled:
                    print("ℹ️ HomeView: Request was cancelled (likely due to navigation or rapid requests)")
                    return // Don't show error state for cancelled requests
                case .notConnectedToInternet, .networkConnectionLost:
                    print("❌ HomeView: Network error: \(error)")
                default:
                    print("❌ HomeView: URL error: \(error)")
                }
            } else {
                print("❌ HomeView: Failed to load home info: \(error)")
            }
            
            // Show empty state instead of fallback data
            self.topUserGalleries = []
            self.events = []
            self.eventPhotos = []
            self.homeInfo = nil
            self.announcements = []
            self.statistics = nil
            
            withAnimation(.easeInOut(duration: 0.25)) { 
                self.isLoaded = true 
            }
        }
        
        isLoading = false
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


}


