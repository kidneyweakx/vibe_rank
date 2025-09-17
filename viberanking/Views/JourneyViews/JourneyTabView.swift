//
//  JourneyTabView.swift
//  viberanking
//
//  Created by Kiro on 2025/07/29.
//

import SwiftUI

struct JourneyTabView: View {
    @EnvironmentObject private var themeManager: ThemeManager
    @EnvironmentObject private var authViewModel: AuthenticationViewModel
    @StateObject private var viewModel = JourneyViewModel()
    @State private var showingPaywall = false
    @State private var showingEvaluation = false
    @State private var showDressingRoom = false
    @State private var isLoaded = false
    
    var body: some View {
        if #available(iOS 16.0, *) {
            NavigationStack {
                mainContent
            }
        } else {
            NavigationView {
                mainContent
            }
            .navigationViewStyle(StackNavigationViewStyle())
        }
    }
    
    private var mainContent: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            if isLoaded {
                ScrollView {
                    LazyVStack(spacing: 24) {
                        // 標題
                        HStack {
                            Text("journey.title".localized)
                                .font(.largeTitle)
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                            Spacer()
                        }
                        .padding(.horizontal, 20)
                        
                        JourneyAchievementBadge(
                            level: viewModel.journeyLevel,
                            overallPerformance: viewModel.overallPerformance
                        )
                        
                        // 圖表
                        JourneyTrendChart(data: viewModel.chartData)
                        
                        // 統計卡片
                        JourneyStatCards(
                            overallPerformance: viewModel.overallPerformance,
                            femaleAttraction: viewModel.femaleAttraction,
                            maleAttraction: viewModel.maleAttraction,
                            currentRankPercentage: viewModel.currentRankPercentage,
                            totalUsers: viewModel.totalUsers
                        )
                        
                        // AI 改進方案 (付費區塊)
                        aiImprovementSection
                    }
                    .padding(.top, 20)
                    .safeAreaInset(edge: .bottom) {
                        // Avoid being overlapped by custom tab bar on compact-height devices (e.g., iPhone 13 non-fullscreen)
                        Color.clear.frame(height: 90)
                    }
                }
            } else {
                // Loading state
                VStack {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        .scaleEffect(1.2)
                    
                    Text("journey.loading_data".localized)
                        .foregroundColor(.white.opacity(0.7))
                        .padding(.top, 16)
                }
            }
        }
        .navigationBarHidden(true)
        .sheet(isPresented: $showingPaywall) {
            PaywallView(isPresented: $showingPaywall) {
                Task {
                    await viewModel.evaluateLatestPhotoIfPossible()
                    await viewModel.analyzeOutfitForLatestPhoto()
                }
                showDressingRoom = true
            }
        }
        .background(
            NavigationLink("", destination: DressingRoomView(userId: authViewModel.user?.id ?? "").environmentObject(themeManager), isActive: $showDressingRoom)
                .opacity(0)
        )
        .alert("AI Evaluation", isPresented: $showingEvaluation, actions: {
            Button("OK", role: .cancel) {}
        }, message: {
            if let result = viewModel.latestEvaluationText {
                Text(result)
            } else {
                Text("No result available")
            }
        })
        .onAppear {
            loadDataIfNeeded()
        }
        .onChange(of: authViewModel.user?.id) { newUserId in
            // When user becomes available or changes, (re)load journey data
            guard let userId = newUserId else { return }
            print("🔁 JourneyTabView: User changed, reloading data for: \(userId)")
            isLoaded = false
            Task {
                await viewModel.loadUserJourney(userId: userId)
                await MainActor.run {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        isLoaded = true
                    }
                }
            }
        }
    }
    
    private func loadDataIfNeeded() {
        guard !isLoaded else { return }
        
        print("🔄 JourneyTabView: Starting to load data...")
        
        if let userId = authViewModel.user?.id {
            print("👤 JourneyTabView: Loading data for user: \(userId)")
            Task {
                do {
                    await viewModel.loadUserJourney(userId: userId)
                    await MainActor.run {
                        print("✅ JourneyTabView: Data loaded successfully")
                        withAnimation(.easeInOut(duration: 0.3)) {
                            isLoaded = true
                        }
                    }
                } catch {
                    print("❌ JourneyTabView: Error loading data: \(error)")
                    await MainActor.run {
                        // Still show the view with mock data
                        withAnimation(.easeInOut(duration: 0.3)) {
                            isLoaded = true
                        }
                    }
                }
            }
        } else {
            // Keep loading until user becomes available to avoid showing N/A placeholders
            print("⏳ JourneyTabView: No user yet, waiting for authentication...")
        }
    }
    
    
    
    
    
    
    
    
    
    private var aiImprovementSection: some View {
        VStack(spacing: 16) {
            HStack {
                Image(systemName: "brain.head.profile")
                    .foregroundColor(.purple)
                Text("journey.ai_improvement.title".localized)
                    .font(.headline)
                    .foregroundColor(.white)
                Spacer()
                Image(systemName: "lock.fill")
                    .foregroundColor(.yellow)
                    .font(.caption)
            }
            
            VStack(alignment: .leading, spacing: 12) {
                Text("journey.ai_improvement.personalized_suggestions".localized)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                        Text("journey.ai_improvement.professional_analysis".localized)
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                    
                    HStack {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                        Text("journey.ai_improvement.outfit_suggestions".localized)
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                    
                    HStack {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                        Text("journey.ai_improvement.color_recommendations".localized)
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                    
                    HStack {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                        Text("journey.ai_improvement.trend_prediction".localized)
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                }
                
                Button(action: {
                    showingPaywall = true
                }) {
                    HStack {
                        Image(systemName: "sparkles")
                        Text("journey.ai_improvement.unlock_button".localized)
                            .fontWeight(.semibold)
                        Spacer()
                        Image(systemName: "arrow.right")
                    }
                    .foregroundColor(.white)
                    .padding(.vertical, 16)
                    .padding(.horizontal, 20)
                    .background(
                        LinearGradient(
                            colors: [.purple, .pink],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .cornerRadius(12)
                }
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.gray.opacity(0.1))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.purple.opacity(0.3), lineWidth: 1)
                )
        )
        .padding(.horizontal, 20)
    }
}

#Preview {
    JourneyTabView()
        .environmentObject(ThemeManager())
        .environmentObject(AuthenticationViewModel())
        .preferredColorScheme(.dark)
}
