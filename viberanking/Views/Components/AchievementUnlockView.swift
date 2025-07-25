//
//  AchievementUnlockView.swift
//  viberanking
//
//  Created by Kiro on 2025/07/25.
//

import SwiftUI

// MARK: - Achievement Unlock Animation View
struct AchievementUnlockView: View {
    let achievement: Achievement
    @State private var showAnimation = false
    @State private var showDetails = false
    @State private var particleAnimation = false
    
    var onDismiss: () -> Void
    
    var body: some View {
        ZStack {
            // Background overlay
            Color.black.opacity(0.7)
                .ignoresSafeArea()
                .onTapGesture {
                    dismissWithAnimation()
                }
            
            VStack(spacing: 20) {
                // Celebration particles
                ParticleEffectView()
                    .opacity(particleAnimation ? 1 : 0)
                    .animation(.easeInOut(duration: 0.5), value: particleAnimation)
                
                // Achievement icon with glow effect
                ZStack {
                    Circle()
                        .fill(
                            RadialGradient(
                                gradient: Gradient(colors: [.yellow.opacity(0.3), .clear]),
                                center: .center,
                                startRadius: 0,
                                endRadius: 60
                            )
                        )
                        .frame(width: 120, height: 120)
                        .scaleEffect(showAnimation ? 1.2 : 0.8)
                        .opacity(showAnimation ? 1 : 0)
                        .animation(.spring(response: 0.6, dampingFraction: 0.8), value: showAnimation)
                    
                    Image(systemName: achievement.iconName)
                        .font(.system(size: 50, weight: .bold))
                        .foregroundColor(.yellow)
                        .scaleEffect(showAnimation ? 1 : 0.5)
                        .rotationEffect(.degrees(showAnimation ? 360 : 0))
                        .animation(.spring(response: 0.8, dampingFraction: 0.6), value: showAnimation)
                }
                
                // Achievement details
                VStack(spacing: 12) {
                    Text("🎉 成就解鎖！")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .opacity(showDetails ? 1 : 0)
                        .offset(y: showDetails ? 0 : 20)
                        .animation(.easeOut(duration: 0.5).delay(0.3), value: showDetails)
                    
                    Text(achievement.title)
                        .font(.title)
                        .fontWeight(.heavy)
                        .foregroundColor(.yellow)
                        .multilineTextAlignment(.center)
                        .opacity(showDetails ? 1 : 0)
                        .offset(y: showDetails ? 0 : 20)
                        .animation(.easeOut(duration: 0.5).delay(0.4), value: showDetails)
                    
                    Text(achievement.description)
                        .font(.body)
                        .foregroundColor(.white.opacity(0.9))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                        .opacity(showDetails ? 1 : 0)
                        .offset(y: showDetails ? 0 : 20)
                        .animation(.easeOut(duration: 0.5).delay(0.5), value: showDetails)
                    
                    // Reward information
                    if let reward = achievement.reward {
                        RewardBadge(reward: reward)
                            .opacity(showDetails ? 1 : 0)
                            .offset(y: showDetails ? 0 : 20)
                            .animation(.easeOut(duration: 0.5).delay(0.6), value: showDetails)
                    }
                }
                
                // Dismiss button
                Button(action: dismissWithAnimation) {
                    Text("太棒了！")
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(.black)
                        .padding(.horizontal, 30)
                        .padding(.vertical, 12)
                        .background(
                            Capsule()
                                .fill(.yellow)
                                .shadow(color: .yellow.opacity(0.3), radius: 10, x: 0, y: 5)
                        )
                }
                .opacity(showDetails ? 1 : 0)
                .offset(y: showDetails ? 0 : 20)
                .animation(.easeOut(duration: 0.5).delay(0.7), value: showDetails)
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(.ultraThinMaterial)
                    .shadow(color: .black.opacity(0.3), radius: 20, x: 0, y: 10)
            )
            .padding(.horizontal, 30)
            .scaleEffect(showAnimation ? 1 : 0.8)
            .opacity(showAnimation ? 1 : 0)
            .animation(.spring(response: 0.6, dampingFraction: 0.8), value: showAnimation)
        }
        .onAppear {
            startAnimation()
        }
    }
    
    private func startAnimation() {
        showAnimation = true
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            showDetails = true
            particleAnimation = true
        }
    }
    
    private func dismissWithAnimation() {
        showAnimation = false
        showDetails = false
        particleAnimation = false
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            onDismiss()
        }
    }
}

// MARK: - Reward Badge
struct RewardBadge: View {
    let reward: AchievementReward
    
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: rewardIcon)
                .foregroundColor(.orange)
                .font(.title3)
            
            VStack(alignment: .leading, spacing: 2) {
                Text("獎勵")
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.7))
                
                Text(reward.description)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.orange)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(
            Capsule()
                .fill(.orange.opacity(0.2))
                .overlay(
                    Capsule()
                        .stroke(.orange.opacity(0.5), lineWidth: 1)
                )
        )
    }
    
    private var rewardIcon: String {
        switch reward.type {
        case .acceleratedRating:
            return "bolt.fill"
        case .bonusAnalysis:
            return "chart.bar.fill"
        case .specialBadge:
            return "star.fill"
        case .priorityQueue:
            return "arrow.up.circle.fill"
        }
    }
}

// MARK: - Particle Effect View
struct ParticleEffectView: View {
    @State private var particles: [Particle] = []
    
    var body: some View {
        ZStack {
            ForEach(particles, id: \.id) { particle in
                Circle()
                    .fill(particle.color)
                    .frame(width: particle.size, height: particle.size)
                    .position(particle.position)
                    .opacity(particle.opacity)
            }
        }
        .onAppear {
            createParticles()
        }
    }
    
    private func createParticles() {
        let colors: [Color] = [.yellow, .orange, .pink, .purple, .blue]
        
        for i in 0..<20 {
            let particle = Particle(
                id: i,
                position: CGPoint(x: 200, y: 200),
                color: colors.randomElement() ?? .yellow,
                size: Double.random(in: 4...12),
                opacity: 1.0
            )
            particles.append(particle)
            
            // Animate particle
            withAnimation(.easeOut(duration: 2.0).delay(Double.random(in: 0...0.5))) {
                particles[i].position = CGPoint(
                    x: Double.random(in: 50...350),
                    y: Double.random(in: 50...350)
                )
                particles[i].opacity = 0.0
            }
        }
    }
}

// MARK: - Particle Model
struct Particle {
    let id: Int
    var position: CGPoint
    let color: Color
    let size: Double
    var opacity: Double
}

// MARK: - Preview
struct AchievementUnlockView_Previews: PreviewProvider {
    static var previews: some View {
        AchievementUnlockView(
            achievement: Achievement(
                title: "評分新手",
                description: "完成你的前10次評分",
                iconName: "star.fill",
                category: .rating,
                requirement: AchievementRequirement(type: .ratingsGiven, target: 10),
                reward: AchievementReward(type: .acceleratedRating, value: 1, description: "獲得1次加速評分機會")
            ),
            onDismiss: {}
        )
    }
}