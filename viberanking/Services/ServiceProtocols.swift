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
    func getPendingUserData() -> InitialUserData?
    func completeProfileSetup(_ profileData: UserProfileData) async throws -> User
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
    func getUploadProgress(for photoId: String) -> UploadProgress
    
    /// Get upload status for multiple photos
    func getUploadStatuses(for photoIds: [String]) -> [String: UploadProgress]
    
    /// Cancel upload for a specific photo
    func cancelUpload(for photoId: String) async throws
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

