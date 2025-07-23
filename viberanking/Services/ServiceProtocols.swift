//
//  ServiceProtocols.swift
//  viberanking
//
//  Created by Kiro on 2025/07/23.
//

import Foundation

// MARK: - Authentication Service Protocol
protocol AuthenticationServiceProtocol {
    func signInWithGoogle() async throws -> User
    func signInWithApple() async throws -> User
    func signOut() async throws
    var currentUser: User? { get }
    var isAuthenticated: Bool { get }
}

// MARK: - Photo Rating Service Protocol
protocol PhotoRatingServiceProtocol {
    func fetchPhotosForRating(excludingUser userId: String) async throws -> [Photo]
    func submitRating(_ rating: Rating) async throws
    func updateUserPreferences(from ratings: [Rating]) async throws
}

// MARK: - Photo Upload Service Protocol
protocol PhotoUploadServiceProtocol {
    func uploadPhoto(_ imageData: Data, for userId: String) async throws -> Photo
    func convertToWebP(_ imageData: Data, quality: Float) async throws -> Data
    func generateThumbnails(_ imageData: Data) async throws -> PhotoSizes
    func extractEXIFData(_ imageData: Data) async throws -> PhotoMetadata
    func validatePhotoFreshness(_ metadata: PhotoMetadata) async throws -> Bool
    func getUploadProgress(for photoId: String) async throws -> UploadProgress
}

// MARK: - Style Analysis Service Protocol
protocol StyleAnalysisServiceProtocol {
    func generateStyleReport(for userId: String) async throws -> StyleReport
    func getUserPreferences(for userId: String) async throws -> UserPreferences
}

// MARK: - Gamification Service Protocol
protocol GamificationServiceProtocol {
    func updateUserProgress(_ progress: UserProgress) async throws
    func checkAchievements(for userId: String) async throws -> [Achievement]
    func getIncentiveStatus(for userId: String) async throws -> IncentiveStatus
}

// MARK: - Supporting Models for Gamification
struct UserProgress: Codable {
    let userId: String
    var totalRatingsGiven: Int
    var totalPhotosUploaded: Int
    var reportsGenerated: Int
    var lastActivityDate: Date
    
    init(userId: String) {
        self.userId = userId
        self.totalRatingsGiven = 0
        self.totalPhotosUploaded = 0
        self.reportsGenerated = 0
        self.lastActivityDate = Date()
    }
}

struct Achievement: Codable, Identifiable {
    let id: String
    let title: String
    let description: String
    let iconName: String
    let unlockedAt: Date?
    let isUnlocked: Bool
    
    init(id: String, title: String, description: String, iconName: String) {
        self.id = id
        self.title = title
        self.description = description
        self.iconName = iconName
        self.unlockedAt = nil
        self.isUnlocked = false
    }
}

struct IncentiveStatus: Codable {
    var acceleratedRatingsAvailable: Int
    var nextAcceleratedRatingAt: Int // ratings needed
    var evolutionAnalysisUnlocked: Bool
    var shareRewardsUnlocked: Bool
    
    init() {
        self.acceleratedRatingsAvailable = 0
        self.nextAcceleratedRatingAt = 10
        self.evolutionAnalysisUnlocked = false
        self.shareRewardsUnlocked = false
    }
}
