//
//  PhotoUploadViewModel.swift
//  viberanking
//
//  Created by Kiro on 2025/07/23.
//

import Foundation
import SwiftUI
import PhotosUI
import Combine
import UIKit

// MARK: - Photo Upload State
enum PhotoUploadState {
    case idle
    case selecting
    case previewing(UIImage)
    case uploading(progress: Double)
    case completed(Photo)
    case error(AppError)
}

// MARK: - Photo Source Type
enum PhotoSourceType {
    case camera
    case photoLibrary
}

// MARK: - Photo Upload ViewModel
@MainActor
class PhotoUploadViewModel: BaseViewModel {
    
    // MARK: - Published Properties
    @Published var uploadState: PhotoUploadState = .idle
    @Published var selectedImage: UIImage?
    @Published var uploadProgress: Double = 0.0
    @Published var showingImagePicker = false
    @Published var showingCamera = false
    @Published var sourceType: PhotoSourceType = .photoLibrary
    
    // MARK: - Dependencies
    private let photoUploadService: PhotoUploadService
    private let authService: AuthenticationService
    
    // MARK: - Private Properties
    private var cancellables = Set<AnyCancellable>()
    private var currentUploadTask: Task<Void, Never>?
    
    // MARK: - Initialization
    init(photoUploadService: PhotoUploadService,
         authService: AuthenticationService) {
        self.photoUploadService = photoUploadService
        self.authService = authService
        super.init()
        setupBindings()
    }
    
    convenience override init() {
        self.init(
            photoUploadService: PhotoUploadService(),
            authService: AuthenticationService()
        )
    }
    
    // MARK: - Public Methods
    
    /// Show camera for photo capture
    func showCamera() {
        sourceType = .camera
        showingCamera = true
        uploadState = .selecting
    }
    
    /// Show photo library picker
    func showPhotoLibrary() {
        sourceType = .photoLibrary
        showingImagePicker = true
        uploadState = .selecting
    }
    
    /// Handle selected image from picker
    func handleSelectedImage(_ image: UIImage) {
        selectedImage = image
        uploadState = .previewing(image)
    }
    
    /// Start photo upload process
    func uploadPhoto() {
        guard let image = selectedImage,
              let user = authService.currentUser else {
            setError(.authenticationFailed)
            return
        }
        
        currentUploadTask = Task {
            await performUpload(image: image, userId: user.id)
        }
    }
    
    /// Cancel current upload
    func cancelUpload() {
        currentUploadTask?.cancel()
        currentUploadTask = nil
        
        if case .uploading = uploadState {
            uploadState = .idle
            uploadProgress = 0.0
        }
    }
    
    /// Reset upload state
    func resetUpload() {
        cancelUpload()
        uploadState = .idle
        selectedImage = nil
        uploadProgress = 0.0
        showingImagePicker = false
        showingCamera = false
    }
    
    /// Retry upload after error
    func retryUpload() {
        if case .error = uploadState {
            if let image = selectedImage {
                uploadState = .previewing(image)
            } else {
                uploadState = .idle
            }
        }
    }
}

// MARK: - Private Methods
private extension PhotoUploadViewModel {
    
    /// Setup reactive bindings
    func setupBindings() {
        // Monitor upload progress changes
        $uploadProgress
            .sink { [weak self] progress in
                if case .uploading = self?.uploadState {
                    self?.uploadState = .uploading(progress: progress)
                }
            }
            .store(in: &cancellables)
    }
    
    /// Perform the actual photo upload
    public func performUpload(image: UIImage, userId: String) async {
        await MainActor.run {
            uploadState = .uploading(progress: 0.0)
            uploadProgress = 0.0
        }
        
        do {
            // Upload photo
            let uploadedPhoto = try await photoUploadService.uploadPhoto(image, for: userId)
            
            await MainActor.run {
                self.uploadProgress = 1.0
                self.uploadState = .completed(uploadedPhoto)
            }
            
        } catch let error as AppError {
            await MainActor.run {
                self.setError(error)
            }
        } catch {
            await MainActor.run {
                self.setError(.imageUploadFailed)
            }
        }
    }
    
    /// Set error state
    func setError(_ error: AppError) {
        uploadState = .error(error)
        uploadProgress = 0.0
    }
}

// MARK: - Computed Properties
extension PhotoUploadViewModel {
    
    /// Check if upload can be started
    var canStartUpload: Bool {
        if case .previewing = uploadState {
            return selectedImage != nil
        }
        return false
    }
    
    /// Check if upload is in progress
    var isUploading: Bool {
        if case .uploading = uploadState {
            return true
        }
        return false
    }
    
    /// Check if upload is completed
    var isCompleted: Bool {
        if case .completed = uploadState {
            return true
        }
        return false
    }
    
    /// Get current error if any
    var currentError: AppError? {
        if case .error(let error) = uploadState {
            return error
        }
        return nil
    }
    
    /// Get uploaded photo if completed
    var uploadedPhoto: Photo? {
        if case .completed(let photo) = uploadState {
            return photo
        }
        return nil
    }
}
