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
    var primary = Color(red: 0.2, green: 0.4, blue: 1.0)
    var secondary = Color(red: 0.0, green: 0.7, blue: 1.0)
    var accent = Color(red: 1.0, green: 0.8, blue: 0.0)
    var background = Color.black 
    var text = Color.white
    var cardBackground = Color(white: 0.05) 
    var chartGradient = [Color.white, Color.red]
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
    
    let themes: [Theme] = [.light, .dark, .blueYellow, .navyOrange]
    
    func applyTheme(_ theme: Theme) {
        self.currentTheme = theme
    }
}
