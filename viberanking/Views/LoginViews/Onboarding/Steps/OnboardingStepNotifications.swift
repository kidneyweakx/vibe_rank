//
//  OnboardingStepNotifications.swift
//  viberanking
//
//  Created by AI Assistant on 2025/08/28.
//

import SwiftUI

struct OnboardingStepNotifications: View {
    let complete: () -> Void
    let back: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    Text("onb.notif.title.en".localized(table: "Onboarding"))
                        .font(.system(size: 24, weight: .semibold))
                        .foregroundColor(.white)

                    VStack(alignment: .leading, spacing: 16) {
                        NotificationItemView(
                            text: "onb.notif.item.en.1".localized(table: "Onboarding"),
                            icon: "📈"
                        )
                        NotificationItemView(
                            text: "onb.notif.item.en.2".localized(table: "Onboarding"),
                            icon: "🔄"
                        )
                        NotificationItemView(
                            text: "onb.notif.item.en.3".localized(table: "Onboarding"),
                            icon: "✨"
                        )
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

                Button(action: complete) {
                    Text("onb.notif.cta.enable".localized(table: "Onboarding"))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(RoundedRectangle(cornerRadius: 12).fill(LinearGradient(gradient: Gradient(colors: [.blue, .purple]), startPoint: .leading, endPoint: .trailing)))
                }
            }
            .padding(20)
        }
        .background(Color.black)
        .preferredColorScheme(.dark)
    }
}

private struct NotificationItemView: View {
    let text: String
    let icon: String
    
    var body: some View {
        HStack(spacing: 16) {
            Text(icon)
                .font(.system(size: 24))
            
            Text(text)
                .font(.system(size: 16))
                .foregroundColor(.white.opacity(0.9))
                .multilineTextAlignment(.leading)
            
            Spacer()
        }
        .padding(.vertical, 8)
    }
}

#Preview {
    OnboardingStepNotifications(complete: {}, back: {})
}


