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
import UIKit

import Combine

@MainActor
class AuthenticationService: NSObject, ObservableObject, ASAuthorizationControllerDelegate {
    
    @Published var currentUser: User?
    
    private var currentNonce: String?
    private var appleSignInCompletion: ((Result<User, Error>) -> Void)?
    private let authAPI = AuthAPI()
    private let userAPI = UserAPI()
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
            
            let fallbackAvatar = result.user.profile?.imageURL(withDimension: 200)?.absoluteString
            return try await verifyGoogleToken(
                idToken: idToken,
                accessToken: result.user.accessToken.tokenString,
                fallbackName: result.user.profile?.name,
                fallbackEmail: result.user.profile?.email,
                fallbackAvatarURL: fallbackAvatar,
                providerUserID: result.user.userID
            )
            
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
        
        return try await withCheckedThrowingContinuation { continuation in
            appleSignInCompletion = { result in
                continuation.resume(with: result)
            }
            DispatchQueue.main.async {
                controller.performRequests()
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
                    
                    let displayName = [appleIDCredential.fullName?.givenName, appleIDCredential.fullName?.familyName]
                        .compactMap { $0 }
                        .joined(separator: " ")
                        .trimmingCharacters(in: .whitespacesAndNewlines)

                    let preservedName = self.currentUser?.name ?? self.getSavedUserFromKeychain()?.name ?? ""
                    let fallbackDisplayName = displayName.isEmpty ? preservedName : displayName

                    user = try await verifyAppleToken(
                        idToken: idTokenString,
                        nonce: nonce,
                        userIdentifier: appleIDCredential.user,
                        fullName: appleIDCredential.fullName,
                        email: appleIDCredential.email,
                        fallbackDisplayName: fallbackDisplayName.isEmpty ? nil : fallbackDisplayName
                    )
                    
                case let passwordCredential as ASPasswordCredential:
                    user = try await verifyPasswordCredential(
                        username: passwordCredential.user,
                        password: passwordCredential.password
                    )
                    
                default:
                    throw AppError.validationError("未知的憑證類型")
                }
                
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
    
    private func verifyGoogleToken(
        idToken: String,
        accessToken: String,
        fallbackName: String?,
        fallbackEmail: String?,
        fallbackAvatarURL: String?,
        providerUserID: String?
    ) async throws -> User {
        do {
            let response = try await authAPI.verifyGoogleToken(idToken: idToken, accessToken: accessToken)
            let providerIdentifier = response.user.providerId ?? providerUserID ?? response.user.id

            return try processAuthResponse(
                response,
                fallbackName: fallbackName,
                fallbackEmail: fallbackEmail ?? response.user.email,
                fallbackAvatar: fallbackAvatarURL,
                authProvider: "google",
                providerUserID: providerIdentifier
            )
        } catch let apiError as APIError {
            throw convertAPIErrorToAppError(apiError)
        }
    }
    
    private func verifyAppleToken(
        idToken: String,
        nonce: String,
        userIdentifier: String,
        fullName: PersonNameComponents?,
        email: String?,
        fallbackDisplayName: String?
    ) async throws -> User {
        do {
            let response = try await authAPI.verifyAppleToken(
                idToken: idToken,
                nonce: nonce,
                userIdentifier: userIdentifier,
                fullName: fullName,
                email: email
            )

            let combinedName = [fullName?.givenName, fullName?.familyName]
                .compactMap { $0 }
                .joined(separator: " ")
                .trimmingCharacters(in: .whitespacesAndNewlines)

            let fallbackName = combinedName.isEmpty ? fallbackDisplayName : combinedName
            let providerIdentifier = response.user.providerId ?? userIdentifier

            return try processAuthResponse(
                response,
                fallbackName: fallbackName ?? response.user.name,
                fallbackEmail: email ?? response.user.email,
                fallbackAvatar: nil,
                authProvider: "apple",
                providerUserID: providerIdentifier
            )
        } catch let apiError as APIError {
            throw convertAPIErrorToAppError(apiError)
        }
    }
    
    private func verifyPasswordCredential(username: String, password: String) async throws -> User {
        do {
            let response = try await authAPI.verifyPasswordCredential(username: username, password: password)
            let providerIdentifier = response.user.providerId ?? username

            return try processAuthResponse(
                response,
                fallbackName: response.user.name,
                fallbackEmail: response.user.email.isEmpty ? username : response.user.email,
                fallbackAvatar: nil,
                authProvider: "password",
                providerUserID: providerIdentifier
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

    func signInAsGuest() async throws -> User {
        print("👤 開始訪客登入...")
        let storedDeviceId = KeychainItem.readGuestDeviceIdentifier()
        let deviceId: String
        if let existing = storedDeviceId {
            deviceId = existing
        } else {
            let generated = UUID().uuidString
            deviceId = generated
            try? KeychainItem.saveGuestDeviceIdentifier(generated)
        }

        do {
            let response = try await authAPI.signInGuest(deviceId: deviceId)
            let providerIdentifier = response.user.providerId ?? deviceId
            let fallbackName = response.user.name.isEmpty ? "Guest User" : response.user.name
            let guestUser = try processAuthResponse(
                response,
                fallbackName: fallbackName,
                fallbackEmail: response.user.email.isEmpty ? "guest@guest.local" : response.user.email,
                fallbackAvatar: nil,
                authProvider: "guest",
                providerUserID: providerIdentifier
            )
            print("✅ 訪客登入成功: \(guestUser.name)")
            return guestUser
        } catch let appError as AppError {
            if case .needsOnboarding = appError {
                print("ℹ️ 訪客登入完成，需進行引導流程")
                throw appError
            }
            print("❌ 訪客登入失敗: \(appError.localizedDescription)")
        } catch let apiError as APIError {
            let converted = convertAPIErrorToAppError(apiError)
            print("❌ 訪客登入失敗: \(converted.localizedDescription)")
        } catch {
            print("❌ 訪客登入失敗: \(error.localizedDescription)")
            let fallbackId = "guest_\(UUID().uuidString)"
            let fallbackUser = User(
                id: fallbackId,
                name: "Guest_\(String(fallbackId.suffix(8)))",
                email: "guest\(String(fallbackId.suffix(8)))@example.com"
            )
            currentUser = fallbackUser
            return fallbackUser
        }
        let fallbackId = "guest_\(UUID().uuidString)"
        let fallbackUser = User(
            id: fallbackId,
            name: "Guest_\(String(fallbackId.suffix(8)))",
            email: "guest\(String(fallbackId.suffix(8)))@example.com"
        )
        pendingUserData = nil
        currentUser = fallbackUser
        return fallbackUser
    }
    
    private func processAuthResponse(
        _ response: AuthResponse,
        fallbackName: String?,
        fallbackEmail: String?,
        fallbackAvatar: String?,
        authProvider: String,
        providerUserID: String,
        overrideOnboarded: Bool = false
    ) throws -> User {
        if let token = response.token {
            try? KeychainItem.saveJWTToken(token)
        }

        let apiUser = response.user
        let trimmedName = apiUser.name.trimmingCharacters(in: .whitespacesAndNewlines)
        let fallbackResolvedName = fallbackName?.trimmingCharacters(in: .whitespacesAndNewlines)
        let resolvedName = trimmedName.isEmpty ? (fallbackResolvedName ?? "") : trimmedName
        let resolvedEmail = apiUser.email.isEmpty ? (fallbackEmail ?? "") : apiUser.email
        let resolvedAvatar = apiUser.avatar ?? fallbackAvatar

        var onboardedAtDate: Date? = nil
        if let onboardedAtString = apiUser.onboardedAt, !onboardedAtString.isEmpty {
            let formatterWithFraction = ISO8601DateFormatter()
            formatterWithFraction.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
            onboardedAtDate = formatterWithFraction.date(from: onboardedAtString) ?? ISO8601DateFormatter().date(from: onboardedAtString)
        }

        let defaultName = resolvedName.isEmpty ? (fallbackResolvedName ?? "") : resolvedName
        let finalName = defaultName.isEmpty ? "\(authProvider.capitalized) User" : defaultName

        let user = User(
            id: apiUser.id,
            name: finalName,
            email: resolvedEmail,
            profileImageURL: resolvedAvatar,
            onboardedAt: onboardedAtDate
        )

        let requiresOnboarding: Bool
        if overrideOnboarded {
            requiresOnboarding = false
        } else if let explicit = response.needsOnboarding {
            requiresOnboarding = explicit
        } else {
            requiresOnboarding = onboardedAtDate == nil
        }

        if requiresOnboarding {
            pendingUserData = InitialUserData(
                name: finalName,
                email: user.email,
                profileImageURL: user.profileImageURL,
                authProvider: authProvider,
                providerUserID: providerUserID
            )
            currentUser = nil
            throw AppError.needsOnboarding
        }

        pendingUserData = nil
        currentUser = user
        saveUserToKeychain(user)
        return user
    }

    // MARK: - Profile Setup
    
    func getPendingUserData() -> InitialUserData? {
        return pendingUserData
    }
    
    func completeProfileSetup(_ profileData: UserProfileData) async throws -> User {
        do {
            let response = try await authAPI.createUserProfile(profileData)
            let user = try processAuthResponse(
                response,
                fallbackName: profileData.displayName,
                fallbackEmail: profileData.email,
                fallbackAvatar: profileData.profileImageURL,
                authProvider: profileData.authProvider,
                providerUserID: profileData.providerUserID,
                overrideOnboarded: true
            )
            pendingUserData = nil
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
                    saveUserToKeychain(user)
                    pendingUserData = nil
                    return user
                } catch let fallbackError as APIError {
                    throw convertAPIErrorToAppError(fallbackError)
                } catch {
                    throw AppError.apiError(error)
                }
            }
            throw convertAPIErrorToAppError(apiError)
        } catch {
            throw error
        }
    }
    
    /// Complete onboarding with consolidated payload
    func completeOnboarding(_ payload: OnboardingCompletePayload) async throws -> User {
        do {
            let response = try await authAPI.completeOnboarding(payload)
            let displayName = payload.account?.displayName
            let avatarUrl = payload.account?.avatarUrl
            let user = try processAuthResponse(
                response,
                fallbackName: displayName,
                fallbackEmail: payload.auth.email ?? response.user.email,
                fallbackAvatar: avatarUrl,
                authProvider: payload.auth.provider,
                providerUserID: payload.auth.providerUserID,
                overrideOnboarded: true
            )
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
                        let fallbackAvatar = googleUser.profile?.imageURL(withDimension: 200)?.absoluteString
                        let user = try await verifyGoogleToken(
                            idToken: googleUser.idToken?.tokenString ?? "",
                            accessToken: googleUser.accessToken.tokenString,
                            fallbackName: googleUser.profile?.name,
                            fallbackEmail: googleUser.profile?.email,
                            fallbackAvatarURL: fallbackAvatar,
                            providerUserID: googleUser.userID
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
                saveUserToKeychain(validatedUser)
                print("✅ 使用保存的用戶數據自動登入成功: \(validatedUser.name)")
                return
            } catch let appError as AppError {
                print("⚠️ 保存的用戶信息無效，清除數據: \(appError)")
                clearSavedUser()
                try? KeychainItem.deleteJWTToken()
                if case .userNotFound = appError {
                    NotificationCenter.default.post(name: .userSessionExpired, object: nil)
                }
            } catch {
                print("⚠️ 保存的用戶信息無效，清除數據: \(error)")
                clearSavedUser()
                try? KeychainItem.deleteJWTToken()
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
        do {
            let response = try await userAPI.getUserProfile(userId: user.id)
            let profile = response.data
            let mappedGender = profile.gender.flatMap { Gender(rawValue: $0) }
            var validatedUser = User(
                id: profile.id,
                name: profile.name,
                email: profile.email,
                profileImageURL: profile.avatar,
                gender: mappedGender
            )
            validatedUser.ratingProgress = user.ratingProgress
            validatedUser.uploadedPhotos = user.uploadedPhotos
            validatedUser.lastActivityAt = user.lastActivityAt
            return validatedUser
        } catch let apiError as APIError {
            if case .serverError(let statusCode) = apiError, statusCode == 404 {
                throw AppError.userNotFound
            }
            throw AppError.apiError(apiError)
        } catch {
            throw AppError.apiError(error)
        }
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

