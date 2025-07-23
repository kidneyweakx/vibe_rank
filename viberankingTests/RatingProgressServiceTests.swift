//
//  RatingProgressServiceTests.swift
//  viberankingTests
//
//  Created by Kiro on 2025/07/23.
//

import XCTest
@testable import viberanking

@MainActor
class RatingProgressServiceTests: XCTestCase {
    
    var ratingProgressService: RatingProgressService!
    var mockUserRepository: MockUserRepository!
    var mockRatingRepository: MockRatingRepository!
    
    override func setUp() {
        super.setUp()
        mockUserRepository = MockUserRepository()
        mockRatingRepository = MockRatingRepository()
        ratingProgressService = RatingProgressService(
            userRepository: mockUserRepository,
            ratingRepository: mockRatingRepository
        )
    }
    
    override func tearDown() {
        ratingProgressService = nil
        mockUserRepository = nil
        mockRatingRepository = nil
        super.tearDown()
    }
    
    // MARK: - Rating Progress Tests
    
    func testUpdateRatingProgress() async throws {
        // Given
        let userId = "test-user-1"
        let rating = Rating(photoId: "photo-1", raterId: userId, isHot: true)
        
        // When
        let progress = try await ratingProgressService.updateRatingProgress(userId: userId, rating: rating)
        
        // Then
        XCTAssertEqual(progress.completedRatings, 1)
        XCTAssertFalse(progress.hasUnlockedUpload) // Should need 20 ratings
        XCTAssertEqual(ratingProgressService.getCachedRatingsCount(userId: userId), 1)
    }
    
    func testUnlockThresholdReached() async throws {
        // Given
        let userId = "test-user-2"
        
        // When - Submit 20 ratings to reach threshold
        for i in 1...20 {
            let rating = Rating(photoId: "photo-\(i)", raterId: userId, isHot: i % 2 == 0)
            _ = try await ratingProgressService.updateRatingProgress(userId: userId, rating: rating)
        }
        
        let progress = try await ratingProgressService.getRatingProgress(userId: userId)
        let isUnlocked = try await ratingProgressService.checkUnlockThreshold(userId: userId)
        
        // Then
        XCTAssertEqual(progress.completedRatings, 20)
        XCTAssertTrue(progress.hasUnlockedUpload)
        XCTAssertTrue(isUnlocked)
        XCTAssertEqual(progress.remainingRatings, 0)
    }
    
    func testUserPreferencesCalculation() async throws {
        // Given
        let userId = "test-user-3"
        
        // When - Submit ratings with specific pattern (70% hot)
        for i in 1...10 {
            let isHot = i <= 7 // First 7 are hot, last 3 are not
            let rating = Rating(photoId: "photo-\(i)", raterId: userId, isHot: isHot)
            _ = try await ratingProgressService.updateRatingProgress(userId: userId, rating: rating)
        }
        
        let preferences = try await ratingProgressService.calculateUserPreferences(userId: userId)
        
        // Then
        XCTAssertEqual(preferences.totalRatingsGiven, 10)
        XCTAssertEqual(preferences.hotRatingsGiven, 7)
        XCTAssertEqual(preferences.hotRatingPercentage, 0.7, accuracy: 0.01)
        XCTAssertFalse(preferences.stylePreferences.isEmpty)
    }
    
    // MARK: - Caching Tests
    
    func testLocalCaching() async throws {
        // Given
        let userId = "test-user-4"
        let rating = Rating(photoId: "photo-1", raterId: userId, isHot: true)
        
        // When
        _ = try await ratingProgressService.updateRatingProgress(userId: userId, rating: rating)
        
        // Then
        XCTAssertTrue(ratingProgressService.hasCachedData(userId: userId))
        XCTAssertEqual(ratingProgressService.getCachedRatingsCount(userId: userId), 1)
    }
    
    func testCacheClearance() async throws {
        // Given
        let userId = "test-user-5"
        let rating = Rating(photoId: "photo-1", raterId: userId, isHot: true)
        _ = try await ratingProgressService.updateRatingProgress(userId: userId, rating: rating)
        
        // When
        ratingProgressService.clearUserCache(userId: userId)
        
        // Then
        XCTAssertFalse(ratingProgressService.hasCachedData(userId: userId))
        XCTAssertEqual(ratingProgressService.getCachedRatingsCount(userId: userId), 0)
    }
    
    // MARK: - Sync Tests
    
    func testPendingRatingsSync() async throws {
        // Given
        let userId = "test-user-6"
        mockRatingRepository.shouldFailCreate = true // Simulate network failure
        
        let rating = Rating(photoId: "photo-1", raterId: userId, isHot: true)
        
        // When - This should fail and store rating as pending
        _ = try await ratingProgressService.updateRatingProgress(userId: userId, rating: rating)
        
        // Then
        XCTAssertEqual(ratingProgressService.getPendingRatingsCount(userId: userId), 1)
        XCTAssertTrue(ratingProgressService.needsSync(userId: userId))
        
        // When - Enable network and sync
        mockRatingRepository.shouldFailCreate = false
        try await ratingProgressService.syncLocalRatings(userId: userId)
        
        // Then
        XCTAssertEqual(ratingProgressService.getPendingRatingsCount(userId: userId), 0)
        XCTAssertFalse(ratingProgressService.needsSync(userId: userId))
    }
    
    func testSyncAllPendingRatings() async throws {
        // Given
        let userIds = ["user-1", "user-2", "user-3"]
        mockRatingRepository.shouldFailCreate = true
        
        // Create pending ratings for multiple users
        for userId in userIds {
            let rating = Rating(photoId: "photo-1", raterId: userId, isHot: true)
            _ = try await ratingProgressService.updateRatingProgress(userId: userId, rating: rating)
        }
        
        // When
        mockRatingRepository.shouldFailCreate = false
        try await ratingProgressService.syncAllPendingRatings()
        
        // Then
        for userId in userIds {
            XCTAssertEqual(ratingProgressService.getPendingRatingsCount(userId: userId), 0)
        }
    }
    
    // MARK: - Style Analysis Tests
    
    func testStylePreferencesAnalysis() async throws {
        // Given
        let userId = "test-user-7"
        
        // When - Submit ratings with high selectivity (low hot percentage)
        for i in 1...10 {
            let isHot = i <= 3 // Only 30% hot ratings
            let rating = Rating(photoId: "photo-\(i)", raterId: userId, isHot: isHot)
            _ = try await ratingProgressService.updateRatingProgress(userId: userId, rating: rating)
        }
        
        let preferences = try await ratingProgressService.calculateUserPreferences(userId: userId)
        
        // Then - Should prefer classic and elegant styles for selective users
        XCTAssertEqual(preferences.hotRatingPercentage, 0.3, accuracy: 0.01)
        XCTAssertTrue(preferences.stylePreferences["classic"] ?? 0.0 > 0.5)
        XCTAssertTrue(preferences.stylePreferences["elegant"] ?? 0.0 > 0.5)
    }
    
    func testProgressPercentageCalculation() async throws {
        // Given
        let userId = "test-user-8"
        
        // When - Submit 10 ratings (50% of required 20)
        for i in 1...10 {
            let rating = Rating(photoId: "photo-\(i)", raterId: userId, isHot: true)
            _ = try await ratingProgressService.updateRatingProgress(userId: userId, rating: rating)
        }
        
        let progress = try await ratingProgressService.getRatingProgress(userId: userId)
        
        // Then
        XCTAssertEqual(progress.progressPercentage, 0.5, accuracy: 0.01)
        XCTAssertEqual(progress.remainingRatings, 10)
    }
    
    // MARK: - Cache Statistics Tests
    
    func testCacheStatistics() async throws {
        // Given
        let userId = "test-user-9"
        let rating = Rating(photoId: "photo-1", raterId: userId, isHot: true)
        
        // When
        _ = try await ratingProgressService.updateRatingProgress(userId: userId, rating: rating)
        let stats = ratingProgressService.getCacheStatistics()
        
        // Then
        XCTAssertEqual(stats["progressCacheCount"] as? Int, 1)
        XCTAssertEqual(stats["totalCachedRatings"] as? Int, 1)
        XCTAssertGreaterThanOrEqual(stats["ratingsCacheCount"] as? Int ?? 0, 1)
    }
}

// MARK: - Mock Repositories

class MockUserRepository: UserRepositoryProtocol {
    private var users: [String: User] = [:]
    private var preferences: [String: UserPreferences] = [:]
    
    func create(_ entity: User) async throws -> User {
        users[entity.id] = entity
        return entity
    }
    
    func read(id: String) async throws -> User? {
        return users[id]
    }
    
    func update(_ entity: User) async throws -> User {
        users[entity.id] = entity
        return entity
    }
    
    func delete(id: String) async throws {
        users.removeValue(forKey: id)
    }
    
    func list(limit: Int?, offset: Int?) async throws -> [User] {
        return Array(users.values)
    }
    
    func getUser(by id: String) async throws -> User? {
        if users[id] == nil {
            // Create a default user for testing
            let user = User(id: id, name: "Test User", email: "test@example.com")
            users[id] = user
        }
        return users[id]
    }
    
    func findByEmail(_ email: String) async throws -> User? {
        return users.values.first { $0.email == email }
    }
    
    func updateRatingProgress(userId: String, progress: RatingProgress) async throws {
        if var user = users[userId] {
            user.ratingProgress = progress
            users[userId] = user
        }
    }
    
    func getUserPreferences(userId: String) async throws -> UserPreferences? {
        return preferences[userId]
    }
    
    func updateUserPreferences(_ preferences: UserPreferences) async throws {
        self.preferences[preferences.userId] = preferences
    }
}

class MockRatingRepository: RatingRepositoryProtocol {
    private var ratings: [String: Rating] = [:]
    var shouldFailCreate = false
    
    func create(_ entity: Rating) async throws -> Rating {
        if shouldFailCreate {
            throw AppError.networkError(NSError(domain: "MockError", code: 1, userInfo: [NSLocalizedDescriptionKey: "Mock network error"]))
        }
        ratings[entity.id] = entity
        return entity
    }
    
    func read(id: String) async throws -> Rating? {
        return ratings[id]
    }
    
    func update(_ entity: Rating) async throws -> Rating {
        ratings[entity.id] = entity
        return entity
    }
    
    func delete(id: String) async throws {
        ratings.removeValue(forKey: id)
    }
    
    func list(limit: Int?, offset: Int?) async throws -> [Rating] {
        return Array(ratings.values)
    }
    
    func getRatingsByPhoto(photoId: String) async throws -> [Rating] {
        return ratings.values.filter { $0.photoId == photoId }
    }
    
    func getRatingsByUser(userId: String) async throws -> [Rating] {
        return ratings.values.filter { $0.raterId == userId }
    }
    
    func hasUserRatedPhoto(userId: String, photoId: String) async throws -> Bool {
        return ratings.values.contains { $0.raterId == userId && $0.photoId == photoId }
    }
}