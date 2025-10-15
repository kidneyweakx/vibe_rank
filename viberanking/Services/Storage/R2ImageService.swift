//
//  R2ImageService.swift
//  viberanking
//
//  Created by Assistant on 2025/08/09.
//

import Foundation
import os.log

// MARK: - R2 Image Variants
/// Image variant names configured on CDN/Worker side.
/// If you do not use variants, pass `nil` to use the original object.
enum R2ImageVariant: String {
    case thumbnail
    case preview
    case highRes
    case original
}

// MARK: - R2 Image Service Protocol
protocol R2ImageServiceProtocol {
    /// Build a public URL for a given object key stored in R2.
    func makePublicURL(for key: String, variant: R2ImageVariant?) -> URL
    
    /// Fetch image data for a given key (optionally using a variant) with timeout control.
    func fetchImageData(for key: String, variant: R2ImageVariant?, timeout: TimeInterval?) async throws -> Data
    
    /// Preload multiple image keys into URLSession cache.
    func preload(keys: [String], variant: R2ImageVariant?) async

    /// Resolve a loadable URL for a key, using signed URL for private endpoints if needed.
    func resolveLoadableURL(for key: String) async -> URL
}

// MARK: - R2 Image Service Implementation
final class R2ImageService: R2ImageServiceProtocol {
    static let shared = R2ImageService()
    
    private let logger = Logger(subsystem: "com.viberanking.app", category: "R2ImageService")
    
    private init() {}
    
    // MARK: - URL Builder
    func makePublicURL(for key: String, variant: R2ImageVariant?) -> URL {
        // Build from configured public domain. Support both CDN/custom domain and
        // S3-compatible public endpoint (r2.cloudflarestorage.com).
        var base = AppConfiguration.R2.publicDomain
        base = base.hasPrefix("http") ? base : "https://\(base)"

        // If using S3 endpoint, ensure bucket segment is present: /<bucket>/<key>
        if base.contains("r2.cloudflarestorage.com") {
            let bucket = AppConfiguration.R2.bucketName
            if !base.hasSuffix("/\(bucket)") && !base.contains("/\(bucket)/") {
                base = base.hasSuffix("/") ? base + bucket : base + "/\(bucket)"
            }
        }

        var urlString = base
        if !urlString.hasSuffix("/") { urlString += "/" }
        urlString += key

        // Only append variant for CDN/worker domains that implement it
        if let variant = variant, variant != .original, !base.contains("r2.cloudflarestorage.com") {
            urlString += "?variant=\(variant.rawValue)"
        }

        logger.debug("R2 makePublicURL -> \(urlString)")
        guard let url = URL(string: urlString) else {
            fatalError("Failed to construct R2 public URL for key: \(key)")
        }
        return url
    }
    
    // MARK: - Fetch
    func fetchImageData(for key: String, variant: R2ImageVariant?, timeout: TimeInterval? = AppConfiguration.Performance.imageLoadTimeoutSeconds) async throws -> Data {
        let url = makePublicURL(for: key, variant: variant)
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.timeoutInterval = timeout ?? AppConfiguration.Performance.imageLoadTimeoutSeconds
        
        logger.debug("➡️ Fetching R2 image: \(url.absoluteString)")
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let http = response as? HTTPURLResponse, (200...299).contains(http.statusCode) else {
            let status = (response as? HTTPURLResponse)?.statusCode ?? -1
            logger.error("❌ R2 image fetch failed (status: \(status)): \(url.absoluteString)")
            throw APIError.serverError((response as? HTTPURLResponse)?.statusCode ?? -1)
        }
        logger.debug("✅ R2 image fetch success, bytes: \(data.count)")
        return data
    }
    
    // MARK: - Preload
    func preload(keys: [String], variant: R2ImageVariant? = .preview) async {
        await withTaskGroup(of: Void.self) { group in
            logger.debug("🔄 Preloading R2 images, count: \(keys.count), variant: \(variant?.rawValue ?? "none")")
            for key in keys {
                group.addTask { [weak self] in
                    guard let self else { return }
                    do {
                        _ = try await self.fetchImageData(for: key, variant: variant, timeout: 8)
                    } catch {
                        self.logger.error("⚠️ Preload failed for key: \(key), error: \(error.localizedDescription)")
                    }
                }
            }
        }
    }

    // MARK: - Resolve Loadable URL
    func resolveLoadableURL(for key: String) async -> URL {
        // If using the S3 endpoint, use backend-signed URL; otherwise use public URL
        if AppConfiguration.R2.publicDomain.contains("r2.cloudflarestorage.com") {
            do {
                let signed = try await FileAPI().getSignedDownloadURL(key: key)
                logger.debug("🔐 Using backend-signed URL for key: \(key)")
                return signed
            } catch {
                logger.error("❌ Backend signing failed: \(error.localizedDescription). Falling back to public URL.")
                return makePublicURL(for: key, variant: nil)
            }
        } else {
            return makePublicURL(for: key, variant: nil)
        }
    }
}


