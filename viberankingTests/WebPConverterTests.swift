//
//  WebPConverterTests.swift
//  viberankingTests
//
//  Created by Kiro on 2025/07/23.
//

import XCTest
@testable import viberanking

final class WebPConverterTests: XCTestCase {
    
    var webpConverter: WebPConverter!
    var testImageData: Data!
    
    override func setUpWithError() throws {
        webpConverter = WebPConverter.shared
        
        // Create a test image data (1x1 pixel JPEG)
        testImageData = createTestImageData()
    }
    
    override func tearDownWithError() throws {
        webpConverter = nil
        testImageData = nil
    }
    
    // MARK: - WebP Conversion Tests
    
    func testConvertToWebP() async throws {
        // Given
        let quality: Float = 0.8
        
        // When
        let convertedData = try await webpConverter.convertToWebP(testImageData, quality: quality)
        
        // Then
        XCTAssertNotNil(convertedData)
        XCTAssertGreaterThan(convertedData.count, 0)
        XCTAssertLessThanOrEqual(convertedData.count, testImageData.count) // Should be compressed
    }
    
    func testConvertToWebPWithDifferentQualities() async throws {
        // Given
        let lowQuality: Float = 0.3
        let highQuality: Float = 0.9
        
        // When
        let lowQualityData = try await webpConverter.convertToWebP(testImageData, quality: lowQuality)
        let highQualityData = try await webpConverter.convertToWebP(testImageData, quality: highQuality)
        
        // Then
        XCTAssertNotNil(lowQualityData)
        XCTAssertNotNil(highQualityData)
        XCTAssertLessThanOrEqual(lowQualityData.count, highQualityData.count) // Lower quality should be smaller
    }
    
    // MARK: - Thumbnail Generation Tests
    
    func testGenerateThumbnails() async throws {
        // When
        let photoSizes = try await webpConverter.generateThumbnails(testImageData)
        
        // Then
        XCTAssertNotNil(photoSizes.thumbnail)
        XCTAssertNotNil(photoSizes.preview)
        XCTAssertNotNil(photoSizes.highRes)
        
        XCTAssertGreaterThan(photoSizes.thumbnail.count, 0)
        XCTAssertGreaterThan(photoSizes.preview.count, 0)
        XCTAssertGreaterThan(photoSizes.highRes.count, 0)
        
        // Thumbnail should be smallest, high-res should be largest
        XCTAssertLessThanOrEqual(photoSizes.thumbnail.count, photoSizes.preview.count)
        XCTAssertLessThanOrEqual(photoSizes.preview.count, photoSizes.highRes.count)
    }
    
    func testGenerateThumbnailsWithLargeImage() async throws {
        // Given
        let largeImageData = createLargeTestImageData()
        
        // When
        let photoSizes = try await webpConverter.generateThumbnails(largeImageData)
        
        // Then
        XCTAssertNotNil(photoSizes.thumbnail)
        XCTAssertNotNil(photoSizes.preview)
        XCTAssertNotNil(photoSizes.highRes)
        
        // All sizes should be significantly smaller than original
        XCTAssertLessThan(photoSizes.thumbnail.count, largeImageData.count)
        XCTAssertLessThan(photoSizes.preview.count, largeImageData.count)
        XCTAssertLessThan(photoSizes.highRes.count, largeImageData.count)
    }
    
    // MARK: - Image Resizing Tests
    
    func testResizeImageData() async throws {
        // Given
        let targetWidth = 300
        let targetHeight = 300
        
        // When
        let resizedData = try await webpConverter.resizeImageData(testImageData, targetWidth: targetWidth, targetHeight: targetHeight)
        
        // Then
        XCTAssertNotNil(resizedData)
        XCTAssertGreaterThan(resizedData.count, 0)
    }
    
    func testResizeImageDataMaintainsAspectRatio() async throws {
        // Given
        let rectangularImageData = createRectangularTestImageData()
        let targetWidth = 200
        let targetHeight = 200
        
        // When
        let resizedData = try await webpConverter.resizeImageData(rectangularImageData, targetWidth: targetWidth, targetHeight: targetHeight)
        
        // Then
        XCTAssertNotNil(resizedData)
        XCTAssertGreaterThan(resizedData.count, 0)
        
        // Verify the image can be loaded (basic validation)
        let source = CGImageSourceCreateWithData(resizedData as CFData, nil)
        XCTAssertNotNil(source)
    }
    
    // MARK: - Error Handling Tests
    
    func testConvertToWebPWithInvalidData() async {
        // Given
        let invalidData = Data([0x00, 0x01, 0x02, 0x03]) // Invalid image data
        
        // When/Then
        do {
            _ = try await webpConverter.convertToWebP(invalidData, quality: 0.8)
            XCTFail("Should have thrown an error for invalid image data")
        } catch {
            XCTAssertTrue(error is AppError)
        }
    }
    
    func testGenerateThumbnailsWithInvalidData() async {
        // Given
        let invalidData = Data([0x00, 0x01, 0x02, 0x03]) // Invalid image data
        
        // When/Then
        do {
            _ = try await webpConverter.generateThumbnails(invalidData)
            XCTFail("Should have thrown an error for invalid image data")
        } catch {
            XCTAssertTrue(error is AppError)
        }
    }
    
    // MARK: - Performance Tests
    
    func testWebPConversionPerformance() {
        let largeImageData = createLargeTestImageData()
        
        measure {
            let expectation = XCTestExpectation(description: "WebP conversion")
            
            Task {
                do {
                    _ = try await webpConverter.convertToWebP(largeImageData, quality: 0.8)
                    expectation.fulfill()
                } catch {
                    XCTFail("WebP conversion failed: \(error)")
                    expectation.fulfill()
                }
            }
            
            wait(for: [expectation], timeout: 5.0)
        }
    }
    
    func testThumbnailGenerationPerformance() {
        let largeImageData = createLargeTestImageData()
        
        measure {
            let expectation = XCTestExpectation(description: "Thumbnail generation")
            
            Task {
                do {
                    _ = try await webpConverter.generateThumbnails(largeImageData)
                    expectation.fulfill()
                } catch {
                    XCTFail("Thumbnail generation failed: \(error)")
                    expectation.fulfill()
                }
            }
            
            wait(for: [expectation], timeout: 10.0)
        }
    }
}

// MARK: - Test Helpers
private extension WebPConverterTests {
    
    func createTestImageData() -> Data {
        // Create a simple 100x100 JPEG image
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
        
        // Fill with a gradient
        context.setFillColor(red: 1.0, green: 0.5, blue: 0.0, alpha: 1.0)
        context.fill(CGRect(origin: .zero, size: size))
        
        guard let cgImage = context.makeImage() else {
            return Data()
        }
        
        // Convert to JPEG data
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
        // Create a larger 1000x1000 JPEG image for performance testing
        let size = CGSize(width: 1000, height: 1000)
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
        
        // Create a more complex pattern
        for x in 0..<Int(size.width) {
            for y in 0..<Int(size.height) {
                let red = CGFloat(x) / size.width
                let green = CGFloat(y) / size.height
                let blue = CGFloat((x + y) % 255) / 255.0
                
                context.setFillColor(red: red, green: green, blue: blue, alpha: 1.0)
                context.fill(CGRect(x: x, y: y, width: 1, height: 1))
            }
        }
        
        guard let cgImage = context.makeImage() else {
            return Data()
        }
        
        // Convert to JPEG data
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
    
    func createRectangularTestImageData() -> Data {
        // Create a 200x100 rectangular JPEG image
        let size = CGSize(width: 200, height: 100)
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
        
        // Fill with blue color
        context.setFillColor(red: 0.0, green: 0.5, blue: 1.0, alpha: 1.0)
        context.fill(CGRect(origin: .zero, size: size))
        
        guard let cgImage = context.makeImage() else {
            return Data()
        }
        
        // Convert to JPEG data
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
}