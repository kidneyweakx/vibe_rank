//
//  ReportSheetView.swift
//  viberanking
//
//  Created by Kiro on 2025/07/25.
//

import SwiftUI

struct ReportSheetView: View {
    let photoId: String?
    let userId: String?
    @Environment(\.dismiss) private var dismiss
    @State private var selectedReportType: ReportType?
    @State private var showReportDetail = false
    @State private var showBlockConfirmation = false
    @StateObject private var authService = AuthenticationService()
    private let fileAPI = FileAPI()
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.black.ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Header
                    VStack(spacing: 16) {
                        Text("Report")
                            .font(.system(size: 28, weight: .bold))
                            .foregroundColor(.white)
                        
                        Text("In order to protect your privacy, we are completely anonymous to report, please feel free to fill in")
                            .font(.system(size: 16))
                            .foregroundColor(.white.opacity(0.7))
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 24)
                    }
                    .padding(.top, 20)
                    .padding(.bottom, 32)
                    
                    // Actions
                    ScrollView {
                        VStack(spacing: 0) {
                            // Block user (if available)
                            if let userId = userId {
                                Button(role: .destructive) {
                                    showBlockConfirmation = true
                                } label: {
                                    HStack {
                                        Image(systemName: "hand.raised.fill")
                                            .foregroundColor(.red)
                                        Text("Block User")
                                            .foregroundColor(.red)
                                        Spacer()
                                        Image(systemName: "chevron.right")
                                            .foregroundColor(.red.opacity(0.7))
                                    }
                                    .padding(16)
                                    .background(
                                        RoundedRectangle(cornerRadius: 12)
                                            .fill(Color.red.opacity(0.08))
                                            .overlay(
                                                RoundedRectangle(cornerRadius: 12)
                                                    .stroke(Color.red.opacity(0.15), lineWidth: 1)
                                            )
                                    )
                                }
                                .padding(.bottom, 16)
                            }

                            ForEach(ReportType.allCases, id: \.self) { reportType in
                                ReportOptionRow(
                                    reportType: reportType,
                                    isSelected: selectedReportType == reportType
                                ) {
                                    selectedReportType = reportType
                                    showReportDetail = true
                                    print("🔘 ReportSheetView: Report type selected: \(reportType.title)")
                                    print("   - photoId: \(photoId ?? "nil")")
                                }
                            }
                        }
                        .padding(.horizontal, 20)
                    }
                    
                    Spacer()
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
        .sheet(isPresented: $showReportDetail) {
            if let selectedType = selectedReportType {
                ReportDetailView(reportType: selectedType, photoId: photoId)
                    .onAppear {
                        print("🔘 ReportSheetView: Opening ReportDetailView")
                        print("   - reportType: \(selectedType.title)")
                        print("   - photoId: \(photoId ?? "nil")")
                    }
            }
        }
        .onAppear {
            print("🔘 ReportSheetView: Appeared with photoId: \(photoId ?? "nil")")
        }
        .alert("Block User", isPresented: $showBlockConfirmation) {
            Button("Cancel", role: .cancel) {}
            Button("Block", role: .destructive) {
                if let userId = userId {
                    UserBlocklist.shared.add(userId)
                    print("🛑 Blocked user: \(userId)")
                }
                // Also submit a report like other actions with a fixed reason
                if let photoId = photoId {
                    Task {
                        do {
                            let reason = "Block User"
                            print("📡 ReportSheetView: Auto submitting report for block action")
                            print("   - photoId: \(photoId)")
                            print("   - reason: \(reason)")
                            try await fileAPI.submitReport(photoId: photoId, reason: reason)
                            print("✅ ReportSheetView: Auto report submitted")
                        } catch {
                            print("❌ ReportSheetView: Failed to auto submit report: \(error)")
                        }
                    }
                } else {
                    print("⚠️ ReportSheetView: No photoId available, skipping auto report on block")
                }
                // Notify rating view to skip current photo
                NotificationCenter.default.post(name: .requestSkipCurrentPhoto, object: nil)
                dismiss()
            }
        } message: {
            Text("You won't see content from this user anymore.")
        }
    }
}

#Preview {
    ReportSheetView(photoId: "demo-photo", userId: "user-123")
}
