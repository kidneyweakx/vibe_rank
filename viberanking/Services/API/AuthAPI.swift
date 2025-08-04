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
        let body = [
            "idToken": idToken,
            "accessToken": accessToken
        ]
        
        return try await apiClient.performRequest(
            endpoint: "/auth/google/verify",
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
            endpoint: "/auth/apple/verify",
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
            endpoint: "/auth/password/verify",
            method: .POST,
            body: body,
            responseType: AuthResponse.self
        )
    }
    
    // MARK: - Sign Out
    
    func signOut() async throws {
        try await apiClient.performRequest(
            endpoint: "/auth/signout",
            method: .POST
        )
    }
}

// MARK: - Response Models

struct AuthResponse: Codable {
    let user: APIUser
    let token: String?
    
    struct APIUser: Codable {
        let id: String
        let name: String
        let email: String
        let profileImageURL: String?
    }
}