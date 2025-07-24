//
//  Photo.swift
//  viberanking
//
//  Created by Kiro on 2025/07/23.
//

import Foundation

// MARK: - Photo Model
struct Photo: Codable, Identifiable {
    let id: String
    let userId: String
    let imageURL: String
    let uploadedAt: Date
    var ratings: [Rating]
    var averageScore: Double
    var totalRatings: Int
    
    init(id: String = UUID().uuidString,
         userId: String,
         imageURL: String) {
        self.id = id
        self.userId = userId
        self.imageURL = imageURL
        self.uploadedAt = Date()
        self.ratings = []
        self.averageScore = 0.0
        self.totalRatings = 0
    }
    
    mutating func addRating(_ rating: Rating) {
        ratings.append(rating)
        updateAverageScore()
    }
    
    private mutating func updateAverageScore() {
        totalRatings = ratings.count
        guard totalRatings > 0 else {
            averageScore = 0.0
            return
        }
        
        let hotRatings = ratings.filter { $0.isHot }.count
        averageScore = Double(hotRatings) / Double(totalRatings)
    }
}

// MARK: - Photo Sizes for WebP Storage
struct PhotoSizes: Codable {
    let thumbnail: Data    // 150x150 WebP, high compression
    let preview: Data      // 800x800 WebP, medium quality
    let highRes: Data      // 1200x1200 WebP, high quality
}

// MARK: - Upload Progress
struct UploadProgress: Codable {
    let photoId: String
    var currentRatings: Int
    let requiredRatings: Int
    
    init(photoId: String, currentRatings: Int = 0, requiredRatings: Int = 50) {
        self.photoId = photoId
        self.currentRatings = currentRatings
        self.requiredRatings = requiredRatings
    }
    
    var isReportUnlocked: Bool {
        return currentRatings >= requiredRatings
    }
    
    var progressPercentage: Double {
        return min(Double(currentRatings) / Double(requiredRatings), 1.0)
    }
    
    var remainingRatings: Int {
        return max(requiredRatings - currentRatings, 0)
    }
}