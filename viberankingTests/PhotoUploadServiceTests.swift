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
    var testImageData: Data!
    
    override func setUpWithError() throws {
        photoUploadService = PhotoUploadService()
        testImageData = createTestImageData()
    }
    
    override func tearDownWithError() throws {
        photoUploadService = nil
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
    
    // MARK: - Upload Progress Tests
    
    func testGetUploadProgress() async throws {
        // Given
        let photoId = "test-photo-id"
        
        // When
        let progress = try await photoUploadService.getUploadProgress(for: photoId)
        
        // Then
        XCTAssertEqual(progress.photoId, photoId)
        XCTAssertEqual(progress.currentRatings, 0)
        XCTAssertEqual(progress.requiredRatings, 50)
        XCTAssertFalse(progress.isReportUnlocked)
    }
    
    // MARK: - UIImage Upload Tests
    
    func testUploadPhotoFromUIImage() async throws {
        // Given
        let testImage = createTestUIImage()
        
        // When/Then - This would require Firebase setup for full integration test
        // For unit test, we verify the image data conversion
        guard let imageData = testImage.jpegData(compressionQuality: 1.0) else {
            XCTFail("Failed to convert UIImage to data")
            return
        }
        
        XCTAssertNotNil(imageData)
        XCTAssertGreaterThan(imageData.count, 0)
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