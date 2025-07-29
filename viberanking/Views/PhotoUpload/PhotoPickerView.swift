//
//  PhotoPickerView.swift
//  viberanking
//
//  Created by Kiro on 2025/07/29.
//

import SwiftUI
import PhotosUI

struct PhotoPickerView: View {
    let onImageSelected: (UIImage) -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var selectedItems: [PhotosPickerItem] = []
    
    var body: some View {
        NavigationView {
            PhotosPicker(
                selection: $selectedItems,
                maxSelectionCount: 1,
                matching: .images
            ) {
                VStack(spacing: 20) {
                    Image(systemName: "photo.on.rectangle.angled")
                        .font(.system(size: 60))
                        .foregroundColor(.blue)
                    
                    Text("選擇照片")
                        .font(.title2)
                        .foregroundColor(.primary)
                    
                    Text("從相簿中選擇一張照片")
                        .font(.body)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color(.systemBackground))
            }
            .navigationTitle("選擇照片")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarBackButtonHidden()
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("取消") {
                        dismiss()
                    }
                }
            }
            .onChange(of: selectedItems) { _, newItems in
                guard let item = newItems.first else { return }
                
                Task {
                    if let data = try? await item.loadTransferable(type: Data.self),
                       let image = UIImage(data: data) {
                        await MainActor.run {
                            onImageSelected(image)
                            dismiss()
                        }
                    }
                }
            }
        }
    }
}

#Preview {
    PhotoPickerView { _ in }
}