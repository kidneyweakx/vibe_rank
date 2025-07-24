//
//  ServiceProtocols.swift
//  viberanking
//
//  Created by Kiro on 2025/07/23.
//

import Foundation
import SwiftUI

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
    /// Upload photo from UIImage
    func uploadPhoto(_ image: UIImage, for userId: String) async throws -> Photo
    
    /// Convert image to WebP format
    func convertToWebP(_ imageData: Data, quality: Float) async throws -> Data
    
    /// Generate thumbnails at different sizes
    func generateThumbnails(_ imageData: Data) async throws -> PhotoSizes
    
    /// Get upload progress for a photo
    func getUploadProgress(for photoId: String) async throws -> UploadProgress
    
    /// Get upload status for multiple photos
    func getUploadStatuses(for photoIds: [String]) async throws -> [String: UploadProgress]
    
    /// Cancel upload for a specific photo
    func cancelUpload(for photoId: String) async throws
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

// MARK: - Upload Status
enum UploadStatus {
    case preparing
    case uploading(progress: Double)
    case processing
    case completed
    case failed(Error)
    case cancelled
}

// MARK: - Upload Task
struct UploadTask {
    let id: String
    let photoId: String
    let userId: String
    var status: UploadStatus
    var progress: Double
    let createdAt: Date
    
    init(photoId: String, userId: String) {
        self.id = UUID().uuidString
        self.photoId = photoId
        self.userId = userId
        self.status = .preparing
        self.progress = 0.0
        self.createdAt = Date()
    }
}
