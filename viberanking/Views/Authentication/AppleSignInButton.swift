//
//  AppleSignInButton.swift
//  viberanking
//
//  Created by Kiro on 2025/07/24.
//

import SwiftUI
import AuthenticationServices

/// A SwiftUI wrapper for ASAuthorizationAppleIDButton
struct AppleSignInButton: UIViewRepresentable {
    let type: ASAuthorizationAppleIDButton.ButtonType
    let style: ASAuthorizationAppleIDButton.Style
    let action: () -> Void
    
    init(
        type: ASAuthorizationAppleIDButton.ButtonType = .signIn,
        style: ASAuthorizationAppleIDButton.Style = .black,
        action: @escaping () -> Void
    ) {
        self.type = type
        self.style = style
        self.action = action
    }
    
    func makeUIView(context: Context) -> ASAuthorizationAppleIDButton {
        let button = ASAuthorizationAppleIDButton(type: type, style: style)
        button.addTarget(
            context.coordinator,
            action: #selector(Coordinator.handleTap),
            for: .touchUpInside
        )
        return button
    }
    
    func updateUIView(_ uiView: ASAuthorizationAppleIDButton, context: Context) {
        // No updates needed
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(action: action)
    }
    
    class Coordinator: NSObject {
        let action: () -> Void
        
        init(action: @escaping () -> Void) {
            self.action = action
        }
        
        @objc func handleTap() {
            action()
        }
    }
}

// MARK: - Preview
struct AppleSignInButton_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 20) {
            AppleSignInButton(
                type: .signIn,
                style: .black
            ) {
                print("Apple Sign-In tapped")
            }
            .frame(height: 50)
            
            AppleSignInButton(
                type: .signIn,
                style: .white
            ) {
                print("Apple Sign-In tapped")
            }
            .frame(height: 50)
            
            AppleSignInButton(
                type: .signIn,
                style: .whiteOutline
            ) {
                print("Apple Sign-In tapped")
            }
            .frame(height: 50)
        }
        .padding()
        .previewLayout(.sizeThatFits)
    }
}