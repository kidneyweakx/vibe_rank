//
//  TagChipView.swift
//  viberanking
//
//  Created by Assistant on 2025/08/10.
//

import SwiftUI

struct TagChipView: View {
    let tag: Tag
    let isSelected: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 6) {
                if let emoji = tag.emoji, !emoji.isEmpty {
                    Text(emoji)
                }
                Text(tag.displayName)
                    .font(.system(size: 14, weight: .medium))
            }
            .foregroundColor(isSelected ? .black : .white)
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(isSelected ? Color.white : Color.white.opacity(0.15))
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(Color.white.opacity(0.25), lineWidth: 1)
            )
            .cornerRadius(16)
        }
        .buttonStyle(.plain)
    }
}

struct TagChipView_Previews: PreviewProvider {
    static var previews: some View {
        ZStack { Color.black.ignoresSafeArea() }
            .overlay(
                TagChipView(tag: Tag(id: "1", name: "casual", displayName: "Casual", emoji: "😎", color: nil, category: "style"), isSelected: true, onTap: {})
                    .padding()
            )
    }
}


