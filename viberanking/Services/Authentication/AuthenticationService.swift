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

class AuthenticationService: NSObject, AuthenticationServiceProtocol, ASAuthorizationControllerDelegate {
    
    // MARK: - Properties
    
    private var currentNonce: String?
    private var appleSignInCompletion: ((Result<User, Error>) -> Void)?
    
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
        guard let clientID = FirebaseApp.app()?.options.clientID else {
            throw AppError.authenticationFailed
        }
        
        let config = GIDConfiguration(clientID: clientID)
        GIDSignIn.sharedInstance.configuration = config
        
        guard let windowScene = await UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let window = await windowScene.windows.first,
              let rootViewController = await window.rootViewController else {
            throw AppError.authenticationFailed
        }
        
        let gidSignInResult = try await GIDSignIn.sharedInstance.signIn(withPresenting: rootViewController)
        
        guard let idToken = gidSignInResult.user.idToken?.tokenString else {
            throw AppError.authenticationFailed
        }
        
        let credential = GoogleAuthProvider.credential(withIDToken: idToken,
                                                         accessToken: gidSignInResult.user.accessToken.tokenString)
        
        let authResult = try await Auth.auth().signIn(with: credential)
        let firebaseUser = authResult.user
        
        return User(id: firebaseUser.uid,
                    name: firebaseUser.displayName ?? "Unknown",
                    email: firebaseUser.email ?? "no-email@example.com",
                    profileImageURL: firebaseUser.photoURL?.absoluteString)
    }
    
    // MARK: - Apple Sign-In
    
    func signInWithApple() async throws -> User {
        return try await withCheckedThrowingContinuation { continuation in
            self.appleSignInCompletion = { result in
                switch result {
                case .success(let user):
                    continuation.resume(returning: user)
                case .failure(let error):
                    continuation.resume(throwing: error)
                }
            }
            
            let nonce = randomNonceString()
            currentNonce = nonce
            
            let appleIDProvider = ASAuthorizationAppleIDProvider()
            let request = appleIDProvider.createRequest()
            request.requestedScopes = [.fullName, .email]
            request.nonce = sha256(nonce)
            
            let controller = ASAuthorizationController(authorizationRequests: [request])
            controller.delegate = self
            controller.performRequests()
        }
    }
    
    func authorizationController(controller: ASAuthorizationController, didCompleteWithAuthorization authorization: ASAuthorization) {
        guard let appleIDCredential = authorization.credential as? ASAuthorizationAppleIDCredential,
              let nonce = currentNonce,
              let appleIDToken = appleIDCredential.identityToken,
              let idTokenString = String(data: appleIDToken, encoding: .utf8) else {
            appleSignInCompletion?(.failure(AppError.authenticationFailed))
            return
        }
        
        let credential = OAuthProvider.appleCredential(withIDToken: idTokenString,
                                                         rawNonce: nonce,
                                                         fullName: appleIDCredential.fullName)
        
        Auth.auth().signIn(with: credential) { [weak self] (authResult, error) in
            if let error = error {
                self?.appleSignInCompletion?(.failure(error))
                return
            }
            
            guard let authResult = authResult else {
                self?.appleSignInCompletion?(.failure(AppError.authenticationFailed))
                return
            }
            
            let firebaseUser = authResult.user
            let user = User(id: firebaseUser.uid,
                            name: firebaseUser.displayName ?? (appleIDCredential.fullName?.givenName ?? "Unknown"),
                            email: firebaseUser.email ?? "no-email@example.com",
                            profileImageURL: firebaseUser.photoURL?.absoluteString)
            
            self?.appleSignInCompletion?(.success(user))
        }
    }
    
    func authorizationController(controller: ASAuthorizationController, didCompleteWithError error: Error) {
        appleSignInCompletion?(.failure(error))
    }
    
    // MARK: - Sign Out
    
    func signOut() async throws {
        let firebaseAuth = Auth.auth()
        do {
            try firebaseAuth.signOut()
        } catch let signOutError as NSError {
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
