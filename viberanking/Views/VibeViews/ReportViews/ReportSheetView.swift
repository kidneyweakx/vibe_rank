//
//  ReportSheetView.swift
//  viberanking
//
//  Created by Kiro on 2025/07/25.
//

import SwiftUI

struct ReportSheetView: View {
    let photoId: String?
    @Environment(\.dismiss) private var dismiss
    @State private var selectedReportType: ReportType?
    @State private var showReportDetail = false
    
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
                    
                    // Report Options
                    ScrollView {
                        VStack(spacing: 0) {
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
    }
}

#Preview {
    ReportSheetView(photoId: "demo-photo")
}
