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
    @Published var userStats: UserStats?
    @Published var rankings: RankingsData?
    @Published var chartData: [ChartDataPoint] = []
    
    // MARK: - Private Properties
    private let rateAPI = RateAPI()
    private var currentUserId: String = ""
    
    // MARK: - Public Methods
    
    func loadUserJourney(userId: String) async {
        currentUserId = userId
        await performAsyncTask {
            // Load user stats
            let statsResponse = try await self.rateAPI.getUserStats(userId: userId)
            if statsResponse.success {
                self.userStats = statsResponse.data
                self.generateChartData()
            }
            
            // Load rankings
            let rankingsResponse = try await self.rateAPI.getRankings(limit: 50)
            if rankingsResponse.success {
                self.rankings = rankingsResponse.data
            }
        }
    }
    
    func refreshData() async {
        guard !currentUserId.isEmpty else { return }
        await loadUserJourney(userId: currentUserId)
    }
    
    // MARK: - Computed Properties
    
    var overallPerformance: Double {
        return userStats?.totalScore ?? 0.0
    }
    
    var femaleAttraction: Double {
        // This would come from gender-specific stats in a real implementation
        return (userStats?.totalScore ?? 0.0) * 0.9
    }
    
    var maleAttraction: Double {
        // This would come from gender-specific stats in a real implementation
        return (userStats?.totalScore ?? 0.0) * 0.85
    }
    
    var currentRankPercentage: String {
        guard let stats = userStats, let rankings = rankings else { return "N/A" }
        
        let percentage = (Double(rankings.totalUsers - stats.overallRank) / Double(rankings.totalUsers)) * 100
        return "前 \(Int(percentage))%"
    }
    
    var totalUsers: String {
        return rankings?.totalUsers.formatted() ?? "0"
    }
    
    // MARK: - Private Methods
    
    private func generateChartData() {
        guard let stats = userStats else { return }
        
        // Generate sample chart data based on user stats
        // In a real app, this would come from historical data
        let baseScore = stats.totalScore
        var data: [ChartDataPoint] = []
        
        for i in 0..<30 {
            let variation = Double.random(in: -10...10)
            let score = max(0, min(100, baseScore + variation))
            data.append(ChartDataPoint(day: i, score: score))
        }
        
        self.chartData = data
    }
}

// MARK: - Chart Data Model

struct ChartDataPoint: Identifiable {
    let id = UUID()
    let day: Int
    let score: Double
}