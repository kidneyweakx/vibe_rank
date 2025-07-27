//
//  PhotoUploadServiceTests.swift
//  viberankingTests
//
//  Created by Kiro on 2025/07/23.
//

import XCTest
@testable import viberanking

final class PhotoUploadServiceTests: XCTestCase {
    
    var photoUploadService: PhotoUploadService!
    var mockStorageService: MockR2StorageService!
    var testImageData: Data!
    
    override func setUpWithError() throws {
        mockStorageService = MockR2StorageService()
        photoUploadService = PhotoUploadService(storageService: mockStorageService)
        testImageData = createTestImageData()
    }
    
    override func tearDownWithError() throws {
        photoUploadService = nil
        mockStorageService = nil
        testImageData = nil
    }
    
    // MARK: - WebP Conversion Tests
    
    func testConvertToWebP() async throws {
        // Given
        let quality: Float = 0.8
        
        // When
        let convertedData = try await photoUploadService.convertToWebP(testImageData, quality: quality)
        
        // Then
        XCTAssertNotNil(convertedData)
        XCTAssertGreaterThan(convertedData.count, 0)
    }
    
    func testGenerateThumbnails() async throws {
        // When
        let photoSizes = try await photoUploadService.generateThumbnails(testImageData)
        
        // Then
        XCTAssertNotNil(photoSizes.thumbnail)
        XCTAssertNotNil(photoSizes.preview)
        XCTAssertNotNil(photoSizes.highRes)
        
        XCTAssertGreaterThan(photoSizes.thumbnail.count, 0)
        XCTAssertGreaterThan(photoSizes.preview.count, 0)
        XCTAssertGreaterThan(photoSizes.highRes.count, 0)
    }
    
    // MARK: - Upload Tests
    
    func testUploadPhoto() async throws {
        // Given
        let testImage = createTestUIImage()
        let userId = "test-user"
        
        // When
        let photo = try await photoUploadService.uploadPhoto(testImage, for: userId)
        
        // Then
        XCTAssertEqual(mockStorageService.uploadPhotoSizesCallCount, 1)
        XCTAssertEqual(photo.userId, userId)
        XCTAssertNotNil(photo.imageURL)
    }
    
    // MARK: - Performance Tests
    
    func testThumbnailGenerationPerformance() {
        let largeImageData = createLargeTestImageData()
        
        measure {
            let expectation = XCTestExpectation(description: "Thumbnail generation performance")
            
            Task {
                do {
                    _ = try await photoUploadService.generateThumbnails(largeImageData)
                    expectation.fulfill()
                } catch {
                    XCTFail("Thumbnail generation failed: \(error)")
                    expectation.fulfill()
                }
            }
            
            wait(for: [expectation], timeout: 10.0)
        }
    }
    
    func testWebPConversionPerformance() {
        let largeImageData = createLargeTestImageData()
        
        measure {
            let expectation = XCTestExpectation(description: "WebP conversion performance")
            
            Task {
                do {
                    _ = try await photoUploadService.convertToWebP(largeImageData, quality: 0.8)
                    expectation.fulfill()
                } catch {
                    XCTFail("WebP conversion failed: \(error)")
                    expectation.fulfill()
                }
            }
            
            wait(for: [expectation], timeout: 5.0)
        }
    }
}

// MARK: - Mock R2 Storage Service
class MockR2StorageService: R2StorageServiceProtocol {
    var uploadPhotoSizesCallCount = 0
    var deletePhotoCallCount = 0
    var getDownloadURLCallCount = 0
    var uploadSingleFileCallCount = 0
    
    var shouldThrowError = false
    
    func uploadPhotoSizes(_ photoSizes: PhotoSizes, photoId: String) async throws -> PhotoURLs {
        uploadPhotoSizesCallCount += 1
        if shouldThrowError {
            throw AppError.imageUploadFailed
        }
        let url = URL(string: "https://example.com/\(photoId).webp")!
        return PhotoURLs(thumbnail: url, preview: url, highRes: url)
    }
    
    func deletePhoto(photoId: String) async throws {
        deletePhotoCallCount += 1
        if shouldThrowError {
            throw AppError.imageUploadFailed
        }
    }
    
    func getDownloadURL(for path: String) async throws -> URL {
        getDownloadURLCallCount += 1
        if shouldThrowError {
            throw AppError.invalidURL
        }
        return URL(string: "https://example.com/\(path)")!
    }
    
    func uploadSingleFile(_ data: Data, to path: String) async throws -> URL {
        uploadSingleFileCallCount += 1
        if shouldThrowError {
            throw AppError.imageUploadFailed
        }
        return URL(string: "https://example.com/\(path)")!
    }
}

// MARK: - Test Helpers
private extension PhotoUploadServiceTests {
    
    func createTestImageData() -> Data {
        let size = CGSize(width: 100, height: 100)
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        
        guard let context = CGContext(
            data: nil,
            width: Int(size.width),
            height: Int(size.height),
            bitsPerComponent: 8,
            bytesPerRow: 0,
            space: colorSpace,
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        ) else {
            return Data()
        }
        
        context.setFillColor(red: 0.5, green: 0.7, blue: 0.9, alpha: 1.0)
        context.fill(CGRect(origin: .zero, size: size))
        
        guard let cgImage = context.makeImage() else {
            return Data()
        }
        
        let mutableData = NSMutableData()
        guard let destination = CGImageDestinationCreateWithData(
            mutableData,
            "public.jpeg" as CFString,
            1,
            nil
        ) else {
            return Data()
        }
        
        CGImageDestinationAddImage(destination, cgImage, nil)
        CGImageDestinationFinalize(destination)
        
        return mutableData as Data
    }
    
    func createLargeTestImageData() -> Data {
        let size = CGSize(width: 800, height: 600)
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        
        guard let context = CGContext(
            data: nil,
            width: Int(size.width),
            height: Int(size.height),
            bitsPerComponent: 8,
            bytesPerRow: 0,
            space: colorSpace,
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        ) else {
            return Data()
        }
        
        // Create a gradient pattern
        let colors = [CGColor(red: 1, green: 0, blue: 0, alpha: 1),
                     CGColor(red: 0, green: 1, blue: 0, alpha: 1),
                     CGColor(red: 0, green: 0, blue: 1, alpha: 1)]
        
        guard let gradient = CGGradient(colorsSpace: colorSpace, colors: colors as CFArray, locations: nil) else {
            return Data()
        }
        
        context.drawLinearGradient(gradient,
                                 start: CGPoint.zero,
                                 end: CGPoint(x: size.width, y: size.height),
                                 options: [])
        
        guard let cgImage = context.makeImage() else {
            return Data()
        }
        
        let mutableData = NSMutableData()
        guard let destination = CGImageDestinationCreateWithData(
            mutableData,
            "public.jpeg" as CFString,
            1,
            nil
        ) else {
            return Data()
        }
        
        CGImageDestinationAddImage(destination, cgImage, nil)
        CGImageDestinationFinalize(destination)
        
        return mutableData as Data
    }
    
    func createTestUIImage() -> UIImage {
        let size = CGSize(width: 200, height: 200)
        let renderer = UIGraphicsImageRenderer(size: size)
        
        return renderer.image { context in
            UIColor.systemBlue.setFill()
            context.fill(CGRect(origin: .zero, size: size))
            
            UIColor.white.setFill()
            let rect = CGRect(x: 50, y: 50, width: 100, height: 100)
            context.fill(rect)
        }
    }
}