//
//  UploadTabView.swift
//  viberanking
//
//  Created by Kiro on 2025/07/25.
//

import SwiftUI
import PhotosUI

struct UploadTabView: View {
    @EnvironmentObject private var authViewModel: AuthenticationViewModel
    @StateObject private var uploadViewModel = PhotoUploadViewModel()
    @State private var selectedPhotos: [PhotosPickerItem] = []
    @State private var uploadedImages: [UIImage] = []
    @State private var isUploading = false
    @State private var showingImagePicker = false
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            if authViewModel.isGuest || !(authViewModel.user?.ratingProgress.hasUnlockedUpload ?? false) {
                lockedStateView
            } else {
                cameraStyleView
            }
        }
    }
}

// MARK: - View Components
private extension UploadTabView {
    
    var lockedStateView: some View {
        VStack(spacing: 24) {
            Image(systemName: "lock.circle.fill")
                .font(.system(size: 80))
                .foregroundColor(.white.opacity(0.8))
            
            Text("upload.locked_title".localized)
                .font(.title2.bold())
                .foregroundColor(.white)
            
            if authViewModel.isGuest {
                Text("login.required.upload".localized)
                    .font(.body)
                    .foregroundColor(.white.opacity(0.7))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
                
                Button("guest.sign_in_now".localized) {
                    authViewModel.signOut()
                }
                .font(.headline)
                .foregroundColor(.black)
                .padding(.horizontal, 32)
                .padding(.vertical, 12)
                .background(Color.white)
                .clipShape(RoundedRectangle(cornerRadius: 25))
            } else {
                let remaining = (authViewModel.user?.ratingProgress.requiredRatings ?? 0) - (authViewModel.user?.ratingProgress.completedRatings ?? 0)
                
                Text("還需要評分 \(remaining) 張照片才能解鎖上傳功能")
                    .font(.body)
                    .foregroundColor(.white.opacity(0.7))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }
        }
    }
    
    var cameraStyleView: some View {
        GeometryReader { geometry in
            VStack(spacing: 0) {
                // Camera preview area (simulated)
                ZStack {
                    Rectangle()
                        .fill(Color.gray.opacity(0.3))
                        .frame(height: geometry.size.height * 0.7)
                    
                    if uploadedImages.isEmpty {
                        VStack(spacing: 16) {
                            Image(systemName: "camera.fill")
                                .font(.system(size: 60))
                                .foregroundColor(.white.opacity(0.6))
                            
                            Text("點擊下方按鈕開始拍攝")
                                .font(.headline)
                                .foregroundColor(.white.opacity(0.8))
                        }
                    } else {
                        // Show latest uploaded image
                        Image(uiImage: uploadedImages.last!)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(height: geometry.size.height * 0.7)
                            .clipped()
                    }
                }
                
                // Bottom control area
                ZStack {
                    Color.black
                        .frame(height: geometry.size.height * 0.3)
                    
                    HStack {
                        // Photo library button (left)
                        PhotosPicker(
                            selection: $selectedPhotos,
                            maxSelectionCount: 5,
                            matching: .images
                        ) {
                            ZStack {
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(Color.white.opacity(0.2))
                                    .frame(width: 50, height: 50)
                                
                                if let firstImage = uploadedImages.first {
                                    Image(uiImage: firstImage)
                                        .resizable()
                                        .aspectRatio(contentMode: .fill)
                                        .frame(width: 46, height: 46)
                                        .clipShape(RoundedRectangle(cornerRadius: 6))
                                } else {
                                    Image(systemName: "photo.on.rectangle")
                                        .font(.title2)
                                        .foregroundColor(.white)
                                }
                            }
                        }
                        .onChange(of: selectedPhotos) { _, newItems in
                            loadSelectedPhotos(newItems)
                        }
                        
                        Spacer()
                        
                        // Camera shutter button (center)
                        Button {
                            showingImagePicker = true
                        } label: {
                            ZStack {
                                Circle()
                                    .stroke(Color.white, lineWidth: 4)
                                    .frame(width: 80, height: 80)
                                
                                Circle()
                                    .fill(Color.white)
                                    .frame(width: 68, height: 68)
                            }
                        }
                        .sheet(isPresented: $showingImagePicker) {
                            ImagePicker(sourceType: .camera) { image in
                                uploadedImages.append(image)
                            }
                        }
                        
                        Spacer()
                        
                        // Upload button (right)
                        Button {
                            if !uploadedImages.isEmpty {
                                uploadPhotos()
                            }
                        } label: {
                            ZStack {
                                Circle()
                                    .fill(uploadedImages.isEmpty ? Color.gray.opacity(0.3) : Color.blue)
                                    .frame(width: 50, height: 50)
                                
                                if isUploading {
                                    ProgressView()
                                        .scaleEffect(0.8)
                                        .tint(.white)
                                } else {
                                    Image(systemName: "arrow.up.circle.fill")
                                        .font(.title2)
                                        .foregroundColor(.white)
                                }
                            }
                        }
                        .disabled(uploadedImages.isEmpty || isUploading)
                    }
                    .padding(.horizontal, 32)
                }
            }
        }
        .ignoresSafeArea(.container, edges: .bottom)
    }
    

}

// MARK: - Actions
private extension UploadTabView {
    func loadSelectedPhotos(_ items: [PhotosPickerItem]) {
        Task {
            for item in items {
                if let data = try? await item.loadTransferable(type: Data.self),
                   let image = UIImage(data: data) {
                    await MainActor.run {
                        uploadedImages.append(image)
                    }
                }
            }
        }
    }
    
    func uploadPhotos() {
        isUploading = true
        Task {
            for image in uploadedImages {
                uploadViewModel.handleSelectedImage(image)
                await uploadViewModel.performUpload(image: image, userId: authViewModel.user?.id ?? "")
            }
            
            await MainActor.run {
                isUploading = false
                uploadedImages.removeAll()
                selectedPhotos.removeAll()
            }
        }
    }
}

#Preview {
    UploadTabView()
        .environmentObject(AuthenticationViewModel())
}
