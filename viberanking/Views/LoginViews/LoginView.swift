//
//  LoginView.swift
//  viberanking
//
//  Created by Kiro on 2025/07/23.
//

import SwiftUI
import AuthenticationServices
import GoogleSignIn

struct LoginView: View {
    @EnvironmentObject private var viewModel: AuthenticationViewModel
    @EnvironmentObject private var themeManager: ThemeManager
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Black background with subtle gradient
                LinearGradient(
                    gradient: Gradient(
                        colors: [Color.black, Color(hex: "1A1A1A")]
                    ),
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    Spacer()
                    
                    // Artistic title
                    VStack(spacing: 8) {
                        Text("VIBE")
                            .font(.system(size: 48, weight: .black, design: .rounded))
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [Color.white, Color(hex: "E0E0E0")],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .shadow(color: Color.white.opacity(0.3), radius: 10, x: 0, y: 0)
                        
                        Text("RANK")
                            .font(.system(size: 48, weight: .black, design: .rounded))
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [Color(hex: "FF6B6B"), Color(hex: "4ECDC4")],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .shadow(color: Color(hex: "FF6B6B").opacity(0.5), radius: 15, x: 0, y: 0)
                    }
                    
                    Spacer()
                    Spacer()
                    
                    // Authentication buttons or loading state
                    if viewModel.isLoading {
                        ModernLoadingView()
                    } else {
                        ModernAuthButtonsView(viewModel: viewModel)
                    }
                    
                    // Error message display with animation
                    if let errorMessage = viewModel.errorMessage {
                        ModernErrorMessageView(message: errorMessage)
                            .padding(.bottom, 20)
                    }
                }
                .padding(.horizontal, 32)
                .frame(width: geometry.size.width)
            }
        }
        .preferredColorScheme(.dark)
    }
}



// MARK: - Modern Authentication Buttons View
struct ModernAuthButtonsView: View {
    @ObservedObject var viewModel: AuthenticationViewModel
    
    var body: some View {
        VStack(spacing: 20) {
            // Google Sign In Button
            ModernGoogleSignInButton {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                    viewModel.signInWithGoogle()
                }
            }
            
            // Apple Sign In Button
            ModernAppleSignInButton {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                    viewModel.signInWithApple()
                }
            }
            
            // Guest mode button
            Button(action: {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                    viewModel.signInAsGuest()
                }
            }) {
                Text("auth.continue_guest".localized)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.white.opacity(0.7))
                    .underline()
                    .padding(.top, 16)
            }
            .buttonStyle(ScaleButtonStyle())
        }
        .padding(.horizontal, 20)
        .padding(.bottom, 60)
    }
}

// MARK: - Modern Loading View
struct ModernLoadingView: View {
    @State private var isAnimating = false
    
    var body: some View {
        VStack(spacing: 24) {
            // Modern loading animation
            ZStack {
                Circle()
                    .stroke(lineWidth: 3)
                    .frame(width: 60, height: 60)
                    .foregroundColor(Color.white.opacity(0.2))
                
                Circle()
                    .trim(from: 0, to: 0.8)
                    .stroke(
                        LinearGradient(
                            colors: [Color(hex: "FF6B6B"), Color(hex: "4ECDC4")],
                            startPoint: .leading,
                            endPoint: .trailing
                        ),
                        style: StrokeStyle(lineWidth: 3, lineCap: .round)
                    )
                    .frame(width: 60, height: 60)
                    .rotationEffect(Angle(degrees: isAnimating ? 360 : 0))
                    .animation(
                        Animation.linear(duration: 1.2)
                            .repeatForever(autoreverses: false),
                        value: isAnimating
                    )
            }
            
            Text("auth.signing_in".localized)
                .font(.system(size: 18, weight: .medium))
                .foregroundColor(.white)
        }
        .frame(maxWidth: .infinity)
        .frame(height: 150)
        .onAppear {
            isAnimating = true
        }
    }
}

// MARK: - Modern Error Message View
struct ModernErrorMessageView: View {
    let message: String
    @State private var isShowing = false
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundColor(Color(hex: "FF6B6B"))
                .font(.system(size: 16))
            
            Text(message)
                .font(.system(size: 15, weight: .medium))
                .foregroundColor(.white)
                .multilineTextAlignment(.leading)
        }
        .padding(.vertical, 16)
        .padding(.horizontal, 20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(hex: "2D2D2D"))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color(hex: "FF6B6B").opacity(0.3), lineWidth: 1)
                )
        )
        .opacity(isShowing ? 1 : 0)
        .offset(y: isShowing ? 0 : 20)
        .animation(.spring(response: 0.4, dampingFraction: 0.8), value: isShowing)
        .onAppear {
            isShowing = true
        }
    }
}

// MARK: - Modern Google Sign-In Button
struct ModernGoogleSignInButton: View {
    let action: () -> Void
    @State private var isPressed = false
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                // Google Logo
                ModernGoogleLogoView()
                    .frame(width: 24, height: 24)
                
                Text("auth.sign_in_google".localized)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.white)
                
                Spacer()
            }
            .padding(.horizontal, 24)
            .frame(maxWidth: .infinity)
            .frame(height: 56)
            .background(
                RoundedRectangle(cornerRadius: 28)
                    .fill(Color(hex: "2D2D2D"))
                    .overlay(
                        RoundedRectangle(cornerRadius: 28)
                            .stroke(Color.white.opacity(0.2), lineWidth: 1)
                    )
                    .shadow(
                        color: Color.black.opacity(0.3),
                        radius: isPressed ? 5 : 10,
                        x: 0,
                        y: isPressed ? 2 : 5
                    )
            )
            .scaleEffect(isPressed ? 0.96 : 1.0)
            .animation(.spring(response: 0.2, dampingFraction: 0.8), value: isPressed)
        }
        .buttonStyle(PlainButtonStyle())
        .onLongPressGesture(minimumDuration: 0, maximumDistance: .infinity, pressing: { pressing in
            isPressed = pressing
        }, perform: {})
    }
}

// MARK: - Modern Apple Sign-In Button
struct ModernAppleSignInButton: View {
    let action: () -> Void
    @State private var isPressed = false
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                // Apple Logo
                Image(systemName: "apple.logo")
                    .font(.system(size: 20, weight: .medium))
                    .foregroundColor(.white)
                
                Text("auth.sign_in_apple".localized)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.white)
                
                Spacer()
            }
            .padding(.horizontal, 24)
            .frame(maxWidth: .infinity)
            .frame(height: 56)
            .background(
                RoundedRectangle(cornerRadius: 28)
                    .fill(Color(hex: "2D2D2D"))
                    .overlay(
                        RoundedRectangle(cornerRadius: 28)
                            .stroke(Color.white.opacity(0.2), lineWidth: 1)
                    )
                    .shadow(
                        color: Color.black.opacity(0.3),
                        radius: isPressed ? 5 : 10,
                        x: 0,
                        y: isPressed ? 2 : 5
                    )
            )
            .scaleEffect(isPressed ? 0.96 : 1.0)
            .animation(.spring(response: 0.2, dampingFraction: 0.8), value: isPressed)
        }
        .buttonStyle(PlainButtonStyle())
        .onLongPressGesture(minimumDuration: 0, maximumDistance: .infinity, pressing: { pressing in
            isPressed = pressing
        }, perform: {})
    }
}

// MARK: - Modern Google Logo View
struct ModernGoogleLogoView: View {
    var body: some View {
        ZStack {
            // Google "G" logo recreation
            Circle()
                .fill(Color.white)
                .frame(width: 24, height: 24)
            
            // Simplified Google G
            Text("G")
                .font(.system(size: 14, weight: .bold))
                .foregroundStyle(
                    LinearGradient(
                        colors: [
                            Color(hex: "4285F4"),
                            Color(hex: "34A853"),
                            Color(hex: "FBBC05"),
                            Color(hex: "EA4335")
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
        }
    }
}

// MARK: - Button Style
struct ScaleButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.97 : 1)
            .opacity(configuration.isPressed ? 0.9 : 1)
            .animation(.easeInOut(duration: 0.2), value: configuration.isPressed)
    }
}



// MARK: - Preview
struct LoginViewPreview: PreviewProvider {
    static var previews: some View {
        Group {
            // Default Preview
            LoginView()
                .environmentObject(LoginPreviewAuthenticationViewModel())
                .environmentObject(ThemeManager())
                .previewDisplayName("Default")
            
            // Loading State Preview
            LoginView()
                .environmentObject(LoginPreviewAuthenticationViewModel(isLoading: true))
                .environmentObject(ThemeManager())
                .previewDisplayName("Loading State")
            
            // Error State Preview
            LoginView()
                .environmentObject(LoginPreviewAuthenticationViewModel(errorMessage: "登入失敗，請重試"))
                .environmentObject(ThemeManager())
                .previewDisplayName("Error State")
        }
    }
}

// Preview helper class
@MainActor
class LoginPreviewAuthenticationViewModel: AuthenticationViewModel {
    init(isLoading: Bool = false, errorMessage: String? = nil) {
        super.init(authenticationService: PreviewAuthenticationService())
        
        // For preview purposes, we'll set properties directly
        self.isLoading = isLoading
        self.errorMessage = errorMessage
        self.isAuthenticated = false
        self.authState = .signedOut
    }
}

// Mock service for previews
@MainActor
class PreviewAuthenticationService: AuthenticationService {
    
    override func signInWithGoogle() async throws -> User {
        let user = User(id: "preview_id", name: "Preview User", email: "preview@example.com")
        currentUser = user
        return user
    }
    
    override func signInWithApple() async throws -> User {
        let user = User(id: "preview_id", name: "Preview User", email: "preview@example.com")
        currentUser = user
        return user
    }
    
    override func signInAsGuest() async throws -> User {
        let user = User(id: "guest_preview", name: "Guest Preview", email: "guest@example.com")
        currentUser = user
        return user
    }
    
    override func signOut() async throws {
        currentUser = nil
    }
}
