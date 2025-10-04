import SwiftUI

// MARK: - Custom TikTok Style Tab Bar
struct CustomTikTokTabBar: View {
    @Binding var selectedTab: TabItem
    let onUploadTap: () -> Void
    let onVibeTap: () -> Void
    
    var body: some View {
        HStack(spacing: 0) {
            // Rating Tab (Vibe)
            TabBarButton(
                icon: "heart.fill",
                title: "tab.vibe".localized,
                isSelected: selectedTab == .rating
            ) {
                onVibeTap()
            }
            .spotlightTarget(id: "tab_rating")
            
            Spacer()
            
            // Trend Tab
            TabBarButton(
                icon: "flame.fill",
                title: "tab.trend".localized,
                isSelected: selectedTab == .home
            ) {
                selectedTab = .home
            }
            .spotlightTarget(id: "tab_trend")
            
            Spacer()
            
            // Plus
            Button(action: { onUploadTap() }) {
                ZStack {
                    Circle()
                        .fill(Color.red)
                        .frame(width: 56, height: 56)
                    Image(systemName: "plus")
                        .font(.system(size: 22, weight: .bold))
                        .foregroundColor(.white)
                }
            }
            .offset(y: -10)
            .spotlightTarget(id: "tab_plus")
            
            Spacer()
            
            // Journey Tab
            TabBarButton(
                icon: "sparkles",
                title: "tab.journey".localized,
                isSelected: selectedTab == .journey
            ) {
                selectedTab = .journey
            }
            .spotlightTarget(id: "tab_journey")
            
            Spacer()
            
            // Profile Tab
            TabBarButton(
                icon: "person.circle.fill",
                title: "tab.profile".localized,
                isSelected: selectedTab == .profile
            ) {
                selectedTab = .profile
            }
            .spotlightTarget(id: "tab_profile")
        }
        .padding(.horizontal, 20)
        .padding(.top, 8)
        .padding(.bottom, 8)
        .background(
            Color.black
                .ignoresSafeArea(edges: .bottom)
        )
    }
}

// MARK: - Tab Bar Button
struct TabBarButton: View {
    let icon: String
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 20))
                    .foregroundColor(isSelected ? .red : .gray)
                Text(title)
                    .font(.system(size: 10))
                    .foregroundColor(isSelected ? .red : .gray)
            }
        }
        .frame(width: 60, height: 50)
    }
}


