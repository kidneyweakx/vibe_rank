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
    @Published var journeyInfo: JourneyInfo?
    @Published var userPhotos: [Photo] = []
    @Published var recentRatings: [RecentRating] = []
    @Published var userPhotoInfos: [PhotoInfo] = []
    
    // MARK: - Private Properties
    private let profileInfoAPI = ProfileInfoAPI()
    private let rateAPI = RateAPI() // Fallback
    private let fileAPI = FileAPI() // Fallback
    private var currentUserId: String = ""
    
    // MARK: - Public Methods
    
    func loadUserProfile(userId: String) async {
        currentUserId = userId
        await performAsyncTask {
            do {
                // Try new consolidated API first
                let profileResponse = try await self.profileInfoAPI.getProfileInfo(userId: userId, photoLimit: 60)
                if profileResponse.success {
                    let data = profileResponse.data
                    
                    // Update journey info
                    self.journeyInfo = data.journey
                    self.recentRatings = data.journey.recentRatings
                    
                    // Update user photos
                    self.userPhotoInfos = data.photos.photos
                    self.userPhotos = data.photos.photos.map { info in
                        Photo(id: info.id, userId: info.userId, imageURL: info.urls)
                    }
                    print("✅ ProfileViewModel: Successfully loaded profile using consolidated API")
                    return
                }
            } catch {
                print("⚠️ ProfileViewModel: Consolidated API failed, falling back to separate APIs: \(error)")
            }
            
            // Fallback to existing separate API calls
            await self.loadUserProfileFallback(userId: userId)
        }
    }
    
    private func loadUserProfileFallback(userId: String) async {
        // Load journey info (includes user stats)
        do {
            let journeyResponse = try await self.rateAPI.getJourneyInfo(userId: userId)
            if journeyResponse.success {
                self.journeyInfo = journeyResponse.data
                self.recentRatings = journeyResponse.data.recentRatings
            }
        } catch {
            print("❌ ProfileViewModel: Failed to load journey info: \(error)")
        }
        
        // Load user's uploaded photos
        do {
            let photosResponse = try await self.fileAPI.getUserPhotos(userId: userId, page: nil, limit: 60)
            let infos = photosResponse.data.photos
            self.userPhotoInfos = infos
            // Build lightweight Photo models for any other consumers
            self.userPhotos = infos.map { info in
                Photo(id: info.id, userId: info.userId, imageURL: info.urls)
            }
            print("✅ ProfileViewModel: Successfully loaded profile using fallback APIs")
        } catch {
            self.userPhotoInfos = []
            self.userPhotos = []
            print("❌ ProfileViewModel: Failed to load user photos: \(error)")
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
        guard let info = journeyInfo else { return "0" }
        return String(format: "%.0f", info.totalScore)
    }
    
    var likeCount: String {
        return String(journeyInfo?.likeCount ?? 0)
    }
    
    var normalCount: String {
        return String(journeyInfo?.normalCount ?? 0)
    }
    
    var totalRatings: String {
        return String(journeyInfo?.totalRatings ?? 0)
    }
    
    var overallRank: String {
        guard let info = journeyInfo else { return "N/A" }
        return "#\(info.overallRank)"
    }
}