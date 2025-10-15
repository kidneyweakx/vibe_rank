import SwiftUI

struct NotificationScheduleView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var time: Date = Calendar.current.date(bySettingHour: 20, minute: 0, second: 0, of: Date()) ?? Date()
    @State private var saving = false
    @State private var errorMessage: String?

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                DatePicker("Reminder Time", selection: $time, displayedComponents: .hourAndMinute)
                    .datePickerStyle(.wheel)
                    .labelsHidden()
                    .colorScheme(.dark)

                if let error = errorMessage {
                    Text(error)
                        .foregroundColor(.red)
                        .font(.footnote)
                }

                Button(action: save) {
                    if saving { ProgressView().tint(.white) } else { Text("Save").bold() }
                }
                .buttonStyle(.borderedProminent)
                .tint(.blue)
            }
            .padding(20)
            .navigationTitle("Daily Reminder")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Close") { dismiss() }
                }
            }
            .task { loadSaved() }
        }
        .preferredColorScheme(.dark)
    }

    private func loadSaved() {
        if let saved = AppNotificationsService.shared.getSavedReminderTime() {
            time = saved
        }
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
    NotificationScheduleView()
}


