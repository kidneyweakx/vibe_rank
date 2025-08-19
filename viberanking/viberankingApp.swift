//
//  viberankingApp.swift
//  viberanking
//
//  Created by kidneyweak on 2025/07/23.
//

import SwiftUI
import GoogleSignIn

@main
struct viberankingApp: App {
    // Environment objects
    @StateObject private var authenticationViewModel = AuthenticationViewModel()
    @StateObject private var errorHandler = ErrorHandler()
    @StateObject private var localizationManager = LocalizationManager.shared
    @StateObject private var themeManager = ThemeManager()

    init() {
        // Configure Google Sign-In
        configureGoogleSignIn()
        
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
    
    /// Configure Google Sign-In
    private func configureGoogleSignIn() {
        guard let path = Bundle.main.path(forResource: "GoogleService-Info", ofType: "plist"),
              let plist = NSDictionary(contentsOfFile: path),
              let clientID = plist["CLIENT_ID"] as? String else {
            print("❌ Google Sign-In configuration failed: CLIENT_ID not found")
            return
        }
        
        GIDSignIn.sharedInstance.configuration = GIDConfiguration(clientID: clientID)
        print("✅ Google Sign-In configured with CLIENT_ID: \(clientID)")
    }
    
    /// Check Apple ID credential state when app launches
    private func checkAppleIDCredentialStateAtLaunch() {
        // 這個檢查現在由 AuthenticationService 的 init 方法處理
        // 不需要在這裡重複檢查
        print("ℹ️ 認證狀態檢查將由 AuthenticationService 處理")
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(authenticationViewModel)
                .environmentObject(errorHandler)
                .environmentObject(localizationManager)
                .environmentObject(themeManager)
                .onAppear {
                    // Log app start event
                    AnalyticsService.shared.logEvent(.featureUsed(feature: "app_launch"))
                }
                .onOpenURL { url in
                    // Handle Google Sign-In URL callback
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
