//
//  FirebaseTestView.swift
//  viberanking
//
//  Created by Jules on 2025/07/24.
//

import SwiftUI
import Kingfisher

struct FirebaseTestView: View {
    @StateObject private var viewModel = FirebaseTestViewModel()
    @State private var isShowingImagePicker = false
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Firebase Storage Test")
                .font(.largeTitle)
            
            if let uploadedImage = viewModel.uploadedImage {
                VStack {
                    Text("Uploaded & Downloaded Image")
                    KFImage(uploadedImage)
                        .resizable()
                        .scaledToFit()
                        .frame(height: 200)
                        .border(Color.green, width: 2)
                }
            } else if viewModel.isUploading {
                ProgressView("Uploading...")
            } else {
                Button("Select Image to Upload") {
                    isShowingImagePicker = true
                }
                .padding()
                .background(Color.blue)
                .foregroundColor(.white)
                .cornerRadius(10)
            }
            
            if let status = viewModel.status {
                Text(status)
                    .foregroundColor(viewModel.isError ? .red : .green)
            }
            
            Spacer()
        }
        .padding()
        .sheet(isPresented: $isShowingImagePicker) {
            ImagePicker(sourceType: .photoLibrary) { image in
                viewModel.uploadImage(image)
            }
        }
    }
}

@MainActor
class FirebaseTestViewModel: ObservableObject {
    @Published var uploadedImage: URL?
    @Published var isUploading = false
    @Published var status: String?
    @Published var isError = false
    
    private let photoUploadService = PhotoUploadService()
    // A dummy user ID for testing purposes.
    private let testUserID = "firebase-test-user"
    
    func uploadImage(_ image: UIImage) {
        isUploading = true
        status = "Starting upload..."
        isError = false
        
        Task {
            do {
                let photo = try await photoUploadService.uploadPhoto(image, for: testUserID)
                status = "Upload successful! Image URL: \(photo.imageURL)"
                if let url = URL(string: photo.imageURL) {
                    self.uploadedImage = url
                } else {
                    status = "Error: Invalid URL received."
                    isError = true
                }
            } catch {
                status = "Upload failed: \(error.localizedDescription)"
                isError = true
            }
            isUploading = false
        }
    }
}

struct FirebaseTestView_Previews: PreviewProvider {
    static var previews: some View {
        FirebaseTestView()
    }
}
