//
//  ImagePreviewView.swift
//  viberanking
//
//  Created by Kiro on 2025/07/29.
//

import SwiftUI

struct ImagePreviewView: View {
    let image: UIImage
    let onDismiss: () -> Void
    
    @EnvironmentObject private var authViewModel: AuthenticationViewModel
    @StateObject private var uploadViewModel = PhotoUploadViewModel()
    @State private var isUploading = false
    @State private var uploadSuccess = false
    @State private var showingFilters = false
    @State private var selectedFilter: FilterType = .none
    @State private var filteredImage: UIImage?
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Top navigation
                HStack {
                    Button("取消") {
                        onDismiss()
                    }
                    .foregroundColor(.white)
                    
                    Spacer()
                    
                    Text("編輯照片")
                        .font(.headline)
                        .foregroundColor(.white)
                    
                    Spacer()
                    
                    Button("上傳") {
                        uploadPhoto()
                    }
                    .foregroundColor(isUploading ? .gray : .blue)
                    .disabled(isUploading)
                }
                .padding(.horizontal, 20)
                .padding(.top, 10)
                
                // Image preview
                GeometryReader { geometry in
                    Image(uiImage: filteredImage ?? image)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: geometry.size.width, height: geometry.size.height)
                        .clipped()
                }
                .padding(.vertical, 20)
                
                // Bottom controls
                VStack(spacing: 20) {
                    // Filter toggle
                    Button {
                        showingFilters.toggle()
                    } label: {
                        HStack {
                            Image(systemName: "camera.filters")
                                .font(.title3)
                            Text("濾鏡")
                                .font(.headline)
                        }
                        .foregroundColor(.white)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 10)
                        .background(Color.white.opacity(0.2))
                        .clipShape(RoundedRectangle(cornerRadius: 20))
                    }
                    
                    // Filter options
                    if showingFilters {
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 15) {
                                ForEach(FilterType.allCases, id: \.self) { filter in
                                    FilterButton(
                                        filter: filter,
                                        isSelected: selectedFilter == filter,
                                        originalImage: image
                                    ) {
                                        selectedFilter = filter
                                        applyFilter(filter)
                                    }
                                }
                            }
                            .padding(.horizontal, 20)
                        }
                    }
                }
                .padding(.bottom, 40)
            }
            
            // Upload progress overlay
            if isUploading {
                Color.black.opacity(0.7)
                    .ignoresSafeArea()
                
                VStack(spacing: 20) {
                    ProgressView()
                        .scaleEffect(1.5)
                        .tint(.white)
                    
                    Text("上傳中...")
                        .font(.headline)
                        .foregroundColor(.white)
                }
            }
            
            // Success overlay
            if uploadSuccess {
                Color.black.opacity(0.7)
                    .ignoresSafeArea()
                
                VStack(spacing: 20) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 60))
                        .foregroundColor(.green)
                    
                    Text("上傳成功！")
                        .font(.title2)
                        .foregroundColor(.white)
                }
                .onAppear {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                        onDismiss()
                    }
                }
            }
        }
    }
    
    private func applyFilter(_ filter: FilterType) {
        filteredImage = filter.apply(to: image)
    }
    
    private func uploadPhoto() {
        isUploading = true
        
        Task {
            let imageToUpload = filteredImage ?? image
            uploadViewModel.handleSelectedImage(imageToUpload)
            await uploadViewModel.performUpload(
                image: imageToUpload,
                userId: authViewModel.user?.id ?? ""
            )
            
            await MainActor.run {
                isUploading = false
                uploadSuccess = true
            }
        }
    }
}

// MARK: - Filter Types
enum FilterType: CaseIterable {
    case none, sepia, noir, vintage, bright, contrast
    
    var name: String {
        switch self {
        case .none: return "原圖"
        case .sepia: return "復古"
        case .noir: return "黑白"
        case .vintage: return "懷舊"
        case .bright: return "明亮"
        case .contrast: return "對比"
        }
    }
    
    func apply(to image: UIImage) -> UIImage {
        guard self != .none else { return image }
        
        let context = CIContext()
        guard let ciImage = CIImage(image: image) else { return image }
        
        let filter: CIFilter?
        
        switch self {
        case .none:
            return image
        case .sepia:
            filter = CIFilter(name: "CISepiaTone")
            filter?.setValue(ciImage, forKey: kCIInputImageKey)
            filter?.setValue(0.8, forKey: kCIInputIntensityKey)
        case .noir:
            filter = CIFilter(name: "CIPhotoEffectNoir")
            filter?.setValue(ciImage, forKey: kCIInputImageKey)
        case .vintage:
            filter = CIFilter(name: "CIPhotoEffectInstant")
            filter?.setValue(ciImage, forKey: kCIInputImageKey)
        case .bright:
            filter = CIFilter(name: "CIExposureAdjust")
            filter?.setValue(ciImage, forKey: kCIInputImageKey)
            filter?.setValue(0.5, forKey: kCIInputEVKey)
        case .contrast:
            filter = CIFilter(name: "CIColorControls")
            filter?.setValue(ciImage, forKey: kCIInputImageKey)
            filter?.setValue(1.5, forKey: kCIInputContrastKey)
        }
        
        guard let outputImage = filter?.outputImage,
              let cgImage = context.createCGImage(outputImage, from: outputImage.extent) else {
            return image
        }
        
        return UIImage(cgImage: cgImage)
    }
}

// MARK: - Filter Button
struct FilterButton: View {
    let filter: FilterType
    let isSelected: Bool
    let originalImage: UIImage
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 8) {
                Image(uiImage: filter.apply(to: originalImage))
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 60, height: 60)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(isSelected ? Color.blue : Color.clear, lineWidth: 2)
                    )
                
                Text(filter.name)
                    .font(.caption)
                    .foregroundColor(isSelected ? .blue : .white)
            }
        }
    }
}

#Preview {
    ImagePreviewView(
        image: UIImage(systemName: "photo") ?? UIImage(),
        onDismiss: {}
    )
    .environmentObject(AuthenticationViewModel())
}