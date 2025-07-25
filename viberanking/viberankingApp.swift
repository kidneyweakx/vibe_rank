//
//  viberankingApp.swift
//  viberanking
//
//  Created by kidneyweak on 2025/07/23.
//

import SwiftUI
import Firebase
import GoogleSignIn

@main
struct viberankingApp: App {
    // Environment objects
    @StateObject private var authenticationViewModel = AuthenticationViewModel()
    @StateObject private var errorHandler = ErrorHandler()
    @StateObject private var localizationManager = LocalizationManager.shared

    init() {
        // Configure Firebase first
        FirebaseApp.configure()
        
        // Configure Google Sign-In
        guard let clientID = FirebaseApp.app()?.options.clientID else {
            fatalError("No client ID found in GoogleService-Info.plist")
        }
        GIDSignIn.sharedInstance.configuration = GIDConfiguration(clientID: clientID)
        
        // Test Apple Sign-In configuration
        AppleSignInTestHelper.testConfiguration()
        AppleSignInTestHelper.checkDeviceSupport()
        AppleSignInTestHelper.testKeychainOperations()
        
        // Print app info for debugging
        print("App Version: \(AppInfo.fullVersionString)")
        print("Environment: \(AppEnvironment.current)")
        
        // Check Apple ID credential state at launch
        checkAppleIDCredentialStateAtLaunch()
    }
    
    /// Check Apple ID credential state when app launches
    private func checkAppleIDCredentialStateAtLaunch() {
        Task {
            let authService = AuthenticationService()
            if let credentialState = await authService.checkAppleIDCredentialState() {
                await MainActor.run {
                    switch credentialState {
                    case .authorized:
                        print("✅ Apple ID credential is valid")
                        // User is still authorized, continue with app
                    case .revoked, .notFound:
                        print("⚠️ Apple ID credential is revoked or not found")
                        // Force user to sign in again
                        authenticationViewModel.signOut()
                    case .transferred:
                        print("📱 Apple ID credential transferred to new device")
                        // Handle credential transfer
                    @unknown default:
                        print("❓ Unknown Apple ID credential state")
                    }
                }
            }
        }
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(authenticationViewModel)
                .environmentObject(errorHandler)
                .environmentObject(localizationManager)
                .onAppear {
                    // Log app start event
                    AnalyticsService.shared.logEvent(.featureUsed(feature: "app_launch"))
                }
                .onOpenURL { url in
                    // Handle Google Sign-In URL
                    GIDSignIn.sharedInstance.handle(url)
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
