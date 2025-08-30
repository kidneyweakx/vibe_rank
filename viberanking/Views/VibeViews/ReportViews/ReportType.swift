//
//  ReportType.swift
//  viberanking
//
//  Created by Kiro on 2025/07/25.
//

import SwiftUI

enum ReportType: CaseIterable {
    case fakeProfile
    case advertiser
    case fraud
    case explicitContent
    case profanity
    case harmfulMinors
    case cyberbullying
    
    var title: String {
        switch self {
        case .fakeProfile:
            return "Fake Profile Information/Photos"
        case .advertiser:
            return "Advertiser/Spam"
        case .fraud:
            return "Fraud"
        case .explicitContent:
            return "Explicit content"
        case .profanity:
            return "Profanity/Harassment"
        case .harmfulMinors:
            return "Harmful information involving minors"
        case .cyberbullying:
            return "Cyberbullying"
        }
    }
    
    var iconName: String {
        switch self {
        case .fakeProfile:
            return "person.crop.circle.badge.exclamationmark"
        case .advertiser:
            return "tag"
        case .fraud:
            return "person.crop.circle.badge.xmark"
        case .explicitContent:
            return "exclamationmark.triangle"
        case .profanity:
            return "text.bubble"
        case .harmfulMinors:
            return "leaf"
        case .cyberbullying:
            return "xmark.square"
        }
    }
    
    var iconColor: Color {
        switch self {
        case .fakeProfile:
            return .purple
        case .advertiser:
            return .blue
        case .fraud:
            return .gray
        case .explicitContent:
            return .pink
        case .profanity:
            return .orange
        case .harmfulMinors:
            return .green
        case .cyberbullying:
            return .blue
        }
    }
    
    var description: String {
        switch self {
        case .fakeProfile:
            return "Report fake or impersonating profiles, stolen photos, or misleading information"
        case .advertiser:
            return "Report spam, advertising, or promotional content"
        case .fraud:
            return "Report scams, fraud attempts, or deceptive behavior"
        case .explicitContent:
            return "Report inappropriate, explicit, or adult content"
        case .profanity:
            return "Report offensive language, harassment, or abusive behavior"
        case .harmfulMinors:
            return "Report content that could harm or exploit minors"
        case .cyberbullying:
            return "Report bullying, intimidation, or targeted harassment"
        }
    }
}
