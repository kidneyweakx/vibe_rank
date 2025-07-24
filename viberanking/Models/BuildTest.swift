//
//  BuildTest.swift
//  viberanking
//
//  Created by Kiro on 2025/07/23.
//

import Foundation

// Simple test to verify all models compile correctly
struct BuildTest {
    static func testModels() {
        // Test User model
        let user = User(id: "test", name: "Test User", email: "test@example.com")
        print("User created: \(user.name)")
        
        // Test Photo model
        let photo = Photo(userId: "test", imageURL: "https://example.com/photo.jpg")
        print("Photo created: \(photo.id)")
        
        // Test Rating model
        let rating = Rating(photoId: "test", raterId: "test", isHot: true)
        print("Rating created: \(rating.id)")
        
        // Test StyleReport model
        let ranking = StyleRanking(overallScore: 95.5, percentile: 90.0, categoryRankings: [.elegant: 1, .classic: 2])
        let styleReport = StyleReport(
            userId: "test",
            dominantStyle: .elegant,
            styleBreakdown: [.elegant: 0.8, .classic: 0.2],
            ranking: ranking,
            recommendations: ["Test recommendation"]
        )
        print("StyleReport created: \(styleReport.id)")
        
        print("All models compile successfully!")
    }
}