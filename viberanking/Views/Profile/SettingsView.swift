//
//  SettingsView.swift
//  viberanking
//
//  Created by Kiro on 2025/08/09.
//

import SwiftUI

struct SettingsView: View {
    @EnvironmentObject private var authViewModel: AuthenticationViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var showingLogoutAlert = false
    @State private var showingImagePicker = false
    @State private var showTerms = false
    @State private var showPrivacy = false
    @State private var showContact = false
    @State private var name = ""
    @State private var customUserID: String = ""
    @State private var isCheckingID = false
    @State private var idAvailable: Bool? = nil
    @State private var selectedGender: Gender? = nil
    @State private var showGenderSheet = false
    @State private var bio = ""
    @State private var location = ""
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.black.ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        // Profile Image Section
                        VStack(spacing: 16) {
                            Button(action: {
                                showingImagePicker = true
                            }) {
                                Circle()
                                    .fill(
                                        LinearGradient(
                                            colors: [Color.pink.opacity(0.8), Color.purple.opacity(0.6)],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                    )
                                    .frame(width: 100, height: 100)
                                    .overlay(
                                        Group {
                                            if let profileImageURL = authViewModel.user?.profileImageURL,
                                               let url = URL(string: profileImageURL) {
                                                AsyncImage(url: url) { image in
                                                    image
                                                        .resizable()
                                                        .aspectRatio(contentMode: .fill)
                                                } placeholder: {
                                                    Image(systemName: "person.fill")
                                                        .font(.system(size: 40))
                                                        .foregroundColor(.white)
                                                }
                                                .clipShape(Circle())
                                            } else {
                                                Image(systemName: "person.fill")
                                                    .font(.system(size: 40))
                                                    .foregroundColor(.white)
                                            }
                                        }
                                    )
                                    .overlay(
                                        Circle()
                                            .stroke(Color.white.opacity(0.2), lineWidth: 2)
                                    )
                            }
                            
                            Text("Tap to change photo")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(.white.opacity(0.6))
                        }
                        
                        // Personal Info Section
                        VStack(alignment: .leading, spacing: 16) {
                            Text("Personal Information")
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundColor(.white)
                            
                            VStack(spacing: 16) {
                                SettingsTextField(title: "Name", text: $name, placeholder: "Enter your name")
                                // Username / ID
                                VStack(alignment: .leading, spacing: 8) {
                                    Text("User ID")
                                        .font(.system(size: 14, weight: .medium))
                                        .foregroundColor(.white.opacity(0.8))
                                    HStack(spacing: 8) {
                                        TextField("Enter your user ID", text: $customUserID)
                                            .autocapitalization(.none)
                                            .disableAutocorrection(true)
                                            .font(.system(size: 16))
                                            .foregroundColor(.white)
                                            .padding(16)
                                            .background(
                                                RoundedRectangle(cornerRadius: 12)
                                                    .fill(Color.white.opacity(0.05))
                                                    .overlay(
                                                        RoundedRectangle(cornerRadius: 12)
                                                            .stroke(Color.white.opacity(0.1), lineWidth: 1)
                                                    )
                                            )
                                            .onChange(of: customUserID) { _ in
                                                idAvailable = nil
                                            }
                                        Button(action: {
                                            Task {
                                                isCheckingID = true
                                                let trimmed = customUserID.trimmingCharacters(in: .whitespacesAndNewlines)
                                                if trimmed.isEmpty {
                                                    idAvailable = nil
                                                    isCheckingID = false
                                                    return
                                                }
                                                let available = await authViewModel.checkUserIDAvailability(trimmed)
                                                await MainActor.run {
                                                    idAvailable = available
                                                    isCheckingID = false
                                                }
                                            }
                                        }) {
                                            if isCheckingID { ProgressView().tint(.white) } else { Text("Check").font(.system(size: 14, weight: .semibold)) }
                                        }
                                        .padding(.horizontal, 12)
                                        .frame(height: 44)
                                        .background(RoundedRectangle(cornerRadius: 10).fill(Color.white.opacity(0.1)))
                                    }
                                    if let idAvailable = idAvailable {
                                        Text(idAvailable ? "This ID is available" : "This ID is taken")
                                            .font(.system(size: 12))
                                            .foregroundColor(idAvailable ? .green : .red)
                                    } else {
                                        Text("ID can be changed here. We will check availability.")
                                            .font(.system(size: 12))
                                            .foregroundColor(.secondary)
                                    }
                                }
                                // Gender Selection
                                VStack(alignment: .leading, spacing: 8) {
                                    Text("Gender")
                                        .font(.system(size: 14, weight: .medium))
                                        .foregroundColor(.white.opacity(0.8))
                                    HStack(spacing: 12) {
                                        ForEach(Gender.allCases, id: \.self) { gender in
                                            Button(action: { selectedGender = gender }) {
                                                Text(gender.displayName)
                                                    .padding(.horizontal, 12)
                                                    .padding(.vertical, 8)
                                                    .background(
                                                        RoundedRectangle(cornerRadius: 10)
                                                            .fill((selectedGender == gender) ? Color.blue.opacity(0.3) : Color.white.opacity(0.05))
                                                    )
                                                    .overlay(
                                                        RoundedRectangle(cornerRadius: 10)
                                                            .stroke((selectedGender == gender) ? Color.blue : Color.white.opacity(0.1), lineWidth: 1)
                                                    )
                                            }
                                            .foregroundColor(.white)
                                        }
                                    }
                                }
                                SettingsTextField(title: "Bio", text: $bio, placeholder: "Tell us about yourself")
                                SettingsTextField(title: "Location", text: $location, placeholder: "Your location")
                            }
                        }
                        
                        // Account Section
                        VStack(alignment: .leading, spacing: 16) {
                            Text("Account")
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundColor(.white)
                            
                            VStack(spacing: 12) {
                                SettingsRow(
                                    icon: "bell.fill",
                                    title: "Notifications",
                                    action: {
                                        // Handle notifications
                                    }
                                )
                                
                                SettingsRow(
                                    icon: "lock.fill",
                                    title: "Privacy",
                                    action: {
                                        showPrivacy = true
                                    }
                                )
                                
                                SettingsRow(
                                    icon: "questionmark.circle.fill",
                                    title: "Help & Support",
                                    action: {
                                        // Handle help
                                    }
                                )
                                
                                SettingsRow(
                                    icon: "info.circle.fill",
                                    title: "About",
                                    action: {
                                        // Handle about
                                    }
                                )
                                
                                SettingsRow(
                                    icon: "doc.text.fill",
                                    title: "Terms of Service",
                                    action: {
                                        showTerms = true
                                    }
                                )
                                
                                SettingsRow(
                                    icon: "envelope.fill",
                                    title: "Contact Us",
                                    action: {
                                        showContact = true
                                    }
                                )
                            }
                        }
                        
                        // Danger Zone
                        VStack(alignment: .leading, spacing: 16) {
                            Text("Account Actions")
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundColor(.white)
                            
                            Button {
                                showingLogoutAlert = true
                            } label: {
                                HStack {
                                    Image(systemName: "rectangle.portrait.and.arrow.right")
                                        .font(.system(size: 16))
                                        .foregroundColor(.red)
                                    
                                    Text("Sign Out")
                                        .font(.system(size: 16, weight: .medium))
                                        .foregroundColor(.red)
                                    
                                    Spacer()
                                    
                                    Image(systemName: "chevron.right")
                                        .font(.system(size: 12))
                                        .foregroundColor(.red.opacity(0.6))
                                }
                                .padding(16)
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(Color.red.opacity(0.1))
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 12)
                                                .stroke(Color.red.opacity(0.3), lineWidth: 1)
                                        )
                                )
                            }
                        }
                    }
                    .padding(20)
                    .padding(.bottom, 100)
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.large)
            .navigationBarBackButtonHidden(true)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.white)
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        saveSettings()
                    }
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.blue)
                }
            }
        }
        .preferredColorScheme(.dark)
        .sheet(isPresented: $showTerms) {
            TermsOfServiceView()
        }
        .sheet(isPresented: $showPrivacy) {
            PrivacyPolicyView()
        }
        .sheet(isPresented: $showContact) {
            ContactUsView()
        }
        .sheet(isPresented: $showingImagePicker) {
            ImagePicker(sourceType: .photoLibrary) { image in
                // Handle profile image upload
                uploadProfileImage(image)
            }
        }
        .alert("Sign Out", isPresented: $showingLogoutAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Sign Out", role: .destructive) {
                authViewModel.signOut()
            }
        } message: {
            Text("Are you sure you want to sign out?")
        }
        .onAppear {
            loadUserData()
            // Prompt gender selection if not set
            if selectedGender == nil { showGenderSheet = authViewModel.user?.gender == nil }
        }
        .sheet(isPresented: $showGenderSheet) {
            GenderPromptView(selectedGender: $selectedGender) {
                showGenderSheet = false
            }
            .presentationDetents([.height(260)])
            .presentationDragIndicator(.visible)
        }
    }
    
    private func loadUserData() {
        name = authViewModel.user?.name ?? ""
        customUserID = authViewModel.user?.id ?? ""
        selectedGender = authViewModel.user?.gender
        // Load other user data
    }
    
    private func saveSettings() {
        let trimmedId = customUserID.trimmingCharacters(in: .whitespacesAndNewlines)
        let currentId = authViewModel.user?.id ?? ""
        Task {
            // Change ID first if different
            if !trimmedId.isEmpty, trimmedId != currentId {
                let available = await authViewModel.checkUserIDAvailability(trimmedId)
                if available {
                    await MainActor.run { self.isCheckingID = true }
                    do { try await authViewModel.changeUserID(to: trimmedId) } catch { await MainActor.run { self.isCheckingID = false }; return }
                    await MainActor.run { self.isCheckingID = false }
                } else {
                    await MainActor.run { self.idAvailable = false }
                    return
                }
            }
            // Update name and gender
            do { try await authViewModel.saveProfileEdits(name: name.isEmpty ? nil : name, gender: selectedGender) } catch { return }
            await MainActor.run { dismiss() }
        }
    }
    
    private func uploadProfileImage(_ image: UIImage) {
        // Upload profile image logic
    }
}

// MARK: - Gender Prompt

struct GenderPromptView: View {
    @Binding var selectedGender: Gender?
    var onDone: () -> Void
    
    var body: some View {
        VStack(spacing: 16) {
            Text("Select Gender")
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(.white)
            HStack(spacing: 12) {
                ForEach(Gender.allCases, id: \.self) { gender in
                    Button(action: { selectedGender = gender }) {
                        Text(gender.displayName)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 10)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill((selectedGender == gender) ? Color.blue.opacity(0.3) : Color.white.opacity(0.05))
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke((selectedGender == gender) ? Color.blue : Color.white.opacity(0.1), lineWidth: 1)
                            )
                    }
                    .foregroundColor(.white)
                }
            }
            Button("Done") { onDone() }
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 44)
                .background(RoundedRectangle(cornerRadius: 12).fill(Color.blue))
                .padding(.top, 8)
        }
        .padding(20)
        .background(Color.black)
    }
}

struct SettingsTextField: View {
    let title: String
    @Binding var text: String
    let placeholder: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.white.opacity(0.8))
            
            TextField(placeholder, text: $text)
                .font(.system(size: 16))
                .foregroundColor(.white)
                .padding(16)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.white.opacity(0.05))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.white.opacity(0.1), lineWidth: 1)
                        )
                )
        }
    }
}

struct SettingsRow: View {
    let icon: String
    let title: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                Image(systemName: icon)
                    .font(.system(size: 16))
                    .foregroundColor(.white.opacity(0.8))
                    .frame(width: 24)
                
                Text(title)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.white)
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.system(size: 12))
                    .foregroundColor(.white.opacity(0.4))
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.white.opacity(0.05))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.white.opacity(0.1), lineWidth: 1)
                    )
            )
        }
    }
}

#Preview {
    SettingsView()
        .environmentObject(AuthenticationViewModel())
}