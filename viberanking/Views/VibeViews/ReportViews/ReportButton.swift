//
//  ReportButton.swift
//  viberanking
//
//  Created by Kiro on 2025/07/25.
//

import SwiftUI

struct ReportButton: View {
    @State private var showReportSheet = false
    
    var body: some View {
        Button {
            showReportSheet = true
        } label: {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 18, weight: .medium))
                .foregroundColor(.white.opacity(0.8))
        }
        .sheet(isPresented: $showReportSheet) {
            ReportSheetView()
        }
    }
}

#Preview {
    ReportButton()
        .background(Color.black)
}
