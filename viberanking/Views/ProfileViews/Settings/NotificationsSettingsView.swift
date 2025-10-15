import SwiftUI

struct NotificationsSettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var notificationsEnabled = false
    @State private var time: Date = Calendar.current.date(bySettingHour: 20, minute: 0, second: 0, of: Date()) ?? Date()
    @State private var saving = false
    @State private var errorMessage: String?

    var body: some View {
        Form {
            Section(header: Text("Daily Reminder")) {
                Toggle("Enable", isOn: $notificationsEnabled)
                    .onChange(of: notificationsEnabled) { enabled in
                        Task {
                            if enabled {
                                let granted = await LocalNotificationService.shared.requestAuthorization()
                                if !granted {
                                    await MainActor.run { notificationsEnabled = false }
                                }
                            } else {
                                await LocalNotificationService.shared.cancelDailyReminder()
                            }
                        }
                    }
                DatePicker("Reminder Time", selection: $time, displayedComponents: .hourAndMinute)
            }

            if let errorMessage = errorMessage {
                Section { Text(errorMessage).foregroundColor(.red) }
            }

            Section {
                Button(action: save) { saving ? AnyView(AnyView(ProgressView())) : AnyView(Text("Save").bold()) }
            }
        }
        .navigationTitle("Notifications")
        .task { await loadInitial() }
        .preferredColorScheme(.dark)
    }

    private func loadInitial() async {
        let settings = await UNUserNotificationCenter.current().notificationSettings()
        await MainActor.run { notificationsEnabled = (settings.authorizationStatus == .authorized) }
        if let saved = AppNotificationsService.shared.getSavedReminderTime() { time = saved }
    }

    private func save() {
        saving = true
        errorMessage = nil
        Task {
            do {
                let granted = await LocalNotificationService.shared.requestAuthorization()
                guard granted else { throw NSError(domain: "notif", code: 1, userInfo: [NSLocalizedDescriptionKey: "Permission denied"]) }
                try await AppNotificationsService.shared.saveAndRescheduleReminder(time: time)
                await MainActor.run { saving = false; dismiss() }
            } catch {
                await MainActor.run { saving = false; errorMessage = error.localizedDescription }
            }
        }
    }
}

#Preview {
    NavigationView { NotificationsSettingsView() }
}


