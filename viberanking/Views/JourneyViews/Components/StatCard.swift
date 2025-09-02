//
//  StatCard.swift
//  viberanking
//
//  Shared statistic card used across Journey views.
//

import SwiftUI

struct StatCards: View {
    let title: String
    let value: String
    let color: Color
    let icon: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(color)
                Spacer()
                Text(value)
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
            }
            
            Text(title)
                .font(.subheadline)
                .foregroundColor(.white)
        }
        .padding(16)
        .background(RoundedRectangle(cornerRadius: 16).fill(Color.gray.opacity(0.1)))
    }
}


