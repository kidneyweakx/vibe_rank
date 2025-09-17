//
//  OnboardingStepNotifications.swift
//  viberanking
//
//  Created by AI Assistant on 2025/08/28.
//

import SwiftUI
import UserNotifications

struct OnboardingStepNotifications: View {
    let complete: () -> Void
    let back: () -> Void

    @State private var selectedTime: Date = defaultInitialTime()
    @State private var isScheduling: Bool = false
    @State private var errorMessage: String?
    @State private var scheduledInfo: String?

    var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    Text("onb.notif.title".localized(table: "Onboarding"))
                        .font(.system(size: 24, weight: .semibold))
                        .foregroundColor(.white)

                    VStack(alignment: .leading, spacing: 16) {
                        NotificationItemView(
                            text: "onb.notif.item.1".localized(table: "Onboarding"),
                            icon: "chart.line.uptrend.xyaxis"
                        )
                        NotificationItemView(
                            text: "onb.notif.item.2".localized(table: "Onboarding"),
                            icon: "arrow.clockwise"
                        )
                        NotificationItemView(
                            text: "onb.notif.item.3".localized(table: "Onboarding"),
                            icon: "sparkles"
                        )
                    }

                    VStack(alignment: .leading, spacing: 8) {
                        Text("onb.notif.time_label".localized(table: "Onboarding"))
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.white)
                        DatePicker("", selection: $selectedTime, displayedComponents: .hourAndMinute)
                            .datePickerStyle(.wheel)
                            .labelsHidden()
                            .colorScheme(.dark)
                        if let scheduledInfo {
                            Text(scheduledInfo)
                                .font(.system(size: 13))
                                .foregroundColor(.white.opacity(0.6))
                        }
                        if let errorMessage {
                            Text(errorMessage)
                                .font(.system(size: 13))
                                .foregroundColor(.red)
                        }
                    }
                }
                .padding(24)
            }

            HStack(spacing: 12) {
                Button(action: back) {
                    Text("common.back".localized(table: "Onboarding"))
                        .frame(maxWidth: .infinity)
                        .padding()
                        .foregroundColor(.white)
                        .background(RoundedRectangle(cornerRadius: 12).stroke(Color.white.opacity(0.25)))
                }

                Button(action: enableAndSchedule) {
                    if isScheduling {
                        ProgressView()
                            .tint(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                    } else {
                        Text("onb.notif.cta.enable".localized(table: "Onboarding"))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                    }
                }
                .background(RoundedRectangle(cornerRadius: 12).fill(LinearGradient(gradient: Gradient(colors: [.blue, .purple]), startPoint: .leading, endPoint: .trailing)))
                .disabled(isScheduling)
            }
            .padding(20)
        }
        .background(Color.black)
        .preferredColorScheme(.dark)
        .onAppear { scheduledInfo = nil; errorMessage = nil }
    }
}

private struct NotificationItemView: View {
    let text: String
    let icon: String
    
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 20, weight: .medium))
                .foregroundColor(.blue)
                .frame(width: 24, height: 24)
            
            Text(text)
                .font(.system(size: 16))
                .foregroundColor(.white.opacity(0.9))
                .multilineTextAlignment(.leading)
            
            Spacer()
        }
        .padding(.vertical, 8)
    }
}

// MARK: - Actions
private extension OnboardingStepNotifications {
    static func defaultInitialTime() -> Date {
        var comps = DateComponents()
        comps.hour = 20
        comps.minute = 0
        return Calendar.current.date(from: comps) ?? Date()
    }

    func enableAndSchedule() {
        errorMessage = nil
        scheduledInfo = nil
        isScheduling = true
        Task {
            let granted = await LocalNotificationService.shared.requestAuthorization()
            guard granted else {
                await MainActor.run {
                    isScheduling = false
                    errorMessage = "onb.notif.permission_denied".localized(table: "Onboarding")
                }
                return
            }

            let hour = Calendar.current.component(.hour, from: selectedTime)
            let minute = Calendar.current.component(.minute, from: selectedTime)
            do {
                try await LocalNotificationService.shared.scheduleDailyReminder(hour: hour, minute: minute)
                await MainActor.run {
                    isScheduling = false
                    let formatter = DateFormatter()
                    formatter.timeStyle = .short
                    scheduledInfo = String(format: "onb.notif.scheduled".localized(table: "Onboarding"), formatter.string(from: selectedTime))
                    // Continue onboarding
                    complete()
                }
            } catch {
                await MainActor.run {
                    isScheduling = false
                    errorMessage = error.localizedDescription
                }
            }
        }
    }
}

#Preview {
    OnboardingStepNotifications(complete: {}, back: {})
}


