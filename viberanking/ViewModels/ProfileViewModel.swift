//
//  ProfileViewModel.swift
//  viberanking
//
//  Created by Kiro on 2025/08/09.
//

import Foundation
import SwiftUI
import Combine

@MainActor
class ProfileViewModel: BaseViewModel {
    
    // MARK: - Published Properties
    @Published var userStats: UserStats?
    @Published var userPhotos: [Photo] = []
    @Published var recentRatings: [RecentRating] = []
    
    // MARK: - Private Properties
    private let rateAPI = RateAPI()
    private let fileAPI = FileAPI()
    private var currentUserId: String = ""
    
    // MARK: - Public Methods
    
    func loadUserProfile(userId: String) async {
        currentUserId = userId
        await performAsyncTask {
            // Load user stats
            let statsResponse = try await self.rateAPI.getUserStats(userId: userId)
            if statsResponse.success {
                self.userStats = statsResponse.data
                self.recentRatings = statsResponse.data.recentRatings
            }
            
            // Load user's uploaded photos (this would need a new API endpoint)
            // For now, we'll use empty array
            self.userPhotos = []
        }
    }
    
    func refreshData() async {
        guard !currentUserId.isEmpty else { return }
        await loadUserProfile(userId: currentUserId)
    }
    
    // MARK: - Computed Properties
    
    var weeksPosted: Int {
        // Calculate based on user photos or stats
        return userPhotos.count / 7 // Rough estimate
    }
    
    var totalScore: String {
        guard let stats = userStats else { return "0" }
        return String(format: "%.0f", stats.totalScore)
    }
    
    var likeCount: String {
        return String(userStats?.likeCount ?? 0)
    }
    
    var normalCount: String {
        return String(userStats?.normalCount ?? 0)
    }
    
    var totalRatings: String {
        return String(userStats?.totalRatings ?? 0)
    }
    
    var overallRank: String {
        guard let stats = userStats else { return "N/A" }
        return "#\(stats.overallRank)"
    }
}