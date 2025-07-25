import XCTest
import Combine
@testable import viberanking

class StyleReportViewModelTests: XCTestCase {

    var viewModel: StyleReportViewModel!
    var mockStyleAnalysisService: MockStyleAnalysisService!
    private var cancellables: Set<AnyCancellable>!

    override func setUpWithError() throws {
        try super.setUpWithError()
        mockStyleAnalysisService = MockStyleAnalysisService()
        viewModel = StyleReportViewModel(styleAnalysisService: mockStyleAnalysisService)
        cancellables = []
    }

    override func tearDownWithError() throws {
        viewModel = nil
        mockStyleAnalysisService = nil
        cancellables = nil
        try super.tearDownWithError()
    }

    func testFetchStyleReportSuccess() {
        // Given
        let userId = "testUser"
        let expectation = XCTestExpectation(description: "Fetch style report successfully")

        // When
        viewModel.fetchStyleReport(for: userId)

        // Then
        viewModel.$styleReport
            .dropFirst()
            .sink { report in
                XCTAssertNotNil(report)
                XCTAssertEqual(report?.userId, userId)
                expectation.fulfill()
            }
            .store(in: &cancellables)

        wait(for: [expectation], timeout: 1.0)
    }

    func testFetchStyleReportFailure() {
        // Given
        let userId = "testUser"
        let expectation = XCTestExpectation(description: "Fetch style report with failure")
        mockStyleAnalysisService.shouldReturnError = true

        // When
        viewModel.fetchStyleReport(for: userId)

        // Then
        viewModel.$errorMessage
            .dropFirst()
            .sink { errorMessage in
                XCTAssertNotNil(errorMessage)
                expectation.fulfill()
            }
            .store(in: &cancellables)
        
        wait(for: [expectation], timeout: 1.0)
    }
}

class MockStyleAnalysisService: StyleAnalysisServiceProtocol {
    var shouldReturnError = false

    func generateStyleReport(for userId: String) async throws -> StyleReport {
        if shouldReturnError {
            throw NSError(domain: "TestError", code: 1, userInfo: nil)
        } else {
            return StyleReport(
                id: "1",
                userId: userId,
                dominantStyle: .streetwear,
                styleBreakdown: [:],
                ranking: StyleRanking(overallAttractiveness: 0, totalVotes: 0, femaleAttractiveness: 0, maleAttractiveness: 0),
                recommendations: [],
                generatedAt: Date()
            )
        }
    }
}
