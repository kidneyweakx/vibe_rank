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
        let ranking = StyleRanking(overallAttractiveness: 95.5, totalVotes: 100, femaleAttractiveness: 90.0, maleAttractiveness: 80.0)
        let styleReport = StyleReport(
            id: "test",
            userId: "test",
            dominantStyle: .elegant,
            styleBreakdown: [StyleType.elegant.rawValue: 0.8, StyleType.classic.rawValue: 0.2],
            ranking: ranking,
            recommendations: ["Test recommendation"],
            generatedAt: Date()
        )
        print("StyleReport created: \(styleReport.id)")
        
        print("All models compile successfully!")
    }
}
