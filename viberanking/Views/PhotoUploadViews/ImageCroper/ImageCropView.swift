//
//  ImageCropView.swift
//  viberanking
//
//  Created by Kiro on 2025/08/08.
//

import SwiftUI
import UIKit

struct ImageCropView: View {
    private let image: UIImage
    let onCropped: (UIImage) -> Void

    init(image: UIImage, onCropped: @escaping (UIImage) -> Void) {
        self.image = image.normalizedOrientation()
        self.onCropped = onCropped
    }
    
    @Environment(\.dismiss) private var dismiss
    @State private var imageOffset: CGPoint = .zero
    @State private var imageScale: CGFloat = 1.0
    @State private var lastScale: CGFloat = 1.0
    
    // 裁切框的尺寸 (9:16 比例) - 自適應 iPhone / iPad
    private var cropWidth: CGFloat {
        let minSide = min(UIScreen.main.bounds.width, UIScreen.main.bounds.height)
        let ratio: CGFloat = UIDevice.current.userInterfaceIdiom == .pad ? 0.58 : 0.6
        return max(320, minSide * ratio)
    }
    private var cropHeight: CGFloat { cropWidth * 16.0 / 9.0 }
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.black.ignoresSafeArea()
                
                VStack(spacing: 20) {
                    Text("crop.instruction.move".localized)
                        .font(.headline)
                        .foregroundColor(.white)
                        .padding(.top, 20)
                    
                    Text("crop.instruction.zoom_pan".localized)
                        .font(.subheadline)
                        .foregroundColor(.gray)
                    
                    // 裁切區域
                    ZStack {
                        // 背景圖片 - 填滿裁切框
                        Image(uiImage: image)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: image.size.width * imageScale, height: image.size.height * imageScale)
                            .offset(x: imageOffset.x, y: imageOffset.y)
                            .clipped()
                        
                        // 半透明遮罩
                        Rectangle()
                            .fill(Color.black.opacity(0.5))
                            .mask(
                                Rectangle()
                                    .fill(Color.black)
                                    .overlay(
                                        Rectangle()
                                            .frame(width: cropWidth, height: cropHeight)
                                            .blendMode(.destinationOut)
                                    )
                            )
                        
                        // 裁切框
                        Rectangle()
                            .stroke(Color.white, lineWidth: 2)
                            .frame(width: cropWidth, height: cropHeight)
                        
                        // 裁切框角落標記
                        VStack {
                            HStack {
                                CropCorner()
                                Spacer()
                                CropCorner()
                            }
                            Spacer()
                            HStack {
                                CropCorner()
                                Spacer()
                                CropCorner()
                            }
                        }
                        .frame(width: cropWidth, height: cropHeight)
                        
                        // 網格線
                        VStack(spacing: 0) {
                            Rectangle()
                                .stroke(Color.white.opacity(0.3), lineWidth: 1)
                                .frame(height: cropHeight / 3)
                            Rectangle()
                                .stroke(Color.white.opacity(0.3), lineWidth: 1)
                                .frame(height: cropHeight / 3)
                            Rectangle()
                                .stroke(Color.white.opacity(0.3), lineWidth: 1)
                                .frame(height: cropHeight / 3)
                        }
                        .frame(width: cropWidth)
                        
                        HStack(spacing: 0) {
                            Rectangle()
                                .stroke(Color.white.opacity(0.3), lineWidth: 1)
                                .frame(width: cropWidth / 3)
                            Rectangle()
                                .stroke(Color.white.opacity(0.3), lineWidth: 1)
                                .frame(width: cropWidth / 3)
                            Rectangle()
                                .stroke(Color.white.opacity(0.3), lineWidth: 1)
                                .frame(width: cropWidth / 3)
                        }
                        .frame(height: cropHeight)
                    }
                    .frame(width: cropWidth, height: cropHeight)
                    .clipped()
                    .simultaneousGesture(
                        DragGesture(minimumDistance: 0)
                            .onChanged { value in
                                let newOffset = CGPoint(x: value.translation.width, y: value.translation.height)
                                imageOffset = limitOffset(newOffset)
                            }
                    )
                    .simultaneousGesture(
                        MagnificationGesture()
                            .onChanged { value in
                                let delta = value / lastScale
                                lastScale = value
                                let newScale = imageScale * delta
                                let minScale = getMinimumScale()
                                imageScale = max(minScale, min(newScale, 3.0))
                            }
                            .onEnded { _ in
                                lastScale = 1.0
                            }
                    )
                    
                    Text("crop.aspect_916".localized)
                        .font(.caption)
                        .foregroundColor(.gray)
                    
                    Spacer()
                    
                    // 操作按鈕
                    HStack(spacing: 20) {
                        Button("crop.reset".localized) {
                            withAnimation(.easeInOut(duration: 0.3)) {
                                imageOffset = .zero
                                imageScale = 1.0
                                setupInitialImagePosition()
                            }
                        }
                        .foregroundColor(.white)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 12)
                        .background(Color.gray.opacity(0.3))
                        .cornerRadius(25)
                        
                        Button("common.cancel".localized) {
                            dismiss()
                        }
                        .foregroundColor(.white)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 12)
                        .background(Color.gray.opacity(0.3))
                        .cornerRadius(25)
                        
                        Button("crop.confirm".localized) {
                            cropImage()
                        }
                        .foregroundColor(.white)
                        .padding(.horizontal, 20)
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
        .onAppear {
            print("🎯 ImageCropView 顯示")
            setupInitialImagePosition()
        }
    }
    
    private func getMinimumScale() -> CGFloat {
        // 計算能夠填滿裁切框的最小縮放比例
        let imageAspectRatio = image.size.width / image.size.height
        let cropAspectRatio = cropWidth / cropHeight
        
        if imageAspectRatio > cropAspectRatio {
            // 圖片比裁切框寬，按高度縮放
            return cropHeight / image.size.height
        } else {
            // 圖片比裁切框高，按寬度縮放
            return cropWidth / image.size.width
        }
    }
    
    private func limitOffset(_ offset: CGPoint) -> CGPoint {
        // 計算當前圖片的顯示尺寸
        let displayWidth = image.size.width * imageScale
        let displayHeight = image.size.height * imageScale
        
        // 計算最大偏移量
        let maxOffsetX = max(0, (displayWidth - cropWidth) / 2)
        let maxOffsetY = max(0, (displayHeight - cropHeight) / 2)
        
        // 限制偏移量在合理範圍內
        let limitedX = max(-maxOffsetX, min(maxOffsetX, offset.x))
        let limitedY = max(-maxOffsetY, min(maxOffsetY, offset.y))
        
        return CGPoint(x: limitedX, y: limitedY)
    }
    
    private func setupInitialImagePosition() {
        // 設置初始縮放比例，確保圖片填滿裁切框
        imageScale = getMinimumScale()
        
        // 重置偏移量到中心
        imageOffset = .zero
        
        let imageAspectRatio = image.size.width / image.size.height
        let cropAspectRatio = cropWidth / cropHeight
        
        print("🔄 初始設置 - 圖片比例: \(imageAspectRatio), 裁切框比例: \(cropAspectRatio), 縮放: \(imageScale)")
    }
    
    private func cropImage() {
        print("🔄 cropImage 函數開始執行 - 交互式裁切")
        
        // 計算實際的裁切區域
        let imageSize = image.size
        let displaySize = CGSize(
            width: imageSize.width * imageScale,
            height: imageSize.height * imageScale
        )
        
        // 計算裁切框在原圖中的位置
        let scaleX = imageSize.width / displaySize.width
        let scaleY = imageSize.height / displaySize.height
        
        // 考慮偏移量
        let offsetX = -imageOffset.x * scaleX
        let offsetY = -imageOffset.y * scaleY
        
        // 計算裁切框在原圖中的實際位置
        let cropX = offsetX + (displaySize.width - cropWidth) / 2 * scaleX
        let cropY = offsetY + (displaySize.height - cropHeight) / 2 * scaleY
        let cropW = cropWidth * scaleX
        let cropH = cropHeight * scaleY
        
        // 確保裁切區域在圖片範圍內
        let finalCropRect = CGRect(
            x: max(0, min(cropX, imageSize.width - cropW)),
            y: max(0, min(cropY, imageSize.height - cropH)),
            width: min(cropW, imageSize.width),
            height: min(cropH, imageSize.height)
        )
        
        print("🔄 計算裁切區域: \(finalCropRect)")
        
        guard let cgImage = image.cgImage?.cropping(to: finalCropRect) else {
            print("❌ 裁切失敗，使用原圖")
            onCropped(image)
            dismiss()
            return
        }
        
        print("✅ 裁切成功，創建新圖片")
        let croppedImage = UIImage(cgImage: cgImage, scale: image.scale, orientation: .up)
        onCropped(croppedImage)
        dismiss()
    }
}

// MARK: - 裁切框角落標記
struct CropCorner: View {
    var body: some View {
        VStack(spacing: 0) {
            Rectangle()
                .fill(Color.white)
                .frame(width: 20, height: 3)
            HStack(spacing: 0) {
                Rectangle()
                    .fill(Color.white)
                    .frame(width: 3, height: 20)
                Spacer()
            }
        }
        .frame(width: 20, height: 20)
    }
}

private extension UIImage {
    func normalizedOrientation() -> UIImage {
        guard imageOrientation != .up else { return self }
        let format = UIGraphicsImageRendererFormat()
        format.scale = scale
        let renderer = UIGraphicsImageRenderer(size: size, format: format)
        return renderer.image { _ in
            draw(in: CGRect(origin: .zero, size: size))
        }
    }
}

