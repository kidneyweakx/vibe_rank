import SwiftUI

enum Theme: String, CaseIterable {
    case light = "Light"
    case dark = "Dark"
    case blueYellow = "Blue & Yellow"
    case navyOrange = "Navy & Orange"
    
    var colors: ColorScheme {
        switch self {
        case .light:
            return LightTheme()
        case .dark:
            return DarkTheme()
        case .blueYellow:
            return BlueYellowTheme()
        case .navyOrange:
            return NavyOrangeTheme()
        }
    }
}

protocol ColorScheme {
    var primary: Color { get }
    var secondary: Color { get }
    var accent: Color { get }
    var background: Color { get }
    var text: Color { get }
    var cardBackground: Color { get }
    var chartGradient: [Color] { get }
}

struct LightTheme: ColorScheme {
    var primary = Color(red: 0.2, green: 0.4, blue: 1.0)
    var secondary = Color(red: 0.0, green: 0.7, blue: 1.0)
    var accent = Color(red: 1.0, green: 0.8, blue: 0.0)
    var background = Color(red: 1.0, green: 1.0, blue: 0.98)
    var text = Color.black
    var cardBackground = Color.white
    var chartGradient = [Color.blue, Color.cyan]
}

struct DarkTheme: ColorScheme {
    // Logo gradient colors: Coral Pink → Turquoise
    var primary = Color(red: 255/255, green: 139/255, blue: 148/255) // Coral Pink
    var secondary = Color(red: 94/255, green: 205/255, blue: 200/255) // Turquoise
    var accent = Color(red: 94/255, green: 205/255, blue: 200/255) // Turquoise accent
    var background = Color(red: 0.06, green: 0.06, blue: 0.08) // Subtle dark blue-black
    var text = Color.white
    var cardBackground = Color(red: 0.10, green: 0.10, blue: 0.12) // Lighter dark with subtle blue
    var chartGradient = [
        Color(red: 255/255, green: 139/255, blue: 148/255), // Coral Pink
        Color(red: 184/255, green: 152/255, blue: 156/255), // Rose Mauve
        Color(red: 152/255, green: 161/255, blue: 159/255), // Gray
        Color(red: 94/255, green: 205/255, blue: 200/255)   // Turquoise
    ]
}

struct BlueYellowTheme: ColorScheme {
    var primary = Color(red: 55/255, green: 175/255, blue: 225/255)
    var secondary = Color(red: 76/255, green: 201/255, blue: 254/255)
    var accent = Color(red: 245/255, green: 244/255, blue: 179/255)
    var background = Color(red: 255/255, green: 254/255, blue: 203/255)
    var text = Color.black
    var cardBackground = Color(red: 250/255, green: 249/255, blue: 198/255)
    var chartGradient = [Color(red: 55/255, green: 175/255, blue: 225/255), Color(red: 245/255, green: 244/255, blue: 179/255)]
}

struct NavyOrangeTheme: ColorScheme {
    var primary = Color(red: 0/255, green: 50/255, blue: 133/255)
    var secondary = Color(red: 42/255, green: 98/255, blue: 154/255)
    var accent = Color(red: 255/255, green: 127/255, blue: 62/255)
    var background = Color(red: 255/255, green: 218/255, blue: 120/255)
    var text = Color.white
    var cardBackground = Color(red: 250/255, green: 213/255, blue: 115/255)
    var chartGradient = [Color(red: 0/255, green: 50/255, blue: 133/255), Color(red: 255/255, green: 127/255, blue: 62/255)]
}

class ThemeManager: ObservableObject {
    @Published var currentTheme: Theme = .light
    
    let themes: [Theme] = [.light, .dark]
    
    func applyTheme(_ theme: Theme) {
        self.currentTheme = theme
    }
}
