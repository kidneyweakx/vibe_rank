//
//  TrackingAuthorizationManager.swift
//  viberanking
//
//  Created by Assistant on 2025/09/11.
//

import Foundation
import AppTrackingTransparency

/// Centralizes App Tracking Transparency (ATT) permission handling.
/// Always call `requestAuthorizationIfNeeded` once after first launch UI is visible.
final class TrackingAuthorizationManager {
    static let shared = TrackingAuthorizationManager()
    private init() {}

    /// Returns true when ATT authorization is granted or when ATT is not available.
    var isAuthorized: Bool {
        if #available(iOS 14, *) {
            return ATTrackingManager.trackingAuthorizationStatus == .authorized
        } else {
            return true
        }
    }

    /// Requests ATT authorization if status is `.notDetermined`. Completion is always called on the main thread.
    func requestAuthorizationIfNeeded(completion: @escaping (ATTrackingManager.AuthorizationStatus) -> Void) {
        if #available(iOS 14, *) {
            let status = ATTrackingManager.trackingAuthorizationStatus
            guard status == .notDetermined else {
                DispatchQueue.main.async { completion(status) }
                return
            }

            // Request after a slight delay to ensure the first frame is on screen.
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                ATTrackingManager.requestTrackingAuthorization { newStatus in
                    DispatchQueue.main.async { completion(newStatus) }
                }
            }
        } else {
            // For iOS versions prior to 14, just proceed.
            DispatchQueue.main.async { completion(.authorized) }
        }
    }
}


