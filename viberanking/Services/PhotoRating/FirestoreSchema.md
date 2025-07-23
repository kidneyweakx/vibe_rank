# Firestore Collection Structure for Photo Rating System

## Overview

This document defines the Firestore database schema for the photo rating system, including collections, documents, and their relationships.

## Collections Structure

### 1. Users Collection (`users`)

```
users/
  {userId}/
    - id: String (document ID)
    - name: String
    - email: String
    - profileImageURL: String?
    - gender: String?
    - createdAt: Timestamp
    - ratingProgress: Map {
        completedRatings: Number
        requiredRatings: Number (default: 20)
        hasUnlockedUpload: Boolean
      }
    - uploadedPhotos: Array<String> (photo IDs)

    // Subcollections
    preferences/ {
      current/
        - userId: String
        - stylePreferences: Map<String, Number>
        - totalRatingsGiven: Number
        - hotRatingsGiven: Number
        - lastUpdated: Timestamp
    }
```

### 2. Photos Collection (`photos`)

```
photos/
  {photoId}/
    - id: String (document ID)
    - userId: String (owner's user ID)
    - imageURL: String (Firebase Storage URL)
    - uploadedAt: Timestamp
    - dateTaken: Timestamp?
    - isVerifiedRecent: Boolean
    - averageScore: Number
    - totalRatings: Number
    - metadata: Map {
        dateTaken: Timestamp?
        cameraModel: String?
        isRecentPhoto: Boolean
        hasValidEXIF: Boolean
      }

    // Subcollections
    ratings/ {
      {ratingId}/
        - id: String (document ID)
        - photoId: String
        - raterId: String
        - isHot: Boolean
        - createdAt: Timestamp
    }
```

### 3. Ratings Collection (`ratings`)

```
ratings/
  {ratingId}/
    - id: String (document ID)
    - photoId: String
    - raterId: String
    - isHot: Boolean (true for "Hot", false for "Not")
    - createdAt: Timestamp
```

### 4. Upload Progress Collection (`uploadProgress`)

```
uploadProgress/
  {photoId}/
    - photoId: String (document ID)
    - currentRatings: Number
    - requiredRatings: Number (default: 50)
    - isReportUnlocked: Boolean
    - lastUpdated: Timestamp
```

## Indexes Required

### Composite Indexes

1. **Photos for Rating Query**

   - Collection: `photos`
   - Fields: `userId` (!=), `uploadedAt` (desc)
   - Used for: Fetching photos excluding current user

2. **Ratings by Photo**

   - Collection: `ratings`
   - Fields: `photoId` (==), `createdAt` (desc)
   - Used for: Getting all ratings for a specific photo

3. **Ratings by User**

   - Collection: `ratings`
   - Fields: `raterId` (==), `createdAt` (desc)
   - Used for: Getting all ratings given by a user

4. **Recent Photos**
   - Collection: `photos`
   - Fields: `isVerifiedRecent` (==), `uploadedAt` (desc)
   - Used for: Fetching only recent photos for rating

## Security Rules

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {

    // Users can read/write their own user document
    match /users/{userId} {
      allow read, write: if request.auth != null && request.auth.uid == userId;

      // User preferences subcollection
      match /preferences/{document=**} {
        allow read, write: if request.auth != null && request.auth.uid == userId;
      }
    }

    // Photos are readable by all authenticated users, writable by owner
    match /photos/{photoId} {
      allow read: if request.auth != null;
      allow write: if request.auth != null &&
                   (resource == null || request.auth.uid == resource.data.userId);

      // Ratings subcollection
      match /ratings/{ratingId} {
        allow read: if request.auth != null;
        allow create: if request.auth != null &&
                      request.auth.uid == request.resource.data.raterId;
        allow update, delete: if false; // Ratings cannot be modified once created
      }
    }

    // Ratings collection (global)
    match /ratings/{ratingId} {
      allow read: if request.auth != null;
      allow create: if request.auth != null &&
                    request.auth.uid == request.resource.data.raterId;
      allow update, delete: if false; // Ratings cannot be modified once created
    }

    // Upload progress is readable by all, writable by system
    match /uploadProgress/{photoId} {
      allow read: if request.auth != null;
      allow write: if request.auth != null; // Will be restricted to server-side updates
    }
  }
}
```

## Data Flow

### 1. Photo Rating Flow

1. User requests photos for rating → Query `photos` collection excluding their own
2. User submits rating → Create document in `ratings` collection
3. System updates photo statistics → Update `photos/{photoId}` document
4. System updates user progress → Update `users/{userId}/ratingProgress`

### 2. Upload Progress Tracking

1. Photo uploaded → Create `uploadProgress/{photoId}` document
2. Rating received → Update `uploadProgress/{photoId}/currentRatings`
3. Threshold reached → Update `uploadProgress/{photoId}/isReportUnlocked`

### 3. User Preferences Update

1. User submits ratings → Collect rating data
2. Analyze rated photos → Extract style preferences
3. Update preferences → Write to `users/{userId}/preferences/current`

## Performance Considerations

### Caching Strategy

- Cache frequently accessed photos for rating (5-minute TTL)
- Cache user's own ratings and progress (local storage)
- Preload next batch of photos while user is rating

### Batch Operations

- Submit multiple ratings in batches to reduce write operations
- Update photo statistics in batches using Cloud Functions

### Real-time Updates

- Listen to upload progress changes for real-time UI updates
- Use Firestore real-time listeners for rating count updates

## Migration Strategy

### Phase 1: Basic Structure

- Create collections with basic fields
- Implement simple CRUD operations
- Add basic security rules

### Phase 2: Optimization

- Add composite indexes
- Implement caching layer
- Add Cloud Functions for complex operations

### Phase 3: Advanced Features

- Add real-time listeners
- Implement batch operations
- Add analytics and monitoring
