//
//  LoginView.swift
//  viberanking
//
//  Created by Kiro on 2025/07/23.
//

import SwiftUI

struct LoginView: View {
    @EnvironmentObject private var viewModel: AuthenticationViewModel
    
    var body: some View {
        VStack(spacing: 20) {
            Spacer()
            
            Image(systemName: "star.circle.fill")
                .resizable()
                .scaledToFit()
                .frame(width: 100, height: 100)
                .foregroundColor(.blue)
            
            Text("數位頂尖社交評價平台")
                .font(.title)
                .fontWeight(.bold)
            
            Text("登入以開始評分和獲取個人風格分析")
                .font(.headline)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            Spacer()
            
            if viewModel.isLoading {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle())
            } else {
                VStack(spacing: 12) {
                    Button(action: {
                        viewModel.signInWithGoogle()
                    }) {
                        HStack {
                            Image(systemName: "g.circle.fill")
                            Text("使用 Google 登入")
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                    }
                    
                    Button(action: {
                        viewModel.signInWithApple()
                    }) {
                        HStack {
                            Image(systemName: "applelogo")
                            Text("使用 Apple 登入")
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.black)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                    }
                }
                .padding(.horizontal)
            }
            
            if let errorMessage = viewModel.errorMessage {
                Text(errorMessage)
                    .foregroundColor(.red)
                    .padding()
            }
            
            Spacer()
        }
        .padding()
    }
}

#Preview {
    LoginView()
        .environmentObject(AuthenticationViewModel())
}
