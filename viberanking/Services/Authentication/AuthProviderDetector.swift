//
//  AuthProviderDetector.swift
//  viberanking
//
//  Created by Kiro on 2025/08/09.
//

import Foundation

enum AuthProviderType: String {
    case apple
    case google
    case guest
    case unknown
}

struct AuthProviderDetector {
    static func infer(fromEmail email: String?) -> AuthProviderType {
        guard let email = email?.lowercased() else { return .unknown }
        if email.contains("privaterelay.appleid.com") { return .apple }
        if email.hasSuffix("@gmail.com") { return .google }
        return .unknown
    }
}


