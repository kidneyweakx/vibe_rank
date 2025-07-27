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
        elements.append(String(format: "cta.style_preference".localized, dominantStyle.emoji, dominantStyle.displayName))
        
        // Add rating behavior insights
        let hotPercentage = Int(preferences.hotRatingPercentage * 100)
        if hotPercentage > 70 {
            elements.append(String(format: "cta.rating_behavior.high".localized, hotPercentage))
        } else if hotPercentage > 40 {
            elements.append("cta.rating_behavior.medium".localized)
        } else {
            elements.append("cta.rating_behavior.low".localized)
        }
        
        // Add style-specific insights
        switch dominantStyle {
        case .elegant:
            elements.append("cta.style_insight.elegant".localized)
        case .casual:
            elements.append("cta.style_insight.casual".localized)
        case .trendy:
            elements.append("cta.style_insight.trendy".localized)
        case .classic:
            elements.append("cta.style_insight.classic".localized)
        case .sporty:
            elements.append("cta.style_insight.sporty".localized)
        case .artistic:
            elements.append("cta.style_insight.artistic".localized)
        case .streetwear:
            elements.append("cta.style_insight.streetwear".localized)
        case .minimalist:
            elements.append("cta.style_insight.minimalist".localized)
        case .edgy:
            elements.append("cta.style_insight.edgy".localized)
        case .formal:
            elements.append("cta.style_insight.formal".localized)
        case .colorful:
            elements.append("cta.style_insight.colorful".localized)
        }
        
        return elements
    }
    
    /// Generate CTA content based on dominant style
    func generateCTAContent(for dominantStyle: StyleType) -> (title: String, subtitle: String, buttonText: String, motivationalText: String) {
        
        switch dominantStyle {
        case .elegant:
            return (
                title: "cta.elegant.title".localized,
                subtitle: "cta.elegant.subtitle".localized,
                buttonText: "cta.elegant.button".localized,
                motivationalText: "cta.elegant.motivation".localized
            )
            
        case .casual:
            return (
                title: "cta.casual.title".localized,
                subtitle: "cta.casual.subtitle".localized,
                buttonText: "cta.casual.button".localized,
                motivationalText: "cta.casual.motivation".localized
            )
            
        case .trendy:
            return (
                title: "cta.trendy.title".localized,
                subtitle: "cta.trendy.subtitle".localized,
                buttonText: "cta.trendy.button".localized,
                motivationalText: "cta.trendy.motivation".localized
            )
            
        case .classic:
            return (
                title: "cta.classic.title".localized,
                subtitle: "cta.classic.subtitle".localized,
                buttonText: "cta.classic.button".localized,
                motivationalText: "cta.classic.motivation".localized
            )
            
        case .sporty:
            return (
                title: "cta.sporty.title".localized,
                subtitle: "cta.sporty.subtitle".localized,
                buttonText: "cta.sporty.button".localized,
                motivationalText: "cta.sporty.motivation".localized
            )
            
        case .artistic:
            return (
                title: "cta.artistic.title".localized,
                subtitle: "cta.artistic.subtitle".localized,
                buttonText: "cta.artistic.button".localized,
                motivationalText: "cta.artistic.motivation".localized
            )
        default:
            return(
                title: "cta.default.title".localized,
                subtitle: "cta.default.subtitle".localized,
                buttonText: "cta.default.button".localized,
                motivationalText: "cta.default.motivation".localized
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
