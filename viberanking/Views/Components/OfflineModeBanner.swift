//
//  OfflineModeBanner.swift
//  viberanking
//
//  Created by Kiro on 2025/07/23.
//

import SwiftUI

/// Banner to show when the app is operating in offline mode
struct OfflineModeBanner: View {
    @Environment(\.colorScheme) private var colorScheme
    @State private var isVisible = true
    
    var body: some View {
        if isVisible {
            HStack(spacing: 8) {
                Image(systemName: "wifi.slash")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.orange)
                
                Text("離線模式 - 部分功能可能受限")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(colorScheme == .dark ? .white : .black)
                
                Spacer()
                
                Button(action: {
                    withAnimation(.easeOut(duration: 0.3)) {
                        isVisible = false
                    }
                }) {
                    Image(systemName: "xmark")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.secondary)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 0)
                    .fill(colorScheme == .dark ? Color.gray.opacity(0.2) : Color.orange.opacity(0.1))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 0)
                    .frame(height: 1),
                alignment: .bottom
            )
            .transition(.move(edge: .top).combined(with: .opacity))
        }
    }
}

// Color extension is already defined in other files

// MARK: - Preview
struct OfflineModeBanner_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            OfflineModeBanner()
                .preferredColorScheme(.light)
                .previewDisplayName("Light Mode")
            
            OfflineModeBanner()
                .preferredColorScheme(.dark)
                .previewDisplayName("Dark Mode")
        }
        .previewLayout(.sizeThatFits)
    }
}
