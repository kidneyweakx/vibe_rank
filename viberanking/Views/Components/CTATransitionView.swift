//
//  CTATransitionView.swift
//  viberanking
//
//  Created by Kiro on 2025/07/23.
//

import SwiftUI

// MARK: - CTA Transition View
struct CTATransitionView: View {
    
    // MARK: - Properties
    @Binding var showCTA: Bool
    @Binding var showUpload: Bool
    let ctaService: CTAServiceProtocol
    let authService: AuthenticationServiceProtocol
    
    // MARK: - Animation State
    @State private var animationPhase: TransitionPhase = .hidden
    @State private var progressValue: Double = 0.0
    
    // MARK: - Body
    var body: some View {
        ZStack {
            // Background overlay
            if animationPhase != .hidden {
                backgroundOverlay
            }
            
            // Transition content
            transitionContent
        }
        .onChange(of: showCTA) { _, newValue in
            if newValue {
                startTransition()
            }
        }
    }
}

// MARK: - View Components
private extension CTATransitionView {
    
    /// Background overlay with blur effect
    var backgroundOverlay: some View {
        Rectangle()
            .fill(.ultraThinMaterial)
            .ignoresSafeArea()
            .opacity(animationPhase == .showing ? 1.0 : 0.0)
            .animation(.easeInOut(duration: 0.3), value: animationPhase)
    }
    
    /// Main transition content
    var transitionContent: some View {
        VStack {
            if animationPhase == .preparing {
                preparingView
            } else if animationPhase == .showing {
                CTAView(
                    ctaService: ctaService,
                    authService: authService,
                    isPresented: $showCTA,
                    onUploadTapped: handleUploadTapped
                )
            }
        }
    }
    
    /// Preparing view with progress indicator
    var preparingView: some View {
        VStack(spacing: 24) {
            // Progress circle
            ZStack {
                Circle()
                    .stroke(Color.gray.opacity(0.3), lineWidth: 8)
                    .frame(width: 80, height: 80)
                
                Circle()
                    .trim(from: 0, to: progressValue)
                    .stroke(
                        Color.accentColor,
                        style: StrokeStyle(lineWidth: 8, lineCap: .round)
                    )
                    .frame(width: 80, height: 80)
                    .rotationEffect(.degrees(-90))
                    .animation(.easeInOut(duration: 0.5), value: progressValue)
                
                Image(systemName: "sparkles")
                    .font(.title2)
                    .foregroundColor(.accentColor)
                    .scaleEffect(progressValue > 0.5 ? 1.2 : 1.0)
                    .animation(.easeInOut(duration: 0.3), value: progressValue)
            }
            
            // Status text
            VStack(spacing: 8) {
                Text("分析你的風格偏好")
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Text(statusText)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
        }
        .padding(40)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(.regularMaterial)
                .shadow(radius: 10)
        )
        .padding(.horizontal, 40)
    }
}

// MARK: - Helper Methods
private extension CTATransitionView {
    
    /// Start the transition animation sequence
    func startTransition() {
        animationPhase = .preparing
        
        // Simulate analysis progress
        Task {
            await simulateAnalysisProgress()
            
            // Transition to CTA view
            withAnimation(.easeInOut(duration: 0.5)) {
                animationPhase = .showing
            }
        }
    }
    
    /// Simulate analysis progress with realistic timing
    func simulateAnalysisProgress() async {
        let steps = 10
        for i in 1...steps {
            
            try? await Task.sleep(nanoseconds: 200_000_000) // 0.2 seconds
            
            await MainActor.run {
                progressValue = Double(i) / Double(steps)
            }
        }
    }
    
    /// Handle upload button tap
    func handleUploadTapped() {
        withAnimation(.easeInOut(duration: 0.5)) {
            showCTA = false
            showUpload = true
        }
    }
    
    /// Get status text based on progress
    var statusText: String {
        let progress = Int(progressValue * 100)
        
        switch progress {
        case 0..<20:
            return "正在分析你的評分模式..."
        case 20..<40:
            return "識別你喜歡的風格類型..."
        case 40..<60:
            return "計算風格偏好分數..."
        case 60..<80:
            return "生成個性化建議..."
        case 80..<100:
            return "準備你的專屬訊息..."
        default:
            return "分析完成！"
        }
    }
}

// MARK: - Transition Phase Enum
private enum TransitionPhase {
    case hidden
    case preparing
    case showing
}

// MARK: - Preview
#Preview {
    CTATransitionView(
        showCTA: .constant(true),
        showUpload: .constant(false),
        ctaService: CTAService(),
        authService: AuthenticationService()
    )
}
