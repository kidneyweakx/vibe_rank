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
    @State private var showingTagSelector = false
    @State private var selectedTagIds: Set<String> = []
    @State private var selectedTags: [Tag] = []
    private let tagsAPI = TagsAPI()
    
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
                    // 預覽區
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
                                    .progressViewStyle(LinearProgressViewStyle())
                                    .tint(.white)
                                    .frame(width: 200)

                                Text("上傳中... \(Int(uploadProgress * 100))%")
                                    .foregroundColor(.white)
                                    .font(.subheadline)
                            }
                        }
                    }

                    Spacer()

                    // 標籤與操作
                    if !isUploading {
                        VStack(spacing: 16) {
                            // 標籤選擇
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Tags")
                                    .foregroundColor(.white.opacity(0.8))
                                    .font(.caption)
                                    .frame(maxWidth: .infinity, alignment: .leading)

                                ScrollView(.horizontal, showsIndicators: false) {
                                    HStack(spacing: 8) {
                                        if selectedTags.isEmpty {
                                            Text("Select up to 10 tags")
                                                .foregroundColor(.white.opacity(0.5))
                                                .font(.caption)
                                        } else {
                                            ForEach(selectedTags, id: \.id) { tag in
                                                TagChipView(tag: tag, isSelected: true, onTap: {})
                                            }
                                        }
                                    }
                                    .padding(.horizontal, 2)
                                }

                                Button {
                                    showingTagSelector = true
                                } label: {
                                    HStack(spacing: 8) {
                                        Image(systemName: "tag")
                                        Text("Choose Tags")
                                            .font(.subheadline)
                                    }
                                    .foregroundColor(.white)
                                    .padding(.vertical, 8)
                                    .padding(.horizontal, 12)
                                    .background(Color.white.opacity(0.15))
                                    .cornerRadius(12)
                                }
                                .frame(maxWidth: .infinity, alignment: .leading)
                            }

                            // 操作按鈕列
                            HStack(spacing: 20) {
                                // 裁切
                                Button {
                                    showingCropView = true
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

                                // 上傳
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
        .sheet(isPresented: $showingTagSelector) {
            TagSelectorSheet { ids in
                selectedTagIds = ids
                Task { await fetchSelectedTags() }
            }
        }
        .onAppear {
            print("🎯 ImagePreviewView 顯示 - 圖片尺寸: \(image.size)")
        }
        .sheet(isPresented: $showingCropView) {
            ImageCropView(image: croppedImage ?? image) { croppedResult in
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
            if let error = uploadError { Text(error) }
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
    
    func uploadImage() {
        // 檢查是否已裁切為直板
        if croppedImage == nil {
            uploadError = "請先裁切圖片為直板後再上傳"
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
                let uploaded = try await photoUploadService.uploadPhoto(imageToUpload, for: userId)
                if !selectedTagIds.isEmpty {
                    _ = try? await tagsAPI.attachTags(to: uploaded.id, tagIds: Array(selectedTagIds))
                }
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

    func fetchSelectedTags() async {
        guard !selectedTagIds.isEmpty else {
            await MainActor.run { selectedTags = [] }
            return
        }
        do {
            let response = try await tagsAPI.searchTags(by: Array(selectedTagIds))
            await MainActor.run { selectedTags = response.data }
        } catch {
            await MainActor.run { selectedTags = [] }
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