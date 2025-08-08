//
//  ImagePreviewView.swift
//  viberanking
//
//  Created by Kiro on 2025/08/08.
//

import SwiftUI
import UIKit

struct ImagePreviewView: View {
    let image: UIImage
    let onCancel: () -> Void
    
    @State private var croppedImage: UIImage?
    @State private var isUploading = false
    @State private var uploadProgress: Double = 0.0
    @State private var showingCropView = false
    @State private var uploadError: String?
    @State private var uploadSuccess = false
    
    @EnvironmentObject private var authViewModel: AuthenticationViewModel
    @Environment(\.dismiss) private var dismiss
    
    init(image: UIImage, onCancel: @escaping () -> Void) {
        self.image = image
        self.onCancel = onCancel
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.black.ignoresSafeArea()
                
                VStack(spacing: 20) {
                    // 圖片預覽區域
                    ZStack {
                        let displayImage = croppedImage ?? image
                        Image(uiImage: displayImage)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(maxHeight: UIScreen.main.bounds.height * 0.6)
                            .cornerRadius(12)
                        
                        if isUploading {
                            Color.black.opacity(0.5)
                                .cornerRadius(12)
                            
                            VStack(spacing: 16) {
                                ProgressView(value: uploadProgress)
                                    .progressViewStyle(LinearProgressViewStyle(tint: .white))
                                    .frame(width: 200)
                                
                                Text("上傳中... \(Int(uploadProgress * 100))%")
                                    .foregroundColor(.white)
                                    .font(.subheadline)
                            }
                        }
                    }
                    
                    Spacer()
                    
                    // 操作按鈕
                    if !isUploading {
                        HStack(spacing: 20) {
                            // 裁切按鈕
                            Button {
                                print("🔧 裁切按鈕被點擊")
                                print("🔧 當前 showingCropView: \(showingCropView)")
                                showingCropView = true
                                print("🔧 設置後 showingCropView: \(showingCropView)")
                            } label: {
                                VStack(spacing: 8) {
                                    Image(systemName: "crop")
                                        .font(.title2)
                                    Text("裁切")
                                        .font(.caption)
                                }
                                .foregroundColor(.white)
                                .frame(width: 60, height: 60)
                                .background(Color.gray.opacity(0.3))
                                .cornerRadius(30)
                            }
                            
                            Spacer()
                            
                            // 上傳按鈕
                            Button {
                                uploadImage()
                            } label: {
                                HStack(spacing: 8) {
                                    Image(systemName: "arrow.up.circle.fill")
                                        .font(.title2)
                                    Text(croppedImage == nil ? "請先裁切" : "上傳")
                                        .font(.headline)
                                }
                                .foregroundColor(.white)
                                .frame(height: 50)
                                .frame(maxWidth: .infinity)
                                .background(croppedImage == nil ? Color.gray : Color.blue)
                                .cornerRadius(25)
                            }
                            .disabled(croppedImage == nil)
                        }
                        .padding(.horizontal, 20)
                        .padding(.bottom, 40)
                    }
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("取消") {
                        onCancel()
                        dismiss()
                    }
                    .foregroundColor(.white)
                }
            }
        }
        .onAppear {
            print("🎯 ImagePreviewView 顯示 - 圖片尺寸: \(image.size)")
        }
        .sheet(isPresented: $showingCropView) {
            ImageCropView(image: croppedImage ?? image) { croppedResult in
                print("✅ 裁切完成，獲得新圖片")
                croppedImage = croppedResult
            }
        }
        .onChange(of: showingCropView) { isShowing in
            print("📱 裁切視圖狀態變更: \(isShowing)")
        }
        .alert("上傳失敗", isPresented: .constant(uploadError != nil)) {
            Button("確定") {
                uploadError = nil
            }
        } message: {
            if let error = uploadError {
                Text(error)
            }
        }
        .alert("上傳成功", isPresented: $uploadSuccess) {
            Button("確定") {
                onCancel()
                dismiss()
            }
        } message: {
            Text("照片已成功上傳！")
        }
    }
    
    private func uploadImage() {
        // 檢查是否已裁切為正方形
        if croppedImage == nil {
            uploadError = "請先裁切圖片為正方形後再上傳"
            return
        }
        
        guard let userId = authViewModel.user?.id else {
            uploadError = "請先登入"
            return
        }
        
        guard let imageToUpload = croppedImage else {
            uploadError = "請先裁切圖片"
            return
        }
        
        print("🚀 開始上傳圖片 - 尺寸: \(imageToUpload.size)")
        isUploading = true
        uploadProgress = 0.0
        
        Task {
            do {
                let photoUploadService = PhotoUploadService()
                
                // 模擬上傳進度
                for i in 1...10 {
                    await MainActor.run {
                        uploadProgress = Double(i) / 10.0
                    }
                    try await Task.sleep(nanoseconds: 200_000_000) // 0.2秒
                }
                
                print("📤 調用 PhotoUploadService.uploadPhoto")
                let _ = try await photoUploadService.uploadPhoto(imageToUpload, for: userId)
                print("✅ 上傳完成")
                
                await MainActor.run {
                    isUploading = false
                    uploadSuccess = true
                }
            } catch {
                print("❌ 上傳失敗: \(error)")
                await MainActor.run {
                    isUploading = false
                    uploadError = error.localizedDescription
                }
            }
        }
    }
}

#Preview {
    ImagePreviewView(
        image: UIImage(systemName: "photo") ?? UIImage(),
        onCancel: {}
    )
    .environmentObject(AuthenticationViewModel())
}