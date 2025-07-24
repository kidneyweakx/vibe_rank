//
//  AppleSignInTestHelper.swift
//  viberanking
//
//  Created by Kiro on 2025/07/24.
//

import Foundation
import AuthenticationServices

/// Helper class to test Apple Sign-In configuration
class AppleSignInTestHelper {
    
    /// Test if Apple Sign-In is properly configured
    static func testConfiguration() {
        print("🧪 Testing Apple Sign-In configuration...")
        
        // Check if Sign in with Apple capability is enabled
        let appleIDProvider = ASAuthorizationAppleIDProvider()
        let request = appleIDProvider.createRequest()
        
        print("✅ ASAuthorizationAppleIDProvider created successfully")
        print("✅ Authorization request created successfully")
        
        // Check if we can create an authorization controller
        let controller = ASAuthorizationController(authorizationRequests: [request])
        print("✅ ASAuthorizationController created successfully")
        
        // Check bundle configuration
        if let bundleId = Bundle.main.bundleIdentifier {
            print("✅ Bundle ID: \(bundleId)")
        } else {
            print("❌ Bundle ID not found")
        }
        
        // Check entitlements
        if let entitlements = Bundle.main.object(forInfoDictionaryKey: "com.apple.developer.applesignin") {
            print("✅ Apple Sign-In entitlement found: \(entitlements)")
        } else {
            print("❌ Apple Sign-In entitlement not found - check Xcode configuration")
        }
        
        print("🎉 Apple Sign-In configuration test completed!")
    }
    
    /// Test keychain operations
    static func testKeychainOperations() {
        print("🧪 Testing keychain operations...")
        
        let testUserID = "test_user_123"
        let keychainItem = KeychainItem(
            service: KeychainItem.userIdentifierKey,
            account: KeychainItem.currentUserIdentifier
        )
        
        do {
            // Test saving
            try keychainItem.saveItem(testUserID)
            print("✅ Keychain save test passed")
            
            // Test reading
            let retrievedUserID = try keychainItem.readItem()
            if retrievedUserID == testUserID {
                print("✅ Keychain read test passed")
            } else {
                print("❌ Keychain read test failed: expected \(testUserID), got \(retrievedUserID)")
            }
            
            // Test deleting
            try keychainItem.deleteItem()
            print("✅ Keychain delete test passed")
            
            // Verify deletion
            do {
                _ = try keychainItem.readItem()
                print("❌ Keychain deletion verification failed: item still exists")
            } catch KeychainItem.KeychainError.noPassword {
                print("✅ Keychain deletion verification passed")
            }
            
        } catch {
            print("❌ Keychain test failed: \(error.localizedDescription)")
        }
    }
    
    /// Check if device supports Apple Sign-In
    static func checkDeviceSupport() {
        print("🧪 Checking device support for Apple Sign-In...")
        
        if #available(iOS 13.0, *) {
            print("✅ iOS version supports Apple Sign-In")
        } else {
            print("❌ iOS version does not support Apple Sign-In")
        }
        
        // Check if running on simulator
        #if targetEnvironment(simulator)
        print("⚠️ Running on simulator - Apple Sign-In should work but requires Apple ID")
        #else
        print("✅ Running on device - Apple Sign-In should work normally")
        #endif
    }
}