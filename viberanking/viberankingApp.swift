//
//  viberankingApp.swift
//  viberanking
//
//  Created by kidneyweak on 2025/07/23.
//

import SwiftUI

@main
struct viberankingApp: App {
    // Environment objects
    @StateObject private var firebaseService = FirebaseService.shared
    @StateObject private var errorHandler = ErrorHandler()
    
    init() {
        // Firebase will be configured when dependencies are added
        
        // Print app info for debugging
        print("App Version: \(AppInfo.fullVersionString)")
        print("Environment: \(AppEnvironment.current)")
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(firebaseService)
                .environmentObject(errorHandler)
                .onAppear {
                    // Log app start event
                    AnalyticsService.shared.logEvent(.featureUsed(feature: "app_launch"))
                }
                .alert(
                    errorHandler.currentError?.localizedDescription ?? "Error",
                    isPresented: $errorHandler.showingError
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
