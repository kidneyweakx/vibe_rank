//
//  SamplePhotoNotificationView.swift
//  viberanking
//
//  Created by Kiro on 2025/07/23.
//

import SwiftUI

// MARK: - Sample Photo Notification View
struct SamplePhotoNotificationView: View {
    
    // MARK: - Properties
    @Binding var isVisible: Bool
    let onDismiss: () -> Void
    
    // MARK: - Animation State
    @State private var animateIcon = false
    @State private var showContent = false
    
    // MARK: - Body
    var body: some View {
        if isVisible {
            notificationContent
                .transition(.asymmetric(
                    insertion: .move(edge: .top).combined(with: .opacity),
                    removal: .move(edge: .top).combined(with: .opacity)
                ))
                .onAppear {
                    startAnimations()
                    
                    // Auto dismiss after 5 seconds
                    DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
                        dismissNotification()
                    }
                }
        }
    }
}

// MARK: - View Components
private extension SamplePhotoNotificationView {
    
    /// Notification content
    var notificationContent: some View {
        VStack(spacing: 0) {
            // Notification card
            notificationCard
                .padding(.horizontal, 16)
                .padding(.top, 8)
            
            Spacer()
        }
        .background(Color.clear)
    }
    
    /// Notification card
    var notificationCard: some View {
        HStack(spacing: 12) {
            // Icon
            iconSection
            
            // Content
            contentSection
            
            // Dismiss button
            dismissButton
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(.regularMaterial)
                .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
        )
        .scaleEffect(showContent ? 1.0 : 0.9)
        .opacity(showContent ? 1.0 : 0.0)
        .animation(.spring(response: 0.5, dampingFraction: 0.8), value: showContent)
    }
    
    /// Icon section
    var iconSection: some View {
        ZStack {
            Circle()
                .fill(
                    LinearGradient(
                        colors: [Color.blue, Color.purple],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 40, height: 40)
            
            Image(systemName: "photo.badge.plus")
                .font(.title3)
                .foregroundColor(.white)
                .scaleEffect(animateIcon ? 1.1 : 1.0)
                .animation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true), value: animateIcon)
        }
    }
    
    /// Content section
    var contentSection: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("使用示例照片")
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundColor(.primary)
            
            Text("目前沒有其他用戶照片，正在使用示例照片供你評分練習")
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.leading)
                .lineLimit(2)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
    
    /// Dismiss button
    var dismissButton: some View {
        Button(action: dismissNotification) {
            Image(systemName: "xmark")
                .font(.caption)
                .foregroundColor(.secondary)
                .padding(8)
                .background(
                    Circle()
                        .fill(Color.gray.opacity(0.2))
                )
        }
    }
}

// MARK: - Helper Methods
private extension SamplePhotoNotificationView {
    
    /// Start animations
    func startAnimations() {
        withAnimation(.easeInOut(duration: 0.5)) {
            showContent = true
        }
        
        withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true).delay(0.3)) {
            animateIcon = true
        }
    }
    
    /// Dismiss notification
    func dismissNotification() {
        withAnimation(.easeInOut(duration: 0.3)) {
            isVisible = false
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            onDismiss()
        }
    }
}

// MARK: - Preview
#Preview {
    ZStack {
        Color.gray.opacity(0.1)
            .ignoresSafeArea()
        
        SamplePhotoNotificationView(
            isVisible: .constant(true),
            onDismiss: {}
        )
    }
}