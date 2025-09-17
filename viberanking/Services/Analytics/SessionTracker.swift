//
//  SessionTracker.swift
//  viberanking
//
//  Created by Assistant on 2025/09/17.
//

import Foundation
import SwiftUI
import os.log

/// Tracks app foreground/background sessions using scenePhase.
/// Emits analytics events for session start and duration.
final class SessionTracker: ObservableObject {
    static let shared = SessionTracker()

    private let logger = Logger(subsystem: "com.viberanking.analytics", category: "Session")
    private var sessionStart: Date?

    private init() {}

    func handleScenePhaseChange(_ newPhase: ScenePhase) {
        switch newPhase {
        case .active:
            startSessionIfNeeded()
        case .inactive, .background:
            endSessionIfNeeded(reason: String(describing: newPhase))
        @unknown default:
            break
        }
    }

    private func startSessionIfNeeded() {
        guard sessionStart == nil else { return }
        sessionStart = Date()
        logger.info("Session started")
        AnalyticsService.shared.logEvent(.featureUsed(feature: "session_start"))
    }

    private func endSessionIfNeeded(reason: String) {
        guard let start = sessionStart else { return }
        let duration = Date().timeIntervalSince(start)
        sessionStart = nil
        logger.info("Session ended after \(duration, privacy: .public)s due to \(reason)")
        AnalyticsService.shared.logEvent(.featureUsed(feature: "session_end_\(Int(duration))"))
    }
}


