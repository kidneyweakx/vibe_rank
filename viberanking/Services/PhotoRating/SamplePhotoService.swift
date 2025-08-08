//
//  SamplePhotoService.swift
//  viberanking
//
//  Created by Kiro on 2025/07/23.
//

import Foundation
import UIKit

// MARK: - Sample Photo Service Protocol
protocol SamplePhotoServiceProtocol {
    func getSamplePhotos() async throws -> [Photo]
    func generateSamplePhoto(id: String, imageUrl: String) -> Photo
}

// MARK: - Sample Photo Service Implementation
@MainActor
class SamplePhotoService: ObservableObject, SamplePhotoServiceProtocol {
    
    // MARK: - Properties
    @Published var isLoading = false
    @Published var error: AppError?
    
    // Sample photo URLs (you can replace these with actual sample images)
    private let sampleImageUrls = [
        "https://images.unsplash.com/photo-1494790108755-2616c6d4e6e8?w=400&h=600&fit=crop&crop=face",
        "https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=400&h=600&fit=crop&crop=face",
        "https://images.unsplash.com/photo-1517841905240-472988babdf9?w=400&h=600&fit=crop&crop=face",
        "https://images.unsplash.com/photo-1539571696357-5a69c17a67c6?w=400&h=600&fit=crop&crop=face",
        "https://images.unsplash.com/photo-1524504388940-b1c1722653e1?w=400&h=600&fit=crop&crop=face",
        "https://images.unsplash.com/photo-1488426862026-3ee34a7d66df?w=400&h=600&fit=crop&crop=face",
        "https://images.unsplash.com/photo-1506794778202-cad84cf45f1d?w=400&h=600&fit=crop&crop=face",
        "https://images.unsplash.com/photo-1472099645785-5658abf4ff4e?w=400&h=600&fit=crop&crop=face",
        "https://images.unsplash.com/photo-1531746020798-e6953c6e8e04?w=400&h=600&fit=crop&crop=face",
        "https://images.unsplash.com/photo-1500648767791-00dcc994a43e?w=400&h=600&fit=crop&crop=face"
    ]
    
    // MARK: - SamplePhotoServiceProtocol Implementation
    
    /// Get sample photos for rating when no real photos are available
    func getSamplePhotos() async throws -> [Photo] {
        isLoading = true
        defer { isLoading = false }
        
        var samplePhotos: [Photo] = []

        for (index, imageUrl) in sampleImageUrls.enumerated() {
            let photo = generateSamplePhoto(
                id: "sample_\(index)",
                imageUrl: imageUrl,
            )
            samplePhotos.append(photo)
        }
        
        return samplePhotos
    }
    
    /// Generate a sample photo with specified parameters
    func generateSamplePhoto(id: String, imageUrl: String) -> Photo {
        let url = URL(string: imageUrl)!
        let photoURLs = PhotoURLs(thumbnail: url, preview: url, highRes: url)
        
        var photo = Photo(
            id: id,
            userId: "sample_user",
            imageURL: photoURLs
        )
        
        // Add some sample ratings to make it more realistic
        let numberOfRatings = Int.random(in: 5...30)
        for i in 0..<numberOfRatings {
            let isHot = Double.random(in: 0...1) > 0.4 // 60% chance of being "hot"
            let rating = Rating(
                id: "sample_rating_\(id)_\(i)",
                photoId: id,
                raterId: "sample_rater_\(i)",
                isHot: isHot
            )
            photo.addRating(rating)
        }
        
        return photo
    }
}

// MARK: - Photo Model Extension
extension Photo {
    /// Check if this is a sample photo
    var isSample: Bool {
        return id.hasPrefix("sample_")
    }
}
