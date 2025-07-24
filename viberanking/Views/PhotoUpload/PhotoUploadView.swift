//
//  PhotoUploadView.swift
//  viberanking
//
//  Created by Kiro on 2025/07/23.
//

import SwiftUI
import PhotosUI

// MARK: - Photo Upload View
struct PhotoUploadView: View {
    
    // MARK: - Properties
    @StateObject private var viewModel = PhotoUploadViewModel()
    @Environment(\.dismiss) private var dismiss
    
    // MARK: - Body
    var body: some View {
        NavigationStack {
            ZStack {
                // Background
                Color(.systemGroupedBackground)
                    .ignoresSafeArea()
                
                // Content
                ScrollView {
                    VStack(spacing: 24) {
                        headerSection
                        
                        switch viewModel.uploadState {
                        case .idle:
                            sourceSelectionSection
                        case .selecting:
                            loadingSection("選擇照片中...")
                        case .validating:
                            loadingSection("驗證照片中...")
                        case .previewing(let image, _):
                            photoPreviewSection(image: image)
                        case .uploading(let progress):
                            uploadProgressSection(progress: progress)
                        case .completed(let photo):
                            completedSection(photo: photo)
                        case .error(let error):
                            errorSection(error: error)
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 16)
                }
            }
            .navigationTitle("上傳照片")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("取消") {
                        dismiss()
                    }
                }
                
                if case .previewing = viewModel.uploadState {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button("重選") {
                            viewModel.resetUpload()
                        }
                    }
                }
            }
        }
        .sheet(isPresented: $viewModel.showingImagePicker) {
            ImagePicker(
                sourceType: .photoLibrary,
                onImageSelected: viewModel.handleSelectedImage
            )
        }
        .sheet(isPresented: $viewModel.showingCamera) {
            ImagePicker(
                sourceType: .camera,
                onImageSelected: viewModel.handleSelectedImage
            )
        }
    }
}

// MARK: - View Components
private extension PhotoUploadView {
    
    /// Header section with instructions
    var headerSection: some View {
        VStack(spacing: 12) {
            Image(systemName: "camera.fill")
                .font(.system(size: 48))
                .foregroundColor(.blue)
            
            Text("分享你的風格")
                .font(.title2)
                .fontWeight(.bold)
            
            Text("上傳一張24小時內拍攝的照片，獲得其他用戶的評分和個人風格分析")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(.vertical, 8)
    }
    
    /// Source selection buttons
    var sourceSelectionSection: some View {
        VStack(spacing: 16) {
            // Camera button
            Button(action: viewModel.showCamera) {
                HStack(spacing: 16) {
                    Image(systemName: "camera.fill")
                        .font(.title2)
                        .foregroundColor(.white)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("拍攝新照片")
                            .font(.headline)
                            .foregroundColor(.white)
                        
                        Text("使用相機拍攝全新照片")
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.8))
                    }
                    
                    Spacer()
                    
                    Image(systemName: "chevron.right")
                        .font(.body)
                        .foregroundColor(.white.opacity(0.7))
                }
                .padding(20)
                .background(
                    LinearGradient(
                        colors: [.blue, .blue.opacity(0.8)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .cornerRadius(16)
            }
            .buttonStyle(PlainButtonStyle())
            
            // Photo library button
            Button(action: viewModel.showPhotoLibrary) {
                HStack(spacing: 16) {
                    Image(systemName: "photo.on.rectangle")
                        .font(.title2)
                        .foregroundColor(.blue)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("從相簿選擇")
                            .font(.headline)
                            .foregroundColor(.primary)
                        
                        Text("選擇相簿中的近期照片")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    Image(systemName: "chevron.right")
                        .font(.body)
                        .foregroundColor(.secondary)
                }
                .padding(20)
                .background(Color(.systemBackground))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.blue.opacity(0.3), lineWidth: 1)
                )
                .cornerRadius(16)
            }
            .buttonStyle(PlainButtonStyle())
            
            // Requirements info
            requirementsInfoSection
        }
    }
    
    /// Requirements information
    var requirementsInfoSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "info.circle.fill")
                    .foregroundColor(.blue)
                Text("照片要求")
                    .font(.headline)
                    .foregroundColor(.primary)
                Spacer()
            }
            
            VStack(alignment: .leading, spacing: 8) {
                requirementRow(
                    icon: "clock.fill",
                    text: "24小時內拍攝",
                    color: .green
                )
                
                requirementRow(
                    icon: "camera.fill",
                    text: "使用相機拍攝（非螢幕截圖）",
                    color: .blue
                )
                
                requirementRow(
                    icon: "checkmark.shield.fill",
                    text: "包含完整EXIF資料",
                    color: .orange
                )
            }
        }
        .padding(16)
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(12)
    }
    
    /// Individual requirement row
    func requirementRow(icon: String, text: String, color: Color) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.caption)
                .foregroundColor(color)
                .frame(width: 16)
            
            Text(text)
                .font(.caption)
                .foregroundColor(.secondary)
            
            Spacer()
        }
    }
    
    /// Loading section
    func loadingSection(_ message: String) -> some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.2)
            
            Text(message)
                .font(.body)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
    }
    
    /// Photo preview section
    func photoPreviewSection(image: UIImage) -> some View {
        VStack(spacing: 20) {
            // Image preview
            Image(uiImage: image)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(maxHeight: 300)
                .cornerRadius(12)
                .shadow(radius: 4)
            
            // Validation status
            validationStatusSection
            
            // Upload button
            if viewModel.canStartUpload {
                Button(action: viewModel.uploadPhoto) {
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
            }
        }
    }
    
    /// Validation status section
    var validationStatusSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: viewModel.isValidationPassed ? "checkmark.circle.fill" : "exclamationmark.triangle.fill")
                    .foregroundColor(viewModel.isValidationPassed ? .green : .orange)
                
                Text("驗證結果")
                    .font(.headline)
                
                Spacer()
            }
            
            Text(viewModel.validationMessage)
                .font(.body)
                .foregroundColor(.primary)
                .multilineTextAlignment(.leading)
        }
        .padding(16)
        .background(
            viewModel.isValidationPassed ? 
            Color.green.opacity(0.1) : 
            Color.orange.opacity(0.1)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(
                    viewModel.isValidationPassed ? 
                    Color.green.opacity(0.3) : 
                    Color.orange.opacity(0.3),
                    lineWidth: 1
                )
        )
        .cornerRadius(12)
    }
    
    /// Upload progress section
    func uploadProgressSection(progress: Double) -> some View {
        VStack(spacing: 20) {
            // Progress indicator
            VStack(spacing: 16) {
                ProgressView(value: progress)
                    .progressViewStyle(LinearProgressViewStyle(tint: .blue))
                    .scaleEffect(y: 2)
                
                Text("\(Int(progress * 100))% 完成")
                    .font(.headline)
                    .foregroundColor(.primary)
                
                Text("正在上傳照片...")
                    .font(.body)
                    .foregroundColor(.secondary)
            }
            .padding(.vertical, 20)
            
            // Cancel button
            Button("取消上傳") {
                viewModel.cancelUpload()
            }
            .font(.body)
            .foregroundColor(.red)
        }
        .padding(20)
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(radius: 2)
    }
    
    /// Completed section
    func completedSection(photo: Photo) -> some View {
        VStack(spacing: 20) {
            // Success icon
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 64))
                .foregroundColor(.green)
            
            Text("上傳成功！")
                .font(.title2)
                .fontWeight(.bold)
            
            Text("你的照片已成功上傳，現在等待其他用戶評分")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            
            // Photo info
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("照片ID:")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text(photo.id.prefix(8) + "...")
                        .font(.caption)
                        .foregroundColor(.primary)
                    Spacer()
                }
                
                HStack {
                    Text("上傳時間:")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text(DateFormatter.localizedString(from: photo.uploadedAt, dateStyle: .short, timeStyle: .short))
                        .font(.caption)
                        .foregroundColor(.primary)
                    Spacer()
                }
            }
            .padding(12)
            .background(Color(.secondarySystemGroupedBackground))
            .cornerRadius(8)
            
            // Done button
            Button("完成") {
                dismiss()
            }
            .font(.headline)
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(Color.blue)
            .cornerRadius(12)
        }
        .padding(20)
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(radius: 4)
    }
    
    /// Error section
    func errorSection(error: AppError) -> some View {
        VStack(spacing: 20) {
            // Error icon
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 48))
                .foregroundColor(.red)
            
            Text("上傳失敗")
                .font(.title2)
                .fontWeight(.bold)
            
            Text(error.errorDescription ?? "未知錯誤")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            
            if let suggestion = error.recoverySuggestion {
                Text(suggestion)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }
            
            // Action buttons
            HStack(spacing: 12) {
                Button("重試") {
                    viewModel.retryUpload()
                }
                .font(.body)
                .foregroundColor(.blue)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(Color.blue.opacity(0.1))
                .cornerRadius(8)
                
                Button("重新選擇") {
                    viewModel.resetUpload()
                }
                .font(.body)
                .foregroundColor(.secondary)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(Color(.secondarySystemGroupedBackground))
                .cornerRadius(8)
            }
        }
        .padding(20)
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(radius: 4)
    }
}

// MARK: - Preview
#Preview {
    PhotoUploadView()
}