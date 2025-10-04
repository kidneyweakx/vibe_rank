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
            HStack(spacing: 8) {
                if let emoji = tag.emoji, !emoji.isEmpty { Text(emoji) }
                Text(tag.displayName)
                    .font(.system(size: 14, weight: .medium))
            }
            .foregroundColor(isSelected ? .black : .white)
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .background(isSelected ? Color.white : Color.white.opacity(0.15))
            .overlay(
                Capsule()
                    .stroke(Color.white.opacity(0.25), lineWidth: 1)
            )
            .clipShape(Capsule())
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


