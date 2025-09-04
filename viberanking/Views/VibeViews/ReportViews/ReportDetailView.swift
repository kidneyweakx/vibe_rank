//
//  ReportDetailView.swift
//  viberanking
//
//  Created by Kiro on 2025/07/25.
//

import SwiftUI

struct ReportDetailView: View {
    let reportType: ReportType
    let photoId: String?
    @Environment(\.dismiss) private var dismiss
    @State private var reportText = ""
    @State private var isSubmitting = false
    @State private var showSuccess = false
    @State private var showError: String?
    @StateObject private var authService = AuthenticationService()
    private let fileAPI = FileAPI()
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.black.ignoresSafeArea()
                
                VStack(spacing: 24) {
                    // Header
                    VStack(spacing: 16) {
                        Image(systemName: reportType.iconName)
                            .font(.system(size: 48))
                            .foregroundColor(reportType.iconColor)
                        
                        Text(reportType.title)
                            .font(.system(size: 24, weight: .bold))
                            .foregroundColor(.white)
                            .multilineTextAlignment(.center)
                        
                        Text(reportType.description)
                            .font(.system(size: 16))
                            .foregroundColor(.white.opacity(0.7))
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 24)
                    }
                    .padding(.top, 20)
                    
                    // Report Text Input
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Additional Details (Optional)")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.white)
                        
                        TextEditor(text: $reportText)
                            .font(.system(size: 16))
                            .foregroundColor(.black) // Changed to black for better visibility
                            .background(Color.white.opacity(0.9)) // Lighter background for contrast
                            .cornerRadius(12)
                            .frame(height: 120)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color.white.opacity(0.3), lineWidth: 1)
                            )
                    }
                    .padding(.horizontal, 24)
                    
                    Spacer()
                    
                    // Submit Button
                    Button {
                        print("🔘 ReportDetailView: Submit button tapped!")
                        submitReport()
                    } label: {
                        HStack {
                            if isSubmitting {
                                ProgressView()
                                    .scaleEffect(0.8)
                                    .tint(.black)
                            } else {
                                Text("Submit Report")
                                    .font(.system(size: 18, weight: .semibold))
                            }
                        }
                        .foregroundColor(.black)
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(.white)
                        )
                    }
                    .disabled(isSubmitting || photoId == nil)
                    .onAppear {
                        print("🔘 ReportDetailView: Submit button appeared")
                        print("   - isSubmitting: \(isSubmitting)")
                        print("   - photoId: \(photoId ?? "nil")")
                        print("   - button disabled: \(isSubmitting || photoId == nil)")
                    }
                    .padding(.horizontal, 24)
                    .padding(.bottom, 32)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarBackButtonHidden(true)
            .navigationBarItems(leading: 
                Button {
                    dismiss()
                } label: {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 18, weight: .medium))
                        .foregroundColor(.white)
                }
            )
        }
        .alert("Report Submitted", isPresented: $showSuccess) {
            Button("OK") {
                dismiss()
            }
        } message: {
            Text("Thank you for your report. We will review it and take appropriate action.")
        }
        .alert(isPresented: .constant(showError != nil)) {
            Alert(title: Text("Report Failed"), message: Text(showError ?? "Unknown error"), dismissButton: .default(Text("OK"), action: { showError = nil }))
        }
        .onAppear {
            print("🔘 ReportDetailView: View appeared")
            print("   - reportType: \(reportType.title)")
            print("   - photoId: \(photoId ?? "nil")")
            print("   - currentUser: \(authService.currentUser?.id ?? "nil")")
        }
    }
    
    private func submitReport() {
        print("🚨 ReportDetailView: submitReport() called")
        print("🚨 ReportDetailView: photoId = \(photoId ?? "nil")")
        print("🚨 ReportDetailView: reportType = \(reportType.title)")
        print("🚨 ReportDetailView: reportText = '\(reportText)'")
        print("🚨 ReportDetailView: isSubmitting = \(isSubmitting)")
        print("🚨 ReportDetailView: currentUser = \(authService.currentUser?.id ?? "nil")")
        
        guard let photoId = photoId else { 
            print("❌ ReportDetailView: No photoId, cannot submit report")
            showError = "No photo ID available for reporting"
            return 
        }
        
        print("✅ ReportDetailView: Starting report submission...")
        isSubmitting = true
        
        Task {
            do {
                // Get current user ID if authenticated, otherwise submit as anonymous
                let reporterId: String? = authService.currentUser?.id
                let reason = reasonForReport()
                
                print("📝 ReportDetailView: Submitting report with:")
                print("   - photoId: \(photoId)")
                print("   - reporterId: \(reporterId ?? "nil (anonymous)")")
                print("   - reason: \(reason)")
                
                try await fileAPI.submitReport(photoId: photoId, reporterId: reporterId, reason: reason)
                
                print("✅ ReportDetailView: Report submitted successfully")
                await MainActor.run {
                    isSubmitting = false
                    showSuccess = true
                }
            } catch {
                print("❌ ReportDetailView: Report submission failed: \(error)")
                print("❌ ReportDetailView: Error type: \(type(of: error))")
                if let apiError = error as? APIError {
                    print("❌ ReportDetailView: APIError details: \(apiError)")
                }
                await MainActor.run {
                    isSubmitting = false
                    showError = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
                }
            }
        }
    }

    private func reasonForReport() -> String {
        let base = reportType.title
        if reportText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return base
        }
        return "\(base) — \(reportText)"
    }
}

#Preview {
    ReportDetailView(reportType: .fakeProfile, photoId: "demo-photo")
}

