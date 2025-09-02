//
//  JourneyViewModel.swift
//  viberanking
//
//  Created by Kiro on 2025/08/09.
//

import Foundation
import SwiftUI
import Combine

@MainActor
class JourneyViewModel: BaseViewModel {
    
    // MARK: - Published Properties
    @Published var journeyInfo: JourneyInfo?
    @Published var chartData: [ChartDataPoint] = []
    
    // MARK: - Private Properties
    private let rateAPI = RateAPI()
    private var currentUserId: String = ""
    
    // MARK: - Public Methods
    
    func loadUserJourney(userId: String) async {
        currentUserId = userId
        await performAsyncTask {
            // Single API call for all journey data
            let journeyResponse = try await self.rateAPI.getJourneyInfo(userId: userId)
            if journeyResponse.success {
                self.journeyInfo = journeyResponse.data
                // Use pre-calculated weekly trend from API
                self.chartData = journeyResponse.data.weeklyTrend.enumerated().map { index, dailyScore in
                    ChartDataPoint(day: index, score: dailyScore.score ?? 0.0)
                }
            }
        }
    }
    
    func refreshData() async {
        guard !currentUserId.isEmpty else { return }
        await loadUserJourney(userId: currentUserId)
    }
    
    // MARK: - Computed Properties
    
    var overallPerformance: Double {
        return journeyInfo?.totalScore ?? 0.0
    }
    
    var femaleAttraction: Double {
        return journeyInfo?.femaleAttraction ?? 0.0
    }
    
    var maleAttraction: Double {
        return journeyInfo?.maleAttraction ?? 0.0
    }
    
    var journeyLevel: JourneyLevel {
        let score = journeyInfo?.totalScore ?? 0
        return JourneyLevel(score: score)
    }
    
    var currentRankPercentage: String {
        guard let info = journeyInfo else { return "N/A" }
        let percentage = (Double(info.totalUsers - info.overallRank) / Double(info.totalUsers)) * 100
        return "前 \(Int(percentage))%"
    }
    
    var totalUsers: String {
        return journeyInfo?.totalUsers.formatted() ?? "0"
    }
    

}

// MARK: - Chart Data Model

struct ChartDataPoint: Identifiable {
    let id = UUID()
    let day: Int
    let score: Double
}

// MARK: - Journey Level

enum JourneyLevel: Int, CaseIterable {
    case background = 1      // 1-10
    case invisible           // 11-20
    case awkward             // 21-30
    case basic               // 31-40
    case wannabe             // 41-50
    case certifiedCutie      // 51-60
    case freshFit            // 61-70
    case flexOnMe            // 71-80
    case cameraMagnet        // 81-90
    case aura                // 91-100
    
    init(score: Double) {
        let clamped = max(0, min(100, score))
        switch clamped {
        case 0...10: self = .background
        case 11...20: self = .invisible
        case 21...30: self = .awkward
        case 31...40: self = .basic
        case 41...50: self = .wannabe
        case 51...60: self = .certifiedCutie
        case 61...70: self = .freshFit
        case 71...80: self = .flexOnMe
        case 81...90: self = .cameraMagnet
        default: self = .aura
        }
    }
    
    // Localization keys
    private var titleKey: String {
        switch self {
        case .background: return "journey.level.background.title"
        case .invisible: return "journey.level.invisible.title"
        case .awkward: return "journey.level.awkward.title"
        case .basic: return "journey.level.basic.title"
        case .wannabe: return "journey.level.wannabe.title"
        case .certifiedCutie: return "journey.level.certified_cutie.title"
        case .freshFit: return "journey.level.fresh_fit.title"
        case .flexOnMe: return "journey.level.flex_on_me.title"
        case .cameraMagnet: return "journey.level.camera_magnet.title"
        case .aura: return "journey.level.aura.title"
        }
    }
    
    private var subtitleKey: String {
        switch self {
        case .background: return "journey.level.background.subtitle"
        case .invisible: return "journey.level.invisible.subtitle"
        case .awkward: return "journey.level.awkward.subtitle"
        case .basic: return "journey.level.basic.subtitle"
        case .wannabe: return "journey.level.wannabe.subtitle"
        case .certifiedCutie: return "journey.level.certified_cutie.subtitle"
        case .freshFit: return "journey.level.fresh_fit.subtitle"
        case .flexOnMe: return "journey.level.flex_on_me.subtitle"
        case .cameraMagnet: return "journey.level.camera_magnet.subtitle"
        case .aura: return "journey.level.aura.subtitle"
        }
    }
    
    var titleLocalized: String { titleKey.localized }
    var subtitleLocalized: String { subtitleKey.localized }
    
    var color: Color {
        switch self {
        case .background: return .gray
        case .invisible: return .blue
        case .awkward: return .orange
        case .basic: return .cyan
        case .wannabe: return .teal
        case .certifiedCutie: return .pink
        case .freshFit: return .green
        case .flexOnMe: return .yellow
        case .cameraMagnet: return .purple
        case .aura: return .yellow
        }
    }
    
    var icon: String {
        switch self {
        case .background: return "person.fill"
        case .invisible: return "eye.slash.fill"
        case .awkward: return "tortoise.fill"
        case .basic: return "book.fill"
        case .wannabe: return "backpack.fill"
        case .certifiedCutie: return "heart.circle.fill"
        case .freshFit: return "tshirt.fill"
        case .flexOnMe: return "sun.max.fill"
        case .cameraMagnet: return "camera.fill"
        case .aura: return "crown.fill"
        }
    }
}