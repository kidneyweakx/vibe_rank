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
class AuthenticationService: NSObject, ObservableObject, AuthenticationServiceProtocol, ASAuthorizationControllerDelegate {
    
    @Published var currentUser: User?
    
    private var currentNonce: String?
    private var appleSignInCompletion: ((Result<User, Error>) -> Void)?
    private let authAPI = AuthAPI()
    
    var isAuthenticated: Bool { currentUser != nil }
    
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
            
            let user = try await verifyGoogleToken(
                idToken: idToken,
                accessToken: result.user.accessToken.tokenString
            )
            
            currentUser = user
            return user
            
        } catch let error as NSError where error.domain == "com.google.GIDSignIn" {
            switch error.code {
            case -2: throw AppError.validationError("用戶取消了登入")
            case -4: throw AppError.networkError(error)
            case -5: throw AppError.validationError("Keychain 錯誤，請重試")
            default: throw AppError.validationError("Google 登入失敗：\(error.localizedDescription)")
            }
        }
    }
    
    private func getGoogleClientID() -> String? {
        return Bundle.main.object(forInfoDictionaryKey: "GOOGLE_CLIENT_ID") as? String
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
                    
                    user = try await verifyAppleToken(
                        idToken: idTokenString,
                        nonce: nonce,
                        userIdentifier: appleIDCredential.user,
                        fullName: appleIDCredential.fullName,
                        email: appleIDCredential.email
                    )
                    
                case let passwordCredential as ASPasswordCredential:
                    user = try await verifyPasswordCredential(
                        username: passwordCredential.user,
                        password: passwordCredential.password
                    )
                    
                default:
                    throw AppError.validationError("未知的憑證類型")
                }
                
                currentUser = user
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
        let response = try await authAPI.verifyGoogleToken(idToken: idToken, accessToken: accessToken)
        return User(
            id: response.user.id,
            name: response.user.name,
            email: response.user.email,
            profileImageURL: response.user.profileImageURL
        )
    }
    
    private func verifyAppleToken(idToken: String, nonce: String, userIdentifier: String, fullName: PersonNameComponents?, email: String?) async throws -> User {
        let response = try await authAPI.verifyAppleToken(
            idToken: idToken,
            nonce: nonce,
            userIdentifier: userIdentifier,
            fullName: fullName,
            email: email
        )
        return User(
            id: response.user.id,
            name: response.user.name,
            email: response.user.email,
            profileImageURL: response.user.profileImageURL
        )
    }
    
    private func verifyPasswordCredential(username: String, password: String) async throws -> User {
        let response = try await authAPI.verifyPasswordCredential(username: username, password: password)
        return User(
            id: response.user.id,
            name: response.user.name,
            email: response.user.email,
            profileImageURL: response.user.profileImageURL
        )
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
    
    // MARK: - Sign Out
    
    func signOut() async throws {
        if GIDSignIn.sharedInstance.currentUser != nil {
            GIDSignIn.sharedInstance.signOut()
        }
        
        clearUserIdentifier()
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

