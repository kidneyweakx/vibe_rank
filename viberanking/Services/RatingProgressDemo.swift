//
//  RatingProgressDemo.swift
//  viberanking
//
//  Created by Kiro on 2025/07/23.
//

import Foundation

// MARK: - Rating Progress Demo
/// This file demonstrates how to use the RatingProgressService
/// for implementing rating logic and progress tracking
class RatingProgressDemo {
    
    private let ratingProgressService: RatingProgressServiceProtocol
    private let userId = "demo-user"
    
    init(ratingProgressService: RatingProgressServiceProtocol) {
        self.ratingProgressService = ratingProgressService
    }
    
    /// Demo: Complete rating flow from 0 to 20 ratings
    func demonstrateCompleteRatingFlow() async throws {
        print("🎯 Starting Rating Progress Demo")
        print("================================")
        
        // 1. Check initial progress
        let initialProgress = try await ratingProgressService.getRatingProgress(userId: userId)
        print("📊 Initial Progress: \(initialProgress.completedRatings)/\(initialProgress.requiredRatings)")
        print("🔒 Upload Unlocked: \(initialProgress.hasUnlockedUpload)")
        
        // 2. Simulate rating 20 photos to unlock upload
        print("\n📱 Starting to rate photos...")
        
        for i in 1...20 {
            let rating = Rating(
                photoId: "demo-photo-\(i)",
                raterId: userId,
                isHot: i % 3 != 0 // 2/3 are hot, 1/3 are not
            )
            
            let progress = try await ratingProgressService.updateRatingProgress(
                userId: userId,
                rating: rating
            )
            
            print("⭐ Rated photo \(i): \(rating.isHot ? "Hot" : "Not") - Progress: \(progress.completedRatings)/\(progress.requiredRatings)")
            
            // Show milestone messages
            if progress.completedRatings == 5 {
                print("🎉 Milestone: 5 ratings completed! User preferences updated.")
            } else if progress.completedRatings == 10 {
                print("🎉 Milestone: 10 ratings completed! Halfway there!")
            } else if progress.completedRatings == 15 {
                print("🎉 Milestone: 15 ratings completed! Almost unlocked!")
            } else if progress.hasUnlockedUpload {
                print("🔓 UPLOAD UNLOCKED! User can now upload photos!")
            }
        }
        
        // 3. Check final progress
        let finalProgress = try await ratingProgressService.getRatingProgress(userId: userId)
        print("\n📊 Final Progress: \(finalProgress.completedRatings)/\(finalProgress.requiredRatings)")
        print("🔓 Upload Unlocked: \(finalProgress.hasUnlockedUpload)")
        print("📈 Progress Percentage: \(Int(finalProgress.progressPercentage * 100))%")
        
        // 4. Show user preferences
        let preferences = try await ratingProgressService.calculateUserPreferences(userId: userId)
        print("\n👤 User Preferences:")
        print("   Total Ratings: \(preferences.totalRatingsGiven)")
        print("   Hot Ratings: \(preferences.hotRatingsGiven)")
        print("   Hot Percentage: \(Int(preferences.hotRatingPercentage * 100))%")
        print("   Style Preferences:")
        for (style, score) in preferences.stylePreferences {
            print("     \(style): \(Int(score * 100))%")
        }
        
        print("\n✅ Demo completed successfully!")
    }
    
    /// Demo: Offline rating and sync functionality
    func demonstrateOfflineSync() async throws {
        print("\n🌐 Demonstrating Offline Sync")
        print("=============================")
        
        // Simulate network failure scenario
        print("📱 Simulating offline ratings...")
        
        // Create some ratings that will be cached locally
        for i in 1...3 {
            let rating = Rating(
                photoId: "offline-photo-\(i)",
                raterId: userId,
                isHot: i % 2 == 0
            )
            
            // This will cache locally if network fails
            _ = try await ratingProgressService.updateRatingProgress(
                userId: userId,
                rating: rating
            )
        }
        
        // Check pending ratings
        let pendingCount = ratingProgressService.getPendingRatingsCount(userId: userId)
        print("📦 Pending ratings to sync: \(pendingCount)")
        
        if ratingProgressService.needsSync(userId: userId) {
            print("🔄 Syncing pending ratings...")
            try await ratingProgressService.syncLocalRatings(userId: userId)
            
            let remainingPending = ratingProgressService.getPendingRatingsCount(userId: userId)
            print("✅ Sync completed. Remaining pending: \(remainingPending)")
        }
    }
    
    /// Demo: Cache management
    func demonstrateCacheManagement() async throws {
        print("\n💾 Demonstrating Cache Management")
        print("=================================")
        
        // Add some data to cache
        let rating = Rating(photoId: "cache-photo", raterId: userId, isHot: true)
        _ = try await ratingProgressService.updateRatingProgress(userId: userId, rating: rating)
        
        // Show cache statistics
        if let service = ratingProgressService as? RatingProgressService {
            let stats = await service.getCacheStatistics()
            print("📊 Cache Statistics:")
            for (key, value) in stats {
                print("   \(key): \(value)")
            }
            
            // Demonstrate cache clearing
            print("\n🧹 Clearing user cache...")
            await service.clearUserCache(userId: userId)
            
            let newStats = await service.getCacheStatistics()
            print("📊 Cache Statistics after clearing:")
            for (key, value) in newStats {
                print("   \(key): \(value)")
            }
        }
    }
}

// MARK: - Usage Example
extension RatingProgressDemo {
    
    /// Run all demos
    static func runAllDemos() async {
        do {
            let userRepository = UserRepository()
            let ratingRepository = RatingRepository()
            let ratingProgressService = await RatingProgressService(
                userRepository: userRepository,
                ratingRepository: ratingRepository
            )
//            try {
//                let demo = RatingProgressDemo(ratingProgressService: ratingProgressService)
//                
//                await demo.demonstrateCompleteRatingFlow()
//                await demo.demonstrateOfflineSync()
//                await demo.demonstrateCacheManagement()
//            } ()
        } catch {

            print("Error running demos: \(error)")
        }
    }
}
