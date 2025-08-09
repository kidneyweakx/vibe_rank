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
        VStack(spacing: 24) {
            Text("選擇上傳方式")
                .font(.title2)
                .fontWeight(.medium)
                .foregroundColor(.white)
                .padding(.top, 32)
            
            HStack(spacing: 20) {
                // Camera option
                Button {
                    dismiss()
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                        onCameraSelected()
                    }
                } label: {
                    VStack(spacing: 16) {
                        Image(systemName: "camera")
                            .font(.largeTitle)
                            .foregroundColor(.white)
                        
                        Text("拍照")
                            .font(.body)
                            .fontWeight(.medium)
                            .foregroundColor(.white)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 32)
                    .background(Color(red: 0.15, green: 0.15, blue: 0.15))
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                }
                .buttonStyle(PlainButtonStyle())
                
                // Photo library option
                Button {
                    dismiss()
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                        onPhotoLibrarySelected()
                    }
                } label: {
                    VStack(spacing: 16) {
                        Image(systemName: "photo")
                            .font(.largeTitle)
                            .foregroundColor(.white)
                        
                        Text("相簿")
                            .font(.body)
                            .fontWeight(.medium)
                            .foregroundColor(.white)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 32)
                    .background(Color(red: 0.15, green: 0.15, blue: 0.15))
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                }
                .buttonStyle(PlainButtonStyle())
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 32)
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