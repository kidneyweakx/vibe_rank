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
                // Background gradient that adapts to light/dark mode
                LinearGradient(
                    gradient: Gradient(
                        colors: [themeManager.currentTheme.colors.background, themeManager.currentTheme.colors.background.opacity(0.8)]
                    ),
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()
                
                VStack(spacing: 30) {
                    Spacer()
                    
                    // App logo with animation
                    LogoView()
                        .frame(width: 120, height: 120)
                        .padding(.bottom, 10)
                    
                    // App title with dynamic text styling
                    Text("auth.title".localized)
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                        .foregroundColor(themeManager.currentTheme.colors.text)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                    
                    // App subtitle
                    Text("auth.subtitle".localized)
                        .font(.system(size: 16, weight: .medium, design: .rounded))
                        .foregroundColor(themeManager.currentTheme.colors.text.opacity(0.7))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 40)
                        .padding(.bottom, 20)
                    
                    Spacer()
                    
                    // Authentication buttons or loading state
                    if viewModel.isLoading {
                        LoadingView()
                    } else {
                        AuthButtonsView(viewModel: viewModel)
                    }
                    
                    // Error message display with animation
                    if let errorMessage = viewModel.errorMessage {
                        ErrorMessageView(message: errorMessage)
                    }
                    
                    Spacer()
                }
                .padding(.horizontal, 24)
                .frame(width: geometry.size.width)
            }
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel("auth.screen_label".localized)
    }
}

// MARK: - Logo View
struct LogoView: View {
    @State private var isAnimating = false
    @EnvironmentObject private var themeManager: ThemeManager
    
    var body: some View {
        ZStack {
            // Outer circle with gradient
            Circle()
                .fill(
                    LinearGradient(
                        gradient: Gradient(
                            colors: [themeManager.currentTheme.colors.primary, themeManager.currentTheme.colors.secondary]
                        ),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 120, height: 120)
                .shadow(color: Color.black.opacity(0.3), radius: 10, x: 0, y: 5)
            
            // Inner star icon
            Image(systemName: "star.fill")
                .resizable()
                .scaledToFit()
                .frame(width: 60, height: 60)
                .foregroundColor(.white)
                .scaleEffect(isAnimating ? 1.1 : 1.0)
                .animation(
                    Animation.easeInOut(duration: 1.2)
                        .repeatForever(autoreverses: true),
                    value: isAnimating
                )
        }
        .onAppear {
            isAnimating = true
        }
    }
}

// MARK: - Authentication Buttons View
struct AuthButtonsView: View {
    @ObservedObject var viewModel: AuthenticationViewModel
    @EnvironmentObject private var themeManager: ThemeManager
    
    var body: some View {
        VStack(spacing: 16) {
            // Google Sign In Button - Native Style
            GoogleSignInButton {
                withAnimation {
                    viewModel.signInWithGoogle()
                }
            }
            .frame(height: 54)
            .cornerRadius(12)
            .accessibilityLabel("auth.sign_in_google".localized)
            
            // Apple Sign In Button - Using official ASAuthorizationAppleIDButton
            AppleSignInButton(
                type: .signIn,
                style: themeManager.currentTheme == .dark ? .white : .black
            ) {
                withAnimation {
                    viewModel.signInWithApple()
                }
            }
            .frame(height: 54)
            .cornerRadius(12)
            .accessibilityLabel("auth.sign_in_apple".localized)
            
            // Guest mode button
            Button(action: {
                withAnimation {
                    viewModel.signInAsGuest()
                }
            }) {
                Text("auth.continue_guest".localized)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(themeManager.currentTheme.colors.text.opacity(0.7))
                    .underline()
                    .padding(.top, 8)
            }
            .buttonStyle(ScaleButtonStyle())
            .accessibilityLabel("auth.continue_guest".localized)
        }
        .padding(.horizontal, 16)
        .padding(.bottom, 20)
    }
}

// MARK: - Loading View
struct LoadingView: View {
    @State private var isAnimating = false
    @EnvironmentObject private var themeManager: ThemeManager
    
    var body: some View {
        VStack(spacing: 20) {
            // Custom loading animation
            ZStack {
                Circle()
                    .stroke(lineWidth: 4)
                    .frame(width: 50, height: 50)
                    .foregroundColor(Color.gray.opacity(0.3))
                
                Circle()
                    .trim(from: 0, to: 0.7)
                    .stroke(
                        LinearGradient(
                            gradient: Gradient(colors: [themeManager.currentTheme.colors.primary, themeManager.currentTheme.colors.secondary]),
                            startPoint: .leading,
                            endPoint: .trailing
                        ),
                        style: StrokeStyle(lineWidth: 4, lineCap: .round)
                    )
                    .frame(width: 50, height: 50)
                    .rotationEffect(Angle(degrees: isAnimating ? 360 : 0))
                    .animation(
                        Animation.linear(duration: 1)
                            .repeatForever(autoreverses: false),
                        value: isAnimating
                    )
            }
            
            Text("auth.signing_in".localized)
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(themeManager.currentTheme.colors.text)
        }
        .frame(maxWidth: .infinity)
        .frame(height: 150)
        .onAppear {
            isAnimating = true
        }
    }
}

// MARK: - Error Message View
struct ErrorMessageView: View {
    let message: String
    @State private var isShowing = false
    
    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundColor(.red)
            
            Text(message)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.red)
                .multilineTextAlignment(.leading)
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 16)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.red.opacity(0.1))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color.red.opacity(0.3), lineWidth: 1)
        )
        .opacity(isShowing ? 1 : 0)
        .offset(y: isShowing ? 0 : 20)
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isShowing)
        .onAppear {
            isShowing = true
        }
        .accessibilityLabel("auth.error_message".localized(with: message))
    }
}

// MARK: - Google Sign-In Button
struct GoogleSignInButton: View {
    let action: () -> Void
    @EnvironmentObject private var themeManager: ThemeManager
    @State private var isPressed = false
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                // Google Logo
                GoogleLogoView()
                    .frame(width: 20, height: 20)
                
                Text("auth.sign_in_google".localized)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(themeManager.currentTheme.colors.text)
                
                Spacer()
            }
            .padding(.horizontal, 20)
            .frame(maxWidth: .infinity)
            .frame(height: 54)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(themeManager.currentTheme.colors.background)
                    .shadow(
                        color: isPressed ? Color.black.opacity(0.2) : Color.black.opacity(0.1),
                        radius: isPressed ? 1 : 2,
                        x: 0,
                        y: isPressed ? 1 : 2
                    )
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(
                        themeManager.currentTheme.colors.text.opacity(0.2),
                        lineWidth: 1
                    )
            )
            .scaleEffect(isPressed ? 0.98 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: isPressed)
        }
        .buttonStyle(PlainButtonStyle())
        .onLongPressGesture(minimumDuration: 0, maximumDistance: .infinity, pressing: { pressing in
            isPressed = pressing
        }, perform: {})
        .accessibilityLabel("auth.sign_in_google".localized)
        .accessibilityHint("auth.google_sign_in_hint".localized)
    }
}

// MARK: - Google Logo View
struct GoogleLogoView: View {
    var body: some View {
        ZStack {
            // Background circle
            Circle()
                .fill(Color.white)
                .frame(width: 20, height: 20)
                .shadow(color: Color.black.opacity(0.1), radius: 1, x: 0, y: 1)
            
            // Google logo using system image with custom coloring
            Image(systemName: "globe")
                .font(.system(size: 12, weight: .medium))
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

// MARK: - Color Extension (if not already defined elsewhere)
extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

// MARK: - Preview
struct LoginViewPreview: PreviewProvider {
    static var previews: some View {
        Group {
            // Light Mode Preview
            LoginView()
                .environmentObject(LoginPreviewAuthenticationViewModel())
                .environmentObject(ThemeManager())
                .preferredColorScheme(.light)
                .previewDisplayName("Light Mode")
            
            // Dark Mode Preview
            LoginView()
                .environmentObject(LoginPreviewAuthenticationViewModel())
                .environmentObject(ThemeManager())
                .preferredColorScheme(.dark)
                .previewDisplayName("Dark Mode")
            
            // Loading State Preview
            LoginView()
                .environmentObject(LoginPreviewAuthenticationViewModel(isLoading: true))
                .environmentObject(ThemeManager())
                .previewDisplayName("Loading State")
            
            // Error State Preview
            LoginView()
                .environmentObject(LoginPreviewAuthenticationViewModel(errorMessage: "auth.login_failed".localized))
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
    
    override func signOut() async throws {
        currentUser = nil
    }
}
