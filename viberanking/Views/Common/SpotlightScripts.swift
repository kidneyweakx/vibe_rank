//
//  SpotlightScripts.swift
//  viberanking
//
//  Created by AI Assistant on 2025/08/29.
//

import SwiftUI

struct SpotlightStepModel {
    let id: String
    let title: String
    let message: String
    let cornerRadius: CGFloat
}

enum SpotlightScripts {
    static let mainSteps: [SpotlightStepModel] = [
        SpotlightStepModel(
            id: "tab_rating",
            title: "Vibe",
            message: "滑動、評價、感受別人的 vibe\n\n- ✅ 「V」 = 可以哦\n- ❌ 「X」= 不太行\n- 🔥 「火焰」= 很有 vibe\n\nSwipe. Judge. Feel the vibe\n\n- ✅ “V” = Looks good\n- ❌ “X” = Not it\n- 🔥 “Flame” = Big vibe energy",
            cornerRadius: 12
        ),
        SpotlightStepModel(
            id: "tab_trend",
            title: "Trend",
            message: "看看現在什麼 vibe 最火\n\nSee what’s trending on the vibe leaderboard",
            cornerRadius: 12
        ),
        SpotlightStepModel(
            id: "tab_plus",
            title: "+",
            message: "- 上傳一張照片，開啟你的 vibe 挑戰\n- One photo to start your vibe challenge",
            cornerRadius: 28
        ),
        SpotlightStepModel(
            id: "tab_journey",
            title: "Journey",
            message: "追蹤查看你的 vibe 成長曲線\n\nTrack your vibe growth over time and see your level-ups",
            cornerRadius: 12
        ),
        SpotlightStepModel(
            id: "tab_profile",
            title: "Profile",
            message: "- 上傳並記錄你的 vibe 照片與個人資訊\n- Upload and keep a record of your vibe photos & profile",
            cornerRadius: 12
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



