import SwiftUI

struct ThemeSwitcherView: View {
    @EnvironmentObject var themeManager: ThemeManager
    
    var body: some View {
        Picker("Theme", selection: $themeManager.currentTheme) {
            ForEach(themeManager.themes, id: \.self) { theme in
                Text(theme.rawValue)
                    .tag(theme)
            }
        }
        .pickerStyle(SegmentedPickerStyle())
        .padding()
    }
}

struct ThemeSwitcherView_Previews: PreviewProvider {
    static var previews: some View {
        ThemeSwitcherView()
            .environmentObject(ThemeManager())
    }
}
