//
//  MotivationalMessageView.swift
//  viberanking
//
//  Created by Kiro on 2025/07/23.
//

import SwiftUI

// MARK: - Motivational Message View
struct MotivationalMessageView: View {
    
    // MARK: - Properties
    @Binding var isPresented: Bool
    let dominantStyle: StyleType
    let onUploadTapped: () -> Void
    let onSkipConfirmed: () -> Void
    
    // MARK: - Animation State
    @State private var animateEmoji = false
    @State private var showContent = false
    
    // MARK: - Body
    var body: some View {
        ZStack {
            // Background
            backgroundView
            
            // Content
            if showContent {
                contentView
                    .transition(.scale.combined(with: .opacity))
            }
        }
        .onAppear {
            startAnimations()
        }
    }
}

// MARK: - View Components
private extension MotivationalMessageView {
    
    /// Background with blur effect
    var backgroundView: some View {
        Rectangle()
            .fill(.ultraThinMaterial)
            .ignoresSafeArea()
            .onTapGesture {
                dismissView()
            }
    }
    
    /// Main content view
    var contentView: some View {
        VStack(spacing: 0) {
            Spacer()
            
            // Message card
            messageCard
                .padding(.horizontal, 30)
            
            Spacer()
        }
    }
    
    /// Message card content
    var messageCard: some View {
        VStack(spacing: 24) {
            // Header with emoji
            headerSection
            
            // Motivational content
            motivationalContent
            
            // Action buttons
            actionButtons
        }
        .padding(32)
        .background(
            RoundedRectangle(cornerRadius: 24)
                .fill(.regularMaterial)
                .shadow(color: .black.opacity(0.15), radius: 20, x: 0, y: 10)
        )
    }
    
    /// Header section with animated emoji
    var headerSection: some View {
        VStack(spacing: 16) {
            // Animated emoji
            Text(dominantStyle.emoji)
                .font(.system(size: 50))
                .scaleEffect(animateEmoji ? 1.2 : 1.0)
                .animation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true), value: animateEmoji)
            
            // Title
            Text("等等！")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.primary)
        }
    }
    
    /// Motivational content based on style
    var motivationalContent: some View {
        VStack(spacing: 16) {
            // Main message
            Text(motivationalMessage)
                .font(.body)
                .multilineTextAlignment(.center)
                .foregroundColor(.primary)
                .lineLimit(nil)
            
            // Benefits list
            benefitsList
        }
    }
    
    /// Benefits of uploading
    var benefitsList: some View {
        VStack(spacing: 12) {
            ForEach(benefits, id: \.self) { benefit in
                HStack(spacing: 12) {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                        .font(.subheadline)
                    
                    Text(benefit)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.leading)
                    
                    Spacer()
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.green.opacity(0.1))
        )
    }
    
    /// Action buttons
    var actionButtons: some View {
        VStack(spacing: 12) {
            // Upload button
            Button(action: {
                onUploadTapped()
                dismissView()
            }) {
                HStack {
                    Image(systemName: "camera.fill")
                        .font(.title3)
                    
                    Text("好的，我要上傳！")
                        .font(.headline)
                        .fontWeight(.semibold)
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 50)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.accentColor)
                )
            }
            
            // Skip button
            Button(action: {
                onSkipConfirmed()
                dismissView()
            }) {
                Text("我真的要跳過")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
        }
    }
}

// MARK: - Helper Methods
private extension MotivationalMessageView {
    
    /// Start entrance animations
    func startAnimations() {
        withAnimation(.easeInOut(duration: 0.5)) {
            showContent = true
        }
        
        withAnimation(.easeInOut(duration: 1.0).delay(0.3)) {
            animateEmoji = true
        }
    }
    
    /// Dismiss the view
    func dismissView() {
        withAnimation(.easeInOut(duration: 0.3)) {
            isPresented = false
        }
    }
    
    /// Get motivational message based on style
    var motivationalMessage: String {
        switch dominantStyle {
        case .elegant:
            return "你的優雅品味值得被更多人看見！上傳一張照片，讓大家欣賞你的精緻風格，並獲得專屬的風格分析報告。"
        case .casual:
            return "你的自然魅力最打動人心！分享一張真實的照片，看看大家如何評價你的親和力，並發現更多關於自己的風格秘密。"
        case .trendy:
            return "時尚達人就是你！展示你的潮流品味，讓其他人見識你的時尚嗅覺，並獲得個性化的風格建議。"
        case .classic:
            return "經典永不過時！你的永恆品味值得被記錄，上傳照片獲得專業的風格分析，發現你的經典魅力。"
        case .sporty:
            return "活力四射的你最有魅力！分享你的正能量，讓大家感受你的健康活力，並獲得專屬的風格報告。"
        case .artistic:
            return "藝術家的眼光獨一無二！展現你的創意風格，讓其他人欣賞你的藝術品味，並發現更多創意靈感。"
        default:
            return "還沒想好"
        }
        
    }
    
    /// Get benefits list
    var benefits: [String] {
        return [
            "獲得詳細的個人風格分析報告",
            "了解別人如何看待你的風格",
            "收到個性化的風格改進建議",
            "解鎖更多平台功能和獎勵"
        ]
    }
}

// MARK: - Preview
#Preview {
    MotivationalMessageView(
        isPresented: .constant(true),
        dominantStyle: .elegant,
        onUploadTapped: {},
        onSkipConfirmed: {}
    )
}
