//
//  S3Presigner.swift
//  viberanking
//
//  Created by Assistant on 2025/08/09.
//

import Foundation
import CryptoKit

/// Minimal AWS SigV4 presigner for Cloudflare R2 (S3-compatible).
/// WARNING: Do not ship AccessKey/SecretKey in production apps.
struct S3Presigner {
    struct PresignConfig {
        let accessKeyId: String
        let secretAccessKey: String
        let region: String // For R2 use "auto"
        let service: String // "s3"
        let endpointHost: String // e.g. 8ed27....r2.cloudflarestorage.com
        let bucket: String // e.g. vibe-rank-01
    }

    private let config: PresignConfig
    
    init(config: PresignConfig) {
        self.config = config
    }
    
    /// Generate a presigned GET URL for the given object key with specified expiry seconds
    func presignGET(objectKey: String, expires: Int = 600, now: Date = Date()) -> URL? {
        let iso8601 = iso8601Timestamp(date: now)
        let datestamp = dateStamp(date: now)
        
        // Build canonical request parts
        let host = config.endpointHost
        let canonicalURI = "/\(config.bucket)/\(objectKey)"
        let algorithm = "AWS4-HMAC-SHA256"
        let credentialScope = "\(datestamp)/\(config.region)/\(config.service)/aws4_request"
        let signedHeaders = "host"
        
        // Query params for presign
        var queryItems: [URLQueryItem] = [
            .init(name: "X-Amz-Algorithm", value: algorithm),
            .init(name: "X-Amz-Credential", value: "\(config.accessKeyId)/\(credentialScope)"),
            .init(name: "X-Amz-Date", value: iso8601),
            .init(name: "X-Amz-Expires", value: String(expires)),
            .init(name: "X-Amz-SignedHeaders", value: signedHeaders)
        ]
        
        // Canonical query string (sorted by name, encoded)
        let canonicalQuery = canonicalQueryString(from: queryItems)
        
        // Canonical headers
        let canonicalHeaders = "host:\(host)\n"
        
        // Payload hash for presign is UNSIGNED-PAYLOAD
        let payloadHash = "UNSIGNED-PAYLOAD"
        
        // Canonical request
        let canonicalRequest = "GET\n\(canonicalURI)\n\(canonicalQuery)\n\(canonicalHeaders)\n\(signedHeaders)\n\(payloadHash)"
        let canonicalRequestHash = sha256Hex(canonicalRequest)
        
        // String to sign
        let stringToSign = "\(algorithm)\n\(iso8601)\n\(credentialScope)\n\(canonicalRequestHash)"
        
        // Signing key
        let signingKey = buildSigningKey(secretKey: config.secretAccessKey, dateStamp: datestamp, region: config.region, service: config.service)
        let signature = hmacSHA256Hex(key: signingKey, data: stringToSign)
        
        // Final URL
        var urlComponents = URLComponents()
        urlComponents.scheme = "https"
        urlComponents.host = host
        urlComponents.path = canonicalURI
        var finalItems = queryItems
        finalItems.append(.init(name: "X-Amz-Signature", value: signature))
        // Must keep the same order as canonicalQueryString
        urlComponents.percentEncodedQuery = canonicalQueryString(from: finalItems)
        return urlComponents.url
    }
}

// MARK: - Helpers
private extension S3Presigner {
    func iso8601Timestamp(date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyyMMdd'T'HHmmss'Z'"
        formatter.timeZone = TimeZone(abbreviation: "UTC")
        return formatter.string(from: date)
    }
    
    func dateStamp(date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyyMMdd"
        formatter.timeZone = TimeZone(abbreviation: "UTC")
        return formatter.string(from: date)
    }
    
    func sha256Hex(_ string: String) -> String {
        let data = Data(string.utf8)
        let digest = SHA256.hash(data: data)
        return digest.compactMap { String(format: "%02x", $0) }.joined()
    }
    
    func hmacSHA256(_ key: Data, _ data: String) -> Data {
        let input = Data(data.utf8)
        let mac = HMAC<SHA256>.authenticationCode(for: input, using: SymmetricKey(data: key))
        return Data(mac)
    }
    
    func hmacSHA256Hex(key: Data, data: String) -> String {
        let mac = hmacSHA256(key, data)
        return mac.compactMap { String(format: "%02x", $0) }.joined()
    }
    
    func buildSigningKey(secretKey: String, dateStamp: String, region: String, service: String) -> Data {
        let kSecret = Data(("AWS4" + secretKey).utf8)
        let kDate = hmacSHA256(kSecret, dateStamp)
        let kRegion = hmacSHA256(kDate, region)
        let kService = hmacSHA256(kRegion, service)
        let kSigning = hmacSHA256(kService, "aws4_request")
        return kSigning
    }
    
    func canonicalQueryString(from items: [URLQueryItem]) -> String {
        let encoded = items.map { (item) -> (String, String) in
            let name = item.name.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? item.name
            let value = (item.value ?? "").addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
            return (name, value)
        }
        .sorted { $0.0 < $1.0 }
        
        return encoded.map { "\($0.0)=\($0.1)" }.joined(separator: "&")
    }
}


