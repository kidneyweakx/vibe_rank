//
//  R2StorageService.swift
//  viberanking
//
//  Created by Kiro on 2025/07/26.
//

import Foundation
import CryptoKit

// MARK: - R2 Storage Service Protocol
protocol R2StorageServiceProtocol {
    func uploadPhotoSizes(_ photoSizes: PhotoSizes, photoId: String) async throws -> PhotoURLs
    func deletePhoto(photoId: String) async throws
    func getDownloadURL(for path: String) async throws -> URL
    func uploadSingleFile(_ data: Data, to path: String) async throws -> URL
}

// MARK: - R2 Storage Service Implementation
class R2StorageService: R2StorageServiceProtocol {
    
    // MARK: - Properties
    private let accountId: String
    private let bucketName: String
    private let accessKey: String
    private let secretKey: String
    private let publicDomain: String
    
    init() {
        // In a real app, you would fetch these from a secure configuration provider.
        self.accountId = AppConfiguration.R2.accountId
        self.bucketName = AppConfiguration.R2.bucketName
        self.accessKey = AppConfiguration.R2.accessKey
        self.secretKey = AppConfiguration.R2.secretKey
        self.publicDomain = AppConfiguration.R2.publicDomain
    }

    // MARK: - Public Methods
    
    func uploadPhotoSizes(_ photoSizes: PhotoSizes, photoId: String) async throws -> PhotoURLs {
        async let thumbnailUpload = uploadSingleFile(
            photoSizes.thumbnail,
            to: "\(AppConfiguration.StoragePaths.photos)/\(photoId)/thumbnail.webp"
        )
        
        async let previewUpload = uploadSingleFile(
            photoSizes.preview,
            to: "\(AppConfiguration.StoragePaths.photos)/\(photoId)/preview.webp"
        )
        
        async let highResUpload = uploadSingleFile(
            photoSizes.highRes,
            to: "\(AppConfiguration.StoragePaths.photos)/\(photoId)/highres.webp"
        )
        
        let (thumbnailURL, previewURL, highResURL) = try await (thumbnailUpload, previewUpload, highResUpload)
        
        return PhotoURLs(thumbnail: thumbnailURL, preview: previewURL, highRes: highResURL)
    }
    
    func deletePhoto(photoId: String) async throws {
        let filePaths = [
            "\(AppConfiguration.StoragePaths.photos)/\(photoId)/thumbnail.webp",
            "\(AppConfiguration.StoragePaths.photos)/\(photoId)/preview.webp",
            "\(AppConfiguration.StoragePaths.photos)/\(photoId)/highres.webp"
        ]
        
        try await withThrowingTaskGroup(of: Void.self) { group in
            for path in filePaths {
                group.addTask {
                    try await self.deleteSingleFile(path)
                }
            }
            try await group.waitForAll()
        }
    }
    
    func getDownloadURL(for path: String) async throws -> URL {
        guard let url = URL(string: "https://\(publicDomain)/\(path)") else {
            throw AppError.invalidURL
        }
        return url
    }
    
    func uploadSingleFile(_ data: Data, to path: String) async throws -> URL {
        let endpoint = "https://\(accountId).r2.cloudflarestorage.com/\(bucketName)/\(path)"
        guard let url = URL(string: endpoint) else {
            throw AppError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "PUT"
        request.httpBody = data
        
        let headers = try awsSignatureV4Headers(
            for: request,
            httpMethod: "PUT",
            date: Date(),
            payload: data
        )
        
        for (key, value) in headers {
            request.setValue(value, forHTTPHeaderField: key)
        }
        
        let (responseData, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse, (200...299).contains(httpResponse.statusCode) else {
            let errorBody = String(data: responseData, encoding: .utf8) ?? "No error body"
            print("R2 upload failed with status code: \((response as? HTTPURLResponse)?.statusCode ?? -1), body: \(errorBody)")
            throw AppError.imageUploadFailed
        }
        
        return try await getDownloadURL(for: path)
    }
    
    private func deleteSingleFile(_ path: String) async throws {
        let endpoint = "https://\(accountId).r2.cloudflarestorage.com/\(bucketName)/\(path)"
        guard let url = URL(string: endpoint) else {
            throw AppError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "DELETE"
        
        let headers = try awsSignatureV4Headers(
            for: request,
            httpMethod: "DELETE",
            date: Date(),
            payload: nil
        )
        
        for (key, value) in headers {
            request.setValue(value, forHTTPHeaderField: key)
        }
        
        let (_, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse, (200...299).contains(httpResponse.statusCode) else {
            throw AppError.imageUploadFailed // Or a more specific deletion error
        }
    }

    // MARK: - AWS Signature V4
    
    private func awsSignatureV4Headers(for request: URLRequest, httpMethod: String, date: Date, payload: Data?) throws -> [String: String] {
        let amzDate = amzDate(for: date)
        let dateStamp = dateStamp(for: date)
        
        let host = request.url!.host!
        let canonicalURI = "/" + (request.url?.pathComponents.dropFirst().joined(separator: "/") ?? "")
        
        let payloadHash = sha256Hex(payload ?? Data())
        
        let canonicalHeaders = "host:\(host)\nx-amz-content-sha256:\(payloadHash)\nx-amz-date:\(amzDate)\n"
        let signedHeaders = "host;x-amz-content-sha256;x-amz-date"
        
        let canonicalRequest = "\(httpMethod)\n\(canonicalURI)\n\n\(canonicalHeaders)\n\(signedHeaders)\n\(payloadHash)"
        
        let algorithm = "AWS4-HMAC-SHA256"
        let credentialScope = "\(dateStamp)/us-east-1/s3/aws4_request"
        
        let stringToSign = "\(algorithm)\n\(amzDate)\n\(credentialScope)\n\(sha256Hex(canonicalRequest.data(using: .utf8)!))"
        
        let signingKey = try getSignatureKey(key: "AWS4\(secretKey)".data(using: .utf8)!, dateStamp: dateStamp, regionName: "us-east-1", serviceName: "s3")
        
        let signature = hex(hmac_sha256(key: signingKey, data: stringToSign.data(using: .utf8)!))
        
        let authorizationHeader = "\(algorithm) Credential=\(accessKey)/\(credentialScope), SignedHeaders=\(signedHeaders), Signature=\(signature)"
        
        return [
            "Authorization": authorizationHeader,
            "x-amz-content-sha256": payloadHash,
            "x-amz-date": amzDate
        ]
    }
    
    private func getSignatureKey(key: Data, dateStamp: String, regionName: String, serviceName: String) throws -> Data {
        let kDate = hmac_sha256(key: key, data: dateStamp.data(using: .utf8)!)
        let kRegion = hmac_sha256(key: kDate, data: regionName.data(using: .utf8)!)
        let kService = hmac_sha256(key: kRegion, data: serviceName.data(using: .utf8)!)
        let kSigning = hmac_sha256(key: kService, data: "aws4_request".data(using: .utf8)!)
        return kSigning
    }
    
    private func hmac_sha256(key: Data, data: Data) -> Data {
        var context = HMAC<SHA256>(key: SymmetricKey(data: key))
        context.update(data: data)
        return context.finalize().withUnsafeBytes { Data($0) }
    }
    
    private func sha256Hex(_ data: Data) -> String {
        let hash = SHA256.hash(data: data)
        return hash.compactMap { String(format: "%02x", $0) }.joined()
    }
    
    private func hex(_ data: Data) -> String {
        return data.map { String(format: "%02x", $0) }.joined()
    }
    
    private func amzDate(for date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyyMMdd'T'HHmmss'Z'"
        formatter.timeZone = TimeZone(identifier: "UTC")
        return formatter.string(from: date)
    }

    private func dateStamp(for date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyyMMdd"
        formatter.timeZone = TimeZone(identifier: "UTC")
        return formatter.string(from: date)
    }
}
