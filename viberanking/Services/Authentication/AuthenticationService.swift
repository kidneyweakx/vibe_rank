//
//  AuthenticationService.swift
//  viberanking
//
//  Created by Kiro on 2025/07/23.
//

import Foundation
import FirebaseAuth
import GoogleSignIn
import CryptoKit
import AuthenticationServices
import FirebaseCore
import SwiftUI

/// Authentication service that handles user authentication with Firebase
/// using Google and Apple sign-in providers
@MainActor
class AuthenticationService: NSObject, AuthenticationServiceProtocol, ASAuthorizationControllerDelegate {
    
    // MARK: - Properties
    
    private var currentNonce: String?
    private var appleSignInCompletion: ((Result<User, Error>) -> Void)?
    private var rootViewController: UIViewController? {
        // Get the root view controller in a SwiftUI-friendly way
        let scenes = UIApplication.shared.connectedScenes
        let windowScene = scenes.first as? UIWindowScene
        return windowScene?.windows.first?.rootViewController
    }
    
    // MARK: - Initializer
    
    nonisolated override init() {
        super.init()
    }
    
    var currentUser: User? {
        guard let firebaseUser = Auth.auth().currentUser else { return nil }
        return User(id: firebaseUser.uid,
                    name: firebaseUser.displayName ?? "N/A",
                    email: firebaseUser.email ?? "N/A",
                    profileImageURL: firebaseUser.photoURL?.absoluteString)
    }
    
    var isAuthenticated: Bool {
        return Auth.auth().currentUser != nil
    }
    
    // MARK: - Google Sign-In
    
    func signInWithGoogle() async throws -> User {
        print("🔐 Starting Google Sign-In...")
        
        // Check if we're running on simulator
        #if targetEnvironment(simulator)
        print("⚠️ Running on simulator - Google Sign-In may have limitations")
        #endif
        
        guard let clientID = FirebaseApp.app()?.options.clientID else {
            print("❌ Firebase clientID not found in GoogleService-Info.plist")
            throw AppError.validationError("Firebase 配置錯誤：找不到 Client ID。請檢查 GoogleService-Info.plist 文件。")
        }
        
        print("✅ Firebase clientID found: \(String(clientID.prefix(10)))...")
        
        // Configure Google Sign-In
        let config = GIDConfiguration(clientID: clientID)
        GIDSignIn.sharedInstance.configuration = config
        
        guard let rootViewController = self.rootViewController else {
            print("❌ Root view controller not found")
            throw AppError.validationError("無法找到根視圖控制器。請確保應用程式已完全載入。")
        }
        
        print("✅ Root view controller found: \(type(of: rootViewController))")
        
        do {
            print("🔄 Attempting Google Sign-In...")
            let gidSignInResult = try await GIDSignIn.sharedInstance.signIn(withPresenting: rootViewController)
            print("✅ Google Sign-In successful")
            
            guard let idToken = gidSignInResult.user.idToken?.tokenString else {
                print("❌ Failed to get ID token from Google")
                throw AppError.validationError("無法獲取 Google ID Token")
            }
            
            print("✅ Google ID token obtained")
            
            let credential = GoogleAuthProvider.credential(
                withIDToken: idToken,
                accessToken: gidSignInResult.user.accessToken.tokenString
            )
            
            print("🔄 Signing in to Firebase with Google credential...")
            let authResult = try await Auth.auth().signIn(with: credential)
            let firebaseUser = authResult.user
            print("✅ Firebase authentication successful for user: \(firebaseUser.uid)")
            
            // Create user profile
            let user = User(
                id: firebaseUser.uid,
                name: firebaseUser.displayName ?? gidSignInResult.user.profile?.name ?? "Unknown",
                email: firebaseUser.email ?? gidSignInResult.user.profile?.email ?? "no-email@example.com",
                profileImageURL: firebaseUser.photoURL?.absoluteString ?? gidSignInResult.user.profile?.imageURL(withDimension: 200)?.absoluteString
            )
            
            try await createOrUpdateUserProfile(user)
            print("✅ User profile created/updated")
            
            return user
        } catch let error as NSError {
            print("❌ Google Sign-In failed: \(error.localizedDescription)")
            print("❌ Error domain: \(error.domain), code: \(error.code)")
            print("❌ Error userInfo: \(error.userInfo)")
            
            // Handle specific Google Sign-In errors
            if error.domain == "com.google.GIDSignIn" {
                switch error.code {
                case -2: // User cancelled (kGIDSignInErrorCodeCanceled)
                    throw AppError.validationError("用戶取消了登入")
                case -4: // No internet connection (kGIDSignInErrorCodeHasNoAuthInKeychain)
                    throw AppError.networkError(error)
                case -5: // Keychain error
                    throw AppError.validationError("Keychain 錯誤，請重試")
                default:
                    throw AppError.validationError("Google 登入失敗：\(error.localizedDescription)")
                }
            }
            
            // Handle Firebase Auth errors
            if let authError = error as? AuthErrorCode {
                switch authError.code {
                case .networkError:
                    throw AppError.networkError(error)
                case .userDisabled:
                    throw AppError.validationError("此帳戶已被停用")
                case .invalidCredential:
                    throw AppError.validationError("登入憑證無效")
                default:
                    throw AppError.validationError("Firebase 認證失敗：\(error.localizedDescription)")
                }
            }
            
            throw AppError.authenticationFailed
        }
    }
    
    // MARK: - Apple Sign-In
    
    func signInWithApple() async throws -> User {
        print("🍎 Starting Apple Sign-In...")
        
        // Check if we're running on simulator
        #if targetEnvironment(simulator)
        print("⚠️ Running on simulator - Apple Sign-In should work but may require Apple ID")
        #endif
        
        // First check if user has existing Apple ID credentials
        await checkExistingAppleIDCredentials()
        
        let appleIDProvider = ASAuthorizationAppleIDProvider()
        let nonce = randomNonceString()
        currentNonce = nonce
        
        let request = appleIDProvider.createRequest()
        request.requestedScopes = [.fullName, .email]
        request.nonce = sha256(nonce)
        
        // Also check for existing password credentials
        let passwordProvider = ASAuthorizationPasswordProvider()
        let passwordRequest = passwordProvider.createRequest()
        
        let controller = ASAuthorizationController(authorizationRequests: [request, passwordRequest])
        controller.delegate = self
        controller.presentationContextProvider = self
        
        return try await withCheckedThrowingContinuation { continuation in
            self.appleSignInCompletion = { result in
                switch result {
                case .success(let user):
                    print("✅ Apple Sign-In successful for user: \(user.id)")
                    continuation.resume(returning: user)
                case .failure(let error):
                    print("❌ Apple Sign-In failed: \(error.localizedDescription)")
                    continuation.resume(throwing: error)
                }
            }
            
            print("🔄 Presenting Apple Sign-In controller...")
            DispatchQueue.main.async {
                controller.performRequests()
            }
        }
    }
    
    /// Check existing Apple ID credentials status
    private func checkExistingAppleIDCredentials() async {
        print("🔍 Checking existing Apple ID credentials...")
        
        // Get stored user identifier from keychain
        guard let userIdentifier = getCurrentUserIdentifier() else {
            print("ℹ️ No stored user identifier found")
            return
        }
        
        print("🔍 Found stored user identifier: \(userIdentifier)")
        
        // Check credential state
        let appleIDProvider = ASAuthorizationAppleIDProvider()
        
        do {
            let credentialState = try await appleIDProvider.credentialState(forUserID: userIdentifier)
            
            switch credentialState {
            case .authorized:
                print("✅ Apple ID credential is valid")
            case .revoked:
                print("❌ Apple ID credential was revoked")
                // Clear stored identifier
                clearUserIdentifier()
            case .notFound:
                print("❌ Apple ID credential not found")
                // Clear stored identifier
                clearUserIdentifier()
            case .transferred:
                print("⚠️ Apple ID credential was transferred")
            @unknown default:
                print("❓ Unknown credential state")
            }
        } catch {
            print("❌ Failed to check credential state: \(error.localizedDescription)")
        }
    }
    
    func authorizationController(controller: ASAuthorizationController, didCompleteWithAuthorization authorization: ASAuthorization) {
        print("✅ Apple Sign-In authorization completed")
        
        Task {
            do {
                switch authorization.credential {
                case let appleIDCredential as ASAuthorizationAppleIDCredential:
                    print("📱 Processing Apple ID credential")
                    
                    // Store user identifier in keychain for future reference
                    let userIdentifier = appleIDCredential.user
                    await saveUserInKeychain(userIdentifier)
                    
                    guard let nonce = currentNonce else {
                        print("❌ Invalid nonce")
                        throw AppError.validationError("無效的 nonce")
                    }
                    
                    guard let appleIDToken = appleIDCredential.identityToken,
                          let idTokenString = String(data: appleIDToken, encoding: .utf8) else {
                        print("❌ Failed to get Apple ID token")
                        throw AppError.validationError("無法獲取 Apple ID Token")
                    }
                    
                    print("✅ Apple ID token obtained for user: \(userIdentifier)")
                    
                    let credential = OAuthProvider.appleCredential(
                        withIDToken: idTokenString,
                        rawNonce: nonce,
                        fullName: appleIDCredential.fullName
                    )
                    
                    print("🔄 Signing in to Firebase with Apple credential...")
                    let authResult = try await Auth.auth().signIn(with: credential)
                    let firebaseUser = authResult.user
                    print("✅ Firebase authentication successful for user: \(firebaseUser.uid)")
                    
                    // Build user name from Apple provided data
                    var userName = "Apple User"
                    if let fullName = appleIDCredential.fullName {
                        let nameComponents = [fullName.givenName, fullName.familyName].compactMap { $0 }
                        if !nameComponents.isEmpty {
                            userName = nameComponents.joined(separator: " ")
                        }
                    } else if let displayName = firebaseUser.displayName, !displayName.isEmpty {
                        userName = displayName
                    }
                    
                    let user = User(
                        id: firebaseUser.uid,
                        name: userName,
                        email: firebaseUser.email ?? appleIDCredential.email ?? "no-email@example.com",
                        profileImageURL: firebaseUser.photoURL?.absoluteString
                    )
                    
                    // Create or update user profile in Firestore
                    try await createOrUpdateUserProfile(user)
                    print("✅ User profile created/updated")
                    
                    appleSignInCompletion?(.success(user))
                    
                case let passwordCredential as ASPasswordCredential:
                    print("🔑 Processing password credential")
                    
                    // Handle existing iCloud Keychain credential
                    let username = passwordCredential.user
                    let password = passwordCredential.password
                    
                    print("✅ Password credential obtained for user: \(username)")
                    
                    // For password credentials, you would typically authenticate with your backend
                    // For this demo, we'll create a user object
                    let user = User(
                        id: "password_\(username)",
                        name: username,
                        email: "\(username)@example.com"
                    )
                    
                    try await createOrUpdateUserProfile(user)
                    appleSignInCompletion?(.success(user))
                    
                default:
                    print("❌ Unknown credential type")
                    throw AppError.validationError("未知的憑證類型")
                }
                
            } catch {
                print("❌ Apple Sign-In processing failed: \(error.localizedDescription)")
                appleSignInCompletion?(.failure(error))
            }
        }
    }
    
    func authorizationController(controller: ASAuthorizationController, didCompleteWithError error: Error) {
        print("❌ Apple Sign-In failed with error: \(error.localizedDescription)")
        print("❌ Error domain: \(error._domain)")
        print("❌ Error code: \(error._code)")
        
        if let authError = error as? ASAuthorizationError {
            print("❌ ASAuthorizationError code: \(authError.code.rawValue)")
            
            switch authError.code {
            case .canceled:
                print("ℹ️ User canceled Apple Sign-In")
                appleSignInCompletion?(.failure(AppError.validationError("用戶取消了 Apple 登入")))
            case .failed:
                print("❌ Apple Sign-In failed - check configuration")
                appleSignInCompletion?(.failure(AppError.validationError("Apple 登入失敗。請檢查：\n1. 是否在設定中登入 Apple ID\n2. 是否啟用雙重認證\n3. Xcode 項目配置是否正確")))
            case .invalidResponse:
                print("❌ Invalid response from Apple")
                appleSignInCompletion?(.failure(AppError.validationError("Apple 登入回應無效")))
            case .notHandled:
                print("❌ Apple Sign-In not handled")
                appleSignInCompletion?(.failure(AppError.validationError("Apple 登入未處理")))
            case .unknown:
                print("❌ Unknown Apple Sign-In error")
                appleSignInCompletion?(.failure(AppError.validationError("Apple 登入發生未知錯誤")))
            @unknown default:
                print("❌ Unknown Apple Sign-In error (future case)")
                appleSignInCompletion?(.failure(AppError.validationError("Apple 登入發生未知錯誤")))
            }
        } else {
            // Handle other types of errors
            let errorMessage = error.localizedDescription
            if errorMessage.contains("沒有可用於登入的憑證") || errorMessage.contains("No credentials available") {
                appleSignInCompletion?(.failure(AppError.validationError("沒有可用的登入憑證。請確保：\n1. 在設定中登入了 Apple ID\n2. 啟用了雙重認證\n3. 網路連接正常")))
            } else {
                appleSignInCompletion?(.failure(AppError.validationError("Apple 登入錯誤：\(errorMessage)")))
            }
        }
    }
    
    // MARK: - Keychain Management
    
    /// Save user identifier to keychain
    private func saveUserInKeychain(_ userIdentifier: String) async {
        print("💾 Saving user identifier to keychain: \(userIdentifier)")
        
        do {
            let keychainItem = KeychainItem(service: KeychainItem.userIdentifierKey, account: KeychainItem.currentUserIdentifier)
            try keychainItem.saveItem(userIdentifier)
            print("✅ User identifier saved to keychain")
        } catch {
            print("❌ Failed to save user identifier to keychain: \(error.localizedDescription)")
        }
    }
    
    /// Get current user identifier from keychain
    private func getCurrentUserIdentifier() -> String? {
        do {
            let keychainItem = KeychainItem(service: KeychainItem.userIdentifierKey, account: KeychainItem.currentUserIdentifier)
            return try keychainItem.readItem()
        } catch KeychainItem.KeychainError.noPassword {
            return nil
        } catch {
            print("❌ Failed to read user identifier from keychain: \(error.localizedDescription)")
            return nil
        }
    }
    
    /// Clear user identifier from keychain
    private func clearUserIdentifier() {
        print("🗑️ Clearing user identifier from keychain")
        
        do {
            let keychainItem = KeychainItem(service: KeychainItem.userIdentifierKey, account: KeychainItem.currentUserIdentifier)
            try keychainItem.deleteItem()
            print("✅ User identifier cleared from keychain")
        } catch {
            print("❌ Failed to clear user identifier from keychain: \(error.localizedDescription)")
        }
    }
    
    /// Check Apple ID credential state for existing user
    func checkAppleIDCredentialState() async -> ASAuthorizationAppleIDProvider.CredentialState? {
        guard let userIdentifier = getCurrentUserIdentifier() else {
            print("📝 No stored user identifier found")
            return nil
        }
        
        print("🔍 Checking credential state for user: \(userIdentifier)")
        
        return await withCheckedContinuation { continuation in
            let appleIDProvider = ASAuthorizationAppleIDProvider()
            appleIDProvider.getCredentialState(forUserID: userIdentifier) { credentialState, error in
                if let error = error {
                    print("❌ Error checking credential state: \(error.localizedDescription)")
                    continuation.resume(returning: nil)
                } else {
                    print("✅ Credential state: \(credentialState)")
                    continuation.resume(returning: credentialState)
                }
            }
        }
    }
    
    // MARK: - User Profile Management
    
    private let userRepository = UserRepository()
    
    /// Creates or updates a user profile in Firestore
    private func createOrUpdateUserProfile(_ user: User) async throws {
        print("🔄 Creating/updating user profile for \(user.id) in Firestore")
        
        do {
            let savedUser = try await userRepository.createOrUpdateUserProfile(user)
            print("✅ User profile saved successfully: \(savedUser.name)")
            
            // Try to update last activity, but don't fail if offline
            do {
                try await userRepository.updateLastActivity(userId: savedUser.id)
            } catch {
                print("⚠️ Could not update last activity (offline mode): \(error.localizedDescription)")
                // Continue without failing
            }
            
        } catch {
            print("⚠️ Failed to create/update user profile (offline mode): \(error.localizedDescription)")
            // In offline mode, don't throw error - allow authentication to continue
            if error.localizedDescription.contains("offline") || error.localizedDescription.contains("network") {
                print("📱 Continuing authentication in offline mode")
                return
            }
            throw error
        }
    }
    
    // MARK: - Sign Out
    
    func signOut() async throws {
        print("🔄 Signing out user...")
        
        let firebaseAuth = Auth.auth()
        do {
            try firebaseAuth.signOut()
            
            // Also sign out from Google if needed
            if GIDSignIn.sharedInstance.currentUser != nil {
                GIDSignIn.sharedInstance.signOut()
                print("✅ Google Sign-In signed out")
            }
            
            // Clear user identifier from keychain
            clearUserIdentifier()
            
            print("✅ User signed out successfully")
        } catch {
            print("❌ Sign out failed: \(error.localizedDescription)")
            throw AppError.firebaseError(.authenticationError)
        }
    }
    
    // MARK: - Private Helpers for Apple Sign-In
    
    private func randomNonceString(length: Int = 32) -> String {
        precondition(length > 0)
        var randomBytes = [UInt8](repeating: 0, count: length)
        let errorCode = SecRandomCopyBytes(kSecRandomDefault, randomBytes.count, &randomBytes)
        if errorCode != errSecSuccess {
            fatalError("Unable to generate random bytes. OSStatus \(errorCode)")
        }
        
        let charset: [Character] =
            Array("0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._")
        
        return String(randomBytes.map { charset[Int($0) % charset.count] })
    }
    
    private func sha256(_ input: String) -> String {
        let inputData = Data(input.utf8)
        let hashedData = SHA256.hash(data: inputData)
        let hashString = hashedData.compactMap {
            String(format: "%02x", $0)
        }.joined()
        
        return hashString
    }
}

// MARK: - ASAuthorizationControllerPresentationContextProviding

extension AuthenticationService: ASAuthorizationControllerPresentationContextProviding {
    func presentationAnchor(for controller: ASAuthorizationController) -> ASPresentationAnchor {
        return rootViewController?.view.window ?? ASPresentationAnchor()
    }
}

// MARK: - ASAuthorizationAppleIDProvider Extension

extension ASAuthorizationAppleIDProvider {
    func credentialState(forUserID userID: String) async throws -> ASAuthorizationAppleIDProvider.CredentialState {
        return try await withCheckedThrowingContinuation { continuation in
            getCredentialState(forUserID: userID) { credentialState, error in
                if let error = error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume(returning: credentialState)
                }
            }
        }
    }
}