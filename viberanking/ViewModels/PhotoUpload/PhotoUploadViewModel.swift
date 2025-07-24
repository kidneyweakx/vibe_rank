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
    case validating
    case previewing(UIImage, PhotoMetadata?)
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
    @Published var photoMetadata: PhotoMetadata?
    @Published var uploadProgress: Double = 0.0
    @Published var showingImagePicker = false
    @Published var showingCamera = false
    @Published var sourceType: PhotoSourceType = .photoLibrary
    @Published var validationMessage: String = ""
    @Published var isValidationPassed = false
    
    // MARK: - Dependencies
    private let photoUploadService: PhotoUploadServiceProtocol
    private let authService: AuthenticationServiceProtocol
    
    // MARK: - Private Properties
    private var cancellables = Set<AnyCancellable>()
    private var currentUploadTask: Task<Void, Never>?
    
    // MARK: - Initialization
    init(photoUploadService: PhotoUploadServiceProtocol, 
         authService: AuthenticationServiceProtocol) {
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
        validateSelectedImage(image)
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
        photoMetadata = nil
        uploadProgress = 0.0
        validationMessage = ""
        isValidationPassed = false
        showingImagePicker = false
        showingCamera = false
    }
    
    /// Retry upload after error
    func retryUpload() {
        if case .error = uploadState {
            if let image = selectedImage {
                validateSelectedImage(image)
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
    
    /// Validate selected image with EXIF data
    func validateSelectedImage(_ image: UIImage) {
        uploadState = .validating
        validationMessage = "正在驗證照片..."
        
        Task {
            do {
                // Convert image to data for EXIF processing
                guard let imageData = image.jpegData(compressionQuality: 1.0) else {
                    throw AppError.invalidImageFormat
                }
                
                // Extract EXIF data
                let metadata = try await photoUploadService.extractEXIFData(imageData)
                
                // Validate photo freshness
                let isValid = try await photoUploadService.validatePhotoFreshness(metadata)
                
                await MainActor.run {
                    self.photoMetadata = metadata
                    self.isValidationPassed = isValid
                    self.uploadState = .previewing(image, metadata)
                    self.updateValidationMessage(for: metadata)
                }
                
            } catch let error as AppError {
                await MainActor.run {
                    self.setError(error)
                }
            } catch {
                await MainActor.run {
                    self.setError(.validationError("照片驗證失敗"))
                }
            }
        }
    }
    
    /// Update validation message based on metadata
    func updateValidationMessage(for metadata: PhotoMetadata) {
        if metadata.hasValidEXIF {
            if metadata.isRecentPhoto {
                validationMessage = "✅ 照片驗證通過"
            } else {
                validationMessage = "⚠️ 照片拍攝時間超過24小時"
            }
        } else {
            validationMessage = "❌ 照片缺少必要的EXIF資料"
        }
        
        if let cameraModel = metadata.cameraModel {
            validationMessage += "\n📷 相機: \(cameraModel)"
        }
        
        if let dateTaken = metadata.dateTaken {
            let formatter = DateFormatter()
            formatter.dateStyle = .medium
            formatter.timeStyle = .short
            validationMessage += "\n📅 拍攝時間: \(formatter.string(from: dateTaken))"
        }
    }
    
    /// Perform the actual photo upload
    func performUpload(image: UIImage, userId: String) async {
        await MainActor.run {
            uploadState = .uploading(progress: 0.0)
            uploadProgress = 0.0
        }
        
        do {
            // Simulate progress updates during upload
            let progressTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { _ in
                Task { @MainActor in
                    if case .uploading(let currentProgress) = self.uploadState,
                       currentProgress < 0.9 {
                        self.uploadProgress = min(currentProgress + 0.02, 0.9)
                    }
                }
            }
            
            // Upload photo
            let uploadedPhoto = try await photoUploadService.uploadPhoto(image, for: userId)
            
            progressTimer.invalidate()
            
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
            return isValidationPassed && selectedImage != nil
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