//
//  ProfileWeeklySection.swift
//  viberanking
//
//  Extracted from ProfileTabView to keep files concise.
//

import SwiftUI

// MARK: - Data Models (Profile weekly grid)
struct WeekData {
    let weekNumber: Int
    let days: [DayData]
}

struct DayData {
    let date: Date
    let dayNumber: Int
    let monthName: String
    let weekdayName: String
    let photoURLs: [String]
    var hasPhoto: Bool { !photoURLs.isEmpty }
}

// MARK: - Section and Cards
struct WeeklyPhotoSection: View {
    let week: WeekData
    let onPhotoTap: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(String(format: "profile.week".localized, week.weekNumber))
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.white)
                
                Spacer()
                
                Button(action: {
                    // More options
                }) {
                    Image(systemName: "ellipsis")
                        .font(.system(size: 16))
                        .foregroundColor(.gray)
                }
            }
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(Array(week.days.enumerated()), id: \.offset) { _, day in
                        // Show all photos; if none, show one empty slot
                        let totalSlots = max(1, day.photoURLs.count)
                        ForEach(0..<totalSlots, id: \.self) { slot in
                            DayPhotoCard(day: day, slotIndex: slot, onTap: onPhotoTap)
                        }
                    }
                }
                .padding(.horizontal, 4)
            }
        }
    }
}

struct DayPhotoCard: View {
    let day: DayData
    let slotIndex: Int
    let onTap: () -> Void
    @State private var isPressed = false
    
    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 8) {
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.gray.opacity(0.1))
                    .frame(width: 120, height: 160)
                    .overlay(
                        Group {
                            if slotIndex < day.photoURLs.count,
                               let urlString = day.photoURLs[safe: slotIndex],
                               let url = URL(string: urlString) {
                                AsyncImage(url: url) { phase in
                                    switch phase {
                                    case .empty:
                                        ProgressView().tint(.white)
                                            .frame(width: 120, height: 160)
                                    case .success(let image):
                                        image
                                            .resizable()
                                            .scaledToFill()
                                            .frame(width: 120, height: 160)
                                            .clipped()
                                    case .failure:
                                        Image(systemName: "photo")
                                            .foregroundColor(.gray)
                                            .frame(width: 120, height: 160)
                                    @unknown default:
                                        Color.clear
                                    }
                                }
                            } else {
                                // Empty slot - show add placeholder
                                VStack(spacing: 8) {
                                    Image(systemName: "plus.circle.dashed")
                                        .font(.system(size: 32))
                                        .foregroundColor(.gray.opacity(0.5))
                                    Text("profile.add_photo".localized)
                                        .font(.system(size: 12, weight: .medium))
                                        .foregroundColor(.gray.opacity(0.7))
                                }
                                .frame(width: 120, height: 160)
                            }
                        }
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(day.hasPhoto ? Color.white.opacity(0.2) : Color.gray.opacity(0.1), lineWidth: 1)
                    )
                
                VStack(spacing: 4) {
                    Text(day.monthName)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.gray)
                    Text("\(day.dayNumber)")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.white)
                    Text(day.weekdayName)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.gray)
                }
            }
        }
        .frame(width: 120)
        .scaleEffect(isPressed ? 0.95 : 1.0)
        .animation(.easeInOut(duration: 0.1), value: isPressed)
        .onLongPressGesture(minimumDuration: 0) { pressing in
            isPressed = pressing
        } perform: {
            // Long press action
        }
    }
}


