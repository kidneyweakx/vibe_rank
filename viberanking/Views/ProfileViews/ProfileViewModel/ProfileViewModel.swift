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
    @Published var userBasicInfo: UserBasicInfo? // 添加用戶基本信息
    
    // MARK: - Private Properties
    private let profileInfoAPI = ProfileInfoAPI()
    private let rateAPI = RateAPI() // Fallback
    private let fileAPI = FileAPI() // Fallback
    private var currentUserId: String = ""
    private var isLoadingProfile = false
    private var lastLoadTime: Date = Date.distantPast
    
    // MARK: - Public Methods
    
    func loadUserProfile(userId: String, forceReload: Bool = false) async {
        // Prevent multiple simultaneous calls
        guard !isLoadingProfile else {
            print("⚠️ ProfileViewModel: Already loading profile, skipping duplicate call")
            return
        }
        
        // Check if we already have data for this user
        if !forceReload && currentUserId == userId && journeyInfo != nil {
            print("✅ ProfileViewModel: Already have data for userId: \(userId), skipping load")
            return
        }
        
        // Prevent too frequent calls (minimum 2 seconds between calls)
        let now = Date()
        if !forceReload && now.timeIntervalSince(lastLoadTime) < 2.0 {
            print("⚠️ ProfileViewModel: Too frequent calls, skipping (last call was \(now.timeIntervalSince(lastLoadTime))s ago)")
            return
        }
        
        currentUserId = userId
        isLoadingProfile = true
        print("🔄 ProfileViewModel: Starting to load profile for userId: \(userId)")
        
        await performAsyncTask {
            print("🚀 ProfileViewModel: Starting API call sequence for userId: \(userId)")
            
            // Try new consolidated API first
            do {
                print("📡 ProfileViewModel: Attempting consolidated API call...")
                print("   📋 API Details:")
                print("   - Endpoint: /api/info/profileInfo/\(userId)")
                print("   - Method: GET")
                print("   - Photo Limit: 60")
                print("   - Timestamp: \(Date())")
                
                let startTime = Date()
                let profileResponse = try await self.profileInfoAPI.getProfileInfo(userId: userId, photoLimit: 60)
                let endTime = Date()
                let duration = endTime.timeIntervalSince(startTime)
                
                print("⏱️ ProfileViewModel: Consolidated API call completed in \(String(format: "%.2f", duration)) seconds")
                print("📊 ProfileViewModel: API Response Analysis:")
                print("   - Success: \(profileResponse.success)")
                
                if profileResponse.success {
                    let data = profileResponse.data
                    print("   - User ID: \(data.user.id)")
                    print("   - User Name: \(data.user.name)")
                    print("   - User Email: \(data.user.email)")
                    print("   - User Avatar: \(data.user.avatar ?? "None")")
                    print("   - User Gender: \(data.user.gender ?? "None")")
                    print("   - User Provider: \(data.user.provider ?? "None")")
                    print("   - Journey Info Available: \(data.journey != nil)")
                    print("   - Photos Count: \(data.photos.count)")
                    print("   - Total Photos: \(data.photos.count)")
                    print("   - Has More Photos: false")
                    
                    // Update user basic info
                    print("🔄 ProfileViewModel: Updating user basic info...")
                    self.userBasicInfo = data.user
                    print("   ✅ User basic info updated")
                    print("   - User Name: \(data.user.name)")
                    print("   - User Avatar: \(data.user.avatar ?? "None")")
                    
                    // Update journey info
                    print("🔄 ProfileViewModel: Updating journey info...")
                    // 將 ProfileJourneyInfo 轉換為 JourneyInfo 以保持兼容性
                    let convertedJourneyInfo = JourneyInfo(
                        userId: data.user.id, // 使用 user.id 作為 userId
                        totalScore: data.journey.totalScore,
                        likeCount: data.journey.likeCount,
                        normalCount: data.journey.normalCount,
                        totalRatings: data.journey.totalRatings,
                        overallRank: data.journey.overallRank,
                        genderRank: data.journey.genderRank,
                        totalUsers: data.journey.totalUsers,
                        femaleAttraction: data.journey.femaleAttraction,
                        maleAttraction: data.journey.maleAttraction,
                        recentRatings: data.journey.recentRatings,
                        weeklyTrend: data.journey.weeklyTrend,
                        achievements: data.journey.achievements,
                        nextMilestone: data.journey.nextMilestone,
                        levelProgress: data.journey.levelProgress,
                        weeklyProgress: data.journey.weeklyProgress
                    )
                    self.journeyInfo = convertedJourneyInfo
                    self.recentRatings = data.journey.recentRatings
                    print("   ✅ Journey info updated")
                    print("   - Total Score: \(data.journey.totalScore)")
                    print("   - Like Count: \(data.journey.likeCount)")
                    print("   - Normal Count: \(data.journey.normalCount)")
                    print("   - Total Ratings: \(data.journey.totalRatings)")
                    print("   - Overall Rank: \(data.journey.overallRank)")
                    print("   - Recent Ratings Count: \(data.journey.recentRatings.count)")
                    
                    // Update user photos
                    print("🔄 ProfileViewModel: Updating user photos...")
                    self.userPhotoInfos = data.photos
                    self.userPhotos = data.photos.map { info in
                        Photo(id: info.id, userId: info.userId, imageURL: info.urls)
                    }
                    print("   ✅ User photos updated")
                    print("   - PhotoInfos Count: \(self.userPhotoInfos.count)")
                    print("   - Photos Count: \(self.userPhotos.count)")

                    print("🎉 ProfileViewModel: Successfully loaded profile using consolidated API!")
                    print("📈 ProfileViewModel: Performance Summary:")
                    print("   - API Duration: \(String(format: "%.2f", duration))s")
                    print("   - Data Points: \(data.photos.count) photos, \(data.journey.recentRatings.count) ratings")
                    return
                } else {
                    print("⚠️ ProfileViewModel: Consolidated API returned success=false")
                    print("   - This indicates the API call succeeded but returned an error response")
                }
            } catch {
                print("❌ ProfileViewModel: Consolidated API failed with error")
                print("   🔍 Error Analysis:")
                print("   - Error Type: \(type(of: error))")
                print("   - Error Description: \(error.localizedDescription)")
                
                if let urlError = error as? URLError {
                    print("   - URL Error Code: \(urlError.code.rawValue)")
                    print("   - URL Error Description: \(urlError.localizedDescription)")
                    print("   - Failed URL: \(urlError.failureURLString ?? "Unknown")")
                    
                    switch urlError.code {
                    case .cancelled:
                        print("   - Issue: Request was cancelled (possibly due to multiple calls)")
                        print("🚫 ProfileViewModel: Cancelling profile load due to request cancellation")
                        return
                    case .timedOut:
                        print("   - Issue: Request timed out")
                    case .notConnectedToInternet:
                        print("   - Issue: No internet connection")
                    case .cannotFindHost:
                        print("   - Issue: Cannot find host server")
                    case .cannotConnectToHost:
                        print("   - Issue: Cannot connect to host")
                    default:
                        print("   - Issue: Other network error")
                    }
                } else if let apiError = error as? APIError {
                    print("   - API Error: \(apiError)")
                    print("   - API Error Description: \(apiError.localizedDescription)")
                }
                
                print("🔄 ProfileViewModel: Falling back to separate APIs...")
            }
            
            // Fallback to existing separate API calls
            print("📡 ProfileViewModel: Using fallback APIs...")
            await self.loadUserProfileFallback(userId: userId)
        }
        
        // Reset loading flag and update last load time
        isLoadingProfile = false
        lastLoadTime = Date()
    }
    
    private func loadUserProfileFallback(userId: String) async {
        print("🔄 ProfileViewModel: Starting fallback API calls for userId: \(userId)")
        
        // Load journey info (includes user stats)
        do {
            print("🔄 ProfileViewModel: Loading journey info...")
            let journeyResponse = try await self.rateAPI.getJourneyInfo(userId: userId)
            if journeyResponse.success {
                self.journeyInfo = journeyResponse.data
                self.recentRatings = journeyResponse.data.recentRatings
                print("✅ ProfileViewModel: Journey info loaded successfully")
            } else {
                print("⚠️ ProfileViewModel: Journey info API returned success=false")
            }
        } catch {
            if let urlError = error as? URLError, urlError.code == .cancelled {
                print("⚠️ ProfileViewModel: Journey info request was cancelled, skipping error handling")
                return
            }
            print("❌ ProfileViewModel: Failed to load journey info: \(error)")
            if let urlError = error as? URLError {
                print("   URL Error code: \(urlError.code.rawValue)")
                print("   URL Error description: \(urlError.localizedDescription)")
            }
        }
        
        // Load user's uploaded photos
        do {
            print("🔄 ProfileViewModel: Loading user photos...")
            let photosResponse = try await self.fileAPI.getUserPhotos(userId: userId, page: nil, limit: 60)
            let infos = photosResponse.data
            self.userPhotoInfos = infos
            // Build lightweight Photo models for any other consumers
            self.userPhotos = infos.map { info in
                Photo(id: info.id, userId: info.userId, imageURL: info.urls)
            }
            print("✅ ProfileViewModel: User photos loaded successfully (\(infos.count) photos)")
        } catch {
            if let urlError = error as? URLError, urlError.code == .cancelled {
                print("⚠️ ProfileViewModel: User photo request was cancelled, skipping error handling")
                return
            }
            self.userPhotoInfos = []
            self.userPhotos = []
            print("❌ ProfileViewModel: Failed to load user photos: \(error)")
            if let urlError = error as? URLError {
                print("   URL Error code: \(urlError.code.rawValue)")
                print("   URL Error description: \(urlError.localizedDescription)")
            }
        }
        
        print("✅ ProfileViewModel: Fallback API calls completed")
    }
    
    func refreshData() async {
        guard !currentUserId.isEmpty else { return }
        print("🔄 ProfileViewModel: Force refreshing data for userId: \(currentUserId)")
        isLoadingProfile = false // Reset loading flag to allow refresh
        await loadUserProfile(userId: currentUserId, forceReload: true)
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
    
    var topPercentageText: String {
        guard let info = journeyInfo else { return "N/A" }
        let percentage = (Double(info.totalUsers - info.overallRank) / Double(info.totalUsers)) * 100
        return String(format: "journey.stats.top_percentage".localized, Int(percentage))
    }

    var currentVibeText: String {
        guard let info = journeyInfo else { return "0" }
        return String(format: "%.0f", info.totalScore)
    }
}