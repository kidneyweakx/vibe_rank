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
    func logScreenDuration(_ screenName: String, seconds: Int)
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
    case screenDuration(screenName: String, seconds: Int)
    
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
        case .screenDuration:
            return "screen_duration"
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
        case .screenDuration(let screenName, let seconds):
            return ["screen_name": screenName, "seconds": seconds]
        }
    }
}

// MARK: - Analytics Service Implementation
class AnalyticsService: AnalyticsServiceProtocol {
    static let shared = AnalyticsService()
    
    private let logger = Logger(subsystem: "com.viberanking.analytics", category: "Analytics")
    private let syncQueue = DispatchQueue(label: "com.viberanking.analytics.syncQueue")

    // Local in-memory counters for quick analysis (not persisted off device)
    private var eventCounts: [String: Int] = [:]
    private var screenDurations: [String: Int] = [:]
    
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

        // Increment local counters for quick analysis
        syncQueue.async { [weak self] in
            guard let self else { return }
            self.eventCounts[event.name, default: 0] += 1
            if case let .screenDuration(screenName, seconds) = event {
                self.screenDurations[screenName, default: 0] += max(0, seconds)
            }
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

    func logScreenDuration(_ screenName: String, seconds: Int) {
        logEvent(.screenDuration(screenName: screenName, seconds: seconds))
        logger.debug("Screen duration: \(screenName) = \(seconds, privacy: .public)s")
    }
}

// MARK: - Lightweight Analysis Snapshot
extension AnalyticsService {
    /// Returns a thread-safe snapshot of local analytics counters.
    /// This does not perform any network I/O and can be used to render a quick in-app summary.
    func analysisSnapshot() -> AnalyticsSnapshot {
        var countsCopy: [String: Int] = [:]
        var durationsCopy: [String: Int] = [:]
        syncQueue.sync {
            countsCopy = self.eventCounts
            durationsCopy = self.screenDurations
        }
        let totalEvents = countsCopy.values.reduce(0, +)
        let topEvents = Array(countsCopy.sorted { $0.value > $1.value }.prefix(5))
        let topScreens = Array(durationsCopy.sorted { $0.value > $1.value }.prefix(5))
        return AnalyticsSnapshot(
            totalEvents: totalEvents,
            topEventCounts: Dictionary(uniqueKeysWithValues: topEvents),
            topScreenDurations: Dictionary(uniqueKeysWithValues: topScreens)
        )
    }
}

/// Immutable representation of local analytics summary.
struct AnalyticsSnapshot {
    let totalEvents: Int
    let topEventCounts: [String: Int]
    let topScreenDurations: [String: Int]
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
