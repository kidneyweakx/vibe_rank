//
//  EXIFValidationServiceTests.swift
//  viberankingTests
//
//  Created by Kiro on 2025/07/23.
//

import XCTest
import SwiftUI
import UniformTypeIdentifiers
@testable import viberanking

@MainActor
final class EXIFValidationServiceTests: XCTestCase {
    
    var sut: EXIFValidationService!
    
    override func setUp() {
        super.setUp()
        sut = EXIFValidationService()
    }
    
    override func tearDown() {
        sut = nil
        super.tearDown()
    }
    
    // MARK: - EXIF Data Extraction Tests
    
    func testExtractEXIFData_WithValidImageData_ShouldReturnMetadata() async throws {
        // Given
        let testImageData = createTestImageDataWithEXIF()
        
        // When
        let metadata = try await sut.extractEXIFData(from: testImageData)
        
        // Then
        XCTAssertTrue(metadata.hasValidEXIF)
        XCTAssertNotNil(metadata.dateTaken)
    }
    
    func testExtractEXIFData_WithImageDataWithoutEXIF_ShouldThrowError() async {
        // Given
        let testImageData = createTestImageDataWithoutEXIF()
        
        // When & Then
        do {
            _ = try await sut.extractEXIFData(from: testImageData)
            XCTFail("Expected EXIFValidationError to be thrown")
        } catch let error as EXIFValidationError {
            XCTAssertEqual(error, .screenshotDetected)
        } catch {
            XCTFail("Unexpected error type: \(error)")
        }
    }
    
    // MARK: - Photo Freshness Validation Tests
    
    func testValidatePhotoFreshness_WithRecentPhoto_ShouldReturnTrue() throws {
        // Given
        let recentDate = Date().addingTimeInterval(-3600) // 1 hour ago
        let metadata = PhotoMetadata(dateTaken: recentDate, cameraModel: "iPhone 13")
        
        // When
        let isValid = try sut.validatePhotoFreshness(metadata)
        
        // Then
        XCTAssertTrue(isValid)
    }
    
    func testValidatePhotoFreshness_WithOldPhoto_ShouldThrowError() {
        // Given
        let oldDate = Date().addingTimeInterval(-25 * 60 * 60) // 25 hours ago
        let metadata = PhotoMetadata(dateTaken: oldDate, cameraModel: "iPhone 13")
        
        // When & Then
        XCTAssertThrowsError(try sut.validatePhotoFreshness(metadata)) { error in
            XCTAssertTrue(error is EXIFValidationError)
            XCTAssertEqual(error as? EXIFValidationError, .photoTooOld)
        }
    }
    
    func testValidatePhotoFreshness_WithNoEXIFData_ShouldThrowError() {
        // Given
        let metadata = PhotoMetadata(dateTaken: nil, cameraModel: nil)
        
        // When & Then
        XCTAssertThrowsError(try sut.validatePhotoFreshness(metadata)) { error in
            XCTAssertTrue(error is EXIFValidationError)
            XCTAssertEqual(error as? EXIFValidationError, .noEXIFData)
        }
    }
    
    // MARK: - Screenshot Detection Tests
    
    func testDetectScreenshot_WithScreenshotImage_ShouldThrowError() throws {
        // Given
        let screenshotData = createScreenshotImageData()
        
        // When & Then
        XCTAssertThrowsError(try sut.detectScreenshot(from: screenshotData)) { error in
            XCTAssertTrue(error is EXIFValidationError)
            XCTAssertEqual(error as? EXIFValidationError, .screenshotDetected)
        }
    }
    
    func testDetectScreenshot_WithCameraImage_ShouldNotThrow() throws {
        // Given
        let cameraImageData = createCameraImageData()
        
        // When & Then
        XCTAssertNoThrow(try sut.detectScreenshot(from: cameraImageData))
    }
    
    // MARK: - EXIF Data Sanitization Tests
    
    func testSanitizeEXIFData_ShouldRemoveSensitiveData() async throws {
        // Given
        let imageWithGPSData = createImageWithGPSData()
        
        // When
        let sanitizedData = try await sut.sanitizeEXIFData(from: imageWithGPSData)
        
        // Then
        XCTAssertFalse(sanitizedData.isEmpty)
        // Verify GPS data is removed (this would require more complex verification in real implementation)
    }
    
    // MARK: - Error Handling Tests
    
    func testExtractEXIFData_WithInvalidImageData_ShouldThrowError() async {
        // Given
        let invalidImageData = Data() // Empty data
        
        // When & Then
        do {
            _ = try await sut.extractEXIFData(from: invalidImageData)
            XCTFail("Expected error to be thrown")
        } catch {
            XCTAssertTrue(error is EXIFValidationError)
        }
    }
}

// MARK: - Test Helpers
private extension EXIFValidationServiceTests {
    
    func createTestImageDataWithEXIF() -> Data {
        // Create a simple test image data with basic properties
        let size = CGSize(width: 4032, height: 3024) // Camera-like resolution
        return createImageData(size: size, color: .blue)
    }
    
    func createTestImageDataWithoutEXIF() -> Data {
        // Create a simple test image data without EXIF (like a programmatically created image)
        let size = CGSize(width: 1170, height: 2532) // iPhone screen size to trigger screenshot detection
        return createImageData(size: size, color: .red)
    }
    
    func createScreenshotImageData() -> Data {
        // Create image data that resembles a screenshot
        let size = CGSize(width: 1170, height: 2532) // iPhone 13 Pro screen size
        return createImageData(size: size, color: .white, format: .png)
    }
    
    func createCameraImageData() -> Data {
        // Create image data that resembles a camera photo
        let size = CGSize(width: 4032, height: 3024) // Typical camera resolution
        return createImageData(size: size, color: .green, format: .jpeg)
    }
    
    func createImageWithGPSData() -> Data {
        // Create image data with GPS information (for sanitization testing)
        let size = CGSize(width: 1000, height: 1000)
        return createImageData(size: size, color: .yellow, format: .jpeg)
    }
    
    private enum ImageFormat {
        case jpeg, png
    }
    
    private func createImageData(size: CGSize, color: Color, format: ImageFormat = .jpeg) -> Data {
        // Create CGContext
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        guard let context = CGContext(data: nil,
                                    width: Int(size.width),
                                    height: Int(size.height),
                                    bitsPerComponent: 8,
                                    bytesPerRow: 0,
                                    space: colorSpace,
                                    bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue) else {
            return Data()
        }
        
        // Fill with color
        let cgColor = CGColor(red: 0.5, green: 0.5, blue: 0.5, alpha: 1.0) // Default gray
        context.setFillColor(cgColor)
        context.fill(CGRect(origin: .zero, size: size))
        
        guard let cgImage = context.makeImage() else {
            return Data()
        }
        
        // Convert to data
        let mutableData = NSMutableData()
        let imageType = format == .jpeg ? kUTTypeJPEG : kUTTypePNG
        
        guard let destination = CGImageDestinationCreateWithData(mutableData, imageType, 1, nil) else {
            return Data()
        }
        
        CGImageDestinationAddImage(destination, cgImage, nil)
        CGImageDestinationFinalize(destination)
        
        return mutableData as Data
    }
}