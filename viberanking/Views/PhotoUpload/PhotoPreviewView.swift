//
//  PhotoPreviewView.swift
//  viberanking
//
//  Created by Kiro on 2025/07/23.
//

import SwiftUI

// MARK: - Photo Preview View
struct PhotoPreviewView: View {
    
    // MARK: - Properties
    let image: UIImage
    let metadata: PhotoMetadata?
    let validationMessage: String
    let isValidationPassed: Bool
    let onUpload: () -> Void
    let onRetake: () -> Void
    
    // MARK: - Body
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Image preview
                imagePreviewSection
                
                // Validation status
                validationStatusSection
                
                // EXIF information
                if let metadata = metadata {
                    exifInfoSection(metadata: metadata)
                }
                
                // Action buttons
                actionButtonsSection
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
        }
        .navigationTitle("照片預覽")
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - View Components
private extension PhotoPreviewView {
    
    /// Image preview section
    var imagePreviewSection: some View {
        VStack(spacing: 12) {
            // Main image
            Image(uiImage: image)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(maxHeight: 400)
                .cornerRadius(16)
                .shadow(radius: 8)
            
            // Image info
            HStack {
                Text("尺寸: \(Int(image.size.width)) × \(Int(image.size.height))")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                Text("格式: JPEG")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
    }
    
    /// Validation status section
    var validationStatusSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: isValidationPassed ? "checkmark.circle.fill" : "exclamationmark.triangle.fill")
                    .foregroundColor(isValidationPassed ? .green : .orange)
                
                Text("驗證結果")
                    .font(.headline)
                
                Spacer()
            }
            
            Text(validationMessage)
                .font(.body)
                .foregroundColor(.primary)
                .multilineTextAlignment(.leading)
        }
        .padding(16)
        .background(
            isValidationPassed ? 
            Color.green.opacity(0.1) : 
            Color.orange.opacity(0.1)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(
                    isValidationPassed ? 
                    Color.green.opacity(0.3) : 
                    Color.orange.opacity(0.3),
                    lineWidth: 1
                )
        )
        .cornerRadius(12)
    }
    
    /// EXIF information section
    func exifInfoSection(metadata: PhotoMetadata) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "info.circle.fill")
                    .foregroundColor(.blue)
                Text("照片資訊")
                    .font(.headline)
                Spacer()
            }
            
            VStack(alignment: .leading, spacing: 8) {
                if let dateTaken = metadata.dateTaken {
                    exifRow(
                        label: "拍攝時間",
                        value: DateFormatter.localizedString(from: dateTaken, dateStyle: .medium, timeStyle: .short),
                        icon: "calendar"
                    )
                }
                
                if let cameraModel = metadata.cameraModel {
                    exifRow(
                        label: "相機型號",
                        value: cameraModel,
                        icon: "camera"
                    )
                }
                
                exifRow(
                    label: "新鮮度",
                    value: metadata.isRecentPhoto ? "24小時內" : "超過24小時",
                    icon: "clock"
                )
                
                exifRow(
                    label: "EXIF資料",
                    value: metadata.hasValidEXIF ? "完整" : "不完整",
                    icon: "doc.text"
                )
            }
        }
        .padding(16)
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(12)
    }
    
    /// Individual EXIF row
    func exifRow(label: String, value: String, icon: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.caption)
                .foregroundColor(.blue)
                .frame(width: 16)
            
            Text(label + ":")
                .font(.caption)
                .foregroundColor(.secondary)
                .frame(width: 80, alignment: .leading)
            
            Text(value)
                .font(.caption)
                .foregroundColor(.primary)
            
            Spacer()
        }
    }
    
    /// Action buttons section
    var actionButtonsSection: some View {
        VStack(spacing: 12) {
            if isValidationPassed {
                // Upload button
                Button(action: onUpload) {
                    HStack {
                        Image(systemName: "icloud.and.arrow.up.fill")
                        Text("開始上傳")
                    }
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(Color.blue)
                    .cornerRadius(12)
                }
                .buttonStyle(PlainButtonStyle())
            } else {
                // Warning message
                VStack(spacing: 8) {
                    Text("此照片不符合上傳要求")
                        .font(.body)
                        .foregroundColor(.orange)
                        .multilineTextAlignment(.center)
                    
                    Text("請重新拍攝一張24小時內的照片")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding(.vertical, 8)
            }
            
            // Retake button
            Button(action: onRetake) {
                HStack {
                    Image(systemName: "camera.fill")
                    Text("重新拍攝")
                }
                .font(.body)
                .foregroundColor(.blue)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(Color.blue.opacity(0.1))
                .cornerRadius(8)
            }
            .buttonStyle(PlainButtonStyle())
        }
    }
}

// MARK: - Preview
#Preview {
    NavigationStack {
        PhotoPreviewView(
            image: UIImage(systemName: "photo") ?? UIImage(),
            metadata: PhotoMetadata(
                dateTaken: Date().addingTimeInterval(-3600), // 1 hour ago
                cameraModel: "iPhone 15 Pro"
            ),
            validationMessage: "✅ 照片驗證通過\n📷 相機: iPhone 15 Pro\n📅 拍攝時間: 1小時前",
            isValidationPassed: true,
            onUpload: {},
            onRetake: {}
        )
    }
}

#Preview("Invalid Photo") {
    NavigationStack {
        PhotoPreviewView(
            image: UIImage(systemName: "photo") ?? UIImage(),
            metadata: PhotoMetadata(
                dateTaken: Date().addingTimeInterval(-25 * 3600), // 25 hours ago
                cameraModel: nil
            ),
            validationMessage: "⚠️ 照片拍攝時間超過24小時\n❌ 照片缺少必要的EXIF資料",
            isValidationPassed: false,
            onUpload: {},
            onRetake: {}
        )
    }
}