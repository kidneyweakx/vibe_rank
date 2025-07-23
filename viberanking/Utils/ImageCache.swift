//
//  ImageCache.swift
//  viberanking
//
//  Created by Kiro on 2025/07/23.
//

import SwiftUI
import Combine

#if canImport(UIKit)
import UIKit
typealias PlatformImage = UIImage
#elseif canImport(AppKit)
import AppKit
typealias PlatformImage = NSImage
#endif

// MARK: - Image Cache Manager
@MainActor
class ImageCache: ObservableObject {
    static let shared = ImageCache()
    
    private let cache = NSCache<NSString, PlatformImage>()
    private let urlSession = URLSession.shared
    private var loadingTasks: [String: Task<PlatformImage?, Error>] = [:]
    
    // Cache configuration
    private let maxCacheSize = 100 * 1024 * 1024 // 100MB
    private let maxCacheCount = 200
    
    private init() {
        setupCache()
    }
    
    private func setupCache() {
        cache.totalCostLimit = maxCacheSize
        cache.countLimit = maxCacheCount
    }
    
    // MARK: - Public Methods
    
    /// Get image from cache or load from URL
    func image(for url: String) async -> PlatformImage? {
        let key = NSString(string: url)
        
        // Check cache first
        if let cachedImage = cache.object(forKey: key) {
            return cachedImage
        }
        
        // Check if already loading
        if let existingTask = loadingTasks[url] {
            return try? await existingTask.value
        }
        
        // Start loading
        let task = Task<PlatformImage?, Error> {
            try await loadImage(from: url)
        }
        
        loadingTasks[url] = task
        
        do {
            let image = try await task.value
            loadingTasks.removeValue(forKey: url)
            return image
        } catch {
            loadingTasks.removeValue(forKey: url)
            return nil
        }
    }
    
    /// Preload images for better performance
    func preloadImages(urls: [String]) {
        for url in urls {
            Task {
                _ = await image(for: url)
            }
        }
    }
    
    /// Clear cache
    func clearCache() {
        cache.removeAllObjects()
        loadingTasks.removeAll()
    }
    
    /// Get cache statistics
    var cacheInfo: (count: Int, size: String) {
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useMB, .useKB]
        formatter.countStyle = .file
        
        // Estimate size (NSCache doesn't provide exact size)
        let estimatedSize = cache.totalCostLimit / 10 // Rough estimate
        let sizeString = formatter.string(fromByteCount: Int64(estimatedSize))
        
        return (count: cache.countLimit, size: sizeString)
    }
}

// MARK: - Private Methods
private extension ImageCache {
    
    func loadImage(from urlString: String) async throws -> PlatformImage? {
        guard let url = URL(string: urlString) else {
            throw URLError(.badURL)
        }
        
        let (data, response) = try await urlSession.data(from: url)
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw URLError(.badServerResponse)
        }
        
        #if canImport(UIKit)
        guard let image = UIImage(data: data) else {
            throw URLError(.cannotDecodeContentData)
        }
        #elseif canImport(AppKit)
        guard let image = NSImage(data: data) else {
            throw URLError(.cannotDecodeContentData)
        }
        #endif
        
        // Cache the image
        let key = NSString(string: urlString)
        let cost = data.count
        cache.setObject(image, forKey: key, cost: cost)
        
        return image
    }
}

// MARK: - Cached Async Image View
struct CachedAsyncImage<Content: View, Placeholder: View>: View {
    private let url: String
    private let content: (Image) -> Content
    private let placeholder: () -> Placeholder
    
    @State private var image: PlatformImage?
    @State private var isLoading = true
    
    init(
        url: String,
        @ViewBuilder content: @escaping (Image) -> Content,
        @ViewBuilder placeholder: @escaping () -> Placeholder
    ) {
        self.url = url
        self.content = content
        self.placeholder = placeholder
    }
    
    var body: some View {
        Group {
            if let image = image {
                #if canImport(UIKit)
                content(Image(uiImage: image))
                #elseif canImport(AppKit)
                content(Image(nsImage: image))
                #endif
            } else {
                placeholder()
                    .task {
                        await loadImage()
                    }
            }
        }
    }
    
    private func loadImage() async {
        let loadedImage = await ImageCache.shared.image(for: url)
        await MainActor.run {
            self.image = loadedImage
            self.isLoading = false
        }
    }
}

// MARK: - Convenience Initializers
extension CachedAsyncImage where Content == Image, Placeholder == ProgressView<EmptyView, EmptyView> {
    init(url: String) {
        self.init(
            url: url,
            content: { $0 },
            placeholder: { ProgressView() }
        )
    }
}

extension CachedAsyncImage where Placeholder == ProgressView<EmptyView, EmptyView> {
    init(
        url: String,
        @ViewBuilder content: @escaping (Image) -> Content
    ) {
        self.init(
            url: url,
            content: content,
            placeholder: { ProgressView() }
        )
    }
}

// MARK: - Image Preloader Component
struct ImagePreloader: View {
    let urls: [String]
    
    var body: some View {
        EmptyView()
            .onAppear {
                ImageCache.shared.preloadImages(urls: urls)
            }
    }
}
