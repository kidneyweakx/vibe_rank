# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

**Vibe Ranking** (VibeRanking / Vibe Rank) is an iOS social rating platform built with SwiftUI where users can upload photos and receive ratings from other users. The app features a TikTok-inspired swipe interface, gamification elements, journey tracking, and profile management.

### Key Features
- **Photo Rating System**: Hot/Not binary rating with swipe gestures
- **Gamification**: Unlock upload feature after 20 ratings, unlock style reports after 50 ratings
- **Journey Tab**: Track user statistics, rankings, achievements, and trends
- **Profile Management**: User profiles with photos, stats, and shareable links
- **Photo Upload**: WebP conversion with presigned URL uploads to Cloudflare R2
- **Events**: Display community events on home feed
- **Authentication**: Google Sign-In and Apple Sign In with Sign in with Apple
- **Localization**: Supports English (en), Traditional Chinese (zh-Hant), and Japanese (ja)

## Development Commands

### Build and Run
```bash
# Open in Xcode
open viberanking.xcodeproj

# Build scheme configurations:
# - Debug: Development environment
# - Staging: Staging environment (defined by STAGING preprocessor flag)
# - Release: Production environment
```

### Testing
```bash
# Run tests via Xcode:
# Cmd+U to run all tests

# Test targets:
# - viberankingTests: Unit tests
# - viberankingUITests: UI tests
```

## Architecture

### MVVM Pattern
- **Models/**: Core data models (User, Photo, Rating, etc.)
- **Views/**: SwiftUI views organized by feature
  - Each major feature has its own folder (HomeViews/, VibeViews/, JourneyViews/, ProfileViews/, etc.)
  - ViewModels are co-located within view folders (e.g., `Views/PhotoUploadViews/PhotoUploadViewModel/`)
- **Services/**: Business logic and external integrations
  - API clients, authentication, storage, analytics
- **Repositories/**: Data access layer (currently using API clients directly)
- **Utils/**: Helper utilities and extensions

### State Management
- Uses `@Published` properties with Combine for reactive updates
- `ObservableObject` view models for each major feature
- Shared services as singletons (`@MainActor` for UI-bound services)

### Navigation
- Tab-based navigation with `CustomTikTokTabBar`
- Five main tabs: Home, Journey, Upload (center), Vibe (rating), Profile
- Conditional navigation based on authentication state and onboarding completion

## API Service Architecture

All services use the centralized `APIClient` for HTTP requests. The backend base URL is configured in `AppConfiguration.swift` → `AppEnvironment.baseURL`.

### API Mapping

| Service | API Files | Endpoints Used |
|---------|-----------|----------------|
| **AuthenticationService** | `AuthAPI.swift` | `POST /api/auth/google` (Google Sign-In)<br>`POST /api/auth/apple/verify` (Apple Sign In)<br>`POST /api/auth/password/verify` (Password credential)<br>`POST /api/auth/profile/create` (Create profile)<br>`POST /api/onboarding/complete` (Complete onboarding)<br>`POST /api/auth/signout` (Sign out) |
| **UserProfileService** | `UserAPI.swift` | `GET /api/user/profile/{userId}` (Get profile)<br>`PUT /api/user/profile/{userId}` (Update profile)<br>`GET /api/user/info/{userId}` (Public info)<br>`GET /api/user/share/{userId}` (Share link)<br>`GET /api/user/qr/{userId}` (QR code)<br>`GET /api/user/id/check?desiredId={id}` (Check ID availability)<br>`PUT /api/user/id/{userId}` (Update user ID)<br>`POST /api/user/profilePicture` (Upload profile picture)<br>`DELETE /api/user/delete` (Delete account) |
| **PhotoRatingViewModel** | `RateAPI.swift` | `POST /api/rate/photo` (Submit rating)<br>`GET /api/rate/photos/random?userId={id}&limit={n}` (Get photos to rate)<br>`GET /api/info/journeyInfo/{userId}` (Get journey stats) |
| **PhotoUploadService** | `FileAPI.swift`<br>`PresignedUploadAPI.swift` | `POST /api/file/presign` (Request presigned URL)<br>`PUT {presignedURL}` (Upload to R2)<br>`POST /api/file/photos/complete` (Finalize upload)<br>`POST /api/file/photos/upload` (Fallback base64 upload)<br>`GET /api/file/photos/user/{userId}` (List user photos)<br>`DELETE /api/file/photos/{photoId}` (Delete photo)<br>`POST /api/file/report` (Report photo) |
| **HomeView** | `HomeInfoAPI.swift`<br>`EventAPI.swift` | `GET /api/info/homeInfo` (Get home feed data)<br>`GET /api/event/list` (Get events) |
| **ProfileView** | `ProfileInfoAPI.swift` | `GET /api/info/profileInfo/{userId}?photoLimit={n}` (Get profile info with photos) |
| **TagsService** | `TagsAPI.swift` | `GET /api/tags/` (Get all tags)<br>`POST /api/tags/` (Create tag)<br>`GET /api/tags/photos/{photoId}` (Get photo tags)<br>`POST /api/tags/photos/{photoId}` (Attach tags)<br>`GET /api/tags/search?tagIds={ids}` (Search by tags) |

### API Response Patterns
- Most endpoints return `{ success: bool, data: T }` wrapper
- Date format: ISO 8601 with milliseconds (`yyyy-MM-dd'T'HH:mm:ss.SSS'Z'`)
- Authentication: `X-Access-Token` header with static token (from `APIClient.accessToken`)
- Error handling: HTTP status codes mapped to `APIError` enum with localized messages

## Key Configuration

### AppConfiguration.swift
Central configuration for:
- **Rating System**: Required ratings thresholds (20 for upload, 50 for reports)
- **Photo Settings**: Max file size (10MB), WebP quality levels, max age (24 hours)
- **Performance**: Timeouts, retry attempts, memory limits
- **R2 Storage**: Cloudflare R2 configuration loaded from `Storage-Info.plist`
- **Environment**: Base URLs for dev/staging/production

### Environment Variables
- `AppEnvironment.current`: Auto-detected based on build configuration
  - `.development` for DEBUG builds
  - `.staging` for STAGING builds
  - `.production` for release builds

## Image Processing

### WebP Conversion
- **All photos MUST be converted to WebP format before upload**
- Uses `SDWebImageWebPCoder` framework via `WebPConverter.shared`
- Adaptive quality compression: starts at 0.8, reduces to 0.4 if size exceeds limits
- Max dimension: 1200px (configurable via `AppConfiguration.Photo.highResSize`)
- Size limit accounts for base64 encoding overhead (72% of 10MB = ~7.2MB binary)

### Metadata Extraction
- **Photo capture time (EXIF takenAt) is extracted from images before upload**
- Uses `ImageMetadataExtractor` utility to extract EXIF DateTimeOriginal
- Supports extraction from UIImage, Data, and PHAsset
- If no EXIF date is available, backend uses upload time as fallback
- Photos are sorted by takenAt (with uploadedAt fallback) in ProfileView for chronological ordering

### Upload Flow
1. Extract EXIF capture date from image (if available)
2. Image → PNG data → WebP conversion with quality adjustment
3. Request presigned URL from backend (`/api/file/presign`)
4. PUT binary data directly to R2 storage
5. Finalize upload with backend (`/api/file/photos/complete`) including optional takenAt timestamp
6. Fallback to base64 JSON upload if presigned flow fails

## Dependencies (SPM)

- **GoogleSignIn**: Google authentication (~9.0.0)
- **Kingfisher**: Image loading and caching (~8.5.0)
- **SDWebImageWebPCoder**: WebP format support (~0.14.6)
- **Firebase iOS SDK**: Analytics and potential future features (~12.0.0)

## Common Development Patterns

### Adding a New API Endpoint

1. Add endpoint definition to appropriate API file in `Services/API/`
2. Define response models as `Codable` structs
3. Use `APIClient.performRequest()` for typed responses
4. Handle errors with `AppError` enum
5. Update this CLAUDE.md file with the new endpoint mapping

### Creating a New View

1. Create view file in appropriate `Views/` subfolder
2. Create accompanying ViewModel if needed (place in same folder structure)
3. Use `BaseViewModel` as base class for common patterns
4. Inject dependencies through initializer
5. Use `@Published` for reactive state
6. Keep files under 500 lines

### Working with User State

- `AuthenticationService.currentUser`: Authentication state
- `UserProfileService.currentUser`: Full user profile with progress
- Check `userProfileService.hasUnlockedUpload` before showing upload UI
- Check `userProfileService.remainingRatingsForUpload` for progress display

### Analytics Integration

- Use `AnalyticsService` for event tracking
- Screen tracking via `ScreenTrackingModifier`
- Session tracking via `SessionTracker`
- Respects user's App Tracking Transparency permission

## Important Constraints

- Keep all Swift files under 500 lines
- Always use async/await for asynchronous operations
- Implement comprehensive error handling with `AppError`
- Follow MVVM pattern strictly
- Co-locate ViewModels with their Views
- Use `@MainActor` for UI-bound services
- All API responses should be validated before use

## Debugging Backend APIs

When identifying redundant backend APIs for cleanup:

1. Search codebase for API endpoint strings (e.g., `"/api/rate/photo"`)
2. Check service layer (`Services/API/*.swift`) for endpoint definitions
3. Verify usage in service consumers (search for API class usage)
4. This CLAUDE.md provides comprehensive endpoint mapping for reference
5. Any endpoint not listed in the "API Mapping" section above is potentially unused by the iOS client

## Localization

- Localization files: `viberanking/Localizations/*.lproj/`
- Supported languages: English (en), Traditional Chinese (zh-Hant), Japanese (ja)
- Use `LocalizationManager` for runtime language switching
- All user-facing strings should be localized

## Build Configurations

- **Debug**: Development environment, detailed logging enabled
- **Staging**: Pre-production testing, same backend as production
- **Release**: Production environment, analytics enabled

Current backend for all environments: `https://vibe-backend2.kidneyweakx.workers.dev`
