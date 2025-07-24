//
//  CTAView.swift
//  viberanking
//
//  Created by Kiro on 2025/07/23.
//

import SwiftUI

// MARK: - CTA View
struct CTAView: View {
    
    // MARK: - Properties
    @StateObject private var viewModel: CTAViewModel
    @Binding var isPresented: Bool
    let onUploadTapped: () -> Void
    
    // MARK: - Animation Properties
    @State private var animateGradient = false
    @State private var animateScale = false
    @State private var showContent = false
    @State private var showMotivationalMessage = false
    
    // MARK: - Initialization
    init(
        ctaService: CTAServiceProtocol,
        authService: AuthenticationServiceProtocol,
        isPresented: Binding<Bool>,
        onUploadTapped: @escaping () -> Void
    ) {
        self._viewModel = StateObject(wrappedValue: CTAViewModel(ctaService: ctaService, authService: authService))
        self._isPresented = isPresented
        self.onUploadTapped = onUploadTapped
    }
    
    // MARK: - Body
    var body: some View {
        ZStack {
            // Background
            backgroundView
            
            // Content
            if showContent {
                contentView
                    .transition(.asymmetric(
                        insertion: .scale.combined(with: .opacity),
                        removal: .opacity
                    ))
            }
        }
        .onAppear {
            startAnimations()
            Task {
                await viewModel.loadCTAMessage()
            }
        }
        .alert("錯誤", isPresented: .constant(viewModel.error != nil)) {
            Button("確定") {
                viewModel.clearError()
            }
        } message: {
            if let error = viewModel.error {
                Text(error.localizedDescription)
            }
        }
    }
}

// MARK: - View Components
private extension CTAView {
    
    /// Background gradient view
    var backgroundView: some View {
        LinearGradient(
            colors: gradientColors,
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .hueRotation(.degrees(animateGradient ? 30 : 0))
        .animation(.easeInOut(duration: 3).repeatForever(autoreverses: true), value: animateGradient)
        .ignoresSafeArea()
    }
    
    /// Main content view
    var contentView: some View {
        VStack(spacing: 0) {
            Spacer()
            
            // CTA Card
            ctaCard
                .scaleEffect(animateScale ? 1.0 : 0.8)
                .animation(.spring(response: 0.6, dampingFraction: 0.8), value: animateScale)
            
            Spacer()
            
            // Skip button
            skipButton
                .padding(.bottom, 50)
        }
        .padding(.horizontal, 20)
    }
    
    /// CTA card content
    var ctaCard: some View {
        VStack(spacing: 24) {
            // Header
            headerSection
            
            // Personalized content
            if let message = viewModel.ctaMessage {
                personalizedContent(message)
            } else if viewModel.isAnalyzingPreferences {
                loadingContent
            }
            
            // Action buttons
            actionButtons
        }
        .padding(32)
        .background(
            RoundedRectangle(cornerRadius: 24)
                .fill(.ultraThinMaterial)
                .shadow(color: .black.opacity(0.1), radius: 20, x: 0, y: 10)
        )
    }
    
    /// Header section with emoji and title
    var headerSection: some View {
        VStack(spacing: 16) {
            // Style emoji
            if let message = viewModel.ctaMessage {
                Text(message.dominantStyle.emoji)
                    .font(.system(size: 60))
                    .scaleEffect(animateScale ? 1.1 : 1.0)
                    .animation(.easeInOut(duration: 2).repeatForever(autoreverses: true), value: animateScale)
            }
            
            // Title
            Text(viewModel.ctaMessage?.title ?? "分析你的風格偏好")
                .font(.title2)
                .fontWeight(.bold)
                .multilineTextAlignment(.center)
                .foregroundColor(.primary)
        }
    }
    
    /// Personalized content based on CTA message
    func personalizedContent(_ message: CTAMessage) -> some View {
        VStack(spacing: 20) {
            // Subtitle
            Text(message.subtitle)
                .font(.body)
                .multilineTextAlignment(.center)
                .foregroundColor(.secondary)
                .lineLimit(nil)
            
            // Personalized elements
            personalizedElements(message.personalizedElements)
        }
    }
    
    /// Personalized elements list
    func personalizedElements(_ elements: [String]) -> some View {
        VStack(spacing: 12) {
            ForEach(Array(elements.enumerated()), id: \.offset) { index, element in
                HStack(spacing: 12) {
                    Circle()
                        .fill(Color.accentColor)
                        .frame(width: 8, height: 8)
                    
                    Text(element)
                        .font(.subheadline)
                        .foregroundColor(.primary)
                        .multilineTextAlignment(.leading)
                    
                    Spacer()
                }
                .opacity(showContent ? 1 : 0)
                .animation(.easeInOut(duration: 0.5).delay(Double(index) * 0.1), value: showContent)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.accentColor.opacity(0.1))
        )
    }
    
    /// Loading content while analyzing preferences
    var loadingContent: some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.2)
            
            Text("正在分析你的風格偏好...")
                .font(.body)
                .foregroundColor(.secondary)
        }
        .padding(.vertical, 40)
    }
    
    /// Action buttons
    var actionButtons: some View {
        VStack(spacing: 16) {
            // Main CTA button
            Button(action: {
                onUploadTapped()
                isPresented = false
            }) {
                HStack {
                    Image(systemName: "camera.fill")
                        .font(.title3)
                    
                    Text(viewModel.ctaMessage?.buttonText ?? "上傳照片")
                        .font(.headline)
                        .fontWeight(.semibold)
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 56)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(
                            LinearGradient(
                                colors: [Color.accentColor, Color.accentColor.opacity(0.8)],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                )
            }
            .disabled(viewModel.ctaMessage == nil)
            .opacity(viewModel.ctaMessage == nil ? 0.6 : 1.0)
            
            // Motivational text
            if let motivationalText = viewModel.ctaMessage?.motivationalText {
                Text(motivationalText)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .italic()
            }
        }
    }
    
    /// Skip button
    var skipButton: some View {
        Button(action: {
            showMotivationalMessage = true
        }) {
            Text("稍後再說")
                .font(.subheadline)
                .foregroundColor(.white.opacity(0.8))
                .padding(.horizontal, 24)
                .padding(.vertical, 12)
                .background(
                    Capsule()
                        .fill(.ultraThinMaterial)
                )
        }
        .sheet(isPresented: $showMotivationalMessage) {
            if let dominantStyle = viewModel.ctaMessage?.dominantStyle {
                MotivationalMessageView(
                    isPresented: $showMotivationalMessage,
                    dominantStyle: dominantStyle,
                    onUploadTapped: {
                        onUploadTapped()
                        isPresented = false
                    },
                    onSkipConfirmed: {
                        viewModel.handleSkipUpload()
                        isPresented = false
                    }
                )
            }
        }
    }
}

// MARK: - Helper Methods
private extension CTAView {
    
    /// Start entrance animations
    func startAnimations() {
        withAnimation(.easeInOut(duration: 0.8)) {
            showContent = true
        }
        
        withAnimation(.easeInOut(duration: 1.0).delay(0.2)) {
            animateScale = true
        }
        
        withAnimation(.easeInOut(duration: 2.0).delay(0.5)) {
            animateGradient = true
        }
    }
    
    /// Get gradient colors based on dominant style
    var gradientColors: [Color] {
        guard let dominantStyle = viewModel.ctaMessage?.dominantStyle else {
            return [Color.accentColor.opacity(0.6), Color.blue.opacity(0.4)]
        }
        
        switch dominantStyle {
        case .elegant:
            return [Color.purple.opacity(0.6), Color.pink.opacity(0.4)]
        case .casual:
            return [Color.green.opacity(0.6), Color.blue.opacity(0.4)]
        case .trendy:
            return [Color.orange.opacity(0.6), Color.red.opacity(0.4)]
        case .classic:
            return [Color.brown.opacity(0.6), Color.gray.opacity(0.4)]
        case .sporty:
            return [Color.blue.opacity(0.6), Color.cyan.opacity(0.4)]
        case .artistic:
            return [Color.indigo.opacity(0.6), Color.purple.opacity(0.4)]
        }
    }
}

// MARK: - Preview
#Preview {
    CTAView(
        ctaService: CTAService(),
        authService: AuthenticationService(),
        isPresented: .constant(true),
        onUploadTapped: {}
    )
}