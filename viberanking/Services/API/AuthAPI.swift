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
    
    // MARK: - Guest Authentication

    func signInGuest(deviceId: String) async throws -> AuthResponse {
        let body = [
            "deviceId": deviceId
        ]
        return try await apiClient.performRequest(
            endpoint: "/api/auth/guest/signin",
            method: .POST,
            body: body,
            responseType: AuthResponse.self
        )
    }

    // MARK: - Google Authentication
    
    func verifyGoogleToken(idToken: String, accessToken: String) async throws -> AuthResponse {
        var body: [String: Any] = [
            "idToken": idToken,
            "token": idToken
        ]
        body["accessToken"] = accessToken
        return try await apiClient.performRequest(
            endpoint: "/api/auth/google",
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
    
    /// Complete onboarding with consolidated payload per OpenAPI (/api/user/onboard)
    func completeOnboarding(_ payload: OnboardingCompletePayload) async throws -> AuthResponse {
        let body = payload.toDictionary()
        return try await apiClient.performRequest(
            endpoint: "/api/user/onboard",
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
    let token: String?
    let success: Bool?
    let message: String?
    let needsOnboarding: Bool?
}

struct APIUser: Decodable {
    let id: String
    let email: String
    let name: String
    let avatar: String?
    let provider: String?
    let providerId: String?
    let onboardedAt: String?
    
    private enum CodingKeys: String, CodingKey {
        case id
        case email
        case name
        case avatar
        case profileImageURL
        case provider
        case providerId
        case onboardedAt
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        if let idString = try? container.decode(String.self, forKey: .id) {
            id = idString
        } else if let idInt = try? container.decode(Int.self, forKey: .id) {
            id = String(idInt)
        } else if let idDouble = try? container.decode(Double.self, forKey: .id) {
            id = String(idDouble)
        } else {
            throw DecodingError.typeMismatch(
                String.self,
                DecodingError.Context(
                    codingPath: decoder.codingPath,
                    debugDescription: "Unable to decode user id as string or number"
                )
            )
        }
        email = try container.decode(String.self, forKey: .email)
        name = try container.decode(String.self, forKey: .name)
        // Support both 'avatar' and 'profileImageURL' from backend
        if let avatarValue = try? container.decode(String.self, forKey: .avatar) {
            avatar = avatarValue
        } else {
            avatar = try? container.decode(String.self, forKey: .profileImageURL)
        }
        provider = try? container.decode(String.self, forKey: .provider)
        providerId = try? container.decode(String.self, forKey: .providerId)
        onboardedAt = try? container.decode(String.self, forKey: .onboardedAt)
    }
}
