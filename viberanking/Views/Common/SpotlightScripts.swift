//
//  SpotlightScripts.swift
//  viberanking
//
//  Created by AI Assistant on 2025/08/29.
//

import SwiftUI

struct SpotlightStepModel {
    let id: String
    let titleKey: String
    let messageKey: String
    let cornerRadius: CGFloat
    let position: SpotlightPosition
}

enum SpotlightPosition {
    case center
    case above
    case below
    case adaptive
}

enum SpotlightScripts {
    static let mainSteps: [SpotlightStepModel] = [
        SpotlightStepModel(
            id: "tab_rating",
            titleKey: "spotlight.vibe.title",
            messageKey: "spotlight.vibe.message",
            cornerRadius: 12,
            position: .center
        ),
        SpotlightStepModel(
            id: "tab_trend",
            titleKey: "spotlight.trend.title",
            messageKey: "spotlight.trend.message",
            cornerRadius: 12,
            position: .center
        ),
        SpotlightStepModel(
            id: "tab_plus",
            titleKey: "spotlight.plus.title",
            messageKey: "spotlight.plus.message",
            cornerRadius: 28,
            position: .center
        ),
        SpotlightStepModel(
            id: "tab_journey",
            titleKey: "spotlight.journey.title",
            messageKey: "spotlight.journey.message",
            cornerRadius: 12,
            position: .center
        ),
        SpotlightStepModel(
            id: "tab_profile",
            titleKey: "spotlight.profile.title",
            messageKey: "spotlight.profile.message",
            cornerRadius: 12,
            position: .center
        )
    ]

    static func pageStep(for tab: TabItem) -> SpotlightStepModel {
        switch tab {
        case .rating:
            return mainSteps[0]
        case .home:
            return mainSteps[1]
        case .journey:
            return mainSteps[3]
        case .profile:
            return mainSteps[4]
        }
    }

    static var plusStep: SpotlightStepModel { mainSteps[2] }
}



