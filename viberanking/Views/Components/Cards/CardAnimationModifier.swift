//
//  CardAnimationModifier.swift
//  viberanking
//
//  Created by Kiro on 2025/07/25.
//

import SwiftUI

// MARK: - Card Animation Modifier
struct CardAnimationModifier: ViewModifier {
    @State private var isPressed = false
    @State private var hasAppeared = false
    
    let delay: Double
    let enableHaptics: Bool
    let scaleEffect: CGFloat
    let animationDuration: Double
    
    init(
        delay: Double = 0,
        enableHaptics: Bool = true,
        scaleEffect: CGFloat = 0.95,
        animationDuration: Double = 0.1
    ) {
        self.delay = delay
        self.enableHaptics = enableHaptics
        self.scaleEffect = scaleEffect
        self.animationDuration = animationDuration
    }
    
    func body(content: Content) -> some View {
        content
            .scaleEffect(isPressed ? scaleEffect : 1.0)
            .brightness(isPressed ? -0.05 : 0)
            .opacity(hasAppeared ? 1.0 : 0.0)
            .offset(y: hasAppeared ? 0 : 20)
            .animation(
                .easeInOut(duration: animationDuration),
                value: isPressed
            )
            .animation(
                .spring(response: 0.8, dampingFraction: 0.9)
                .delay(delay),
                value: hasAppeared
            )
            .onAppear {
                hasAppeared = true
            }
            .simultaneousGesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { _ in
                        if !isPressed {
                            isPressed = true
                            if enableHaptics {
                                let impactFeedback = UIImpactFeedbackGenerator(style: .light)
                                impactFeedback.impactOccurred()
                            }
                        }
                    }
                    .onEnded { _ in
                        isPressed = false
                    }
            )
    }
}

// MARK: - Card Touch Feedback Modifier
struct CardTouchFeedback: ViewModifier {
    @State private var isPressed = false
    
    let hapticStyle: UIImpactFeedbackGenerator.FeedbackStyle
    let scaleEffect: CGFloat
    let brightnessEffect: Double
    
    init(
        hapticStyle: UIImpactFeedbackGenerator.FeedbackStyle = .medium,
        scaleEffect: CGFloat = 0.98,
        brightnessEffect: Double = -0.05
    ) {
        self.hapticStyle = hapticStyle
        self.scaleEffect = scaleEffect
        self.brightnessEffect = brightnessEffect
    }
    
    func body(content: Content) -> some View {
        content
            .scaleEffect(isPressed ? scaleEffect : 1.0)
            .brightness(isPressed ? brightnessEffect : 0)
            .animation(.easeInOut(duration: 0.1), value: isPressed)
            .onTapGesture {
                // Haptic feedback
                let impactFeedback = UIImpactFeedbackGenerator(style: hapticStyle)
                impactFeedback.impactOccurred()
            }
            .simultaneousGesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { _ in isPressed = true }
                    .onEnded { _ in isPressed = false }
            )
    }
}

// MARK: - Card Swipe Gesture Modifier
struct CardSwipeGesture: ViewModifier {
    let onSwipeLeft: (() -> Void)?
    let onSwipeRight: (() -> Void)?
    let threshold: CGFloat
    
    @State private var offset: CGSize = .zero
    @State private var isDragging = false
    
    init(
        threshold: CGFloat = 50,
        onSwipeLeft: (() -> Void)? = nil,
        onSwipeRight: (() -> Void)? = nil
    ) {
        self.threshold = threshold
        self.onSwipeLeft = onSwipeLeft
        self.onSwipeRight = onSwipeRight
    }
    
    func body(content: Content) -> some View {
        content
            .offset(offset)
            .scaleEffect(isDragging ? 0.98 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.8), value: offset)
            .animation(.easeInOut(duration: 0.2), value: isDragging)
            .gesture(
                DragGesture()
                    .onChanged { value in
                        isDragging = true
                        offset = CGSize(
                            width: value.translation.width * 0.5, // Reduce movement for better feel
                            height: 0
                        )
                    }
                    .onEnded { value in
                        isDragging = false
                        
                        if abs(value.translation.width) > threshold {
                            // Haptic feedback for successful swipe
                            let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
                            impactFeedback.impactOccurred()
                            
                            if value.translation.width > 0 {
                                onSwipeRight?()
                            } else {
                                onSwipeLeft?()
                            }
                        }
                        
                        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                            offset = .zero
                        }
                    }
            )
    }
}

// MARK: - Card Entrance Animation
struct CardEntranceAnimation: ViewModifier {
    @State private var hasAppeared = false
    
    let delay: Double
    let direction: EntranceDirection
    
    enum EntranceDirection {
        case bottom, top, left, right, scale
        
        var initialOffset: CGSize {
            switch self {
            case .bottom: return CGSize(width: 0, height: 50)
            case .top: return CGSize(width: 0, height: -50)
            case .left: return CGSize(width: -50, height: 0)
            case .right: return CGSize(width: 50, height: 0)
            case .scale: return .zero
            }
        }
        
        var initialScale: CGFloat {
            switch self {
            case .scale: return 0.8
            default: return 1.0
            }
        }
    }
    
    init(delay: Double = 0, direction: EntranceDirection = .bottom) {
        self.delay = delay
        self.direction = direction
    }
    
    func body(content: Content) -> some View {
        content
            .opacity(hasAppeared ? 1.0 : 0.0)
            .offset(hasAppeared ? .zero : direction.initialOffset)
            .scaleEffect(hasAppeared ? 1.0 : direction.initialScale)
            .animation(
                .spring(response: 0.6, dampingFraction: 0.8)
                .delay(delay),
                value: hasAppeared
            )
            .onAppear {
                hasAppeared = true
            }
    }
}

// MARK: - Card Hover Effect (for iPad/Mac)
struct CardHoverEffect: ViewModifier {
    @State private var isHovered = false
    
    let hoverScale: CGFloat
    let shadowRadius: CGFloat
    
    init(hoverScale: CGFloat = 1.02, shadowRadius: CGFloat = 12) {
        self.hoverScale = hoverScale
        self.shadowRadius = shadowRadius
    }
    
    func body(content: Content) -> some View {
        content
            .scaleEffect(isHovered ? hoverScale : 1.0)
            .shadow(
                color: Color.black.opacity(isHovered ? 0.2 : 0.1),
                radius: isHovered ? shadowRadius : 8,
                x: 0,
                y: isHovered ? 6 : 4
            )
            .animation(.easeInOut(duration: 0.2), value: isHovered)
            .onHover { hovering in
                isHovered = hovering
            }
    }
}

// MARK: - View Extensions
extension View {
    func cardAnimation(
        delay: Double = 0,
        enableHaptics: Bool = true,
        scaleEffect: CGFloat = 0.95,
        animationDuration: Double = 0.1
    ) -> some View {
        modifier(CardAnimationModifier(
            delay: delay,
            enableHaptics: enableHaptics,
            scaleEffect: scaleEffect,
            animationDuration: animationDuration
        ))
    }
    
    func cardTouchFeedback(
        hapticStyle: UIImpactFeedbackGenerator.FeedbackStyle = .medium,
        scaleEffect: CGFloat = 0.98,
        brightnessEffect: Double = -0.05
    ) -> some View {
        modifier(CardTouchFeedback(
            hapticStyle: hapticStyle,
            scaleEffect: scaleEffect,
            brightnessEffect: brightnessEffect
        ))
    }
    
    func cardSwipeGesture(
        threshold: CGFloat = 50,
        onSwipeLeft: (() -> Void)? = nil,
        onSwipeRight: (() -> Void)? = nil
    ) -> some View {
        modifier(CardSwipeGesture(
            threshold: threshold,
            onSwipeLeft: onSwipeLeft,
            onSwipeRight: onSwipeRight
        ))
    }
    
    func cardEntranceAnimation(
        delay: Double = 0,
        direction: CardEntranceAnimation.EntranceDirection = .bottom
    ) -> some View {
        modifier(CardEntranceAnimation(delay: delay, direction: direction))
    }
    
    func cardHoverEffect(
        hoverScale: CGFloat = 1.02,
        shadowRadius: CGFloat = 12
    ) -> some View {
        modifier(CardHoverEffect(hoverScale: hoverScale, shadowRadius: shadowRadius))
    }
}

// MARK: - Preview
struct CardAnimationModifier_Previews: PreviewProvider {
    static var previews: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Basic Animation
                Text("基本動畫效果")
                    .font(AppTheme.Typography.headline)
                    .frame(maxWidth: .infinity, alignment: .leading)
                
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.blue.opacity(0.3))
                    .frame(height: 100)
                    .overlay(Text("點擊測試動畫").font(AppTheme.Typography.callout))
                    .cardAnimation()
                
                // Touch Feedback
                Text("觸摸反饋")
                    .font(AppTheme.Typography.headline)
                    .frame(maxWidth: .infinity, alignment: .leading)
                
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.green.opacity(0.3))
                    .frame(height: 100)
                    .overlay(Text("觸摸反饋測試").font(AppTheme.Typography.callout))
                    .cardTouchFeedback()
                
                // Swipe Gesture
                Text("滑動手勢")
                    .font(AppTheme.Typography.headline)
                    .frame(maxWidth: .infinity, alignment: .leading)
                
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.orange.opacity(0.3))
                    .frame(height: 100)
                    .overlay(Text("左右滑動測試").font(AppTheme.Typography.callout))
                    .cardSwipeGesture(
                        onSwipeLeft: { print("向左滑動") },
                        onSwipeRight: { print("向右滑動") }
                    )
                
                // Entrance Animations
                Text("入場動畫")
                    .font(AppTheme.Typography.headline)
                    .frame(maxWidth: .infinity, alignment: .leading)
                
                HStack(spacing: 16) {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.purple.opacity(0.3))
                        .frame(height: 80)
                        .overlay(Text("從下方").font(AppTheme.Typography.caption))
                        .cardEntranceAnimation(delay: 0.1, direction: .bottom)
                    
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.red.opacity(0.3))
                        .frame(height: 80)
                        .overlay(Text("縮放").font(AppTheme.Typography.caption))
                        .cardEntranceAnimation(delay: 0.2, direction: .scale)
                    
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.cyan.opacity(0.3))
                        .frame(height: 80)
                        .overlay(Text("從右方").font(AppTheme.Typography.caption))
                        .cardEntranceAnimation(delay: 0.3, direction: .right)
                }
            }
            .padding()
        }
        .environmentObject(ThemeManager())
    }
}