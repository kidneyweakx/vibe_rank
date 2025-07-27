//
//  Upload.swift
//  viberanking
//
//  Created by Kiro on 2025/07/27.
//

import Foundation

// MARK: - Upload Progress
struct UploadProgress {
    var photoId: String
    var status: UploadStatus = .pending
    var progress: Double = 0.0
}

// MARK: - Upload Status
enum UploadStatus {
    case pending
    case processing
    case uploading(progress: Double)
    case completed
    case failed(Error)
    case cancelled
}

// MARK: - Upload Task
struct UploadTask {
    var photoId: String
    var userId: String
    var status: UploadStatus = .pending
    var progress: Double = 0.0
}
