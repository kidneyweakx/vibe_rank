import SwiftUI
import UserNotifications

struct NotificationsListView: View {
    @ObservedObject private var notifService = AppNotificationsService.shared

    var body: some View {
        List {
            if notifService.delivered.isEmpty {
                Section {
                    Text("No notifications in the last 7 days")
                        .foregroundColor(.secondary)
                }
            } else {
                ForEach(notifService.delivered, id: \.request.identifier) { item in
                    VStack(alignment: .leading, spacing: 6) {
                        Text(item.request.content.title)
                            .font(.headline)
                        if !item.request.content.body.isEmpty {
                            Text(item.request.content.body)
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        Text(item.date, style: .date)
                            + Text("  ")
                            + Text(item.date, style: .time)
                    }
                    .padding(.vertical, 6)
                }
            }
        }
        .listStyle(.insetGrouped)
        .scrollContentBackground(.hidden)
        .background(Color.black.ignoresSafeArea())
        .task { await notifService.refreshDelivered(lastDays: 7) }
        .navigationTitle("Notifications")
        .preferredColorScheme(.dark)
    }
}

#Preview {
    NotificationsListView()
}


