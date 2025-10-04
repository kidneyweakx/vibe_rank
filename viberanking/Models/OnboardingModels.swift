//
//  OnboardingModels.swift
//  viberanking
//
//  Created by AI Assistant on 2025/09/04.
//

import Foundation

// MARK: - Questionnaire Answers captured during onboarding
struct OnboardingAnswers: Codable {
    var ageRange: String?
    var gender: Gender?
    var vibeLevel: Int?
    var timeInvestmentHours: Int?
    var notificationsEnabled: Bool?
}

// MARK: - Onboarding Complete Payload (API contract)
struct OnboardingCompletePayload {
    struct Account: Codable {
        let customUserID: String?
        let displayName: String?
        let avatarUrl: String?
    }
    
    struct AuthInfo: Codable {
        let provider: String
        let providerUserID: String
        let email: String?
    }
    
    struct Demographics: Codable {
        let gender: String?
        let ageRange: String?
    }
    
    struct Questionnaire: Codable {
        let vibeLevel: Int?
        let timeInvestmentHours: Int?
        let notificationsEnabled: Bool?
    }
    
    struct Consent: Codable {
        let tosVersion: String?
        let privacyVersion: String?
        let acceptedAt: String?
    }
    
    struct ClientInfo: Codable {
        let locale: String?
        let timezone: String?
        let appVersion: String?
    }
    
    let account: Account?
    let auth: AuthInfo
    let demographics: Demographics?
    let questionnaire: Questionnaire?
    let consent: Consent?
    let client: ClientInfo?
}

// MARK: - Dictionary conversion for APIClient body
extension OnboardingCompletePayload {
    func toDictionary() -> [String: Any] {
        var dict: [String: Any] = [:]
        if let account = account, let data = try? JSONEncoder().encode(account),
           let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
            dict["account"] = json
        }
        if let data = try? JSONEncoder().encode(auth),
           let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
            dict["auth"] = json
        }
        if let demographics = demographics, let data = try? JSONEncoder().encode(demographics),
           let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
            dict["demographics"] = json
        }
        if let questionnaire = questionnaire, let data = try? JSONEncoder().encode(questionnaire),
           let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
            dict["questionnaire"] = json
        }
        if let consent = consent, let data = try? JSONEncoder().encode(consent),
           let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
            dict["consent"] = json
        }
        if let client = client, let data = try? JSONEncoder().encode(client),
           let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
            dict["client"] = json
        }
        return dict
    }
}


