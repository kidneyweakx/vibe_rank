//
//  PhotoPickerView.swift
//  viberanking
//
//  Created by Kiro on 2025/08/08.
//

import SwiftUI
import PhotosUI

struct PhotoPickerView: UIViewControllerRepresentable {
    let onImageSelected: (UIImage) -> Void
    @Environment(\.dismiss) private var dismiss
    
    func makeUIViewController(context: Context) -> PHPickerViewController {
        var configuration = PHPickerConfiguration()
        configuration.filter = .images
        configuration.selectionLimit = 1
        configuration.preferredAssetRepresentationMode = .current
        
        let controller = PHPickerViewController(configuration: configuration)
        controller.delegate = context.coordinator
        return controller
    }
    
    func updateUIViewController(_ uiViewController: PHPickerViewController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, PHPickerViewControllerDelegate {
        let parent: PhotoPickerView
        
        init(_ parent: PhotoPickerView) {
            self.parent = parent
        }
        
        func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
            print("📸 PhotoPicker didFinishPicking 被調用")
            
            guard let result = results.first else {
                print("❌ 沒有選擇圖片")
                parent.dismiss()
                return
            }
            
            print("🔄 開始加載圖片")
            result.itemProvider.loadObject(ofClass: UIImage.self) { [weak self] object, error in
                DispatchQueue.main.async {
                    if let error = error {
                        print("❌ 圖片加載失敗: \(error)")
                        self?.parent.dismiss()
                        return
                    }
                    
                    if let image = object as? UIImage {
                        print("✅ 圖片加載成功 - 尺寸: \(image.size)")
                        self?.parent.onImageSelected(image)
                        self?.parent.dismiss()
                    } else {
                        print("❌ 無法轉換為 UIImage")
                        self?.parent.dismiss()
                    }
                }
            }
        }
    }
}