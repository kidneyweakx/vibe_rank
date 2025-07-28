//
//  ProfileTabView.swift
//  viberanking
//
//  Created by Kiro on 2025/07/25.
//

import SwiftUI

struct ProfileTabView: View {
    @EnvironmentObject private var authViewModel: AuthenticationViewModel
    @EnvironmentObject private var themeManager: ThemeManager
    @State private var showingImagePicker = false
    @State private var showingShareSheet = false
    @State private var showingLogoutAlert = false
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.black.ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Profile Header
                    profileHeader
                        .padding(.horizontal, 20)
                        .padding(.top, 20)
                    
                    // Weekly Photos ScrollView
                    weeklyPhotosScrollView
                        .padding(.top, 20)
                }
            }
            .navigationBarHidden(true)
        }
        .sheet(isPresented: $showingImagePicker) {
            // Image picker implementation
        }
        .sheet(isPresented: $showingShareSheet) {
            // Share sheet implementation
        }
        .alert("Sign Out", isPresented: $showingLogoutAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Sign Out", role: .destructive) {
                authViewModel.signOut()
            }
        } message: {
            Text("Are you sure you want to sign out?")
        }
    }
}

// MARK: - View Components
private extension ProfileTabView {
    
    var profileHeader: some View {
        VStack(spacing: 16) {
            // Top row: Name/Age/Location and Avatar
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(authViewModel.user?.name ?? "User")
                        .font(.system(size: 28, weight: .bold))
                        .foregroundColor(.white)
                    
                    Text(authViewModel.isGuest ? "Guest User" : "Member")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.gray)
                }
                
                Spacer()
                
                Button(action: {
                    showingImagePicker = true
                }) {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [Color.pink.opacity(0.8), Color.purple.opacity(0.6)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 60, height: 60)
                        .overlay(
                            Group {
                                if let profileImageURL = authViewModel.user?.profileImageURL,
                                   let url = URL(string: profileImageURL) {
                                    AsyncImage(url: url) { image in
                                        image
                                            .resizable()
                                            .aspectRatio(contentMode: .fill)
                                    } placeholder: {
                                        Image(systemName: "person.fill")
                                            .font(.system(size: 24))
                                            .foregroundColor(.white)
                                    }
                                    .clipShape(Circle())
                                } else {
                                    Image(systemName: "person.fill")
                                        .font(.system(size: 24))
                                        .foregroundColor(.white)
                                }
                            }
                        )
                }
            }
            
            // Middle row: Stats
            HStack(spacing: 20) {
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 8) {
                        Image(systemName: "calendar")
                            .font(.system(size: 14))
                            .foregroundColor(.gray)
                        
                        Text("Weeks posted: 3")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.white)
                    }
                    
                    HStack(spacing: 8) {
                        Image(systemName: "location")
                            .font(.system(size: 14))
                            .foregroundColor(.gray)
                        
                        Text("Homebase: space")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.white)
                    }
                }
                
                Spacer()
                
                HStack(spacing: 12) {
                    Button(action: {
                        // Settings action
                    }) {
                        Image(systemName: "gearshape.fill")
                            .font(.system(size: 20))
                            .foregroundColor(.white)
                            .frame(width: 40, height: 40)
                            .background(
                                Circle()
                                    .fill(Color.white.opacity(0.1))
                            )
                    }
                    
                    Button(action: {
                        showingShareSheet = true
                    }) {
                        Image(systemName: "square.and.arrow.up")
                            .font(.system(size: 20))
                            .foregroundColor(.white)
                            .frame(width: 40, height: 40)
                            .background(
                                Circle()
                                    .fill(Color.white.opacity(0.1))
                            )
                    }
                }
            }
            
            // Bottom row: Action buttons
            HStack(spacing: 12) {
                Button("Recaps") {
                    // Recaps action
                }
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 44)
                .background(
                    RoundedRectangle(cornerRadius: 22)
                        .stroke(Color.white.opacity(0.3), lineWidth: 1)
                )
                
                Button("Share Profile") {
                    showingShareSheet = true
                }
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 44)
                .background(
                    RoundedRectangle(cornerRadius: 22)
                        .stroke(Color.white.opacity(0.3), lineWidth: 1)
                )
                
                Button("Sign Out") {
                    showingLogoutAlert = true
                }
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.red)
                .frame(maxWidth: .infinity)
                .frame(height: 44)
                .background(
                    RoundedRectangle(cornerRadius: 22)
                        .stroke(Color.red.opacity(0.5), lineWidth: 1)
                )
            }
        }
    }
    
    var weeklyPhotosScrollView: some View {
        ScrollView {
            LazyVStack(spacing: 20) {
                ForEach(getRecentWeeks(), id: \.weekNumber) { week in
                    WeeklyPhotoSection(week: week)
                }
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 100)
        }
    }
    
    func getRecentWeeks() -> [WeekData] {
        let calendar = Calendar.current
        let today = Date()
        var weeks: [WeekData] = []
        
        for i in 0..<5 {
            let weekStart = calendar.date(byAdding: .weekOfYear, value: -i, to: today) ?? today
            let weekNumber = calendar.component(.weekOfYear, from: weekStart)
            
            var days: [DayData] = []
            for j in 0..<7 {
                if let dayDate = calendar.date(byAdding: .day, value: j, to: weekStart) {
                    let dayNumber = calendar.component(.day, from: dayDate)
                    let monthName = DateFormatter().shortMonthSymbols[calendar.component(.month, from: dayDate) - 1]
                    let weekdayName = DateFormatter().shortWeekdaySymbols[calendar.component(.weekday, from: dayDate) - 1]
                    
                    days.append(DayData(
                        date: dayDate,
                        dayNumber: dayNumber,
                        monthName: monthName,
                        weekdayName: weekdayName,
                        hasPhoto: Bool.random() // Random for demo
                    ))
                }
            }
            
            weeks.append(WeekData(weekNumber: weekNumber, days: days))
        }
        
        return weeks
    }
    

}

// MARK: - Data Models
struct WeekData {
    let weekNumber: Int
    let days: [DayData]
}

struct DayData {
    let date: Date
    let dayNumber: Int
    let monthName: String
    let weekdayName: String
    let hasPhoto: Bool
}

// MARK: - Supporting Views
struct WeeklyPhotoSection: View {
    let week: WeekData
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Week \(week.weekNumber)")
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
            
            HStack(spacing: 8) {
                ForEach(Array(week.days.enumerated()), id: \.offset) { index, day in
                    DayPhotoCard(day: day)
                }
            }
        }
    }
}

struct DayPhotoCard: View {
    let day: DayData
    
    var body: some View {
        VStack(spacing: 4) {
            RoundedRectangle(cornerRadius: 8)
                .fill(day.hasPhoto ? Color.gray.opacity(0.3) : Color.gray.opacity(0.1))
                .frame(height: 80)
                .overlay(
                    Group {
                        if day.hasPhoto {
                            Image(systemName: "photo.fill")
                                .font(.system(size: 20))
                                .foregroundColor(.gray)
                        }
                    }
                )
            
            VStack(spacing: 2) {
                Text(day.monthName)
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(.gray)
                
                Text("\(day.dayNumber)")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.white)
                
                Text(day.weekdayName)
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(.gray)
            }
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Supporting Views


#Preview {
    ProfileTabView()
        .environmentObject(AuthenticationViewModel())
        .environmentObject(ThemeManager())
}
