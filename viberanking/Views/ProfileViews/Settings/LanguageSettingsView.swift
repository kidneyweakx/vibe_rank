//
//  LanguageSettingsView.swift
//  viberanking
//
//  Created by Kiro on 2025/07/25.
//

import SwiftUI

// MARK: - Language Settings View
struct LanguageSettingsView: View {
    
    // MARK: - Properties
    @ObservedObject private var localizationManager = LocalizationManager.shared
    @Environment(\.dismiss) private var dismiss
    
    // MARK: - Body
    var body: some View {
        NavigationView {
            List {
                Section {
                    ForEach(LocalizationManager.Language.allCases, id: \.rawValue) { language in
                        languageRow(for: language)
                    }
                } header: {
                    Text("settings.language.available".localized)
                } footer: {
                    Text("settings.language.restart_note".localized)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .navigationTitle("settings.language.title".localized)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("common.done".localized) {
                        dismiss()
                    }
                }
            }
        }
    }
}

// MARK: - View Components
private extension LanguageSettingsView {
    
    /// Language selection row
    func languageRow(for language: LocalizationManager.Language) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(language.displayName)
                    .font(.body)
                    .foregroundColor(.primary)
                
                if language == .system {
                    Text("settings.language.system_desc".localized)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
            
            if localizationManager.currentLanguage == language {
                Image(systemName: "checkmark")
                    .foregroundColor(.accentColor)
                    .font(.body.weight(.semibold))
            }
        }
        .contentShape(Rectangle())
        .onTapGesture {
            withAnimation(.easeInOut(duration: 0.2)) {
                localizationManager.currentLanguage = language
            }
        }
    }
}

// MARK: - Preview
#Preview {
    LanguageSettingsView()
}