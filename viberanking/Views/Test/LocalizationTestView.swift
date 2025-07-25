//
//  LocalizationTestView.swift
//  viberanking
//
//  Created by Kiro on 2025/07/25.
//

import SwiftUI

// MARK: - Localization Test View
struct LocalizationTestView: View {
    
    // MARK: - Properties
    @ObservedObject private var localizationManager = LocalizationManager.shared
    @State private var showLanguageSettings = false
    
    // MARK: - Body
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // Current language info
                    currentLanguageSection
                    
                    // Sample localized strings
                    sampleStringsSection
                    
                    // Tab bar strings
                    tabBarSection
                    
                    // Authentication strings
                    authenticationSection
                    
                    // Upload strings
                    uploadSection
                    
                    // Rating strings
                    ratingSection
                }
                .padding()
            }
            .navigationTitle("Localization Test")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Language") {
                        showLanguageSettings = true
                    }
                }
            }
            .sheet(isPresented: $showLanguageSettings) {
                LanguageSettingsView()
            }
        }
    }
}

// MARK: - View Components
private extension LocalizationTestView {
    
    /// Current language section
    var currentLanguageSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Current Language")
                .font(.headline)
            
            Text("Selected: \(localizationManager.currentLanguage.displayName)")
                .font(.body)
                .foregroundColor(.secondary)
            
            Text("Code: \(localizationManager.currentLanguage.code)")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color(.systemGroupedBackground))
        .cornerRadius(12)
    }
    
    /// Sample strings section
    var sampleStringsSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Sample Strings")
                .font(.headline)
            
            Group {
                Text("common.loading".localized)
                Text("common.error".localized)
                Text("common.cancel".localized)
                Text("common.done".localized)
            }
            .font(.body)
            .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color(.systemGroupedBackground))
        .cornerRadius(12)
    }
    
    /// Tab bar section
    var tabBarSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Tab Bar")
                .font(.headline)
            
            Group {
                Text("tab.rating".localized)
                Text("tab.upload".localized)
                Text("tab.report".localized)
                Text("tab.profile".localized)
            }
            .font(.body)
            .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color(.systemGroupedBackground))
        .cornerRadius(12)
    }
    
    /// Authentication section
    var authenticationSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Authentication")
                .font(.headline)
            
            Group {
                Text("auth.title".localized)
                Text("auth.subtitle".localized)
                Text("auth.sign_in_google".localized)
                Text("auth.sign_in_apple".localized)
            }
            .font(.body)
            .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color(.systemGroupedBackground))
        .cornerRadius(12)
    }
    
    /// Upload section
    var uploadSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Upload")
                .font(.headline)
            
            Group {
                Text("upload.title".localized)
                Text("upload.share_style".localized)
                Text("upload.take_photo".localized)
                Text("upload.choose_library".localized)
            }
            .font(.body)
            .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color(.systemGroupedBackground))
        .cornerRadius(12)
    }
    
    /// Rating section
    var ratingSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Rating")
                .font(.headline)
            
            Group {
                Text("rating.title".localized)
                Text("rating.subtitle".localized)
                Text("rating.hot".localized)
                Text("rating.not".localized)
            }
            .font(.body)
            .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color(.systemGroupedBackground))
        .cornerRadius(12)
    }
}

// MARK: - Preview
#Preview {
    LocalizationTestView()
}