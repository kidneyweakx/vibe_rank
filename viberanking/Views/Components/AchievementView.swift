import SwiftUI

struct AchievementView: View {
    let achievement: Achievement
    
    var body: some View {
        HStack {
            Image(systemName: achievement.iconName)
                .font(.largeTitle)
                .foregroundColor(achievement.isUnlocked ? .yellow : .gray)
                .frame(width: 60)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(achievement.title)
                    .font(.headline)
                    .fontWeight(.bold)
                
                Text(achievement.description)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                if !achievement.isUnlocked {
                    ProgressView(value: achievement.requirement.progressPercentage)
                        .progressViewStyle(LinearProgressViewStyle(tint: .yellow))
                }
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(10)
    }
}

struct AchievementView_Previews: PreviewProvider {
    static var previews: some View {
        VStack {
            AchievementView(achievement: mockAchievements[0])
            AchievementView(achievement: mockAchievements[3])
        }
        .padding()
    }
}
