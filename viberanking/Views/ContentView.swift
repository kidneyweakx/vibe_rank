//
//  ContentView.swift
//  viberanking
//
//  Created by kidneyweak on 2025/07/23.
//

import SwiftUI

struct ContentView: View {
    @EnvironmentObject private var viewModel: AuthenticationViewModel
    
    var body: some View {
        ZStack {
            // Background gradient matching the cute star theme
            AppTheme.Colors.primaryGradient
                .ignoresSafeArea()
            
            Group {
                if viewModel.isAuthenticated {
                    MainTabView()
                } else {
                    LoginView()
                }
            }
        }
        .preferredColorScheme(.light) // Force light mode for consistent cute theme
        .localized()
    }
}



#Preview {
    ContentView()
        .environmentObject(AuthenticationViewModel())
}