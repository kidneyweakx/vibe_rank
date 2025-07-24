//
//  UploadProgressView.swift
//  viberanking
//
//  Created by Kiro on 2025/07/23.
//

import SwiftUI

// MARK: - Upload Progress View
struct UploadProgressView: View {
    
    // MARK: - Properties
    let photoId: String
    let currentRatings: Int
    let requiredRatings: Int
    let onDismiss: () -> Void
    
    // MARK: - Computed Properties
    private var progressPercentage: Double {
        return min(Double(currentRatings) / Double(requiredRatings), 1.0)
    }
    
    private var remainingRatings: Int {
        return max(requiredRatings - currentRatings, 0)
    }
    
    private var isCompleted: Bool {
        return currentRatings >= requiredRatings
    }
    
    // MARK: - Body
    var body: some View {
        NavigationStack {
            ZStack {
                // Background
                Color(.systemGroupedBackground)
                    .ignoresSafeArea()
                
                // Content
                ScrollView {
                    VStack(spacing: 24) {
                        headerSection
                        progressSection
                        statusSection
                        actionSection
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 16)
                }
            }
            .navigationTitle("評分進度")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("完成") {
                        onDismiss()
                    }
                }
            }
        }
    }
}

// MARK: - View Components
private extension UploadProgressView {
    
    /// Header section with photo status
    var headerSection: some View {
        VStack(spacing: 12) {
            Image(systemName: isCompleted ? "checkmark.circle.fill" : "clock.fill")
                .font(.system(size: 48))
                .foregroundColor(isCompleted ? .green : .blue)
            
            Text(isCompleted ? "報告已解鎖！" : "等待評分中")
                .font(.title2)
                .fontWeight(.bold)
            
            Text(isCompleted ? 
                 "恭喜！你的照片已獲得足夠評分，風格報告已解鎖" :
                 "你的照片正在接受其他用戶評分，請耐心等待")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(.vertical, 8)
    }
    
    /// Progress section with visual indicator
    var progressSection: some View {
        VStack(spacing: 16) {
            // Progress ring or bar
            ZStack {
                // Background circle
                Circle()
                    .stroke(Color(.systemGray5), lineWidth: 8)
                    .frame(width: 120, height: 120)
                
                // Progress circle
                Circle()
                    .trim(from: 0, to: progressPercentage)
                    .stroke(
                        isCompleted ? Color.green : Color.blue,
                        style: StrokeStyle(lineWidth: 8, lineCap: .round)
                    )
                    .frame(width: 120, height: 120)
                    .rotationEffect(.degrees(-90))
                    .animation(.easeInOut(duration: 0.5), value: progressPercentage)
                
                // Progress text
                VStack(spacing: 4) {
                    Text("\(currentRatings)")
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)
                    
                    Text("/ \(requiredRatings)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            // Progress percentage
            Text("\(Int(progressPercentage * 100))% 完成")
                .font(.headline)
                .foregroundColor(.primary)
        }
        .padding(.vertical, 8)
    }
    
    /// Status information section
    var statusSection: some View {
        VStack(spacing: 16) {
            // Status cards
            HStack(spacing: 12) {
                statusCard(
                    icon: "person.2.fill",
                    title: "已評分",
                    value: "\(currentRatings)",
                    color: .blue
                )
                
                statusCard(
                    icon: "clock.fill",
                    title: "剩餘",
                    value: "\(remainingRatings)",
                    color: .orange
                )
            }
            
            // Photo ID info
            photoInfoSection
        }
    }
    
    /// Individual status card
    func statusCard(icon: String, title: String, value: String, color: Color) -> some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)
            
            Text(value)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.primary)
            
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(radius: 2)
    }
    
    /// Photo information section
    var photoInfoSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "info.circle.fill")
                    .foregroundColor(.blue)
                Text("照片資訊")
                    .font(.headline)
                    .foregroundColor(.primary)
                Spacer()
            }
            
            VStack(alignment: .leading, spacing: 8) {
                infoRow(
                    label: "照片ID",
                    value: String(photoId.prefix(8)) + "..."
                )
                
                infoRow(
                    label: "上傳時間",
                    value: DateFormatter.localizedString(from: Date(), dateStyle: .short, timeStyle: .short)
                )
                
                infoRow(
                    label: "狀態",
                    value: isCompleted ? "已完成" : "評分中"
                )
            }
        }
        .padding(16)
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(12)
    }
    
    /// Individual info row
    func infoRow(label: String, value: String) -> some View {
        HStack {
            Text(label + ":")
                .font(.caption)
                .foregroundColor(.secondary)
                .frame(width: 80, alignment: .leading)
            
            Text(value)
                .font(.caption)
                .foregroundColor(.primary)
            
            Spacer()
        }
    }
    
    /// Action section with buttons
    var actionSection: some View {
        VStack(spacing: 12) {
            if isCompleted {
                // View report button
                Button(action: {
                    // TODO: Navigate to style report
                }) {
                    HStack {
                        Image(systemName: "chart.bar.fill")
                        Text("查看風格報告")
                    }
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(Color.green)
                    .cornerRadius(12)
                }
                .buttonStyle(PlainButtonStyle())
            } else {
                // Encourage more rating
                VStack(spacing: 8) {
                    Text("想要加速獲得評分？")
                        .font(.body)
                        .foregroundColor(.secondary)
                    
                    Button(action: {
                        // TODO: Navigate to rating view
                    }) {
                        HStack {
                            Image(systemName: "heart.fill")
                            Text("去評分其他照片")
                        }
                        .font(.body)
                        .foregroundColor(.blue)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(Color.blue.opacity(0.1))
                        .cornerRadius(8)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
            
            // Tips section
            tipsSection
        }
    }
    
    /// Tips and information section
    var tipsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "lightbulb.fill")
                    .foregroundColor(.yellow)
                Text("小貼士")
                    .font(.headline)
                    .foregroundColor(.primary)
                Spacer()
            }
            
            VStack(alignment: .leading, spacing: 8) {
                tipRow(
                    icon: "timer",
                    text: "評分通常在24小時內完成",
                    color: .blue
                )
                
                tipRow(
                    icon: "arrow.2.circlepath",
                    text: "評分其他照片可以加速你的評分進度",
                    color: .green
                )
                
                tipRow(
                    icon: "bell.fill",
                    text: "達到50個評分時會收到通知",
                    color: .orange
                )
            }
        }
        .padding(16)
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(12)
    }
    
    /// Individual tip row
    func tipRow(icon: String, text: String, color: Color) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.caption)
                .foregroundColor(color)
                .frame(width: 16)
            
            Text(text)
                .font(.caption)
                .foregroundColor(.secondary)
            
            Spacer()
        }
    }
}

// MARK: - Preview
#Preview {
    UploadProgressView(
        photoId: "sample-photo-id-12345",
        currentRatings: 25,
        requiredRatings: 50,
        onDismiss: {}
    )
}

#Preview("Completed") {
    UploadProgressView(
        photoId: "sample-photo-id-12345",
        currentRatings: 50,
        requiredRatings: 50,
        onDismiss: {}
    )
}