import Foundation
import UserNotifications

/// Centralized facade for app notifications: delivered list, pending, and reminder schedule.
final class AppNotificationsService: ObservableObject {
    static let shared = AppNotificationsService()

    @Published private(set) var delivered: [UNNotification] = []
    @Published private(set) var hasRecent: Bool = false

    private init() {}

    // MARK: - Delivered Notifications
    @MainActor
    func refreshDelivered(lastDays: Int = 7) async {
        let center = UNUserNotificationCenter.current()
        let notifications = await center.deliveredNotifications()
        let cutoff = Calendar.current.date(byAdding: .day, value: -lastDays, to: Date()) ?? Date.distantPast
        let recent = notifications.filter { $0.date >= cutoff }
        self.delivered = recent
        self.hasRecent = !recent.isEmpty
    }

    func removeAllDelivered() async {
        await UNUserNotificationCenter.current().removeAllDeliveredNotifications()
        await MainActor.run {
            self.delivered = []
            self.hasRecent = false
        }
    }

    // MARK: - Reminder Time
    func getSavedReminderTime() -> Date? {
        let defaults = UserDefaults.standard
        let hour = defaults.object(forKey: "notifications.dailyReminder.hour") as? Int
        let minute = defaults.object(forKey: "notifications.dailyReminder.minute") as? Int
        guard let hour = hour, let minute = minute else { return nil }
        var comps = DateComponents()
        comps.hour = hour
        comps.minute = minute
        return Calendar.current.date(from: comps)
    }

    func saveAndRescheduleReminder(time: Date) async throws {
        let hour = Calendar.current.component(.hour, from: time)
        let minute = Calendar.current.component(.minute, from: time)
        try await LocalNotificationService.shared.scheduleDailyReminder(hour: hour, minute: minute)
    }
}


