import SwiftUI

// MARK: - Per-Page Spotlight Helpers
extension MainTabView {
    func maybeShowPerPageSpotlight(for tab: TabItem) {
        print("🔄 maybeShowPerPageSpotlight called for tab: \(tab)")
        print("🔄 showSpotlight: \(showSpotlight)")
        print("🔄 hasSeenPageSpotlight: \(hasSeenPageSpotlight(for: tab))")
        
        if showSpotlight { 
            print("ℹ️ Spotlight already showing, returning")
            return 
        }
        if hasSeenPageSpotlight(for: tab) { 
            print("ℹ️ User has already seen page spotlight for tab: \(tab), returning")
            return 
        }
        
        // Only skip per-page spotlight if user has seen ALL page spotlights
        // This allows new users to see all per-page spotlights
        if hasSeenAllPageSpotlights() {
            print("ℹ️ User has seen all page spotlights, skipping per-page spotlight")
            return
        }
        
        print("🔄 Showing per-page spotlight for tab: \(tab)")
        let step = SpotlightScripts.pageStep(for: tab)
        overrideSpotlightStep = step
        withAnimation { showSpotlight = true }
    }

    func hasSeenPageSpotlight(for tab: TabItem) -> Bool {
        let hasSeen = switch tab {
        case .rating: hasSeenRatingPageSpotlight
        case .home: hasSeenTrendPageSpotlight
        case .journey: hasSeenJourneyPageSpotlight
        case .profile: hasSeenProfilePageSpotlight
        }
        print("🔄 hasSeenPageSpotlight for \(tab): \(hasSeen)")
        return hasSeen
    }
    
    /// Check if user has seen all page spotlights
    func hasSeenAllPageSpotlights() -> Bool {
        return hasSeenRatingPageSpotlight && 
               hasSeenTrendPageSpotlight && 
               hasSeenJourneyPageSpotlight && 
               hasSeenProfilePageSpotlight
    }

    func markCurrentPageSpotlightSeen(for tab: TabItem) {
        print("🔄 Marking page spotlight as seen for tab: \(tab)")
        switch tab {
        case .rating: hasSeenRatingPageSpotlight = true
        case .home: hasSeenTrendPageSpotlight = true
        case .journey: hasSeenJourneyPageSpotlight = true
        case .profile: hasSeenProfilePageSpotlight = true
        }
        
        // Only mark user as having seen spotlight globally after ALL page spotlights are completed
        if hasSeenAllPageSpotlights() {
            markCurrentUserSpotlightSeen()
            print("🎉 All page spotlights completed! Marking user as having seen spotlight globally")
        }
    }
}


