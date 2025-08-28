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
                VStack(alignment: .leading, spacing: 18) {
                    Text("onb.notif.title.en".localized(table: "Onboarding"))
                        .font(.system(size: 22, weight: .semibold))
                        .foregroundColor(.white)

                    VStack(alignment: .leading, spacing: 8) {
                        HStack(spacing: 12) {
                            Rectangle().fill(LinearGradient(gradient: Gradient(colors: [.blue, .purple]), startPoint: .leading, endPoint: .trailing)).frame(width: 6)
                            Text("onb.notif.item.en.1".localized(table: "Onboarding"))
                        }
                        HStack(spacing: 12) {
                            Rectangle().fill(LinearGradient(gradient: Gradient(colors: [.blue, .purple]), startPoint: .leading, endPoint: .trailing)).frame(width: 6)
                            Text("onb.notif.item.en.2".localized(table: "Onboarding"))
                        }
                        HStack(spacing: 12) {
                            Rectangle().fill(LinearGradient(gradient: Gradient(colors: [.blue, .purple]), startPoint: .leading, endPoint: .trailing)).frame(width: 6)
                            Text("onb.notif.item.en.3".localized(table: "Onboarding"))
                        }
                    }

                    Text("onb.notif.title.zh".localized(table: "Onboarding"))
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundColor(.white)

                    VStack(alignment: .leading, spacing: 8) {
                        HStack(spacing: 12) {
                            Rectangle().fill(LinearGradient(gradient: Gradient(colors: [.blue, .purple]), startPoint: .leading, endPoint: .trailing)).frame(width: 6)
                            Text("onb.notif.item.zh.1".localized(table: "Onboarding"))
                        }
                        HStack(spacing: 12) {
                            Rectangle().fill(LinearGradient(gradient: Gradient(colors: [.blue, .purple]), startPoint: .leading, endPoint: .trailing)).frame(width: 6)
                            Text("onb.notif.item.zh.2".localized(table: "Onboarding"))
                        }
                        HStack(spacing: 12) {
                            Rectangle().fill(LinearGradient(gradient: Gradient(colors: [.blue, .purple]), startPoint: .leading, endPoint: .trailing)).frame(width: 6)
                            Text("onb.notif.item.zh.3".localized(table: "Onboarding"))
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

#Preview {
    OnboardingStepNotifications(complete: {}, back: {})
}


