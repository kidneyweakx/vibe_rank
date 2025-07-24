//
//  PhotoUploadDemoView.swift
//  viberanking
//
//  Created by Kiro on 2025/07/23.
//

import SwiftUI

// MARK: - Photo Upload Demo View
/// This view demonstrates the photo upload functionality
/// and can be used for testing the upload UI components
struct PhotoUploadDemoView: View {
    
    // MARK: - State
    @State private var showingUploadView = false
    @State private var showingProgressView = false
    
    // MARK: - Body
    var body: some View {
        NavigationStack {
            List {
                Section("照片上傳功能") {
                    // Upload new photo
                    Button(action: {
                        showingUploadView = true
                    }) {
                        HStack {
                            Image(systemName: "camera.fill")
                                .foregroundColor(.blue)
                            
                            VStack(alignment: .leading) {
                                Text("上傳新照片")
                                    .foregroundColor(.primary)
                                Text("拍攝或選擇照片進行上傳")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            
                            Spacer()
                            
                            Image(systemName: "chevron.right")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    // View upload progress
                    Button(action: {
                        showingProgressView = true
                    }) {
                        HStack {
                            Image(systemName: "chart.line.uptrend.xyaxis")
                                .foregroundColor(.green)
                            
                            VStack(alignment: .leading) {
                                Text("查看評分進度")
                                    .foregroundColor(.primary)
                                Text("查看照片評分狀態")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            
                            Spacer()
                            
                            Image(systemName: "chevron.right")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                
                Section("功能說明") {
                    featureRow(
                        icon: "camera.fill",
                        title: "相機拍攝",
                        description: "支援直接使用相機拍攝照片",
                        color: .blue
                    )
                    
                    featureRow(
                        icon: "photo.on.rectangle",
                        title: "相簿選擇",
                        description: "從相簿中選擇近期照片",
                        color: .green
                    )
                    
                    featureRow(
                        icon: "checkmark.shield.fill",
                        title: "EXIF驗證",
                        description: "自動驗證照片新鮮度和真實性",
                        color: .orange
                    )
                    
                    featureRow(
                        icon: "icloud.and.arrow.up.fill",
                        title: "智能上傳",
                        description: "WebP格式壓縮，節省流量",
                        color: .purple
                    )
                }
                
                Section("上傳要求") {
                    requirementRow(
                        icon: "clock.fill",
                        text: "照片必須在24小時內拍攝",
                        isValid: true
                    )
                    
                    requirementRow(
                        icon: "camera.fill",
                        text: "使用相機拍攝（非螢幕截圖）",
                        isValid: true
                    )
                    
                    requirementRow(
                        icon: "doc.text.fill",
                        text: "包含完整的EXIF資料",
                        isValid: true
                    )
                }
            }
            .navigationTitle("照片上傳")
            .navigationBarTitleDisplayMode(.large)
        }
        .sheet(isPresented: $showingUploadView) {
            PhotoUploadView()
        }
        .sheet(isPresented: $showingProgressView) {
            UploadProgressView(
                photoId: "demo-photo-id-12345",
                currentRatings: 25,
                requiredRatings: 50,
                onDismiss: {
                    showingProgressView = false
                }
            )
        }
    }
}

// MARK: - Helper Views
private extension PhotoUploadDemoView {
    
    /// Feature row component
    func featureRow(icon: String, title: String, description: String, color: Color) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)
                .frame(width: 24)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.body)
                    .foregroundColor(.primary)
                
                Text(description)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
        }
        .padding(.vertical, 4)
    }
    
    /// Requirement row component
    func requirementRow(icon: String, text: String, isValid: Bool) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.body)
                .foregroundColor(isValid ? .green : .red)
                .frame(width: 20)
            
            Text(text)
                .font(.body)
                .foregroundColor(.primary)
            
            Spacer()
            
            Image(systemName: isValid ? "checkmark.circle.fill" : "xmark.circle.fill")
                .font(.caption)
                .foregroundColor(isValid ? .green : .red)
        }
        .padding(.vertical, 2)
    }
}

// MARK: - Preview
#Preview {
    PhotoUploadDemoView()
}