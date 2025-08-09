//
//  AppConfiguration.swift
//  viberanking
//
//  Created by Kiro on 2025/07/23.
//

import Foundation

// MARK: - Application Configuration Constants
struct AppConfiguration {
    
    // MARK: - Rating System Constants
    struct Rating {
        static let requiredRatingsToUnlockUpload = 20
        static let requiredRatingsToUnlockReport = 50
        static let acceleratedRatingThreshold = 10
        static let maxPhotosPerBatch = 10
        static let preloadImageCount = 3
    }
    
    // MARK: - Photo Upload Constants
    struct Photo {
        static let maxPhotoAgeHours = 24
        static let maxFileSizeMB = 10
        static let thumbnailSize = 150
        static let previewSize = 800
        static let highResSize = 1200
        static let webpQualityThumbnail: Float = 0.6
        static let webpQualityPreview: Float = 0.8
        static let webpQualityHighRes: Float = 0.9
    }
    
    // MARK: - Performance Constants
    struct Performance {
        static let maxMemoryUsageMB = 150
        static let targetFPS = 60
        static let maxAppStartupTimeSeconds = 2.0
        static let imageLoadTimeoutSeconds = 10.0
        static let networkTimeoutSeconds = 30.0
        static let maxRetryAttempts = 3
    }
    
    // MARK: - UI Constants
    struct UI {
        static let animationDuration = 0.3
        static let hapticFeedbackEnabled = true
        static let progressBarHeight: CGFloat = 4.0
        static let cornerRadius: CGFloat = 12.0
        static let shadowRadius: CGFloat = 8.0
    }
    
    // MARK: - R2 Configuration
    struct R2 {
        private static let r2Config: [String: Any] = {
            guard let path = Bundle.main.path(forResource: "Storage-Info", ofType: "plist"),
                  let dict = NSDictionary(contentsOfFile: path) as? [String: Any],
                  let r2Dict = dict["R2"] as? [String: Any] else {
                fatalError("R2 configuration not found in Info.plist")
            }
            return r2Dict
        }()

        static let accountId: String = {
            guard let accountId = r2Config["AccountId"] as? String else {
                fatalError("R2 AccountId not found in Info.plist")
            }
            return accountId
        }()

        static let bucketName: String = {
            guard let bucketName = r2Config["BucketName"] as? String else {
                fatalError("R2 BucketName not found in Info.plist")
            }
            return bucketName
        }()

        static let accessKey: String = {
            guard let accessKey = r2Config["AccessKey"] as? String else {
                fatalError("R2 AccessKey not found in Info.plist")
            }
            return accessKey
        }()

        static let secretKey: String = {
            guard let secretKey = r2Config["SecretKey"] as? String else {
                fatalError("R2 SecretKey not found in Info.plist")
            }
            return secretKey
        }()

        static let publicDomain: String = {
            guard let publicDomain = r2Config["PublicDomain"] as? String else {
                fatalError("R2 PublicDomain not found in Info.plist")
            }
            return publicDomain
        }()
    }
    
    // MARK: - Gamification Constants
    struct Gamification {
        static let shareRewardThreshold = 5
        static let evolutionAnalysisMinPhotos = 3
        static let achievementCategories = [
            "first_rating", "rating_milestone", "upload_milestone",
            "style_evolution", "social_sharing", "consistency"
        ]
    }
    
    // MARK: - Development/Debug Settings
    struct Debug {
        static let enableDetailedLogging = true
        static let enablePerformanceMonitoring = true
        static let enableCrashReporting = true
        static let mockDataEnabled = false
    }
}

// MARK: - App Version and Build Info
struct AppInfo {
    static let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0"
    static let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
    static let bundleIdentifier = Bundle.main.bundleIdentifier ?? "com.yourcompany.viberanking"
    
    static var fullVersionString: String {
        return "\(version) (\(build))"
    }
}

// MARK: - Environment Configuration
enum AppEnvironment {
    case development
    case staging
    case production
    
    static var current: AppEnvironment {
        #if DEBUG
        return .development
        #elseif STAGING
        return .staging
        #else
        return .production
        #endif
    }
    
    var baseURL: String {
        switch self {
        case .development:
            return "http://localhost:8181"
        case .staging:
            return "https://vibe-backend.kidneyweakx.workers.devm"
        case .production:
            return "https://vibe-backend.kidneyweakx.workers.dev"
        }
    }
    
    var enableAnalytics: Bool {
        switch self {
        case .development:
            return false
        case .staging, .production:
            return true
        }
    }
}
