//
//  ImageCache.swift
//  viberanking
//
//  Created by Kiro on 2025/08/09.
//

import Foundation
import SwiftUI
import os.log

class ImageCache {
    static let shared = ImageCache()
    
    // Memory cache
    private let memoryCache = NSCache<NSString, UIImage>()
    
    // Disk cache
    private let diskCache = DiskCache()
    
    // Loading tasks to avoid duplicate requests
    private var loadingTasks: [String: Task<Void, Never>] = [:]
    
    private init() {
        // Configure memory cache
        memoryCache.countLimit = 100 // Max 100 images in memory
        memoryCache.totalCostLimit = 50 * 1024 * 1024 // 50MB limit
        
        // Clear expired disk cache on app launch
        Task {
            await diskCache.cleanExpiredCache()
        }
    }
    
    // MARK: - Public Methods
    
    /// Get image from cache or load from network
    func getImage(from urlString: String) async -> UIImage? {
        // Check memory cache first
        if let cachedImage = memoryCache.object(forKey: urlString as NSString) {
            logger.debug("✅ Memory cache hit: \(urlString)")
            return cachedImage
        }
        
        // Check disk cache
        if let diskImage = await diskCache.getImage(for: urlString) {
            logger.debug("✅ Disk cache hit: \(urlString)")
            // Store in memory cache for faster access
            memoryCache.setObject(diskImage, forKey: urlString as NSString)
            return diskImage
        }
        
        // Load from network
        return await loadAndCacheImage(from: urlString)
    }
    
    /// Preload images for better performance
    func preloadImages(urls: [String]) {
        let logger = Logger(subsystem: "com.viberanking.app", category: "ImageCache")
        logger.debug("🔄 Preloading images, count: \(urls.count)")
        
        for urlString in urls {
            // Avoid duplicate loading tasks
            guard loadingTasks[urlString] == nil else { continue }
            
            let task = Task {
                _ = await getImage(from: urlString)
            }
            loadingTasks[urlString] = task
        }
    }
    
    /// Clear all caches
    func clearAllCaches() {
        memoryCache.removeAllObjects()
        Task {
            await diskCache.clearAll()
        }
        loadingTasks.values.forEach { $0.cancel() }
        loadingTasks.removeAll()
    }
    
    // MARK: - Private Methods
    
    private func loadAndCacheImage(from urlString: String) async -> UIImage? {
        guard let url = URL(string: urlString) else { return nil }
        
        do {
            // Use optimized URLSession configuration
            let config = URLSessionConfiguration.default
            config.timeoutIntervalForRequest = 15
            config.timeoutIntervalForResource = 30
            config.waitsForConnectivity = true
            config.requestCachePolicy = .returnCacheDataElseLoad
            
            let session = URLSession(configuration: config)
            let (data, response) = try await session.data(from: url)
            
            guard let httpResponse = response as? HTTPURLResponse,
                  httpResponse.statusCode == 200 else {
                throw URLError(.badServerResponse)
            }
            
            guard let image = UIImage(data: data) else {
                throw URLError(.cannotDecodeContentData)
            }
            
            // Cache the image
            await cacheImage(image, for: urlString)
            
            // Clean up loading task
            loadingTasks.removeValue(forKey: urlString)
            
            logger.debug("✅ Loaded and cached: \(urlString) (size: \(data.count) bytes)")
            return image
            
        } catch {
            logger.error("❌ Failed to load image: \(urlString), error: \(error.localizedDescription)")
            loadingTasks.removeValue(forKey: urlString)
            return nil
        }
    }
    
    private func cacheImage(_ image: UIImage, for urlString: String) async {
        // Store in memory cache
        memoryCache.setObject(image, forKey: urlString as NSString)
        
        // Store in disk cache
        await diskCache.storeImage(image, for: urlString)
    }
    
    // MARK: - Logger
    private let logger = Logger(subsystem: "com.viberanking.app", category: "ImageCache")
}

// MARK: - Disk Cache
private actor DiskCache {
    private let cacheDirectory: URL
    private let maxDiskCacheSize: Int = 100 * 1024 * 1024 // 100MB
    private let cacheExpirationInterval: TimeInterval = 7 * 24 * 60 * 60 // 7 days
    
    init() {
        let paths = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask)
        cacheDirectory = paths[0].appendingPathComponent("ImageCache")
        
        // Create cache directory if needed
        try? FileManager.default.createDirectory(at: cacheDirectory, withIntermediateDirectories: true)
    }
    
    func getImage(for urlString: String) async -> UIImage? {
        let fileURL = cacheDirectory.appendingPathComponent(urlString.sha256)
        
        guard let data = try? Data(contentsOf: fileURL),
              let image = UIImage(data: data) else {
            return nil
        }
        
        // Check if cache is expired
        if isCacheExpired(fileURL: fileURL) {
            try? FileManager.default.removeItem(at: fileURL)
            return nil
        }
        
        return image
    }
    
    func storeImage(_ image: UIImage, for urlString: String) async {
        guard let data = image.jpegData(compressionQuality: 0.8) else { return }
        
        let fileURL = cacheDirectory.appendingPathComponent(urlString.sha256)
        
        do {
            try data.write(to: fileURL)
            
            // Set creation date for expiration tracking
            try FileManager.default.setAttributes([
                .creationDate: Date()
            ], ofItemAtPath: fileURL.path)
            
        } catch {
            logger.error("Failed to store image to disk: \(error.localizedDescription)")
        }
    }
    
    func clearAll() async {
        do {
            let contents = try FileManager.default.contentsOfDirectory(at: cacheDirectory, includingPropertiesForKeys: nil)
            for fileURL in contents {
                try FileManager.default.removeItem(at: fileURL)
            }
        } catch {
            logger.error("Failed to clear disk cache: \(error.localizedDescription)")
        }
    }
    
    func cleanExpiredCache() async {
        do {
            let contents = try FileManager.default.contentsOfDirectory(
                at: cacheDirectory,
                includingPropertiesForKeys: [.creationDateKey]
            )
            
            let now = Date()
            for fileURL in contents {
                if let attributes = try? FileManager.default.attributesOfItem(atPath: fileURL.path),
                   let creationDate = attributes[.creationDate] as? Date,
                   now.timeIntervalSince(creationDate) > cacheExpirationInterval {
                    try? FileManager.default.removeItem(at: fileURL)
                }
            }
        } catch {
            logger.error("Failed to clean expired cache: \(error.localizedDescription)")
        }
    }
    
    private func isCacheExpired(fileURL: URL) -> Bool {
        guard let attributes = try? FileManager.default.attributesOfItem(atPath: fileURL.path),
              let creationDate = attributes[.creationDate] as? Date else {
            return true
        }
        
        return Date().timeIntervalSince(creationDate) > cacheExpirationInterval
    }
    
    private let logger = Logger(subsystem: "com.viberanking.app", category: "DiskCache")
}

// MARK: - String Extension for SHA256
extension String {
    var sha256: String {
        let data = Data(self.utf8)
        var hash = [UInt8](repeating: 0, count: Int(CC_SHA256_DIGEST_LENGTH))
        data.withUnsafeBytes { buffer in
            _ = CC_SHA256(buffer.baseAddress, CC_LONG(buffer.count), &hash)
        }
        return hash.map { String(format: "%02x", $0) }.joined()
    }
}

// MARK: - CommonCrypto Import
import CommonCrypto