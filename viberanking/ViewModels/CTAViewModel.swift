//
//  CTAViewModel.swift
//  viberanking
//
//  Created by Kiro on 2025/07/23.
//

import Foundation
import Combine
import SwiftUI

// MARK: - CTA View Model
@MainActor
class CTAViewModel: ObservableObject {
    
    // MARK: - Published Properties
    @Published var ctaMessage: CTAMessage?
    @Published var triggerConditions: CTATriggerConditions?
    @Published var isLoading = false
    @Published var error: AppError?
    @Published var shouldShowCTA = false
    @Published var isAnalyzingPreferences = false
    
    // MARK: - Dependencies
    private let ctaService: CTAServiceProtocol
    private let authService: AuthenticationServiceProtocol
    
    // MARK: - Cancellables
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Initialization
    init(ctaService: CTAServiceProtocol, authService: AuthenticationServiceProtocol) {
        self.ctaService = ctaService
        self.authService = authService
        
        setupBindings()
    }
    
    // MARK: - Public Methods
    
    /// Check if CTA should be displayed for current user
    func checkCTAEligibility() async {
        guard let currentUser = authService.currentUser else {
            error = AppError.userNotFound
            return
        }
        
        isLoading = true
        error = nil
        
        do {
            let shouldShow = try await ctaService.shouldShowCTA(for: currentUser.id)
            shouldShowCTA = shouldShow
            
            if shouldShow {
                await loadCTAMessage()
            }
            
        } catch {
            self.error = error as? AppError ?? AppError.networkError(error)
        }
        
        isLoading = false
    }
    
    /// Load personalized CTA message
    func loadCTAMessage() async {
        guard let currentUser = authService.currentUser else {
            error = AppError.userNotFound
            return
        }
        
        isAnalyzingPreferences = true
        error = nil
        
        do {
            let message = try await ctaService.generatePersonalizedCTA(for: currentUser.id)
            ctaMessage = message
            
        } catch {
            self.error = error as? AppError ?? AppError.networkError(error)
        }
        
        isAnalyzingPreferences = false
    }
    
    /// Load CTA trigger conditions
    func loadTriggerConditions() async {
        guard let currentUser = authService.currentUser else {
            error = AppError.userNotFound
            return
        }
        
        isLoading = true
        error = nil
        
        do {
            let conditions = try await ctaService.checkCTATriggerConditions(for: currentUser.id)
            triggerConditions = conditions
            
        } catch {
            self.error = error as? AppError ?? AppError.networkError(error)
        }
        
        isLoading = false
    }
    
    /// Refresh CTA data
    func refresh() async {
        await checkCTAEligibility()
        await loadTriggerConditions()
    }
    
    /// Handle CTA button tap
    func handleCTAButtonTap() {
        // This will be handled by the parent view
        // The view should navigate to photo upload
    }
    
    /// Handle skip upload action
    func handleSkipUpload() {
        // This could track analytics or show additional motivation
        // For now, just dismiss the CTA
        shouldShowCTA = false
    }
    
    /// Clear error state
    func clearError() {
        error = nil
    }
}

// MARK: - Private Methods
private extension CTAViewModel {
    
    /// Setup reactive bindings
    func setupBindings() {
        // Monitor authentication state changes
        // In a real app, you'd subscribe to auth state changes
        // For now, we'll manually trigger checks
    }
}

// MARK: - Computed Properties
extension CTAViewModel {
    
    /// Check if user has completed required ratings
    var hasCompletedRequiredRatings: Bool {
        return triggerConditions?.hasUnlockedUpload ?? false
    }
    
    /// Check if user preferences are analyzed
    var hasAnalyzedPreferences: Bool {
        return triggerConditions?.userPreferencesAnalyzed ?? false
    }
    
    /// Check if dominant style is identified
    var hasDominantStyle: Bool {
        return triggerConditions?.dominantStyleIdentified ?? false
    }
    
    /// Get progress percentage for CTA eligibility
    var ctaEligibilityProgress: Double {
        guard let conditions = triggerConditions else { return 0.0 }
        
        var completedSteps = 0
        let totalSteps = 3
        
        if conditions.hasUnlockedUpload { completedSteps += 1 }
        if conditions.userPreferencesAnalyzed { completedSteps += 1 }
        if conditions.dominantStyleIdentified { completedSteps += 1 }
        
        return Double(completedSteps) / Double(totalSteps)
    }
    
    /// Get user-friendly status message
    var statusMessage: String {
        guard let conditions = triggerConditions else {
            return "cta.checking_status".localized
        }
        
        if conditions.shouldShowCTA {
            return "cta.ready_to_upload".localized
        }
        
        if !conditions.hasUnlockedUpload {
            return "cta.need_more_ratings".localized
        }
        
        if !conditions.userPreferencesAnalyzed {
            return "cta.analyzing_preferences".localized
        }
        
        if !conditions.dominantStyleIdentified {
            return "cta.identifying_style".localized
        }
        
        return "cta.preparing".localized
    }
}

// MARK: - Error Handling
extension CTAViewModel {
    
    /// Handle specific error types
    func handleError(_ error: AppError) {
        self.error = error
        
        // Log error for analytics
        print("CTA Error: \(error.localizedDescription)")
        
        // Handle specific error types
        switch error {
        case .userNotFound:
            // Might need to re-authenticate
            break
        case .networkError:
            // Could implement retry logic
            break
        default:
            break
        }
    }
}