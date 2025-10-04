//
//  viberankingApp.swift
//  viberanking
//
//  Created by kidneyweak on 2025/07/23.
//

import SwiftUI
import GoogleSignIn
import GoogleMobileAds
import MetricKit
import Clarity

@main
struct viberankingApp: App {
    // Environment objects
    @StateObject private var authenticationViewModel = AuthenticationViewModel()
    @StateObject private var errorHandler = ErrorHandler()
    @StateObject private var localizationManager = LocalizationManager.shared
    @StateObject private var themeManager = ThemeManager()
    @Environment(\.scenePhase) private var scenePhase

    init() {
        // Initialize Google Mobile Ads SDK
        MobileAds.shared.start { status in
            print("✅ Google Mobile Ads SDK initialized")
            print("   Adapter statuses:")
            for (adapter, adapterStatus) in status.adapterStatusesByClassName {
                print("   - \(adapter): \(adapterStatus.state.rawValue) - \(adapterStatus.description)")
            }
        }

        // Initialize Microsoft Clarity
        let clarityConfig = ClarityConfig(projectId: "tkwzcyjf2m")
        ClaritySDK.initialize(config: clarityConfig)
        print("✅ Microsoft Clarity initialized")

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

        // Start Apple analytics (MetricKit)
        AppleAnalyticsManager.shared.start()

        // Setup session expiry observer
        setupSessionExpiryObserver()
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

    /// Setup observer for session expiry notifications
    private func setupSessionExpiryObserver() {
        NotificationCenter.default.addObserver(
            forName: .userSessionExpired,
            object: nil,
            queue: .main
        ) { [weak authenticationViewModel] _ in
            print("🔒 Session expired notification received - signing out user")
            authenticationViewModel?.signOut(dueTo: "Session expired (401)")
        }
    }

    var body: some Scene {
        WindowGroup {
            RootEntryView()
                .environmentObject(authenticationViewModel)
                .environmentObject(errorHandler)
                .environmentObject(localizationManager)
                .environmentObject(themeManager)
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
                .onChange(of: scenePhase) { newPhase in
                    SessionTracker.shared.handleScenePhaseChange(newPhase)
                }
        }
    }
}
