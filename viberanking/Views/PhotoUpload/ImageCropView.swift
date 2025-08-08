//
//  ImageCropView.swift
//  viberanking
//
//  Created by Kiro on 2025/08/08.
//

import SwiftUI
import UIKit

struct ImageCropView: View {
    let image: UIImage
    let onCropped: (UIImage) -> Void
    
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        print("🎯 ImageCropView body 被調用")
        return
        NavigationView {
            ZStack {
                Color.black.ignoresSafeArea()
                
                VStack(spacing: 30) {
                    Text("裁切為正方形")
                        .font(.headline)
                        .foregroundColor(.white)
                        .padding(.top, 20)
                    
                    // 圖片預覽
                    Image(uiImage: image)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(maxWidth: 300, maxHeight: 300)
                        .cornerRadius(12)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.white, lineWidth: 2)
                        )
                    
                    Text("將會裁切為正方形圖片")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                    
                    Spacer()
                    
                    // 操作按鈕
                    HStack(spacing: 20) {
                        Button("取消") {
                            dismiss()
                        }
                        .foregroundColor(.white)
                        .padding(.horizontal, 30)
                        .padding(.vertical, 12)
                        .background(Color.gray.opacity(0.3))
                        .cornerRadius(25)
                        
                        Button("確認裁切") {
                            print("🔄 開始裁切圖片")
                            cropImage()
                        }
                        .foregroundColor(.white)
                        .padding(.horizontal, 30)
                        .padding(.vertical, 12)
                        .background(Color.blue)
                        .cornerRadius(25)
                    }
                    .padding(.bottom, 40)
                }
                .padding(.horizontal, 20)
            }
            .navigationBarHidden(true)
        }
    }
    
    private func cropImage() {
        print("🔄 cropImage 函數開始執行")
        
        // 簡化的裁切實現：創建一個正方形的裁切版本
        let size = min(image.size.width, image.size.height)
        let x = (image.size.width - size) / 2
        let y = (image.size.height - size) / 2
        
        print("🔄 計算裁切區域: size=\(size), x=\(x), y=\(y)")
        
        let cropRect = CGRect(x: x, y: y, width: size, height: size)
        
        guard let cgImage = image.cgImage?.cropping(to: cropRect) else {
            print("❌ 裁切失敗，使用原圖")
            onCropped(image)
            dismiss()
            return
        }
        
        print("✅ 裁切成功，創建新圖片")
        let croppedImage = UIImage(cgImage: cgImage, scale: image.scale, orientation: image.imageOrientation)
        onCropped(croppedImage)
        dismiss()
    }
}

