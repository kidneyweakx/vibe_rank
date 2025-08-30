//
//  ReportOptionRow.swift
//  viberanking
//
//  Created by Kiro on 2025/07/25.
//

import SwiftUI

struct ReportOptionRow: View {
    let reportType: ReportType
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button {
            onTap()
        } label: {
            HStack(spacing: 16) {
                // Icon
                Image(systemName: reportType.iconName)
                    .font(.system(size: 20))
                    .foregroundColor(reportType.iconColor)
                    .frame(width: 24, height: 24)
                
                // Title
                Text(reportType.title)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.white)
                
                Spacer()
                
                // Chevron
                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.white.opacity(0.5))
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isSelected ? Color.white.opacity(0.1) : Color.clear)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.white.opacity(0.1), lineWidth: 1)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

#Preview {
    VStack(spacing: 12) {
        ReportOptionRow(
            reportType: .fakeProfile,
            isSelected: false
        ) {}
        
        ReportOptionRow(
            reportType: .fakeProfile,
            isSelected: true
        ) {}
    }
    .padding()
    .background(Color.black)
}
