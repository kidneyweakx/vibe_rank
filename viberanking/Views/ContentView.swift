//
//  ContentView.swift
//  viberanking
//
//  Created by kidneyweak on 2025/07/23.
//

import SwiftUI

struct ContentView: View {
    @EnvironmentObject private var viewModel: AuthenticationViewModel
    @EnvironmentObject private var themeManager: ThemeManager
    
    var body: some View {
        ZStack {
            // Background gradient matching the cute star theme
            LinearGradient(
                colors: [themeManager.currentTheme.colors.primary, themeManager.currentTheme.colors.secondary],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            Group {
                if viewModel.isAuthenticated {
                    MainTabView()
                } else {
                    LoginView()
                }
            }
        }
        .preferredColorScheme(themeManager.currentTheme == .dark ? .dark : .light)
        .localized()
    }
}



#Preview {
    ContentView()
        .environmentObject(AuthenticationViewModel())
}