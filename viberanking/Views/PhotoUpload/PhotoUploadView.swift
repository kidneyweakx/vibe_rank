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
                            loadingSection("upload.selecting".localized)
                        case .previewing(let image):
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
            .navigationTitle("upload.title".localized)
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("upload.cancel".localized) {
                        dismiss()
                    }
                }
                
                if case .previewing = viewModel.uploadState {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button("upload.reselect".localized) {
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
            
            Text("upload.share_style".localized)
                .font(.title2)
                .fontWeight(.bold)
            
            Text("upload.description".localized)
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
                        Text("upload.take_photo".localized)
                            .font(.headline)
                            .foregroundColor(.white)
                        
                        Text("upload.take_photo_desc".localized)
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
                        Text("upload.choose_library".localized)
                            .font(.headline)
                            .foregroundColor(.primary)
                        
                        Text("upload.choose_library_desc".localized)
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

            // Upload button
            Button(action: viewModel.uploadPhoto) {
                HStack {
                    Image(systemName: "icloud.and.arrow.up.fill")
                    Text("upload.start_upload".localized)
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
    
    /// Upload progress section
    func uploadProgressSection(progress: Double) -> some View {
        VStack(spacing: 20) {
            // Progress indicator
            VStack(spacing: 16) {
                ProgressView(value: progress)
                    .progressViewStyle(LinearProgressViewStyle(tint: .blue))
                    .scaleEffect(y: 2)
                
                Text("upload.progress".localized(with: Int(progress * 100)))
                    .font(.headline)
                    .foregroundColor(.primary)
                
                Text("upload.uploading".localized)
                    .font(.body)
                    .foregroundColor(.secondary)
            }
            .padding(.vertical, 20)
            
            // Cancel button
            Button("upload.cancel_upload".localized) {
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
            
            Text("upload.success".localized)
                .font(.title2)
                .fontWeight(.bold)
            
            Text("upload.success_desc".localized)
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            
            // Photo info
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("upload.photo_id".localized)
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text(photo.id.prefix(8) + "...")
                        .font(.caption)
                        .foregroundColor(.primary)
                    Spacer()
                }
                
                HStack {
                    Text("upload.upload_time".localized)
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
            Button("upload.done".localized) {
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
            
            Text("upload.failed".localized)
                .font(.title2)
                .fontWeight(.bold)
            
            Text(error.errorDescription ?? "upload.unknown_error".localized)
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
                Button("upload.retry".localized) {
                    viewModel.retryUpload()
                }
                .font(.body)
                .foregroundColor(.blue)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(Color.blue.opacity(0.1))
                .cornerRadius(8)
                
                Button("upload.reselect".localized) {
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
