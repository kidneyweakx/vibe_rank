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
    let onUpload: () -> Void
    let onRetake: () -> Void
    
    // MARK: - Body
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Image preview
                imagePreviewSection
                
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
    
    /// Action buttons section
    var actionButtonsSection: some View {
        VStack(spacing: 12) {
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
            onUpload: {},
            onRetake: {}
        )
    }
}
