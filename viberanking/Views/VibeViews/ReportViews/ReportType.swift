//
//  ReportType.swift
//  viberanking
//
//  Created by Kiro on 2025/07/25.
//

import SwiftUI

enum ReportType: String, CaseIterable {
    case inappropriate = "inappropriate"
    case spam = "spam"
    case harassment = "harassment"
    case nudity = "nudity"
    case violence = "violence"
    case other = "other"

    var title: String {
        switch self {
        case .inappropriate:
            return "Inappropriate Content"
        case .spam:
            return "Spam or Advertising"
        case .harassment:
            return "Harassment or Bullying"
        case .nudity:
            return "Nudity or Sexual Content"
        case .violence:
            return "Violence or Threats"
        case .other:
            return "Other"
        }
    }
    
    var iconName: String {
        switch self {
        case .inappropriate:
            return "exclamationmark.triangle"
        case .spam:
            return "tag"
        case .harassment:
            return "text.bubble"
        case .nudity:
            return "eye.slash"
        case .violence:
            return "exclamationmark.shield"
        case .other:
            return "ellipsis.circle"
        }
    }

    var iconColor: Color {
        switch self {
        case .inappropriate:
            return .orange
        case .spam:
            return .blue
        case .harassment:
            return .red
        case .nudity:
            return .pink
        case .violence:
            return .purple
        case .other:
            return .gray
        }
    }

    var description: String {
        switch self {
        case .inappropriate:
            return "Content that violates community guidelines"
        case .spam:
            return "Spam, advertising, or promotional content"
        case .harassment:
            return "Bullying, harassment, or abusive behavior"
        case .nudity:
            return "Inappropriate sexual or nudity content"
        case .violence:
            return "Violence, threats, or harmful content"
        case .other:
            return "Other issues not listed above"
        }
    }
}
