//
//  RatingProgressService.swift
//  viberanking
//
//  Created by Kiro on 2025/07/23.
//

import Foundation
import Combine

// MARK: - Rating Progress Service Protocol
protocol RatingProgressServiceProtocol {
    func updateRatingProgress(userId: String, rating: Rating) async throws -> RatingProgress
    func getRatingProgress(userId: String) async throws -> RatingProgress
    func checkUnlockThreshold(userId: String) async throws -> Bool
    func calculateUserPreferences(userId: String) async throws -> UserPreferences
    func syncLocalRatings(userId: String) async throws
    func getPendingRatingsCount(userId: String) -> Int
    func needsSync(userId: String) -> Bool
    func syncAllPendingRatings() async throws
}

// MARK: - Rating Progress Service Implementation
@MainActor
class RatingProgressService: ObservableObject, RatingProgressServiceProtocol {
    
    // MARK: - Properties
    private let userRepository: UserRepositoryProtocol
    private let ratingRepository: RatingRepositoryProtocol
    @Published var isLoading = false
    @Published var error: AppError?
    
    // Local cache for rating progress
    private var progressCache: [String: RatingProgress] = [:]
    private var ratingsCache: [String: [Rating]] = [:]
    private var preferencesCache: [String: UserPreferences] = [:]
    
    // Local storage for offline support
    private var pendingRatings: [String: [Rating]] = [:]
    private var lastSyncTime: [String: Date] = [:]
    
    // Sync queue for local operations
    private let syncQueue = DispatchQueue(label: "rating.progress.sync", qos: .userInitiated)
    
    // Rating calculation constants
    private let preferencesUpdateInterval = 5 // Update preferences every 5 ratings
    private let cacheExpirationTime: TimeInterval = 300 // 5 minutes
    private let syncRetryAttempts = 3
    
    // MARK: - Initialization
    init(userRepository: UserRepositoryProtocol, ratingRepository: RatingRepositoryProtocol) {
        self.userRepository = userRepository
        self.ratingRepository = ratingRepository
    }
    
    // MARK: - Rating Progress Management
    
    /// Update rating progress when user submits a rating
    func updateRatingProgress(userId: String, rating: Rating) async throws -> RatingProgress {
        isLoading = true
        defer { isLoading = false }
        
        do {
            // Get current progress
            var progress = try await getRatingProgress(userId: userId)
            
            // Update progress
            progress.completedRatings += 1
            
            // Cache the rating locally first for immediate UI update
            await cacheRating(userId: userId, rating: rating)
            
            // Update progress in cache
            progressCache[userId] = progress
            
            // Try to sync with remote repository
            do {
                try await userRepository.updateRatingProgress(userId: userId, progress: progress)
                try await ratingRepository.create(rating)
                
                // Mark as synced
                lastSyncTime[userId] = Date()
                
            } catch {
                // Store for later sync if network fails
                await storePendingRating(userId: userId, rating: rating)
                print("Rating stored locally for later sync: \(error.localizedDescription)")
            }
            
            // Update user preferences if threshold reached
            if progress.completedRatings % preferencesUpdateInterval == 0 {
                _ = try await calculateUserPreferences(userId: userId)
            }
            
            // Check if upload threshold is reached
            if progress.completedRatings == progress.requiredRatings {
                await notifyUploadUnlocked(userId: userId)
            }
            
            return progress
            
        } catch {
            let appError = AppError.networkError(error)
            self.error = appError
            throw appError
        }
    }
    
    /// Get current rating progress for user
    func getRatingProgress(userId: String) async throws -> RatingProgress {
        // Check cache first
        if let cachedProgress = progressCache[userId] {
            return cachedProgress
        }
        
        // Fetch from repository
        if let user = try await userRepository.getUser(by: userId) {
            let progress = user.ratingProgress
            progressCache[userId] = progress
            return progress
        }
        
        // Return default progress if user not found
        let defaultProgress = RatingProgress()
        progressCache[userId] = defaultProgress
        return defaultProgress
    }
    
    /// Check if user has reached the unlock threshold
    func checkUnlockThreshold(userId: String) async throws -> Bool {
        let progress = try await getRatingProgress(userId: userId)
        return progress.hasUnlockedUpload
    }
    
    /// Calculate and update user preferences based on rating history
    func calculateUserPreferences(userId: String) async throws -> UserPreferences {
        isLoading = true
        defer { isLoading = false }
        
        do {
            // Get user's rating history
            let userRatings = try await getUserRatings(userId: userId)
            
            // Calculate preferences
            var preferences = UserPreferences(userId: userId)
            
            // Update basic statistics
            for rating in userRatings {
                preferences.updateWithRating(rating)
            }
            
            // Analyze style preferences based on rated photos
            try await analyzeStylePreferences(for: &preferences, from: userRatings)
            
            // Cache preferences
            preferencesCache[userId] = preferences
            
            // Update in repository
            try await userRepository.updateUserPreferences(preferences)
            
            return preferences
            
        } catch {
            let appError = AppError.networkError(error)
            self.error = appError
            throw appError
        }
    }
    
    /// Sync local ratings with remote storage
    func syncLocalRatings(userId: String) async throws {
        isLoading = true
        defer { isLoading = false }
        
        guard let pendingUserRatings = pendingRatings[userId], !pendingUserRatings.isEmpty else {
            print("No pending ratings to sync for user: \(userId)")
            return
        }
        
        var syncedRatings: [Rating] = []
        var failedRatings: [Rating] = []
        
        for rating in pendingUserRatings {
            var retryCount = 0
            var synced = false
            
            while retryCount < syncRetryAttempts && !synced {
                do {
                    try await ratingRepository.create(rating)
                    syncedRatings.append(rating)
                    synced = true
                    print("Successfully synced rating: \(rating.id)")
                } catch {
                    retryCount += 1
                    if retryCount < syncRetryAttempts {
                        // Wait before retry with exponential backoff
                        let delay = pow(2.0, Double(retryCount)) * 0.5
                        try await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
                    } else {
                        failedRatings.append(rating)
                        print("Failed to sync rating after \(syncRetryAttempts) attempts: \(error.localizedDescription)")
                    }
                }
            }
        }
        
        // Update pending ratings - keep only failed ones
        if failedRatings.isEmpty {
            pendingRatings.removeValue(forKey: userId)
        } else {
            pendingRatings[userId] = failedRatings
        }
        
        // Update sync time if any ratings were synced
        if !syncedRatings.isEmpty {
            lastSyncTime[userId] = Date()
        }
        
        // Update user progress with synced ratings
        if !syncedRatings.isEmpty {
            try await updateProgressAfterSync(userId: userId, syncedRatings: syncedRatings)
        }
    }
}

// MARK: - Private Helper Methods
private extension RatingProgressService {
    
    /// Cache rating locally for offline support
    func cacheRating(userId: String, rating: Rating) async {
        await syncQueue.sync {
            if ratingsCache[userId] == nil {
                ratingsCache[userId] = []
            }
            ratingsCache[userId]?.append(rating)
        }
    }
    
    /// Get user's rating history (from cache or repository)
    func getUserRatings(userId: String) async throws -> [Rating] {
        // Check cache first
        if let cachedRatings = ratingsCache[userId], !cachedRatings.isEmpty {
            return cachedRatings
        }
        
        // Fetch from repository
        let ratings = try await ratingRepository.getRatingsByUser(userId: userId)
        ratingsCache[userId] = ratings
        return ratings
    }
    
    /// Analyze style preferences based on rated photos
    func analyzeStylePreferences(for preferences: inout UserPreferences, from ratings: [Rating]) async throws {
        let hotRatings = ratings.filter { $0.isHot }
        let notRatings = ratings.filter { !$0.isHot }
        
        // Calculate style preferences based on rating patterns
        // This is a simplified implementation - in reality, this would analyze actual photo content
        
        if hotRatings.count > 0 {
            let hotPercentage = Double(hotRatings.count) / Double(ratings.count)
            
            // Advanced style analysis based on rating patterns and timing
            await analyzeRatingPatterns(preferences: &preferences, 
                                      hotPercentage: hotPercentage, 
                                      ratings: ratings)
            
            // Analyze rating consistency
            await analyzeRatingConsistency(preferences: &preferences, ratings: ratings)
            
            // Analyze temporal patterns
            await analyzeTemporalPatterns(preferences: &preferences, ratings: ratings)
        }
    }
    
    /// Analyze rating patterns to determine style preferences
    func analyzeRatingPatterns(preferences: inout UserPreferences, 
                             hotPercentage: Double, 
                             ratings: [Rating]) async {
        if hotPercentage > 0.7 {
            // User likes most photos - more open to different styles
            preferences.updateStylePreference(for: "casual", score: 0.8)
            preferences.updateStylePreference(for: "trendy", score: 0.7)
            preferences.updateStylePreference(for: "elegant", score: 0.6)
        } else if hotPercentage > 0.4 {
            // User is selective - prefers specific styles
            preferences.updateStylePreference(for: "elegant", score: 0.9)
            preferences.updateStylePreference(for: "classic", score: 0.8)
            preferences.updateStylePreference(for: "trendy", score: 0.5)
        } else {
            // User is very selective - has strong preferences
            preferences.updateStylePreference(for: "classic", score: 0.9)
            preferences.updateStylePreference(for: "elegant", score: 0.8)
            preferences.updateStylePreference(for: "artistic", score: 0.7)
        }
    }
    
    /// Analyze rating consistency over time
    func analyzeRatingConsistency(preferences: inout UserPreferences, ratings: [Rating]) async {
        let sortedRatings = ratings.sorted { $0.createdAt < $1.createdAt }
        
        // Calculate consistency score based on rating patterns
        var consistencyScore = 1.0
        
        if sortedRatings.count > 10 {
            let recentRatings = Array(sortedRatings.suffix(10))
            let hotCount = recentRatings.filter { $0.isHot }.count
            let recentHotPercentage = Double(hotCount) / Double(recentRatings.count)
            
            let overallHotPercentage = preferences.hotRatingPercentage
            let difference = abs(recentHotPercentage - overallHotPercentage)
            
            consistencyScore = max(0.0, 1.0 - difference)
            
            // Adjust style preferences based on consistency
            if consistencyScore > 0.8 {
                // Consistent rater - strengthen existing preferences
                for (style, score) in preferences.stylePreferences {
                    preferences.updateStylePreference(for: style, score: min(score * 1.1, 1.0))
                }
            }
        }
    }
    
    /// Analyze temporal rating patterns
    func analyzeTemporalPatterns(preferences: inout UserPreferences, ratings: [Rating]) async {
        let now = Date()
        let oneHourAgo = now.addingTimeInterval(-3600)
        let oneDayAgo = now.addingTimeInterval(-86400)
        
        let recentRatings = ratings.filter { $0.createdAt >= oneHourAgo }
        let todayRatings = ratings.filter { $0.createdAt >= oneDayAgo }
        
        // Active rating behavior suggests preference for trendy styles
        if recentRatings.count > 5 {
            let currentTrendyScore = preferences.stylePreferences["trendy"] ?? 0.0
            preferences.updateStylePreference(for: "trendy", score: min(currentTrendyScore + 0.2, 1.0))
        }
        
        // Consistent daily rating suggests preference for classic styles
        if todayRatings.count > 10 {
            let currentClassicScore = preferences.stylePreferences["classic"] ?? 0.0
            preferences.updateStylePreference(for: "classic", score: min(currentClassicScore + 0.1, 1.0))
        }
    }
    
    /// Store rating for later sync when network is unavailable
    func storePendingRating(userId: String, rating: Rating) async {
        await syncQueue.sync {
            if pendingRatings[userId] == nil {
                pendingRatings[userId] = []
            }
            pendingRatings[userId]?.append(rating)
        }
    }
    
    /// Notify when upload threshold is reached
    func notifyUploadUnlocked(userId: String) async {
        print("🎉 Upload feature unlocked for user: \(userId)")
        // In a real app, this would trigger a notification or UI update
        // Could also trigger analytics event
    }
    
    /// Update progress after successful sync
    func updateProgressAfterSync(userId: String, syncedRatings: [Rating]) async throws {
        // Update cached ratings
        if ratingsCache[userId] == nil {
            ratingsCache[userId] = []
        }
        ratingsCache[userId]?.append(contentsOf: syncedRatings)
        
        // Recalculate preferences if needed
        let totalRatings = ratingsCache[userId]?.count ?? 0
        if totalRatings % preferencesUpdateInterval == 0 {
            _ = try await calculateUserPreferences(userId: userId)
        }
    }
}

// MARK: - Cache Management
extension RatingProgressService {
    
    /// Clear all caches
    func clearCache() {
        progressCache.removeAll()
        ratingsCache.removeAll()
        preferencesCache.removeAll()
        pendingRatings.removeAll()
        lastSyncTime.removeAll()
    }
    
    /// Clear cache for specific user
    func clearUserCache(userId: String) {
        progressCache.removeValue(forKey: userId)
        ratingsCache.removeValue(forKey: userId)
        preferencesCache.removeValue(forKey: userId)
        pendingRatings.removeValue(forKey: userId)
        lastSyncTime.removeValue(forKey: userId)
    }
    
    /// Get cached ratings count for user
    func getCachedRatingsCount(userId: String) -> Int {
        return ratingsCache[userId]?.count ?? 0
    }
    
    /// Get pending ratings count for user
    func getPendingRatingsCount(userId: String) -> Int {
        return pendingRatings[userId]?.count ?? 0
    }
    
    /// Check if user has cached data
    func hasCachedData(userId: String) -> Bool {
        return progressCache[userId] != nil || ratingsCache[userId] != nil
    }
    
    /// Check if cache is expired for user
    func isCacheExpired(userId: String) -> Bool {
        guard let lastSync = lastSyncTime[userId] else { return true }
        return Date().timeIntervalSince(lastSync) > cacheExpirationTime
    }
    
    /// Get cache statistics for debugging
    func getCacheStatistics() -> [String: Any] {
        return [
            "progressCacheCount": progressCache.count,
            "ratingsCacheCount": ratingsCache.count,
            "preferencesCacheCount": preferencesCache.count,
            "pendingRatingsCount": pendingRatings.values.reduce(0) { $0 + $1.count },
            "totalCachedRatings": ratingsCache.values.reduce(0) { $0 + $1.count }
        ]
    }
    
    /// Force sync all pending ratings for all users
    func syncAllPendingRatings() async throws {
        for userId in pendingRatings.keys {
            try await syncLocalRatings(userId: userId)
        }
    }
    
    /// Check if user needs sync
    func needsSync(userId: String) -> Bool {
        return getPendingRatingsCount(userId: userId) > 0 || isCacheExpired(userId: userId)
    }
}