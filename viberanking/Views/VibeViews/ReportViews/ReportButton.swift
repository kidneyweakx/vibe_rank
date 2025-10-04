//
//  ReportButton.swift
//  viberanking
//
//  Created by Kiro on 2025/07/25.
//

import SwiftUI

struct ReportButton: View {
    /// Optional photo id to report. If nil, the sheet opens but submission will be disabled.
    var photoId: String? = nil
    /// Optional user id to enable Block User in the same sheet
    var userId: String? = nil

    @State private var showReportSheet = false
    
    var body: some View {
        Button {
            print("🔘 ReportButton: Button tapped")
            print("   - photoId: \(photoId ?? "nil")")
            showReportSheet = true
        } label: {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 18, weight: .medium))
                .foregroundColor(.white.opacity(0.9))
                .padding(.vertical, 10)
                .padding(.horizontal, 14)
                .background(
                    Capsule().fill(Color.white.opacity(0.08))
                        .overlay(Capsule().stroke(Color.white.opacity(0.15), lineWidth: 1))
                )
        }
        .buttonStyle(.plain)
        .contentShape(Rectangle())
        .sheet(isPresented: $showReportSheet) {
            ReportSheetView(photoId: photoId, userId: userId)
                .presentationDetents([.medium, .large])
                .presentationDragIndicator(.visible)
        }
        .onAppear {
            print("🔘 ReportButton: Appeared with photoId: \(photoId ?? "nil")")
        }
    }
}

#Preview {
    ReportButton(photoId: "demo-photo", userId: "user-123")
        .background(Color.black)
}
