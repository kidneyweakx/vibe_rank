//
//  UploadMenuView.swift
//  viberanking
//
//  Created by Kiro on 2025/07/29.
//

import SwiftUI

struct UploadMenuView: View {
    let onCameraSelected: () -> Void
    let onPhotoLibrarySelected: () -> Void
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        VStack(spacing: 0) {
            // Drag indicator
            RoundedRectangle(cornerRadius: 2)
                .fill(Color.gray.opacity(0.3))
                .frame(width: 40, height: 4)
                .padding(.top, 8)
            
            VStack(spacing: 20) {
                Text("選擇上傳方式")
                    .font(.headline)
                    .foregroundColor(.white)
                    .padding(.top, 20)
                
                HStack(spacing: 70) {
                    // Camera option
                    Button {
                        dismiss()
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                            onCameraSelected()
                        }
                    } label: {
                        VStack(spacing: 12) {
                            ZStack {
                                Circle()
                                    .fill(Color.blue)
                                    .frame(width: 60, height: 60)
                                
                                Image(systemName: "camera.fill")
                                    .font(.title2)
                                    .foregroundColor(.white)
                            }
                            
                            Text("拍照")
                                .font(.subheadline)
                                .foregroundColor(.white)
                        }
                    }
                    
                    // Photo library option
                    Button {
                        dismiss()
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                            onPhotoLibrarySelected()
                        }
                    } label: {
                        VStack(spacing: 12) {
                            ZStack {
                                Circle()
                                    .fill(Color.green)
                                    .frame(width: 60, height: 60)
                                
                                Image(systemName: "photo.on.rectangle")
                                    .font(.title2)
                                    .foregroundColor(.white)
                            }
                            
                            Text("相簿")
                                .font(.subheadline)
                                .foregroundColor(.white)
                        }
                    }
                }
                .padding(.bottom, 30)
            }
        }
        .frame(maxWidth: .infinity)
        .background(Color.black)
    }
}

#Preview {
    UploadMenuView(
        onCameraSelected: {},
        onPhotoLibrarySelected: {}
    )
}