//
//  PresignedUploadService.swift
//  viberanking
//
//  Created by Assistant on 2025/08/10.
//

import Foundation

/// Service dedicated to uploading bytes to a presigned URL (S3/R2 style)
final class PresignedUploadService {
    static let shared = PresignedUploadService()
    private init() {}
    
    func upload(data: Data, to urlString: String, headers: [String: String]?) async throws {
        guard let url = URL(string: urlString) else {
            throw APIError.invalidURL
        }
        var request = URLRequest(url: url)
        request.httpMethod = "PUT"
        request.httpBody = data
        headers?.forEach { key, value in
            request.setValue(value, forHTTPHeaderField: key)
        }
        // Ensure content-type header exists; callers can override via headers
        if request.value(forHTTPHeaderField: "Content-Type") == nil {
            request.setValue("image/webp", forHTTPHeaderField: "Content-Type")
        }
        let (_, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse, (200..<300).contains(http.statusCode) else {
            let code = (response as? HTTPURLResponse)?.statusCode ?? -1
            throw APIError.serverError(code)
        }
    }
}


