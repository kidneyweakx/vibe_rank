//
//  AuthAPI.swift
//  viberanking
//
//  Created by Kiro on 2025/08/04.
//

import Foundation
import AuthenticationServices

/// API service for authentication-related requests
class AuthAPI {
    
    private let apiClient = APIClient.shared
    
    // MARK: - Google Authentication
    
    func verifyGoogleToken(idToken: String, accessToken: String) async throws -> AuthResponse {
        // Backend expects a single 'token' field containing the Google ID token
        let body = [
            "token": idToken
        ]
        return try await apiClient.performRequest(
            endpoint: "/api/auth/google",
            method: .POST,
            body: body,
            responseType: AuthResponse.self
        )
    }
    
    // MARK: - Test Authentication
    
    func testLogin(email: String, name: String) async throws -> AuthResponse {
        let body = [
            "email": email,
            "name": name
        ]
        return try await apiClient.performRequest(
            endpoint: "/api/auth/test",
            method: .POST,
            body: body,
            responseType: AuthResponse.self
        )
    }
    
    // MARK: - Apple Authentication
    
    func verifyAppleToken(
        idToken: String,
        nonce: String,
        userIdentifier: String,
        fullName: PersonNameComponents?,
        email: String?
    ) async throws -> AuthResponse {
        var body: [String: Any] = [
            "idToken": idToken,
            "nonce": nonce,
            "userIdentifier": userIdentifier
        ]
        if let email = email {
            body["email"] = email
        }
        if let fullName = fullName {
            let nameComponents = [
                "givenName": fullName.givenName,
                "familyName": fullName.familyName
            ].compactMapValues { $0 }
            if !nameComponents.isEmpty {
                body["fullName"] = nameComponents
            }
        }
        return try await apiClient.performRequest(
            endpoint: "/api/auth/apple/verify",
            method: .POST,
            body: body,
            responseType: AuthResponse.self
        )
    }
    
    // MARK: - Password Authentication
    
    func verifyPasswordCredential(username: String, password: String) async throws -> AuthResponse {
        let body = [
            "username": username,
            "password": password
        ]
        return try await apiClient.performRequest(
            endpoint: "/api/auth/password/verify",
            method: .POST,
            body: body,
            responseType: AuthResponse.self
        )
    }
    
    // MARK: - Profile Setup
    
    func createUserProfile(_ profileData: UserProfileData) async throws -> AuthResponse {
        // Ensure backend receives strings for all fields it validates as strings
        var body: [String: Any] = [
            "customUserID": profileData.customUserID,
            "displayName": profileData.displayName,
            "email": profileData.email,
            "authProvider": profileData.authProvider,
            "providerUserID": profileData.providerUserID,
            "gender": "other"
        ]
        // Only include optional profileImageURL if present and non-empty to avoid backend errors
        if let url = profileData.profileImageURL, !url.isEmpty {
            body["profileImageURL"] = url
        }
        return try await apiClient.performRequest(
            endpoint: "/api/auth/profile/create",
            method: .POST,
            body: body,
            responseType: AuthResponse.self
        )
    }

    // MARK: - Onboarding (Consolidated)
    
    /// Complete onboarding with consolidated payload per OpenAPI (/api/onboarding/complete)
    func completeOnboarding(_ payload: OnboardingCompletePayload) async throws -> AuthResponse {
        let body = payload.toDictionary()
        return try await apiClient.performRequest(
            endpoint: "/api/onboarding/complete",
            method: .POST,
            body: body,
            responseType: AuthResponse.self
        )
    }
    
    // MARK: - Sign Out
    
    func signOut() async throws {
        try await apiClient.performRequest(
            endpoint: "/api/auth/signout",
            method: .POST
        )
    }
}

// MARK: - Response Models

struct AuthResponse: Decodable {
    let user: APIUser
    let token: String
    let success: Bool?
    let message: String?
}

struct APIUser: Decodable {
    let id: String
    let email: String
    let name: String
    let avatar: String?
    let provider: String?
    
    private enum CodingKeys: String, CodingKey {
        case id
        case email
        case name
        case avatar
        case profileImageURL
        case provider
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        email = try container.decode(String.self, forKey: .email)
        name = try container.decode(String.self, forKey: .name)
        // Support both 'avatar' and 'profileImageURL' from backend
        if let avatarValue = try? container.decode(String.self, forKey: .avatar) {
            avatar = avatarValue
        } else {
            avatar = try? container.decode(String.self, forKey: .profileImageURL)
        }
        provider = try? container.decode(String.self, forKey: .provider)
    }
}
