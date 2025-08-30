//
//  ReportDetailView.swift
//  viberanking
//
//  Created by Kiro on 2025/07/25.
//

import SwiftUI

struct ReportDetailView: View {
    let reportType: ReportType
    @Environment(\.dismiss) private var dismiss
    @State private var reportText = ""
    @State private var isSubmitting = false
    @State private var showSuccess = false
    
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
                            .foregroundColor(.white)
                            .background(Color.white.opacity(0.1))
                            .cornerRadius(12)
                            .frame(height: 120)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color.white.opacity(0.2), lineWidth: 1)
                            )
                    }
                    .padding(.horizontal, 24)
                    
                    Spacer()
                    
                    // Submit Button
                    Button {
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
                    .disabled(isSubmitting)
                    .padding(.horizontal, 24)
                    .padding(.bottom, 32)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarBackButtonHidden(true)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 18, weight: .medium))
                            .foregroundColor(.white)
                    }
                }
            }
        }
        .alert("Report Submitted", isPresented: $showSuccess) {
            Button("OK") {
                dismiss()
            }
        } message: {
            Text("Thank you for your report. We will review it and take appropriate action.")
        }
    }
    
    private func submitReport() {
        isSubmitting = true
        
        // Simulate API call
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            isSubmitting = false
            showSuccess = true
            
            // Log report for debugging
            print("📝 Report submitted: \(reportType.title)")
            if !reportText.isEmpty {
                print("📝 Additional details: \(reportText)")
            }
        }
    }
}

#Preview {
    ReportDetailView(reportType: .fakeProfile)
}
