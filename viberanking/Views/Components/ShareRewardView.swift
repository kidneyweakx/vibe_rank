//
//  ShareRewardView.swift
//  viberanking
//
//  Created by Kiro on 2025/07/25.
//

import SwiftUI
import UIKit

// MARK: - Share Reward View
struct ShareRewardView: View {
    let shareContent: ShareContent
    @State private var showShareSheet = false
    @State private var showRewardAnimation = false
    
    var onShareCompleted: (ShareType) -> Void
    
    var body: some View {
        VStack(spacing: 16) {
            // Share preview
            SharePreviewCard(content: shareContent)
            
            // Share buttons
            VStack(spacing: 12) {
                ShareButton(
                    title: "分享到社交媒體",
                    icon: "square.and.arrow.up",
                    color: .blue,
                    action: {
                        showShareSheet = true
                    }
                )
                
                ShareButton(
                    title: "複製連結",
                    icon: "link",
                    color: .green,
                    action: {
                        copyToClipboard()
                    }
                )
                
                ShareButton(
                    title: "儲存圖片",
                    icon: "square.and.arrow.down",
                    color: .purple,
                    action: {
                        saveToPhotos()
                    }
                )
            }
            
            // Reward information
            if !shareContent.hasSharedBefore {
                RewardInfoCard()
            }
        }
        .padding()
        .sheet(isPresented: $showShareSheet) {
            ShareSheet(
                activityItems: shareContent.activityItems,
                onCompletion: { completed in
                    if completed {
                        handleShareCompletion()
                    }
                }
            )
        }
        .overlay(
            RewardAnimationOverlay(show: $showRewardAnimation)
        )
    }
    
    private func copyToClipboard() {
        UIPasteboard.general.string = shareContent.shareText
        
        // Show feedback
        let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
        impactFeedback.impactOccurred()
        
        handleShareCompletion()
    }
    
    private func saveToPhotos() {
        if let image = shareContent.shareImage {
            UIImageWriteToSavedPhotosAlbum(image, nil, nil, nil)
            handleShareCompletion()
        }
    }
    
    private func handleShareCompletion() {
        if !shareContent.hasSharedBefore {
            showRewardAnimation = true
        }
        
        onShareCompleted(shareContent.shareType)
    }
}

// MARK: - Share Preview Card
struct SharePreviewCard: View {
    let content: ShareContent
    
    var body: some View {
        VStack(spacing: 12) {
            // Preview image or icon
            if let image = content.previewImage {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(maxHeight: 200)
                    .cornerRadius(12)
            } else {
                Image(systemName: content.defaultIcon)
                    .font(.system(size: 60))
                    .foregroundColor(.blue)
                    .frame(height: 100)
            }
            
            // Content text
            VStack(spacing: 4) {
                Text(content.title)
                    .font(.headline)
                    .fontWeight(.semibold)
                    .multilineTextAlignment(.center)
                
                Text(content.description)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.secondarySystemBackground))
                .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
        )
    }
}

// MARK: - Share Button
struct ShareButton: View {
    let title: String
    let icon: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.title3)
                    .foregroundColor(color)
                    .frame(width: 24)
                
                Text(title)
                    .font(.body)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(.tertiarySystemBackground))
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Reward Info Card
struct RewardInfoCard: View {
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "gift.fill")
                .font(.title2)
                .foregroundColor(.orange)
            
            VStack(alignment: .leading, spacing: 2) {
                Text("首次分享獎勵")
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Text("分享後獲得1次加速評分機會")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(.orange.opacity(0.1))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(.orange.opacity(0.3), lineWidth: 1)
                )
        )
    }
}

// MARK: - Reward Animation Overlay
struct RewardAnimationOverlay: View {
    @Binding var show: Bool
    @State private var animationPhase = 0
    
    var body: some View {
        if show {
            ZStack {
                Color.black.opacity(0.3)
                    .ignoresSafeArea()
                
                VStack(spacing: 16) {
                    // Animated gift icon
                    Image(systemName: "gift.fill")
                        .font(.system(size: 60))
                        .foregroundColor(.orange)
                        .scaleEffect(animationPhase == 0 ? 0.5 : 1.2)
                        .rotationEffect(.degrees(animationPhase == 0 ? 0 : 360))
                        .animation(.spring(response: 0.6, dampingFraction: 0.6), value: animationPhase)
                    
                    Text("🎉 獲得獎勵！")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .opacity(animationPhase >= 1 ? 1 : 0)
                        .animation(.easeIn(duration: 0.3).delay(0.5), value: animationPhase)
                    
                    Text("獲得1次加速評分機會")
                        .font(.body)
                        .foregroundColor(.orange)
                        .opacity(animationPhase >= 2 ? 1 : 0)
                        .animation(.easeIn(duration: 0.3).delay(0.8), value: animationPhase)
                }
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(.ultraThinMaterial)
                )
                .padding(.horizontal, 40)
            }
            .onAppear {
                startAnimation()
            }
            .onTapGesture {
                dismissAnimation()
            }
        }
    }
    
    private func startAnimation() {
        animationPhase = 1
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            animationPhase = 2
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            dismissAnimation()
        }
    }
    
    private func dismissAnimation() {
        show = false
        animationPhase = 0
    }
}

// MARK: - Share Sheet
struct ShareSheet: UIViewControllerRepresentable {
    let activityItems: [Any]
    let onCompletion: (Bool) -> Void
    
    func makeUIViewController(context: Context) -> UIActivityViewController {
        let controller = UIActivityViewController(
            activityItems: activityItems,
            applicationActivities: nil
        )
        
        controller.completionWithItemsHandler = { _, completed, _, _ in
            onCompletion(completed)
        }
        
        return controller
    }
    
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

// MARK: - Share Content Model
struct ShareContent {
    let shareType: ShareType
    let title: String
    let description: String
    let shareText: String
    let shareImage: UIImage?
    let previewImage: UIImage?
    let hasSharedBefore: Bool
    
    var defaultIcon: String {
        switch shareType {
        case .styleReport:
            return "chart.bar.fill"
        case .achievement:
            return "star.fill"
        case .evolution:
            return "chart.line.uptrend.xyaxis"
        }
    }
    
    var activityItems: [Any] {
        var items: [Any] = [shareText]
        if let image = shareImage {
            items.append(image)
        }
        return items
    }
}

// MARK: - Preview
struct ShareRewardView_Previews: PreviewProvider {
    static var previews: some View {
        ShareRewardView(
            shareContent: ShareContent(
                shareType: .achievement,
                title: "我解鎖了新成就！",
                description: "在數位頂尖社交評價平台完成了評分新手成就",
                shareText: "我在數位頂尖社交評價平台解鎖了「評分新手」成就！快來一起評分吧！",
                shareImage: nil,
                previewImage: nil,
                hasSharedBefore: false
            ),
            onShareCompleted: { _ in }
        )
    }
}