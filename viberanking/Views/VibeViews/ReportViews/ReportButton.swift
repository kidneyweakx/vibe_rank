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

    @State private var showReportSheet = false
    
    var body: some View {
        Button {
            print("🔘 ReportButton: Button tapped")
            print("   - photoId: \(photoId ?? "nil")")
            showReportSheet = true
        } label: {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 18, weight: .medium))
                .foregroundColor(.white.opacity(0.8))
        }
        .sheet(isPresented: $showReportSheet) {
            ReportSheetView(photoId: photoId)
        }
        .onAppear {
            print("🔘 ReportButton: Appeared with photoId: \(photoId ?? "nil")")
        }
    }
}

#Preview {
    ReportButton()
        .background(Color.black)
}
