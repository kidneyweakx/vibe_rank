//
//  TestUploadFlow.swift
//  viberanking
//
//  Created by Kiro on 2025/08/08.
//

import SwiftUI

struct TestUploadFlow: View {
    @State private var showingPhotoPicker = false
    @State private var selectedImage: UIImage?
    @State private var showingCropView = false
    @State private var croppedImage: UIImage?
    
    var body: some View {
        VStack(spacing: 30) {
            Text("測試上傳流程")
                .font(.largeTitle)
                .fontWeight(.bold)
            
            if let image = selectedImage {
                Image(uiImage: croppedImage ?? image)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(maxWidth: 200, maxHeight: 200)
                    .border(Color.gray, width: 1)
            }
            
            Button("選擇照片") {
                print("🔘 選擇照片按鈕被點擊")
                showingPhotoPicker = true
            }
            .padding()
            .background(Color.blue)
            .foregroundColor(.white)
            .cornerRadius(8)
            
            if selectedImage != nil {
                Button("裁切照片") {
                    print("🔘 裁切照片按鈕被點擊")
                    showingCropView = true
                }
                .padding()
                .background(Color.green)
                .foregroundColor(.white)
                .cornerRadius(8)
            }
            
            if croppedImage != nil {
                Text("✅ 圖片已裁切完成")
                    .foregroundColor(.green)
            }
            
            Spacer()
        }
        .padding()
        .sheet(isPresented: $showingPhotoPicker) {
            PhotoPickerView { image in
                print("📸 測試流程收到圖片")
                selectedImage = image
            }
        }
        .sheet(isPresented: $showingCropView) {
            if let image = selectedImage {
                ImageCropView(image: image) { cropped in
                    print("✅ 測試流程收到裁切圖片")
                    croppedImage = cropped
                }
            }
        }
    }
}

#Preview {
    TestUploadFlow()
}