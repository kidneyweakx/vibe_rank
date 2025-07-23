//
//  viberankingApp.swift
//  viberanking
//
//  Created by kidneyweak on 2025/07/23.
//

import SwiftUI
import Firebase

@main
struct viberankingApp: App {
    // Environment objects
    @StateObject private var authenticationViewModel = AuthenticationViewModel()
    @StateObject private var errorHandler = ErrorHandler()

    init() {
        FirebaseApp.configure()
        // Print app info for debugging
        print("App Version: \(AppInfo.fullVersionString)")
        print("Environment: \(AppEnvironment.current)")
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(authenticationViewModel)
                .environmentObject(errorHandler)
                .onAppear {
                    // Log app start event
                    AnalyticsService.shared.logEvent(.featureUsed(feature: "app_launch"))
                }
                .alert(
                    errorHandler.currentError?.localizedDescription ?? "Error",
                    isPresented: Binding<Bool>(
                        get: { errorHandler.currentError != nil },
                        set: { _ in errorHandler.clearError() }
                    )
                ) {
                    Button("OK") {
                        errorHandler.clearError()
                    }
                } message: {
                    if let recoverySuggestion = errorHandler.currentError?.recoverySuggestion {
                        Text(recoverySuggestion)
                    }
                }
        }
    }
}
