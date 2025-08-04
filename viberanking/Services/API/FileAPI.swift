//
//  FileAPI.swift
//  viberanking
//
//  Created by Kiro on 2025/08/05.
//

import Foundation

// MARK: - File API Response Models

struct PhotoUploadResponse: Codable {
    let photoId: String
    let urls: PhotoURLs
    let uploadedAt: Date
}

struct PhotoListResponse: Codable {
    let photos: [PhotoInfo]
    let totalCount: Int
    let hasMore: Bool
}

struct PhotoInfo: Codable {
    let id: String
    let userId: String
    let urls: PhotoURLs
    let uploadedAt: Date
}

// MARK: - File API Implementation

class FileAPI {
    
    private let apiClient = APIClient.shared
    
    // MARK: - Photo Operations
    
    /// Upload photo
    func uploadPhoto(_ imageData: Data, userId: String) async throws -> PhotoUploadResponse {
        print("upload files")
        let base64Image = imageData.base64EncodedString()
        
        let body: [String: Any] = [
            "userId": userId,
            "imageData": base64Image,
            "format": "png"
        ]
        
        return try await apiClient.performRequest(
            endpoint: "/file/upload",
            method: .POST,
            body: body,
            responseType: PhotoUploadResponse.self
        )
    }
    
    /// Verify file exists
    func verifyFile(key: String) async throws -> Bool {
        let endpoint = "/file/verify/\(key)"
        
        // This would need to be adjusted based on your APIClient implementation
        // for handling responses that don't match PhotoListResponse
        return try await apiClient.performRequest(
            endpoint: endpoint,
            method: .GET,
            responseType: Bool.self // You might need to create a proper response type
        )
    }
    
    /// Delete file
    func deleteFile(key: String) async throws {
        try await apiClient.performRequest(
            endpoint: "/file/\(key)",
            method: .DELETE
        )
    }
}