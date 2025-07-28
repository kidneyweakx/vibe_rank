//
//  JourneyTabView.swift
//  viberanking
//
//  Created by Kiro on 2025/07/29.
//

import SwiftUI

struct JourneyTabView: View {
    @EnvironmentObject private var themeManager: ThemeManager
    
    var body: some View {
        NavigationView {
            ZStack {
                // 黑色背景
                Color.black
                    .ignoresSafeArea()
                
                VStack(spacing: 20) {
                    Text("Journey")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                    
                    Text("探索你的風格之旅")
                        .font(.headline)
                        .foregroundColor(.gray)
                    
                    Spacer()
                    
                    // 佔位內容
                    VStack(spacing: 16) {
                        Image(systemName: "map.circle.fill")
                            .font(.system(size: 60))
                            .foregroundColor(.red)
                        
                        Text("即將推出")
                            .font(.title2)
                            .foregroundColor(.white)
                        
                        Text("記錄你的時尚成長軌跡")
                            .font(.body)
                            .foregroundColor(.gray)
                            .multilineTextAlignment(.center)
                    }
                    
                    Spacer()
                }
                .padding()
            }
            .navigationBarHidden(true)
        }
    }
}

#Preview {
    JourneyTabView()
        .environmentObject(ThemeManager())
}