import SwiftUI

// MARK: - Data & Layout Helpers
extension HomeView {
    func calculateGridConfiguration(for availableWidth: CGFloat) -> (columns: [GridItem], spacing: CGFloat, cardWidth: CGFloat) {
        let spacing: CGFloat = 16
        let columnsCount: Int

        // Responsive grid based on available width (iPad-friendly)
        if availableWidth >= 1200 {
            // iPad Pro 12.9" landscape or larger displays
            columnsCount = 5
        } else if availableWidth >= 900 {
            // iPad Air/Pro landscape
            columnsCount = 4
        } else if availableWidth >= 600 {
            // iPad portrait or large phones landscape
            columnsCount = 3
        } else if availableWidth >= 400 {
            // Standard phone portrait
            columnsCount = 2
        } else {
            // Small phones
            columnsCount = 1
        }

        let totalSpacing = spacing * CGFloat(columnsCount - 1)
        let cardWidth = (availableWidth - totalSpacing - 40) / CGFloat(columnsCount) // 40 for horizontal padding
        let columns = Array(repeating: GridItem(.flexible(), spacing: spacing, alignment: .top), count: columnsCount)
        return (columns: columns, spacing: spacing, cardWidth: cardWidth)
    }


    func loadHomeInfo() async {
        let started: Bool = await MainActor.run {
            if isLoading { return false }
            isLoading = true
            return true
        }
        guard started else { return }
        defer { Task { await MainActor.run { isLoading = false } } }

        let maxAttempts = 3
        var attempt = 0
        var lastError: Error? = nil
        
        while attempt < maxAttempts {
            if Task.isCancelled { 
                print("ℹ️ HomeView: load cancelled before request start (attempt: \(attempt + 1))")
                return
            }
            attempt += 1
            do {
                let response = try await HomeInfoAPI().getHomeInfo()
                if Task.isCancelled { return }

                // Prepare view models off the main actor
                let computedTopGalleries: [TopUserGallery] = response.data.topUsers.overall.prefix(5).map { user in
                    TopUserGallery(
                        userId: user.userId,
                        name: user.name,
                        rank: user.rank,
                        avatarURL: user.avatar,
                        photoURLs: user.avatar != nil ? [user.avatar!] : []
                    )
                }

                let computedEvents: [EventItem] = response.data.recentEvents.map { event in
                    EventItem(
                        id: event.id,
                        title: event.title,
                        description: event.description,
                        imageURL: event.imageUrl,
                        linkUrl: event.url,
                        startsAt: event.startsAt,
                        endsAt: event.endsAt,
                        startDate: nil,
                        endDate: nil,
                        participantCount: 0,
                        isActive: true
                    )
                }

                // Start prefetching images in the background (avatars + event images)
                let avatarURLs = computedTopGalleries.compactMap { $0.avatarURL }
                let eventImageURLs = computedEvents.compactMap { $0.imageURL }
                let uniqueURLs = Array(Set(avatarURLs + eventImageURLs))
                if !uniqueURLs.isEmpty {
                    Task.detached(priority: .utility) {
                        ImageCache.shared.preloadImages(urls: uniqueURLs)
                    }
                }

                // Debug logging
                print("✅ HomeView: Loaded \(response.data.topUsers.overall.count) top users")
                print("📊 HomeView: topUserGalleries count: \(computedTopGalleries.count)")
                for (index, gallery) in computedTopGalleries.enumerated() {
                    print("  [\(index+1)] \(gallery.name) - avatar: \(gallery.avatarURL ?? "nil")")
                }

                // Apply to UI on main actor
                await MainActor.run {
                    self.homeInfo = response.data
                    self.announcements = []
                    self.statistics = nil
                    self.topUserGalleries = computedTopGalleries
                    self.events = computedEvents
                    withAnimation(.easeInOut(duration: 0.25)) { 
                        self.isLoaded = true 
                    }
                }
                return
            } catch is CancellationError {
                print("ℹ️ HomeView: Request cancelled during attempt \(attempt)")
                return
            } catch {
                lastError = error
                if let apiError = error as? APIError {
                    switch apiError {
                    case .serverError(let code) where code == 429 || (500...599).contains(code):
                        // retryable
                        break
                    default:
                        // non-retryable
                        attempt = maxAttempts
                    }
                } else if let urlError = error as? URLError {
                    switch urlError.code {
                    case .timedOut, .cannotFindHost, .cannotConnectToHost, .networkConnectionLost, .notConnectedToInternet:
                        break // retryable
                    case .cancelled:
                        print("ℹ️ HomeView: Request was cancelled (likely due to navigation or rapid requests)")
                        return
                    default:
                        attempt = maxAttempts // non-retryable
                    }
                } else {
                    // Unknown error, do not hammer the server
                    attempt = maxAttempts
                }

                if attempt < maxAttempts {
                    // Exponential backoff with jitter
                    let baseDelay: Double = 0.25
                    let delay = baseDelay * pow(2.0, Double(attempt - 1))
                    let jitter = Double.random(in: 0...0.15)
                    let sleepNs = UInt64((delay + jitter) * 1_000_000_000)
                    print("🔁 HomeView: retrying in \(String(format: "%.2f", delay + jitter))s (attempt \(attempt + 1)/\(maxAttempts)) due to: \(error)")
                    try? await Task.sleep(nanoseconds: sleepNs)
                    continue
                }
            }
        }

        // Final failure: show empty state but keep UI responsive
        if let lastError = lastError {
            print("❌ HomeView: Failed to load home info after retries: \(lastError)")
        }
        await MainActor.run {
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


