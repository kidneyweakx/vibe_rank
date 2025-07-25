//
//  LocalizationManager.swift
//  viberanking
//
//  Created by Kiro on 2025/07/25.
//

import Foundation
import SwiftUI

// MARK: - Localization Manager
class LocalizationManager: ObservableObject {
    
    // MARK: - Singleton
    static let shared = LocalizationManager()
    
    // MARK: - Properties
    @Published var currentLanguage: Language = .system {
        didSet {
            UserDefaults.standard.set(currentLanguage.rawValue, forKey: "selected_language")
            updateBundle()
        }
    }
    
    private var bundle: Bundle = Bundle.main
    
    // MARK: - Supported Languages
    enum Language: String, CaseIterable {
        case system = "system"
        case english = "en"
        case traditionalChinese = "zh-Hant"
        
        var displayName: String {
            switch self {
            case .system:
                return "System"
            case .english:
                return "English"
            case .traditionalChinese:
                return "繁體中文"
            }
        }
        
        var code: String {
            switch self {
            case .system:
                return Locale.current.language.languageCode?.identifier ?? "en"
            case .english:
                return "en"
            case .traditionalChinese:
                return "zh-Hant"
            }
        }
    }
    
    // MARK: - Initialization
    private init() {
        // Load saved language preference
        if let savedLanguage = UserDefaults.standard.string(forKey: "selected_language"),
           let language = Language(rawValue: savedLanguage) {
            currentLanguage = language
        }
        updateBundle()
    }
    
    // MARK: - Methods
    private func updateBundle() {
        let languageCode = currentLanguage == .system ? 
            (Locale.current.language.languageCode?.identifier ?? "en") : 
            currentLanguage.code
        
        if let path = Bundle.main.path(forResource: languageCode, ofType: "lproj"),
           let bundle = Bundle(path: path) {
            self.bundle = bundle
        } else {
            // Fallback to main bundle if localization not found
            self.bundle = Bundle.main
        }
    }
    
    func localizedString(for key: String, comment: String = "") -> String {
        return NSLocalizedString(key, bundle: bundle, comment: comment)
    }
}

// MARK: - String Extension for Localization
extension String {
    var localized: String {
        return LocalizationManager.shared.localizedString(for: self)
    }
    
    func localized(with arguments: CVarArg...) -> String {
        return String(format: self.localized, arguments: arguments)
    }
}

// MARK: - SwiftUI Environment Key
struct LocalizationEnvironmentKey: EnvironmentKey {
    static let defaultValue = LocalizationManager.shared
}

extension EnvironmentValues {
    var localization: LocalizationManager {
        get { self[LocalizationEnvironmentKey.self] }
        set { self[LocalizationEnvironmentKey.self] = newValue }
    }
}

// MARK: - View Modifier for Localization
struct LocalizedViewModifier: ViewModifier {
    @ObservedObject private var localizationManager = LocalizationManager.shared
    
    func body(content: Content) -> some View {
        content
            .environment(\.localization, localizationManager)
            .environment(\.locale, Locale(identifier: localizationManager.currentLanguage.code))
    }
}

extension View {
    func localized() -> some View {
        self.modifier(LocalizedViewModifier())
    }
}