import Foundation

// MARK: - Data Models
struct RecommendedUser {
    let id: String
    let name: String
    let rank: Int
    let score: Double
    let avatarURL: String?
}

struct TopUserGallery {
    let userId: String
    let name: String
    let rank: Int
    let avatarURL: String?
    let photoURLs: [String]
}

struct EventPhoto {
    let id: String
    let imageURL: String?
    let likes: Int
    let timestamp: Date
}
