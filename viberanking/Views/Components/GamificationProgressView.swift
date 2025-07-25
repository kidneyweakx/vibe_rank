//
//  GamificationProgressView.swift
//  viberanking
//
//  Created by Kiro on 2025/07/25.
//

import SwiftUI

// MARK: - Gamification Progress View
struct GamificationProgressView: View {
    let incentiveStatus: IncentiveStatus
    let userProgress: UserProgress
    
    var body: some View {
        VStack(spacing: 16) {
            // Accelerated Rating Progress
            AcceleratedRatingCard(
                available: incentiveStatus.acceleratedRatingsAvailable,
                nextAt: incentiveStatus.nextAcceleratedRatingAt,
                currentRatings: userProgress.totalRatingsGiven
            )
            
            // Evolution Analysis Status
            EvolutionAnalysisCard(
                isUnlocked: incentiveStatus.evolutionAnalysisUnlocked,
                photosUploaded: userProgress.totalPhotosUploaded,
                requiredPhotos: 3
            )
            
            // Share Rewards Status
            ShareRewardsCard(
                isUnlocked: incentiveStatus.shareRewardsUnlocked
            )
        }
        .padding(.horizontal)
    }
}

// MARK: - Accelerated Rating Card
struct AcceleratedRatingCard: View {
    let available: Int
    let nextAt: Int
    let currentRatings: Int
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "bolt.fill")
                    .foregroundColor(.yellow)
                    .font(.title2)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text("加速評分機會")
                        .font(.headline)
                        .fontWeight(.semibold)
                    
                    Text("每評分10張照片獲得1次機會")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                VStack(alignment: .trailing) {
                    Text("\(available)")
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundColor(.yellow)
                    
                    Text("可用")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            // Progress to next accelerated rating
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text("距離下次獎勵")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    Text("\(nextAt) 張評分")
                        .font(.caption)
                        .fontWeight(.medium)
                }
                
                ProgressView(value: Double(10 - nextAt), total: 10.0)
                    .progressViewStyle(LinearProgressViewStyle(tint: .yellow))
                    .scaleEffect(y: 1.5)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.secondarySystemBackground))
                .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
        )
    }
}

// MARK: - Evolution Analysis Card
struct EvolutionAnalysisCard: View {
    let isUnlocked: Bool
    let photosUploaded: Int
    let requiredPhotos: Int
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: isUnlocked ? "chart.line.uptrend.xyaxis" : "chart.line.uptrend.xyaxis")
                    .foregroundColor(isUnlocked ? .green : .gray)
                    .font(.title2)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text("風格演變分析")
                        .font(.headline)
                        .fontWeight(.semibold)
                    
                    Text(isUnlocked ? "已解鎖" : "需要\(requiredPhotos)張照片解鎖")
                        .font(.caption)
                        .foregroundColor(isUnlocked ? .green : .secondary)
                }
                
                Spacer()
                
                if isUnlocked {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                        .font(.title2)
                } else {
                    VStack(alignment: .trailing) {
                        Text("\(photosUploaded)/\(requiredPhotos)")
                            .font(.title3)
                            .fontWeight(.bold)
                            .foregroundColor(.orange)
                        
                        Text("照片")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
            
            if !isUnlocked {
                ProgressView(value: Double(photosUploaded), total: Double(requiredPhotos))
                    .progressViewStyle(LinearProgressViewStyle(tint: .orange))
                    .scaleEffect(y: 1.5)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.secondarySystemBackground))
                .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
        )
    }
}

// MARK: - Share Rewards Card
struct ShareRewardsCard: View {
    let isUnlocked: Bool
    
    var body: some View {
        HStack {
            Image(systemName: "square.and.arrow.up")
                .foregroundColor(isUnlocked ? .blue : .gray)
                .font(.title2)
            
            VStack(alignment: .leading, spacing: 2) {
                Text("分享獎勵")
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Text(isUnlocked ? "已解鎖分享獎勵" : "分享成就解鎖獎勵")
                    .font(.caption)
                    .foregroundColor(isUnlocked ? .blue : .secondary)
            }
            
            Spacer()
            
            if isUnlocked {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.blue)
                    .font(.title2)
            } else {
                Image(systemName: "lock.fill")
                    .foregroundColor(.gray)
                    .font(.title2)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.secondarySystemBackground))
                .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
        )
    }
}

// MARK: - Preview
struct GamificationProgressView_Previews: PreviewProvider {
    static var previews: some View {
        ScrollView {
            GamificationProgressView(
                incentiveStatus: IncentiveStatus(),
                userProgress: UserProgress(userId: "test")
            )
        }
        .background(Color(.systemBackground))
    }
}