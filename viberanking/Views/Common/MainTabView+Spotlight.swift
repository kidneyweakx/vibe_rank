import SwiftUI

// MARK: - Per-Page Spotlight Helpers
extension MainTabView {
    func maybeShowPerPageSpotlight(for tab: TabItem) {
        if showSpotlight { return }
        if hasSeenPageSpotlight(for: tab) { return }
        let step = SpotlightScripts.pageStep(for: tab)
        overrideSpotlightStep = step
        withAnimation { showSpotlight = true }
    }

    func hasSeenPageSpotlight(for tab: TabItem) -> Bool {
        switch tab {
        case .rating: return hasSeenRatingPageSpotlight
        case .home: return hasSeenTrendPageSpotlight
        case .journey: return hasSeenJourneyPageSpotlight
        case .profile: return hasSeenProfilePageSpotlight
        }
    }

    func markCurrentPageSpotlightSeen(for tab: TabItem) {
        switch tab {
        case .rating: hasSeenRatingPageSpotlight = true
        case .home: hasSeenTrendPageSpotlight = true
        case .journey: hasSeenJourneyPageSpotlight = true
        case .profile: hasSeenProfilePageSpotlight = true
        }
    }
}


