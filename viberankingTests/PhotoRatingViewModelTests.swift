//
//  PhotoRatingViewModelTests.swift
//  viberankingTests
//
//  Created by Kiro on 2025/07/23.
//

import Testing
@testable import viberanking

@MainActor
struct PhotoRatingViewModelTests {
    
    var viewModel: PhotoRatingViewModel!
    var mockPhotoRatingService: MockPhotoRatingService!
    var mockUserRepository: MockUserRepository!
    
    init() {
        mockPhotoRatingService = MockPhotoRatingService()
        mockUserRepository = MockUserRepository()
        viewModel = PhotoRatingViewModel(
            photoRatingService: mockPhotoRatingService,
            userRepository: mockUserRepository
        )
    }
    
    @Test func loadPhotosForRating() async {
        // Given
        let userId = "test_user"
        let mockPhotos = [
            Photo(id: "1", userId: "other_user", imageURL: "https://example.com/1.jpg"),
            Photo(id: "2", userId: "other_user", imageURL: "https://example.com/2.jpg")
        ]
        mockPhotoRatingService.mockPhotos = mockPhotos
        
        // When
        await viewModel.loadPhotosForRating(userId: userId)
        
        // Then
        #expect(viewModel.photos.count == 2)
        #expect(viewModel.currentPhotoIndex == 0)
        #expect(!viewModel.isLoading)
    }
    
    @Test func submitRating() async {
        // Given
        let userId = "test_user"
        let mockPhotos = [
            Photo(id: "1", userId: "other_user", imageURL: "https://example.com/1.jpg")
        ]
        mockPhotoRatingService.mockPhotos = mockPhotos
        await viewModel.loadPhotosForRating(userId: userId)
        
        // When
        await viewModel.submitRating(isHot: true)
        
        // Then
        #expect(mockPhotoRatingService.submittedRatings.count == 1)
        #expect(mockPhotoRatingService.submittedRatings.first?.isHot == true)
        #expect(viewModel.ratingProgress.completedRatings == 1)
    }
    
    @Test func progressText() {
        // Given
        viewModel.ratingProgress = RatingProgress(completedRatings: 5, requiredRatings: 20)
        
        // When
        let progressText = viewModel.progressText
        
        // Then
        #expect(progressText == "還需評分 15 張照片解鎖上傳功能")
    }
    
    @Test func progressTextWhenUnlocked() {
        // Given
        viewModel.ratingProgress = RatingProgress(completedRatings: 20, requiredRatings: 20)
        
        // When
        let progressText = viewModel.progressText
        
        // Then
        #expect(progressText == "已解鎖上傳功能！")
    }
}

// MARK: - Mock Services
class MockPhotoRatingService: PhotoRatingServiceProtocol {
    var mockPhotos: [Photo] = []
    var submittedRatings: [Rating] = []
    var shouldThrowError = false
    
    func fetchPhotosForRating(excludingUser userId: String) async throws -> [Photo] {
        if shouldThrowError {
            throw AppError.networkError(URLError(.badServerResponse))
        }
        return mockPhotos.filter { $0.userId != userId }
    }
    
    func submitRating(_ rating: Rating) async throws {
        if shouldThrowError {
            throw AppError.ratingSubmissionFailed
        }
        submittedRatings.append(rating)
    }
    
    func updateUserPreferences(from ratings: [Rating]) async throws {
        if shouldThrowError {
            throw AppError.networkError(URLError(.badServerResponse))
        }
        // Mock implementation
    }
}

class MockUserRepository: UserRepositoryProtocol {
    var mockUser: User?
    var shouldThrowError = false
    
    func create(_ entity: User) async throws -> User {
        if shouldThrowError {
            throw AppError.networkError(URLError(.badServerResponse))
        }
        return entity
    }
    
    func read(id: String) async throws -> User? {
        if shouldThrowError {
            throw AppError.userNotFound
        }
        return mockUser
    }
    
    func update(_ entity: User) async throws -> User {
        if shouldThrowError {
            throw AppError.networkError(URLError(.badServerResponse))
        }
        mockUser = entity
        return entity
    }
    
    func delete(id: String) async throws {
        if shouldThrowError {
            throw AppError.networkError(URLError(.badServerResponse))
        }
        mockUser = nil
    }
    
    func list(limit: Int?, offset: Int?) async throws -> [User] {
        if shouldThrowError {
            throw AppError.networkError(URLError(.badServerResponse))
        }
        return mockUser != nil ? [mockUser!] : []
    }
    
    func getUser(by id: String) async throws -> User? {
        if shouldThrowError {
            throw AppError.userNotFound
        }
        return mockUser ?? User(id: id, name: "Test User", email: "test@example.com")
    }
    
    func findByEmail(_ email: String) async throws -> User? {
        if shouldThrowError {
            throw AppError.userNotFound
        }
        return mockUser
    }
    
    func updateRatingProgress(userId: String, progress: RatingProgress) async throws {
        if shouldThrowError {
            throw AppError.networkError(URLError(.badServerResponse))
        }
        // Mock implementation
    }
    
    func getUserPreferences(userId: String) async throws -> UserPreferences? {
        if shouldThrowError {
            throw AppError.networkError(URLError(.badServerResponse))
        }
        return nil
    }
    
    func updateUserPreferences(_ preferences: UserPreferences) async throws {
        if shouldThrowError {
            throw AppError.networkError(URLError(.badServerResponse))
        }
        // Mock implementation
    }
}