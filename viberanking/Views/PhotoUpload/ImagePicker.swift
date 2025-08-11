//
//  ImagePicker.swift
//  viberanking
//
//  Created by Kiro on 2025/07/23.
//

import SwiftUI
import UIKit
import PhotosUI
import AVFoundation

// MARK: - Image Picker Source Type
enum ImagePickerSourceType {
    case camera
    case photoLibrary
}

// MARK: - Image Picker View
struct ImagePicker: UIViewControllerRepresentable {
    
    // MARK: - Properties
    let sourceType: ImagePickerSourceType
    let onImageSelected: (UIImage) -> Void
    
    @Environment(\.dismiss) private var dismiss
    
    // MARK: - UIViewControllerRepresentable
    func makeUIViewController(context: Context) -> UIViewController {
        switch sourceType {
        case .camera:
            // Guard camera availability to prevent crash
            if CameraPermissionHelper.isCameraAvailable {
                return makeCameraController(context: context)
            } else {
                // Fallback to a simple host controller if camera not available
                return UIViewController()
            }
        case .photoLibrary:
            return makePhotoLibraryController(context: context)
        }
    }
    
    func updateUIViewController(_ uiViewController: UIViewController, context: Context) {
        // No updates needed
    }
    
    // MARK: - Coordinator
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate, PHPickerViewControllerDelegate {
        let parent: ImagePicker
        
        init(_ parent: ImagePicker) {
            self.parent = parent
        }
        
        // MARK: - UIImagePickerControllerDelegate
        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            if let image = info[.originalImage] as? UIImage {
                parent.onImageSelected(image)
            }
            parent.dismiss()
        }
        
        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.dismiss()
        }
        
        // MARK: - PHPickerViewControllerDelegate
        func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
            parent.dismiss()
            
            guard let result = results.first else { return }
            
            result.itemProvider.loadObject(ofClass: UIImage.self) { [weak self] object, error in
                if let image = object as? UIImage {
                    DispatchQueue.main.async {
                        self?.parent.onImageSelected(image)
                    }
                }
            }
        }
    }
}

// MARK: - Private Methods
private extension ImagePicker {
    
    /// Create camera controller
    func makeCameraController(context: Context) -> UIViewController {
        let controller = UIImagePickerController()
        controller.sourceType = .camera
        controller.allowsEditing = false
        controller.delegate = context.coordinator
        
        // Camera settings for better quality
        controller.cameraCaptureMode = .photo
        controller.cameraDevice = .rear
        
        return controller
    }
    
    /// Create photo library controller using PHPickerViewController
    func makePhotoLibraryController(context: Context) -> UIViewController {
        var configuration = PHPickerConfiguration()
        configuration.filter = .images
        configuration.selectionLimit = 1
        configuration.preferredAssetRepresentationMode = .current
        
        let controller = PHPickerViewController(configuration: configuration)
        controller.delegate = context.coordinator
        
        return controller
    }
}

// MARK: - Camera Permission Helper
struct CameraPermissionHelper {
    
    /// Check if camera is available
    static var isCameraAvailable: Bool {
        return UIImagePickerController.isSourceTypeAvailable(.camera)
    }
    
    /// Request camera permission
    static func requestCameraPermission() async -> Bool {
        return await withCheckedContinuation { continuation in
            AVCaptureDevice.requestAccess(for: .video) { granted in
                continuation.resume(returning: granted)
            }
        }
    }
    
    /// Check camera authorization status
    static var cameraAuthorizationStatus: AVAuthorizationStatus {
        return AVCaptureDevice.authorizationStatus(for: .video)
    }
}

// MARK: - Photo Library Permission Helper
struct PhotoLibraryPermissionHelper {
    
    /// Request photo library permission
    static func requestPhotoLibraryPermission() async -> PHAuthorizationStatus {
        return await withCheckedContinuation { continuation in
            PHPhotoLibrary.requestAuthorization(for: .readWrite) { status in
                continuation.resume(returning: status)
            }
        }
    }
    
    /// Check photo library authorization status
    static var photoLibraryAuthorizationStatus: PHAuthorizationStatus {
        return PHPhotoLibrary.authorizationStatus(for: .readWrite)
    }
}

// MARK: - Permission Alert View
struct PermissionAlertView: View {
    let title: String
    let message: String
    let onOpenSettings: () -> Void
    let onCancel: () -> Void
    
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 48))
                .foregroundColor(.orange)
            
            Text(title)
                .font(.title2)
                .fontWeight(.bold)
                .multilineTextAlignment(.center)
            
            Text(message)
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            
            HStack(spacing: 12) {
                Button("common.cancel".localized) {
                    onCancel()
                }
                .font(.body)
                .foregroundColor(.secondary)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(Color(.secondarySystemGroupedBackground))
                .cornerRadius(8)
                
                Button("permission.go_to_settings".localized) {
                    onOpenSettings()
                }
                .font(.body)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(Color.blue)
                .cornerRadius(8)
            }
        }
        .padding(24)
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(radius: 8)
    }
}

// MARK: - Extensions
import AVFoundation

extension ImagePicker {
    
    /// Create permission alert for camera
    static func cameraPermissionAlert(onOpenSettings: @escaping () -> Void, onCancel: @escaping () -> Void) -> some View {
        PermissionAlertView(
            title: "permission.camera.title".localized,
            message: "permission.camera.message".localized,
            onOpenSettings: onOpenSettings,
            onCancel: onCancel
        )
    }
    
    /// Create permission alert for photo library
    static func photoLibraryPermissionAlert(onOpenSettings: @escaping () -> Void, onCancel: @escaping () -> Void) -> some View {
        PermissionAlertView(
            title: "permission.photo_library.title".localized,
            message: "permission.photo_library.message".localized,
            onOpenSettings: onOpenSettings,
            onCancel: onCancel
        )
    }
}