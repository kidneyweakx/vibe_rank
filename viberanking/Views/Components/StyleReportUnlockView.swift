//
//  StyleReportUnlockView.swift
//  viberanking
//
//  Created by Kiro on 2025/07/25.
//

import SwiftUI

struct StyleReportUnlockView: View {
    @State private var animationPhase = 0
    @State private var showContent = false
    @State private var particleOffset: [CGPoint] = []
    
    let onComplete: () -> Void
    
    var body: some View {
        ZStack {
            // Background
            Color.black.opacity(0.9)
                .ignoresSafeArea()
            
            // Main content
            VStack(spacing: 30) {
                // Animated icon
                ZStack {
                    // Glow effect
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [Color.blue.opacity(0.6), Color.clear],
                                center: .center,
                                startRadius: 0,
                                endRadius: 100
                            )
                        )
                        .frame(width: 200, height: 200)
                        .scaleEffect(animationPhase >= 1 ? 1.5 : 0.5)
                        .opacity(animationPhase >= 1 ? 0.8 : 0)
                    
                    // Main icon
                    Image(systemName: "chart.bar.doc.horizontal.fill")
                        .font(.system(size: 80))
                        .foregroundColor(.white)
                        .scaleEffect(animationPhase >= 2 ? 1.0 : 0.3)
                        .rotationEffect(.degrees(animationPhase >= 2 ? 0 : 180))
                }
                
                // Text content
                if showContent {
                    VStack(spacing: 16) {
                        Text("🎉 恭喜！")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                            .foregroundColor(.yellow)
                            .scaleEffect(animationPhase >= 3 ? 1.0 : 0.5)
                        
                        Text("你的風格報告已解鎖")
                            .font(.title2)
                            .fontWeight(.semibold)
                            .foregroundColor(.white)
                            .opacity(animationPhase >= 4 ? 1.0 : 0)
                        
                        Text("基於 50+ 個評分的深度分析")
                            .font(.body)
                            .foregroundColor(.white.opacity(0.8))
                            .opacity(animationPhase >= 5 ? 1.0 : 0)
                    }
                    .transition(.scale.combined(with: .opacity))
                }
                
                // Action button
                if animationPhase >= 6 {
                    Button(action: {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            onComplete()
                        }
                    }) {
                        HStack {
                            Image(systemName: "eye.fill")
                            Text("查看我的報告")
                                .fontWeight(.semibold)
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(
                            LinearGradient(
                                colors: [Color.blue, Color.purple],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .foregroundColor(.white)
                        .cornerRadius(12)
                    }
                    .padding(.horizontal, 40)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                }
            }
            
            // Particle effects
            ForEach(0..<particleOffset.count, id: \.self) { index in
                Text(["✨", "⭐", "🎊", "🎉"].randomElement() ?? "✨")
                    .font(.title2)
                    .position(particleOffset[index])
                    .opacity(animationPhase >= 3 ? 1.0 : 0)
                    .animation(
                        .easeInOut(duration: 2.0)
                        .delay(Double(index) * 0.1),
                        value: animationPhase
                    )
            }
        }
        .onAppear {
            startAnimation()
            generateParticles()
        }
    }
    
    private func startAnimation() {
        // Phase 1: Glow effect
        withAnimation(.easeInOut(duration: 0.8)) {
            animationPhase = 1
        }
        
        // Phase 2: Icon animation
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
            withAnimation(.spring(response: 0.8, dampingFraction: 0.6)) {
                animationPhase = 2
            }
        }
        
        // Phase 3: Show content
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            withAnimation(.easeInOut(duration: 0.5)) {
                showContent = true
                animationPhase = 3
            }
        }
        
        // Phase 4-6: Sequential text animations
        for phase in 4...6 {
            DispatchQueue.main.asyncAfter(deadline: .now() + Double(phase - 3) * 0.5 + 1.0) {
                withAnimation(.easeInOut(duration: 0.4)) {
                    animationPhase = phase
                }
            }
        }
    }
    
    private func generateParticles() {
        let screenWidth = UIScreen.main.bounds.width
        let screenHeight = UIScreen.main.bounds.height
        
        particleOffset = (0..<15).map { _ in
            CGPoint(
                x: CGFloat.random(in: 0...screenWidth),
                y: CGFloat.random(in: 0...screenHeight)
            )
        }
    }
}

struct StyleReportUnlockView_Previews: PreviewProvider {
    static var previews: some View {
        StyleReportUnlockView {
            print("Animation completed")
        }
    }
}