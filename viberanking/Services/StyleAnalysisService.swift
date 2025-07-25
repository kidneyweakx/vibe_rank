import Foundation

// MARK: - Style Analysis Service Implementation
@MainActor
class StyleAnalysisService: StyleAnalysisServiceProtocol {
    
    // MARK: - Dependencies
    private let userRepository = UserRepository()
    private let photoRepository = PhotoRepository()
    private let ratingRepository = RatingRepository()
    private let styleReportRepository = StyleReportRepository()
    
    // MARK: - Style Analysis Configuration
    private struct AnalysisConfig {
        static let minimumRatingsForAnalysis = 50
        static let styleConfidenceThreshold = 0.15
        static let dominantStyleThreshold = 0.25
        static let recommendationCount = 5
    }
    
    // MARK: - Public Methods
    
    /// Generate comprehensive style report for user
    func generateStyleReport(for userId: String) async throws -> StyleReport {
        print("🎨 Generating style report for user: \(userId)")
        
        // 1. Validate user has sufficient data
        guard let user = try await userRepository.getUser(by: userId) else {
            throw StyleAnalysisError.userNotFound
        }
        
        let userPhotos = try await photoRepository.getPhotosByUser(userId: userId)
        guard !userPhotos.isEmpty else {
            throw StyleAnalysisError.noPhotosUploaded
        }
        
        // 2. Collect all ratings for user's photos
        let allRatings = try await collectUserPhotoRatings(for: userPhotos)
        guard allRatings.count >= AnalysisConfig.minimumRatingsForAnalysis else {
            throw StyleAnalysisError.insufficientRatings(current: allRatings.count, required: AnalysisConfig.minimumRatingsForAnalysis)
        }
        
        // 3. Analyze user preferences from their rating behavior
        let userPreferences = try await getUserPreferences(for: userId)
        
        // 4. Perform style analysis
        let styleBreakdown = try await analyzeUserStyle(ratings: allRatings, preferences: userPreferences)
        let dominantStyle = determineDominantStyle(from: styleBreakdown)
        
        // 5. Calculate ranking metrics
        let ranking = try await calculateStyleRanking(for: userId, photos: userPhotos, ratings: allRatings)
        
        // 6. Generate personalized recommendations
        let recommendations = generateRecommendations(
            dominantStyle: dominantStyle,
            styleBreakdown: styleBreakdown,
            ranking: ranking,
            preferences: userPreferences
        )
        
        // 7. Create and save style report
        let report = StyleReport(
            id: styleReportRepository.generateReportId(userId: userId),
            userId: userId,
            dominantStyle: dominantStyle,
            styleBreakdown: styleBreakdown.reduce(into: [:]) { $0[$1.key.rawValue] = $1.value },
            ranking: ranking,
            recommendations: recommendations,
            generatedAt: Date()
        )
        
        let savedReport = try await styleReportRepository.create(report)
        
        print("✅ Style report generated successfully for user: \(userId)")
        return savedReport
    }
    
    /// Get user preferences based on their rating behavior
    func getUserPreferences(for userId: String) async throws -> UserPreferences {
        print("📊 Analyzing user preferences for: \(userId)")
        
        // Get all ratings given by the user
        let userRatings = try await ratingRepository.getRatingsByUser(userId: userId)
        
        var preferences = UserPreferences(userId: userId)
        
        // Update basic rating statistics
        preferences.totalRatingsGiven = userRatings.count
        preferences.hotRatingsGiven = userRatings.filter { $0.isHot }.count
        
        // Analyze style preferences based on what they rated as "Hot"
        let hotRatedPhotos = try await getPhotosFromRatings(userRatings.filter { $0.isHot })
        let stylePreferences = analyzeStylePreferences(from: hotRatedPhotos)
        
        // Update style preferences
        for (style, score) in stylePreferences {
            preferences.updateStylePreference(for: style.rawValue, score: score)
        }
        
        print("✅ User preferences analyzed: \(preferences.stylePreferences.count) style preferences")
        return preferences
    }
    
    // MARK: - Private Analysis Methods
    
    /// Collect all ratings for user's uploaded photos
    private func collectUserPhotoRatings(for photos: [Photo]) async throws -> [Rating] {
        var allRatings: [Rating] = []
        
        for photo in photos {
            let photoRatings = try await ratingRepository.getRatingsByPhoto(photoId: photo.id)
            allRatings.append(contentsOf: photoRatings)
        }
        
        return allRatings
    }
    
    /// Analyze user's style based on ratings received
    private func analyzeUserStyle(ratings: [Rating], preferences: UserPreferences) async throws -> [StyleType: Double] {
        var styleScores: [StyleType: Double] = [:]
        
        // Initialize all style types with base scores
        for styleType in StyleType.allCases {
            styleScores[styleType] = 0.0
        }
        
        // Get photos that received ratings
        let ratedPhotos = try await getPhotosFromRatings(ratings)
        
        // Analyze each photo's style contribution
        for photo in ratedPhotos {
            let photoRatings = ratings.filter { $0.photoId == photo.id }
            let hotRatings = photoRatings.filter { $0.isHot }.count
            let totalRatings = photoRatings.count
            
            guard totalRatings > 0 else { continue }
            
            let attractivenessScore = Double(hotRatings) / Double(totalRatings)
            
            // Analyze photo style characteristics (simplified algorithm)
            let photoStyleScores = analyzePhotoStyle(photo: photo, attractivenessScore: attractivenessScore)
            
            // Accumulate style scores
            for (style, score) in photoStyleScores {
                styleScores[style, default: 0.0] += score
            }
        }
        
        // Normalize scores to percentages
        let totalScore = styleScores.values.reduce(0, +)
        if totalScore > 0 {
            for style in StyleType.allCases {
                styleScores[style] = (styleScores[style] ?? 0.0) / totalScore * 100.0
            }
        }
        
        return styleScores
    }
    
    /// Analyze individual photo style characteristics
    private func analyzePhotoStyle(photo: Photo, attractivenessScore: Double) -> [StyleType: Double] {
        var styleScores: [StyleType: Double] = [:]
        
        // This is a simplified style analysis algorithm
        // In a real implementation, this would use ML models or more sophisticated analysis
        
        // Base style assignment based on photo characteristics
        // For now, we'll use a simplified heuristic approach
        
        let photoId = photo.id
        let hashValue = abs(photoId.hashValue)
        
        // Distribute styles based on photo characteristics (simplified)
        let primaryStyleIndex = hashValue % StyleType.allCases.count
        let secondaryStyleIndex = (hashValue / 2) % StyleType.allCases.count
        
        let primaryStyle = StyleType.allCases[primaryStyleIndex]
        let secondaryStyle = StyleType.allCases[secondaryStyleIndex]
        
        // Weight styles based on attractiveness score
        let primaryWeight = attractivenessScore * 0.7
        let secondaryWeight = attractivenessScore * 0.3
        
        styleScores[primaryStyle] = primaryWeight
        if primaryStyle != secondaryStyle {
            styleScores[secondaryStyle] = secondaryWeight
        }
        
        return styleScores
    }
    
    /// Determine dominant style from style breakdown
    private func determineDominantStyle(from styleBreakdown: [StyleType: Double]) -> StyleType {
        let sortedStyles = styleBreakdown.sorted { $0.value > $1.value }
        
        guard let topStyle = sortedStyles.first else {
            return .casual // Default fallback
        }
        
        // Ensure the dominant style has sufficient confidence
        if topStyle.value >= AnalysisConfig.dominantStyleThreshold * 100 {
            return topStyle.key
        }
        
        return .casual // Default if no clear dominant style
    }
    
    /// Calculate style ranking metrics
    private func calculateStyleRanking(for userId: String, photos: [Photo], ratings: [Rating]) async throws -> StyleRanking {
        let totalVotes = ratings.count
        let hotVotes = ratings.filter { $0.isHot }.count
        
        let overallAttractiveness = totalVotes > 0 ? Double(hotVotes) / Double(totalVotes) * 100 : 0.0
        
        // Calculate gender-specific attractiveness
        let (femaleAttractiveness, maleAttractiveness) = try await calculateGenderSpecificRatings(ratings: ratings)
        
        return StyleRanking(
            overallAttractiveness: overallAttractiveness,
            totalVotes: totalVotes,
            femaleAttractiveness: femaleAttractiveness,
            maleAttractiveness: maleAttractiveness
        )
    }
    
    /// Calculate gender-specific rating breakdown
    private func calculateGenderSpecificRatings(ratings: [Rating]) async throws -> (female: Double, male: Double) {
        var femaleHotRatings = 0
        var femaleTotalRatings = 0
        var maleHotRatings = 0
        var maleTotalRatings = 0
        
        for rating in ratings {
            // Get rater's gender
            if let rater = try await userRepository.getUser(by: rating.raterId) {
                switch rater.gender {
                case .female:
                    femaleTotalRatings += 1
                    if rating.isHot { femaleHotRatings += 1 }
                case .male:
                    maleTotalRatings += 1
                    if rating.isHot { maleHotRatings += 1 }
                case .other, .none:
                    // Include in both categories with half weight
                    femaleTotalRatings += 1
                    maleTotalRatings += 1
                    if rating.isHot {
                        femaleHotRatings += 1
                        maleHotRatings += 1
                    }
                }
            }
        }
        
        let femaleAttractiveness = femaleTotalRatings > 0 ? Double(femaleHotRatings) / Double(femaleTotalRatings) * 100 : 0.0
        let maleAttractiveness = maleTotalRatings > 0 ? Double(maleHotRatings) / Double(maleTotalRatings) * 100 : 0.0
        
        return (femaleAttractiveness, maleAttractiveness)
    }
    
    /// Generate personalized recommendations
    private func generateRecommendations(
        dominantStyle: StyleType,
        styleBreakdown: [StyleType: Double],
        ranking: StyleRanking,
        preferences: UserPreferences
    ) -> [String] {
        var recommendations: [String] = []
        
        // Recommendation based on dominant style
        recommendations.append(generateDominantStyleRecommendation(dominantStyle))
        
        // Recommendation based on attractiveness score
        recommendations.append(generateAttractivenessRecommendation(ranking.overallAttractiveness))
        
        // Recommendation based on style diversity
        recommendations.append(generateDiversityRecommendation(styleBreakdown))
        
        // Recommendation based on gender appeal
        recommendations.append(generateGenderAppealRecommendation(ranking))
        
        // Recommendation based on user preferences
        recommendations.append(generatePreferencesRecommendation(preferences))
        
        return Array(recommendations.prefix(AnalysisConfig.recommendationCount))
    }
    
    /// Generate recommendation based on dominant style
    private func generateDominantStyleRecommendation(_ style: StyleType) -> String {
        switch style {
        case .elegant:
            return "style.elegant.advice".localized
        case .casual:
            return "style.casual.advice".localized
        case .trendy:
            return "style.trendy.advice".localized
        case .classic:
            return "style.classic.advice".localized
        case .sporty:
            return "style.sporty.advice".localized
        case .artistic:
            return "style.artistic.advice".localized
        case .streetwear:
            return "style.streetwear.advice".localized
        case .minimalist:
            return "style.minimalist.advice".localized
        case .edgy:
            return "style.edgy.advice".localized
        case .formal:
            return "style.formal.advice".localized
        case .colorful:
            return "style.colorful.advice".localized
        }
    }
    
    /// Generate recommendation based on attractiveness score
    private func generateAttractivenessRecommendation(_ score: Double) -> String {
        switch score {
        case 80...:
            return "style.score.high".localized
        case 60..<80:
            return "style.score.good".localized
        case 40..<60:
            return "style.score.average".localized
        default:
            return "style.score.low".localized
        }
    }
    
    /// Generate recommendation based on style diversity
    private func generateDiversityRecommendation(_ styleBreakdown: [StyleType: Double]) -> String {
        let significantStyles = styleBreakdown.filter { $0.value > 15.0 }.count
        
        switch significantStyles {
        case 1:
            return "style.diversity.focused".localized
        case 2...3:
            return "style.diversity.balanced".localized
        default:
            return "style.diversity.scattered".localized
        }
    }
    
    /// Generate recommendation based on gender appeal
    private func generateGenderAppealRecommendation(_ ranking: StyleRanking) -> String {
        let femaleScore = ranking.femaleAttractiveness
        let maleScore = ranking.maleAttractiveness
        let difference = abs(femaleScore - maleScore)
        
        if difference < 10 {
            return "style.gender.balanced".localized
        } else if femaleScore > maleScore {
            return "style.gender.female_preferred".localized
        } else {
            return "style.gender.male_preferred".localized
        }
    }
    
    /// Generate recommendation based on user preferences
    private func generatePreferencesRecommendation(_ preferences: UserPreferences) -> String {
        let hotPercentage = preferences.hotRatingPercentage * 100
        
        switch hotPercentage {
        case 70...:
            return "style.rating.high_taste".localized
        case 50..<70:
            return "style.rating.balanced_view".localized
        default:
            return "style.rating.unique_view".localized
        }
    }
    
    /// Analyze style preferences from photos
    private func analyzeStylePreferences(from photos: [Photo]) -> [StyleType: Double] {
        var stylePreferences: [StyleType: Double] = [:]
        
        // Initialize all styles
        for style in StyleType.allCases {
            stylePreferences[style] = 0.0
        }
        
        // Analyze each photo (simplified algorithm)
        for photo in photos {
            let photoStyles = analyzePhotoStyle(photo: photo, attractivenessScore: 1.0)
            for (style, score) in photoStyles {
                stylePreferences[style, default: 0.0] += score
            }
        }
        
        // Normalize to percentages
        let totalScore = stylePreferences.values.reduce(0, +)
        if totalScore > 0 {
            for style in StyleType.allCases {
                stylePreferences[style] = (stylePreferences[style] ?? 0.0) / totalScore * 100.0
            }
        }
        
        return stylePreferences
    }
    
    /// Get photos from ratings
    private func getPhotosFromRatings(_ ratings: [Rating]) async throws -> [Photo] {
        var photos: [Photo] = []
        let uniquePhotoIds = Set(ratings.map { $0.photoId })
        
        for photoId in uniquePhotoIds {
            if let photo = try await photoRepository.read(id: photoId) {
                photos.append(photo)
            }
        }
        
        return photos
    }
}

// MARK: - Style Analysis Errors
enum StyleAnalysisError: LocalizedError {
    case userNotFound
    case noPhotosUploaded
    case insufficientRatings(current: Int, required: Int)
    case analysisProcessingError
    case reportGenerationFailed
    
    var errorDescription: String? {
        switch self {
        case .userNotFound:
            return "style.error.user_not_found".localized
        case .noPhotosUploaded:
            return "style.error.no_photos_uploaded".localized
        case .insufficientRatings(let current, let required):
            return "評分數量不足：目前 \(current) 個，需要 \(required) 個"
        case .analysisProcessingError:
            return "風格分析處理失敗"
        case .reportGenerationFailed:
            return "報告生成失敗"
        }
    }
}
