//
//  SimpleUploadFlow.swift
//  viberanking
//
//  Created by Kiro on 2025/08/08.
//

import SwiftUI

/// 簡化的上傳流程演示
/// 流程：按下上傳按鈕 → 選擇拍照/相簿 → 圖片預覽和裁切 → 上傳到服務器
struct SimpleUploadFlow: View {
    @State private var showingUploadMenu = false
    @State private var showingImagePicker = false
    @State private var showingPhotoPicker = false
    @State private var showingImagePreview = false
    @State private var selectedImage: UIImage?
    
    var body: some View {
        VStack(spacing: 30) {
            Text("簡化上傳流程")
                .font(.largeTitle)
                .fontWeight(.bold)
            
            Text("點擊下方按鈕開始上傳照片")
                .font(.body)
                .foregroundColor(.secondary)
            
            // 上傳按鈕
            Button {
                showingUploadMenu = true
            } label: {
                HStack(spacing: 12) {
                    Image(systemName: "plus.circle.fill")
                        .font(.title2)
                    Text("上傳照片")
                        .font(.headline)
                }
                .foregroundColor(.white)
                .frame(height: 56)
                .frame(maxWidth: .infinity)
                .background(Color.red)
                .cornerRadius(28)
            }
            .padding(.horizontal, 40)
            
            Spacer()
        }
        .padding()
        .sheet(isPresented: $showingUploadMenu) {
            UploadMenuView(
                onCameraSelected: {
                    showingImagePicker = true
                },
                onPhotoLibrarySelected: {
                    showingPhotoPicker = true
                }
            )
            .presentationDetents([.height(200)])
            .presentationDragIndicator(.visible)
        }
        .sheet(isPresented: $showingImagePicker) {
            ImagePicker(sourceType: .camera) { image in
                selectedImage = image
                showingImagePreview = true
            }
        }
        .sheet(isPresented: $showingPhotoPicker) {
            PhotoPickerView { image in
                selectedImage = image
                showingImagePreview = true
            }
        }
        .fullScreenCover(isPresented: $showingImagePreview) {
            if let image = selectedImage {
                ImagePreviewView(image: image) {
                    selectedImage = nil
                }
                .environmentObject(AuthenticationViewModel())
            }
        }
    }
}

#Preview {
    SimpleUploadFlow()
}