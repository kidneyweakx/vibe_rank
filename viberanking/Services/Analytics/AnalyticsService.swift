//
//  AnalyticsService.swift
//  viberanking
//
//  Created by Kiro on 2025/07/23.
//

import Foundation
import AppTrackingTransparency
import os.log

// MARK: - Analytics Service Protocol
protocol AnalyticsServiceProtocol {
    func logEvent(_ event: AnalyticsEvent)
    func setUserProperty(_ property: String, value: String?)
    func setUserId(_ userId: String?)
    func logScreenView(_ screenName: String, screenClass: String?)
}

// MARK: - Analytics Events
enum AnalyticsEvent {
    case userSignIn(method: String)
    case userSignOut
    case photoRated(isHot: Bool, photoId: String)
    case photoUploaded(photoId: String)
    case reportGenerated(userId: String, dominantStyle: String)
    case achievementUnlocked(achievementId: String)
    case errorOccurred(error: String, screen: String)
    case screenViewed(screenName: String)
    case featureUsed(feature: String)
    
    var name: String {
        switch self {
        case .userSignIn:
            return "user_sign_in"
        case .userSignOut:
            return "user_sign_out"
        case .photoRated:
            return "photo_rated"
        case .photoUploaded:
            return "photo_uploaded"
        case .reportGenerated:
            return "report_generated"
        case .achievementUnlocked:
            return "achievement_unlocked"
        case .errorOccurred:
            return "error_occurred"
        case .screenViewed:
            return "screen_view"
        case .featureUsed:
            return "feature_used"
        }
    }
    
    var parameters: [String: Any] {
        switch self {
        case .userSignIn(let method):
            return ["method": method]
        case .userSignOut:
            return [:]
        case .photoRated(let isHot, let photoId):
            return ["is_hot": isHot, "photo_id": photoId]
        case .photoUploaded(let photoId):
            return ["photo_id": photoId]
        case .reportGenerated(let userId, let dominantStyle):
            return ["user_id": userId, "dominant_style": dominantStyle]
        case .achievementUnlocked(let achievementId):
            return ["achievement_id": achievementId]
        case .errorOccurred(let error, let screen):
            return ["error": error, "screen": screen]
        case .screenViewed(let screenName):
            return ["screen_name": screenName]
        case .featureUsed(let feature):
            return ["feature": feature]
        }
    }
}

// MARK: - Analytics Service Implementation
class AnalyticsService: AnalyticsServiceProtocol {
    static let shared = AnalyticsService()
    
    private let logger = Logger(subsystem: "com.viberanking.analytics", category: "Analytics")
    
    private init() {}
    
    func logEvent(_ event: AnalyticsEvent) {
        guard AppEnvironment.current.enableAnalytics,
              TrackingAuthorizationManager.shared.isAuthorized else {
            return
        }
        
        // Firebase Analytics implementation will be added when Firebase is properly configured
        // For now, just log to console
        if AppConfiguration.Debug.enableDetailedLogging {
            logger.info("Analytics event logged: \(event.name) with parameters: \(event.parameters)")
        }
    }
    
    func setUserProperty(_ property: String, value: String?) {
        guard AppEnvironment.current.enableAnalytics,
              TrackingAuthorizationManager.shared.isAuthorized else { return }
        
        // Firebase Analytics implementation will be added when Firebase is properly configured
        logger.debug("User property set: \(property) = \(value ?? "nil")")
    }
    
    func setUserId(_ userId: String?) {
        guard AppEnvironment.current.enableAnalytics,
              TrackingAuthorizationManager.shared.isAuthorized else { return }
        
        // Firebase Analytics implementation will be added when Firebase is properly configured
        logger.debug("User ID set: \(userId ?? "nil")")
    }
    
    func logScreenView(_ screenName: String, screenClass: String? = nil) {
        logEvent(.screenViewed(screenName: screenName))
        
        if let screenClass = screenClass {
            logger.debug("Screen view: \(screenName), class: \(screenClass)")
        }
    }
}

// MARK: - Performance Monitoring
class PerformanceMonitor {
    static let shared = PerformanceMonitor()
    
    private let logger = Logger(subsystem: "com.viberanking.performance", category: "Performance")
    private var startTimes: [String: Date] = [:]
    
    private init() {}
    
    func startTimer(for operation: String) {
        startTimes[operation] = Date()
        logger.debug("Started timer for: \(operation)")
    }
    
    func endTimer(for operation: String) {
        guard let startTime = startTimes[operation] else {
            logger.warning("No start time found for operation: \(operation)")
            return
        }
        
        let duration = Date().timeIntervalSince(startTime)
        startTimes.removeValue(forKey: operation)
        
        logger.info("Operation '\(operation)' completed in \(duration, privacy: .public) seconds")
        
        // Log to analytics if enabled
        if AppConfiguration.Debug.enablePerformanceMonitoring {
            AnalyticsService.shared.logEvent(.featureUsed(feature: "performance_\(operation)"))
        }
    }
    
    func measureAsync<T>(_ operation: String, task: () async throws -> T) async rethrows -> T {
        startTimer(for: operation)
        defer { endTimer(for: operation) }
        return try await task()
    }
}
