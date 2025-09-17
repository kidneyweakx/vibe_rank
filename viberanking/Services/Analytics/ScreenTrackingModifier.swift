//
//  ScreenTrackingModifier.swift
//  viberanking
//
//  Created by Assistant on 2025/09/17.
//

import Foundation
import SwiftUI

/// A SwiftUI modifier that tracks screen view and time spent on the screen.
struct ScreenTrackingModifier: ViewModifier {
    let screenName: String
    let screenClass: String?

    @State private var appearDate: Date?

    func body(content: Content) -> some View {
        content
            .onAppear {
                appearDate = Date()
                AnalyticsService.shared.logScreenView(screenName, screenClass: screenClass)
            }
            .onDisappear {
                guard let start = appearDate else { return }
                let seconds = max(0, Int(Date().timeIntervalSince(start)))
                AnalyticsService.shared.logScreenDuration(screenName, seconds: seconds)
                appearDate = nil
            }
    }
}

extension View {
    func trackScreen(name: String, screenClass: String? = nil) -> some View {
        modifier(ScreenTrackingModifier(screenName: name, screenClass: screenClass))
    }
}


