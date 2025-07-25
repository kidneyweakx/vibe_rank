//
//  CTAService.swift
//  viberanking
//
//  Created by Kiro on 2025/07/23.
//

import Foundation
import Combine
import FirebaseFirestore

// MARK: - CTA Service Protocol
protocol CTAServiceProtocol {
    func generatePersonalizedCTA(for userId: String) async throws -> CTAMessage
    func checkCTATriggerConditions(for userId: String) async throws -> CTATriggerConditions
    func analyzeUserStylePreferences(from preferences: UserPreferences) async throws -> StyleType
    func shouldShowCTA(for userId: String) async throws -> Bool
}

// MARK: - CTA Service Implementation
@MainActor
class CTAService: ObservableObject, CTAServiceProtocol {
    
    // MARK: - Properties
    private let db = Firestore.firestore()
    private var usersCollection: CollectionReference {
        return db.collection("users")
    }
    
    @Published var isLoading = false
    @Published var error: AppError?
    
    // MARK: - CTAServiceProtocol Implementation
    
    /// Generate personalized CTA message based on user preferences
    func generatePersonalizedCTA(for userId: String) async throws -> CTAMessage {
        isLoading = true
        defer { isLoading = false }
        
        do {
            // Get user preferences
            let preferences = try await getUserPreferences(for: userId)
            
            // Analyze dominant style
            let dominantStyle = try await analyzeUserStylePreferences(from: preferences)
            
            // Generate personalized message
            let ctaMessage = createPersonalizedMessage(
                userId: userId,
                dominantStyle: dominantStyle,
                preferences: preferences
            )
            
            return ctaMessage
            
        } catch {
            let appError = AppError.firebaseError(.firestoreError(error.localizedDescription))
            self.error = appError
            throw appError
        }
    }
    
    /// Check if CTA trigger conditions are met
    func checkCTATriggerConditions(for userId: String) async throws -> CTATriggerConditions {
        isLoading = true
        defer { isLoading = false }
        
        do {
            // Get user data
            let userDoc = try await usersCollection.document(userId).getDocument()
            guard userDoc.exists else {
                throw AppError.userNotFound
            }
            
            let user: User
            do {
                user = try userDoc.data(as: User.self)
            } catch {
                throw AppError.userNotFound
            }
            
            // Check if user has completed required ratings
            let hasUnlockedUpload = user.ratingProgress.hasUnlockedUpload
            
            // Check if preferences exist and are analyzed
            let preferencesDoc = try await usersCollection
                .document(userId)
                .collection("preferences")
                .document("current")
                .getDocument()
            
            let userPreferencesAnalyzed = preferencesDoc.exists
            
            // Check if dominant style can be identified
            var dominantStyleIdentified = false
            if let preferences = try? preferencesDoc.data(as: UserPreferences.self) {
                dominantStyleIdentified = !preferences.stylePreferences.isEmpty
            }
            
            let conditions = CTATriggerConditions(
                minimumRatingsRequired: user.ratingProgress.requiredRatings,
                hasUnlockedUpload: hasUnlockedUpload,
                userPreferencesAnalyzed: userPreferencesAnalyzed,
                dominantStyleIdentified: dominantStyleIdentified
            )
            
            return conditions
            
        } catch {
            let appError = AppError.firebaseError(.firestoreError(error.localizedDescription))
            self.error = appError
            throw appError
        }
    }
    
    /// Analyze user style preferences to determine dominant style
    func analyzeUserStylePreferences(from preferences: UserPreferences) async throws -> StyleType {
        // Find the style with highest preference score
        guard !preferences.stylePreferences.isEmpty else {
            // Default to casual if no preferences available
            return .casual
        }
        
        let sortedPreferences = preferences.stylePreferences.sorted { $0.value > $1.value }
        
        guard let topStyleString = sortedPreferences.first?.key,
              let dominantStyle = StyleType(rawValue: topStyleString) else {
            return .casual
        }
        
        return dominantStyle
    }
    
    /// Check if CTA should be shown to user
    func shouldShowCTA(for userId: String) async throws -> Bool {
        let conditions = try await checkCTATriggerConditions(for: userId)
        return conditions.shouldShowCTA
    }
}

// MARK: - Private Helper Methods
private extension CTAService {
    
    /// Get user preferences from Firestore
    func getUserPreferences(for userId: String) async throws -> UserPreferences {
        let preferencesDoc = try await usersCollection
            .document(userId)
            .collection("preferences")
            .document("current")
            .getDocument()
        
        guard let preferences = try? preferencesDoc.data(as: UserPreferences.self) else {
            // Return default preferences if none exist
            return UserPreferences(userId: userId)
        }
        
        return preferences
    }
    
    /// Create personalized CTA message based on user's dominant style
    func createPersonalizedMessage(userId: String, dominantStyle: StyleType, preferences: UserPreferences) -> CTAMessage {
        
        let personalizedElements = generatePersonalizedElements(for: dominantStyle, preferences: preferences)
        
        let (title, subtitle, buttonText, motivationalText) = generateCTAContent(for: dominantStyle)
        
        return CTAMessage(
            userId: userId,
            title: title,
            subtitle: subtitle,
            buttonText: buttonText,
            motivationalText: motivationalText,
            dominantStyle: dominantStyle,
            personalizedElements: personalizedElements
        )
    }
    
    /// Generate personalized elements based on user preferences
    func generatePersonalizedElements(for dominantStyle: StyleType, preferences: UserPreferences) -> [String] {
        var elements: [String] = []
        
        // Add style-specific elements
        elements.append("你偏愛\(dominantStyle.emoji) \(dominantStyle.displayName)風格")
        
        // Add rating behavior insights
        let hotPercentage = Int(preferences.hotRatingPercentage * 100)
        if hotPercentage > 70 {
            elements.append("你對\(hotPercentage)%的照片給予好評，品味很棒！")
        } else if hotPercentage > 40 {
            elements.append("你的評分很有選擇性，展現獨特眼光")
        } else {
            elements.append("你的評分標準很高，追求完美品質")
        }
        
        // Add style-specific insights
        switch dominantStyle {
        case .elegant:
            elements.append("你欣賞精緻優雅的美感")
        case .casual:
            elements.append("你喜歡自然舒適的風格")
        case .trendy:
            elements.append("你總是跟上最新潮流")
        case .classic:
            elements.append("你偏愛永恆經典的設計")
        case .sporty:
            elements.append("你展現活力健康的生活態度")
        case .artistic:
            elements.append("你具有獨特的藝術眼光")
        case .streetwear:
            elements.append("你具有獨特的藝術眼光")
        case .minimalist:
            elements.append("你具有獨特的藝術眼光")
        case .edgy:
            elements.append("你具有獨特的藝術眼光")
        case .formal:
            elements.append("你具有獨特的藝術眼光")
        case .colorful:
            elements.append("你具有獨特的藝術眼光")
        }
        
        return elements
    }
    
    /// Generate CTA content based on dominant style
    func generateCTAContent(for dominantStyle: StyleType) -> (title: String, subtitle: String, buttonText: String, motivationalText: String) {
        
        switch dominantStyle {
        case .elegant:
            return (
                title: "展現你的優雅風格！",
                subtitle: "根據你的評分偏好，你擁有精緻的品味。讓我們看看別人如何評價你的優雅風格！",
                buttonText: "上傳我的優雅照片",
                motivationalText: "優雅的你值得被看見，分享你的精緻品味吧！"
            )
            
        case .casual:
            return (
                title: "分享你的自然魅力！",
                subtitle: "你喜歡輕鬆自然的風格，這種真實的美最打動人心。來看看大家對你的自然風格有什麼看法！",
                buttonText: "上傳我的自然照片",
                motivationalText: "自然就是美，展現最真實的你！"
            )
            
        case .trendy:
            return (
                title: "展示你的時尚品味！",
                subtitle: "你總是能捕捉到最新的時尚趨勢，這種敏銳的時尚嗅覺讓人印象深刻！",
                buttonText: "上傳我的時尚照片",
                motivationalText: "時尚達人就是你，讓大家見識你的潮流品味！"
            )
            
        case .classic:
            return (
                title: "彰顯你的經典品味！",
                subtitle: "你欣賞永恆的經典美學，這種不受時間影響的品味最珍貴。",
                buttonText: "上傳我的經典照片",
                motivationalText: "經典永不過時，展現你的永恆魅力！"
            )
            
        case .sporty:
            return (
                title: "展現你的活力風采！",
                subtitle: "你喜歡充滿活力的運動風格，這種健康正面的能量最吸引人！",
                buttonText: "上傳我的活力照片",
                motivationalText: "活力四射的你最有魅力，分享你的正能量！"
            )
            
        case .artistic:
            return (
                title: "分享你的藝術眼光！",
                subtitle: "你具有獨特的藝術品味，這種創意和個性最難得。讓大家欣賞你的藝術風格！",
                buttonText: "上傳我的藝術照片",
                motivationalText: "藝術家的眼光獨一無二，展現你的創意魅力！"
            )
        default:
            return(
                title: "分享你的藝術眼光！",
                subtitle: "你具有獨特的藝術品味，這種創意和個性最難得。讓大家欣賞你的藝術風格！",
                buttonText: "上傳我的藝術照片",
                motivationalText: "藝術家的眼光獨一無二，展現你的創意魅力！"
            )
        }
    }
}

// MARK: - Style Analysis Helper
extension CTAService {
    
    /// Advanced style analysis based on rating patterns
    func performAdvancedStyleAnalysis(for userId: String) async throws -> [StyleType: Double] {
        // This would analyze the actual photos that user rated positively
        // and use ML or pattern recognition to determine style preferences
        
        // For now, return a simulated analysis
        // In real implementation, this would:
        // 1. Fetch all photos rated "Hot" by the user
        // 2. Analyze visual features of those photos
        // 3. Classify them into style categories
        // 4. Calculate preference scores
        
        return [
            .elegant: 0.3,
            .casual: 0.2,
            .trendy: 0.25,
            .classic: 0.1,
            .sporty: 0.1,
            .artistic: 0.05
        ]
    }
}
