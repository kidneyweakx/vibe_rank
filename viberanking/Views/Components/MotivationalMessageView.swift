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
            Text("motivational.wait".localized)
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
                    
                    Text("motivational.upload_now".localized)
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
                Text("motivational.really_skip".localized)
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
            return "style.elegant.message".localized
        case .casual:
            return "style.casual.message".localized
        case .trendy:
            return "style.trendy.message".localized
        case .classic:
            return "style.classic.message".localized
        case .sporty:
            return "style.sporty.message".localized
        case .artistic:
            return "style.artistic.message".localized
        default:
            return "style.default.message".localized
        }
    }
    
    /// Get benefits list
    var benefits: [String] {
        return [
            "motivational.benefit_1".localized,
            "motivational.benefit_2".localized,
            "motivational.benefit_3".localized,
            "motivational.benefit_4".localized
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
