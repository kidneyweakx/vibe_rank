//
//  RootEntryView.swift
//  viberanking
//
//  Created by Assistant on 2025/09/17.
//

import SwiftUI
import AppTrackingTransparency

struct RootEntryView: View {
    @AppStorage("hasShownTrackingPrePrompt") private var hasShownTrackingPrePrompt: Bool = false
    @State private var showTrackingPrePrompt: Bool = false

    var body: some View {
        ZStack {
            ContentView()
                .trackScreen(name: "RootEntry")

            if showTrackingPrePrompt {
                TrackingPrePromptView(
                    onContinue: { handleTrackingContinue() }
                )
                .transition(.opacity)
            }
        }
        .onAppear {
            // Start Apple analytics (no tracking, diagnostic only)
            AppleAnalyticsManager.shared.start()
            evaluateAndPresentPrePromptIfNeeded()
        }
    }

    private func evaluateAndPresentPrePromptIfNeeded() {
        if #available(iOS 14, *) {
            let status = ATTrackingManager.trackingAuthorizationStatus
            if status == .notDetermined && !hasShownTrackingPrePrompt {
                showTrackingPrePrompt = true
            } else {
                AnalyticsService.shared.logEvent(.featureUsed(feature: "app_launch"))
            }
        } else {
            AnalyticsService.shared.logEvent(.featureUsed(feature: "app_launch"))
        }
    }

    private func handleTrackingContinue() {
        hasShownTrackingPrePrompt = true
        showTrackingPrePrompt = false
        // Immediately request ATT after the message (no Later/Close path)
        TrackingAuthorizationManager.shared.requestAuthorizationIfNeeded { _ in
            AnalyticsService.shared.logEvent(.featureUsed(feature: "app_launch"))
        }
    }
}

#if DEBUG
struct RootEntryView_Previews: PreviewProvider {
    static var previews: some View {
        RootEntryView()
    }
}
#endif


