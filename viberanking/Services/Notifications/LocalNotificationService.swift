//
//  LocalNotificationService.swift
//  viberanking
//
//  Created by AI Assistant on 2025/09/17.
//

import Foundation
import UserNotifications

/// Service responsible for requesting permissions and scheduling local notifications.
final class LocalNotificationService {
    static let shared = LocalNotificationService()

    // MARK: - Keys
    private enum Keys {
        static let dailyReminderId = "com.viberanking.notifications.dailyReminder"
        static let scheduledHourKey = "notifications.dailyReminder.hour"
        static let scheduledMinuteKey = "notifications.dailyReminder.minute"
        static let lastOverallRankKey = "journey.last.overallRank"
        static let lastTotalUsersKey = "journey.last.totalUsers"
    }

    private init() {}

    // MARK: - Permission
    func requestAuthorization() async -> Bool {
        do {
            return try await UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge])
        } catch {
            return false
        }
    }

    // MARK: - Scheduling
    func scheduleDailyReminder(hour: Int, minute: Int) async throws {
        // Save selected time
        let defaults = UserDefaults.standard
        defaults.set(hour, forKey: Keys.scheduledHourKey)
        defaults.set(minute, forKey: Keys.scheduledMinuteKey)

        // Remove existing
        await cancelDailyReminder()

        // Build content
        let content = buildDailyContent()

        // Trigger at given time every day
        var dateComponents = DateComponents()
        dateComponents.hour = hour
        dateComponents.minute = minute

        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
        let request = UNNotificationRequest(identifier: Keys.dailyReminderId, content: content, trigger: trigger)

        try await UNUserNotificationCenter.current().add(request)
    }

    func cancelDailyReminder() async {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [Keys.dailyReminderId])
    }

    /// Rebuilds and reschedules the daily reminder using last saved time.
    func refreshDailyReminderContent() async {
        let defaults = UserDefaults.standard
        let hour = defaults.integer(forKey: Keys.scheduledHourKey)
        let minute = defaults.integer(forKey: Keys.scheduledMinuteKey)
        guard hour >= 0 && hour <= 23 && minute >= 0 && minute <= 59 else { return }

        // Update by re-adding with same trigger
        let content = buildDailyContent()
        var comps = DateComponents()
        comps.hour = hour
        comps.minute = minute
        let trigger = UNCalendarNotificationTrigger(dateMatching: comps, repeats: true)
        let request = UNNotificationRequest(identifier: Keys.dailyReminderId, content: content, trigger: trigger)
        do { try await UNUserNotificationCenter.current().add(request) } catch { /* ignore */ }
    }

    // MARK: - Helpers
    private func buildDailyContent() -> UNMutableNotificationContent {
        let defaults = UserDefaults.standard
        let overallRank = defaults.integer(forKey: Keys.lastOverallRankKey)
        let totalUsers = defaults.integer(forKey: Keys.lastTotalUsersKey)

        let title = "notif.daily.title".localized

        var body: String
        if totalUsers > 0 && overallRank > 0 && overallRank <= totalUsers {
            let beatCount = max(0, totalUsers - overallRank)
            body = String(format: "notif.daily.body.beat_people".localized, beatCount)
        } else {
            body = "notif.daily.body.generic".localized
        }

        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default
        return content
    }

    // MARK: - Public Snapshots API
    /// Save latest ranking snapshot for later notification content.
    static func saveLatestRankingSnapshot(overallRank: Int, totalUsers: Int) {
        let defaults = UserDefaults.standard
        defaults.set(overallRank, forKey: Keys.lastOverallRankKey)
        defaults.set(totalUsers, forKey: Keys.lastTotalUsersKey)
    }
}


