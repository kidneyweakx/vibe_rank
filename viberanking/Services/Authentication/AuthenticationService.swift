//
//  AuthenticationService.swift
//  viberanking
//
//  Created by Kiro on 2025/07/23.
//

import Foundation
import GoogleSignIn
import CryptoKit
import AuthenticationServices
import SwiftUI

import Combine

@MainActor
class AuthenticationService: NSObject, ObservableObject, ASAuthorizationControllerDelegate {
    
    @Published var currentUser: User?
    
    private var currentNonce: String?
    private var appleSignInCompletion: ((Result<User, Error>) -> Void)?
    private let authAPI = AuthAPI()
    private var pendingUserData: InitialUserData?
    
    var isAuthenticated: Bool { currentUser != nil }
    
    override init() {
        super.init()
        // 在初始化時檢查已保存的登入狀態
        Task {
            await checkSavedAuthState()
        }
    }
    
    private var rootViewController: UIViewController? {
        UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .first?.windows.first?.rootViewController
    }
    
    // MARK: - Google Sign-In
    
    func signInWithGoogle() async throws -> User {
        guard let clientID = getGoogleClientID() else {
            throw AppError.validationError("Google Client ID 未配置")
        }
        
        guard let rootViewController = rootViewController else {
            throw AppError.validationError("無法找到根視圖控制器")
        }
        
        GIDSignIn.sharedInstance.configuration = GIDConfiguration(clientID: clientID)
        
        do {
            let result = try await GIDSignIn.sharedInstance.signIn(withPresenting: rootViewController)
            
            guard let idToken = result.user.idToken?.tokenString else {
                throw AppError.validationError("無法獲取 Google ID Token")
            }
            
            do {
                let user = try await verifyGoogleToken(
                    idToken: idToken,
                    accessToken: result.user.accessToken.tokenString
                )
                
                currentUser = user
                saveUserToKeychain(user)
                return user
                
            } catch let error as AppError {
                if case .serverError(let statusCode) = error, statusCode == 404 {
                    // Store the user data for profile setup
                    let userData = InitialUserData(
                        name: result.user.profile?.name ?? "Google User",
                        email: result.user.profile?.email ?? "",
                        profileImageURL: result.user.profile?.imageURL(withDimension: 200)?.absoluteString,
                        authProvider: "google",
                        providerUserID: result.user.userID ?? ""
                    )
                    
                    // Store this data temporarily for profile setup
                    pendingUserData = userData
                    
                    // Re-throw the 404 error so the ViewModel can handle it
                    throw error
                } else {
                    throw error
                }
            }
            
        } catch let error as NSError where error.domain == "com.google.GIDSignIn" {
            switch error.code {
            case -2: throw AppError.validationError("用戶取消了登入")
            case -4: throw AppError.networkError(error)
            case -5: throw AppError.validationError("Keychain 錯誤，請重試")
            default: throw AppError.validationError("Google 登入失敗：\(error.localizedDescription)")
            }
        }
    }
    

    
    // MARK: - Apple Sign-In
    
    func signInWithApple() async throws -> User {
        await checkExistingAppleIDCredentials()
        
        let nonce = randomNonceString()
        currentNonce = nonce
        
        let appleIDProvider = ASAuthorizationAppleIDProvider()
        let request = appleIDProvider.createRequest()
        request.requestedScopes = [.fullName, .email]
        request.nonce = sha256(nonce)
        
        let controller = ASAuthorizationController(authorizationRequests: [request])
        controller.delegate = self
        controller.presentationContextProvider = self
        
        do {
            return try await withCheckedThrowingContinuation { continuation in
                appleSignInCompletion = { result in
                    continuation.resume(with: result)
                }
                DispatchQueue.main.async {
                    controller.performRequests()
                }
            }
        } catch let error as AppError {
            if case .serverError(let statusCode) = error, statusCode == 404 {
                // The user data should have been stored in the delegate method
                // Re-throw the 404 error so the ViewModel can handle it
                throw error
            } else {
                throw error
            }
        }
    }
    
    private func checkExistingAppleIDCredentials() async {
        guard let userIdentifier = getCurrentUserIdentifier() else { return }
        
        do {
            let state = try await ASAuthorizationAppleIDProvider().credentialState(forUserID: userIdentifier)
            if state == .revoked || state == .notFound {
                clearUserIdentifier()
            }
        } catch {
            print("Failed to check credential state: \(error)")
        }
    }
    
    // MARK: - ASAuthorizationControllerDelegate
    
    func authorizationController(controller: ASAuthorizationController, didCompleteWithAuthorization authorization: ASAuthorization) {
        Task {
            do {
                let user: User
                
                switch authorization.credential {
                case let appleIDCredential as ASAuthorizationAppleIDCredential:
                    await saveUserInKeychain(appleIDCredential.user)
                    
                    guard let nonce = currentNonce,
                          let appleIDToken = appleIDCredential.identityToken,
                          let idTokenString = String(data: appleIDToken, encoding: .utf8) else {
                        throw AppError.validationError("無法獲取 Apple ID Token")
                    }
                    
                    do {
                        user = try await verifyAppleToken(
                            idToken: idTokenString,
                            nonce: nonce,
                            userIdentifier: appleIDCredential.user,
                            fullName: appleIDCredential.fullName,
                            email: appleIDCredential.email
                        )
                    } catch let error as AppError {
                        if case .serverError(let statusCode) = error, statusCode == 404 {
                            // Store the user data for profile setup
                            let displayName = [appleIDCredential.fullName?.givenName, appleIDCredential.fullName?.familyName]
                                .compactMap { $0 }
                                .joined(separator: " ")

                            // Preserve existing/saved name on re-login when Apple doesn't provide fullName again
                            let preservedName = self.currentUser?.name ?? self.getSavedUserFromKeychain()?.name ?? ""

                            let userData = InitialUserData(
                                name: displayName.isEmpty ? preservedName : displayName,
                                email: appleIDCredential.email ?? "",
                                profileImageURL: nil, // Apple doesn't provide profile images
                                authProvider: "apple",
                                providerUserID: appleIDCredential.user
                            )
                            
                            // Store this data temporarily for profile setup
                            pendingUserData = userData
                            
                            // Re-throw the 404 error so the ViewModel can handle it
                            throw error
                        } else {
                            throw error
                        }
                    }
                    
                case let passwordCredential as ASPasswordCredential:
                    user = try await verifyPasswordCredential(
                        username: passwordCredential.user,
                        password: passwordCredential.password
                    )
                    
                default:
                    throw AppError.validationError("未知的憑證類型")
                }
                
                currentUser = user
                saveUserToKeychain(user)
                appleSignInCompletion?(.success(user))
                
            } catch {
                appleSignInCompletion?(.failure(error))
            }
        }
    }
    
    func authorizationController(controller: ASAuthorizationController, didCompleteWithError error: Error) {
        let errorMessage: String
        
        if let authError = error as? ASAuthorizationError {
            switch authError.code {
            case .canceled:
                errorMessage = "用戶取消了 Apple 登入"
            case .failed:
                errorMessage = "Apple 登入失敗。請檢查配置和網路連接"
            default:
                errorMessage = "Apple 登入發生錯誤"
            }
        } else {
            errorMessage = "Apple 登入錯誤：\(error.localizedDescription)"
        }
        
        appleSignInCompletion?(.failure(AppError.validationError(errorMessage)))
    }
    
    // MARK: - API Verification
    
    private func verifyGoogleToken(idToken: String, accessToken: String) async throws -> User {
        do {
            let response = try await authAPI.verifyGoogleToken(idToken: idToken, accessToken: accessToken)

            // Save JWT token to keychain
            try? KeychainItem.saveJWTToken(response.token)

            return User(
                id: response.user.id,
                name: response.user.name,
                email: response.user.email,
                profileImageURL: response.user.avatar
            )
        } catch let apiError as APIError {
            throw convertAPIErrorToAppError(apiError)
        }
    }
    
    private func verifyAppleToken(idToken: String, nonce: String, userIdentifier: String, fullName: PersonNameComponents?, email: String?) async throws -> User {
        do {
            let response = try await authAPI.verifyAppleToken(
                idToken: idToken,
                nonce: nonce,
                userIdentifier: userIdentifier,
                fullName: fullName,
                email: email
            )

            // Save JWT token to keychain
            try? KeychainItem.saveJWTToken(response.token)

            return User(
                id: response.user.id,
                name: response.user.name,
                email: response.user.email,
                profileImageURL: response.user.avatar
            )
        } catch let apiError as APIError {
            throw convertAPIErrorToAppError(apiError)
        }
    }
    
    private func verifyPasswordCredential(username: String, password: String) async throws -> User {
        do {
            let response = try await authAPI.verifyPasswordCredential(username: username, password: password)

            // Save JWT token to keychain
            try? KeychainItem.saveJWTToken(response.token)

            return User(
                id: response.user.id,
                name: response.user.name,
                email: response.user.email,
                profileImageURL: response.user.avatar
            )
        } catch let apiError as APIError {
            throw convertAPIErrorToAppError(apiError)
        }
    }
    
    // MARK: - Keychain Management
    
    private func saveUserInKeychain(_ userIdentifier: String) async {
        do {
            let keychainItem = KeychainItem(service: KeychainItem.userIdentifierKey, account: KeychainItem.currentUserIdentifier)
            try keychainItem.saveItem(userIdentifier)
        } catch {
            print("Failed to save user identifier: \(error)")
        }
    }
    
    private func getCurrentUserIdentifier() -> String? {
        do {
            let keychainItem = KeychainItem(service: KeychainItem.userIdentifierKey, account: KeychainItem.currentUserIdentifier)
            return try keychainItem.readItem()
        } catch {
            return nil
        }
    }
    
    private func clearUserIdentifier() {
        do {
            let keychainItem = KeychainItem(service: KeychainItem.userIdentifierKey, account: KeychainItem.currentUserIdentifier)
            try keychainItem.deleteItem()
        } catch {
            print("Failed to clear user identifier: \(error)")
        }
    }
    
    /// Check Apple ID credential state for existing user
    func checkAppleIDCredentialState() async -> ASAuthorizationAppleIDProvider.CredentialState? {
        guard let userIdentifier = getCurrentUserIdentifier() else {
            return nil
        }
        
        do {
            return try await ASAuthorizationAppleIDProvider().credentialState(forUserID: userIdentifier)
        } catch {
            print("Failed to check credential state: \(error)")
            return nil
        }
    }
    
    // MARK: - Guest Sign-In
    
    func signInAsGuest() async -> User {
        print("👤 開始訪客登入...")
        let guestId = "guest_\(UUID().uuidString)"
        let guestUser = User(
            id: guestId,
            name: "Guest_\(String(guestId.suffix(8)))", // Use last 8 chars of guest ID for better identification
            email: "guest\(String(guestId.suffix(8)))@example.com"
        )
        
        currentUser = guestUser
        saveUserToKeychain(guestUser)
        print("✅ 訪客登入成功: \(guestUser.name)")
        return guestUser
    }
    
    // MARK: - Profile Setup
    
    func getPendingUserData() -> InitialUserData? {
        return pendingUserData
    }
    
    func completeProfileSetup(_ profileData: UserProfileData) async throws -> User {
        do {
            let response = try await authAPI.createUserProfile(profileData)

            // Save JWT token to keychain
            try? KeychainItem.saveJWTToken(response.token)

            let user = User(
                id: response.user.id,
                name: response.user.name,
                email: response.user.email,
                profileImageURL: response.user.avatar
            )

            currentUser = user
            saveUserToKeychain(user)
            pendingUserData = nil // Clear pending data
            return user
        } catch let apiError as APIError {
            // Fallback: if backend returns 400 (e.g., UNIQUE constraint on email), try updating existing profile
            if case .serverError(let statusCode) = apiError, statusCode == 400 {
                do {
                    let userAPI = UserAPI()
                    // Attempt to update profile using the chosen customUserID
                    let updateResponse = try await userAPI.updateUserProfile(
                        userId: profileData.customUserID,
                        name: profileData.displayName,
                        gender: nil,
                        avatar: profileData.profileImageURL
                    )
                    // Map minimal response to our User model
                    let user = User(
                        id: updateResponse.data.id,
                        name: updateResponse.data.name,
                        email: updateResponse.data.email,
                        profileImageURL: updateResponse.data.avatar,
                        gender: updateResponse.data.gender.flatMap { Gender(rawValue: $0) }
                    )
                    currentUser = user
                    pendingUserData = nil
                    return user
                } catch let fallbackError as APIError {
                    throw convertAPIErrorToAppError(fallbackError)
                } catch {
                    throw AppError.apiError(error)
                }
            }
            throw convertAPIErrorToAppError(apiError)
        }
    }
    
    /// Complete onboarding with consolidated payload
    func completeOnboarding(_ payload: OnboardingCompletePayload) async throws -> User {
        do {
            let response = try await authAPI.completeOnboarding(payload)

            // Save JWT token to keychain
            try? KeychainItem.saveJWTToken(response.token)

            let user = User(
                id: response.user.id,
                name: response.user.name,
                email: response.user.email,
                profileImageURL: response.user.avatar
            )
            currentUser = user
            saveUserToKeychain(user)
            pendingUserData = nil
            return user
        } catch let apiError as APIError {
            throw convertAPIErrorToAppError(apiError)
        }
    }
    
    // MARK: - Auto Login Check
    
    /// 檢查已保存的認證狀態並嘗試自動登入
    func checkSavedAuthState() async {
        print("🔍 開始檢查已保存的認證狀態...")
        
        // 檢查 Google Sign-In 的自動登入
        if let googleUser = GIDSignIn.sharedInstance.currentUser {
            print("📱 找到 Google 用戶: \(googleUser.profile?.email ?? "unknown")")
            if let expirationDate = googleUser.accessToken.expirationDate {
                print("⏰ Google token 過期時間: \(expirationDate)")
                if expirationDate > Date() {
                    print("✅ Google token 仍然有效，嘗試自動登入...")
                    do {
                        let user = try await verifyGoogleToken(
                            idToken: googleUser.idToken?.tokenString ?? "",
                            accessToken: googleUser.accessToken.tokenString
                        )
                        currentUser = user
                        saveUserToKeychain(user)
                        print("✅ Google 自動登入成功: \(user.name)")
                        return
                    } catch {
                        print("❌ Google 自動登入失敗: \(error)")
                    }
                } else {
                    print("⚠️ Google token 已過期")
                }
            } else {
                print("⚠️ Google token 沒有過期時間")
            }
        } else {
            print("ℹ️ 沒有找到 Google 用戶")
        }
        
        // 檢查保存的用戶數據（不依賴於特定的登入提供商）
        if let savedUser = getSavedUserFromKeychain() {
            print("📦 找到保存的用戶數據: \(savedUser.name)")
            do {
                let validatedUser = try await validateSavedUser(savedUser)
                currentUser = validatedUser
                print("✅ 使用保存的用戶數據自動登入成功: \(validatedUser.name)")
                return
            } catch {
                print("⚠️ 保存的用戶信息無效，清除數據: \(error)")
                clearSavedUser()
            }
        } else {
            print("ℹ️ 沒有找到保存的用戶數據")
        }
        
        // 檢查 Apple Sign-In 的自動登入
        if let userIdentifier = getCurrentUserIdentifier() {
            print("🍎 找到 Apple 用戶標識符: \(userIdentifier)")
            do {
                let credentialState = try await ASAuthorizationAppleIDProvider().credentialState(forUserID: userIdentifier)
                print("🔐 Apple 憑證狀態: \(credentialState.rawValue)")
                if credentialState == .authorized {
                    print("✅ Apple 憑證仍然有效")
                } else {
                    print("⚠️ Apple 憑證已撤銷或不存在，清除保存的數據")
                    clearUserIdentifier()
                    clearSavedUser()
                }
            } catch {
                print("❌ Apple 憑證檢查失敗: \(error)")
            }
        } else {
            print("ℹ️ 沒有找到 Apple 用戶標識符")
        }
        
        print("ℹ️ 沒有找到有效的已保存登入狀態")
    }
    
    // MARK: - User Data Persistence
    
    /// 保存用戶信息到 keychain
    private func saveUserToKeychain(_ user: User) {
        print("💾 嘗試保存用戶信息到 keychain: \(user.name)")
        do {
            let userData = try JSONEncoder().encode(user)
            let keychainItem = KeychainItem(service: "com.viberanking.userdata", account: "currentUser")
            try keychainItem.saveItem(String(data: userData, encoding: .utf8) ?? "")
            print("✅ 用戶信息已成功保存到 keychain")
        } catch {
            print("❌ 保存用戶信息失敗: \(error)")
        }
    }
    
    /// 從 keychain 獲取保存的用戶信息
    private func getSavedUserFromKeychain() -> User? {
        print("🔍 嘗試從 keychain 獲取保存的用戶信息...")
        do {
            let keychainItem = KeychainItem(service: "com.viberanking.userdata", account: "currentUser")
            let userDataString = try keychainItem.readItem()
            guard let userData = userDataString.data(using: .utf8) else { 
                print("⚠️ 無法將用戶數據字符串轉換為 Data")
                return nil 
            }
            let user = try JSONDecoder().decode(User.self, from: userData)
            print("✅ 成功從 keychain 獲取用戶信息: \(user.name)")
            return user
        } catch KeychainItem.KeychainError.noPassword {
            print("ℹ️ keychain 中沒有保存的用戶信息")
            return nil
        } catch {
            print("❌ 獲取保存的用戶信息失敗: \(error)")
            return nil
        }
    }
    
    /// 清除保存的用戶信息
    private func clearSavedUser() {
        do {
            let keychainItem = KeychainItem(service: "com.viberanking.userdata", account: "currentUser")
            try keychainItem.deleteItem()
        } catch {
            print("❌ 清除用戶信息失敗: \(error)")
        }
    }
    
    /// 驗證保存的用戶信息是否仍然有效
    private func validateSavedUser(_ user: User) async throws -> User {
        // 這裡可以調用 API 來驗證用戶信息是否仍然有效
        // 暫時直接返回用戶，在實際應用中應該調用後端 API
        return user
    }
    
    // MARK: - Sign Out
    
    func signOut() async throws {
        if GIDSignIn.sharedInstance.currentUser != nil {
            GIDSignIn.sharedInstance.signOut()
        }

        clearUserIdentifier()
        clearSavedUser()

        // Delete JWT token from keychain
        try? KeychainItem.deleteJWTToken()

        currentUser = nil

        // Optional API notification
        try? await authAPI.signOut()
    }
    
    // MARK: - Helpers
    
    private func randomNonceString(length: Int = 32) -> String {
        var randomBytes = [UInt8](repeating: 0, count: length)
        SecRandomCopyBytes(kSecRandomDefault, randomBytes.count, &randomBytes)
        
        let charset: [Character] = Array("0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._")
        return String(randomBytes.map { charset[Int($0) % charset.count] })
    }
    
    private func sha256(_ input: String) -> String {
        let inputData = Data(input.utf8)
        let hashedData = SHA256.hash(data: inputData)
        return hashedData.compactMap { String(format: "%02x", $0) }.joined()
    }
    
    private func getGoogleClientID() -> String? {
        // First try to get from GoogleService-Info.plist
        if let path = Bundle.main.path(forResource: "GoogleService-Info", ofType: "plist"),
           let plist = NSDictionary(contentsOfFile: path),
           let clientID = plist["CLIENT_ID"] as? String {
            return clientID
        }
        
        // Fallback to Info.plist
        return Bundle.main.object(forInfoDictionaryKey: "GOOGLE_CLIENT_ID") as? String
    }
    
    private func convertAPIErrorToAppError(_ apiError: APIError) -> AppError {
        switch apiError {
        case .invalidURL:
            return .invalidURL
        case .invalidResponse:
            return .networkError(apiError)
        case .serverError(let statusCode):
            return .serverError(statusCode)
        case .decodingError(let error):
            return .apiError(error)
        }
    }
}

// MARK: - Extensions

extension AuthenticationService: ASAuthorizationControllerPresentationContextProviding {
    func presentationAnchor(for controller: ASAuthorizationController) -> ASPresentationAnchor {
        rootViewController?.view.window ?? ASPresentationAnchor()
    }
}

extension ASAuthorizationAppleIDProvider {
    func credentialState(forUserID userID: String) async throws -> ASAuthorizationAppleIDProvider.CredentialState {
        try await withCheckedThrowingContinuation { continuation in
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

