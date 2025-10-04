//
//  ReportViews.swift
//  viberanking
//
//  Created by Kiro on 2025/07/25.
//

import SwiftUI

// MARK: - Report Views Index
// This file serves as an index for all report-related components

/*
 ReportViews 資料夾包含以下組件：
 
 1. ReportButton.swift - 右上角檢舉按鈕
 2. ReportSheetView.swift - 檢舉選單主視圖
 3. ReportOptionRow.swift - 檢舉選項行組件
 4. ReportType.swift - 檢舉類型枚舉
 5. ReportDetailView.swift - 檢舉詳情視圖
 
 使用方式：
 - 在需要檢舉功能的地方添加 ReportButton()
 - 按鈕會自動彈出檢舉選單
 - 選擇檢舉類型後會顯示詳情視圖
 - 支持匿名檢舉，保護用戶隱私
 */

// MARK: - Quick Access Extensions
extension View {
    /// Add report functionality to any view
    func withReportButton() -> some View {
        self.overlay(
            VStack {
                HStack {
                    Spacer()
                    ReportButton()
                        .padding(.trailing, 20)
                }
                .padding(.top, 60)
                Spacer()
            }
            .zIndex(1000)
        )
    }

    /// Add block user action to any view via a context menu when userId exists
    func withBlockUserContextMenu(userId: String?) -> some View {
        self.contextMenu {
            if let userId = userId {
                Button(role: .destructive) {
                    UserBlocklist.shared.add(userId)
                } label: {
                    Label("Block User", systemImage: "hand.raised.fill")
                }
            }
        }
    }
}
