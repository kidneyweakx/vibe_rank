import XCTest
@testable import viberanking

class StyleAnalysisServiceTests: XCTestCase {

    var styleAnalysisService: StyleAnalysisService!

    override func setUpWithError() throws {
        try super.setUpWithError()
        styleAnalysisService = StyleAnalysisService()
    }

    override func tearDownWithError() throws {
        styleAnalysisService = nil
        try super.tearDownWithError()
    }

    func testGenerateStyleReport() async throws {
        // Given
        let userId = "testUser"

        // When
        let styleReport = try await styleAnalysisService.generateStyleReport(for: userId)

        // Then
        XCTAssertEqual(styleReport.userId, userId)
        XCTAssertEqual(styleReport.dominantStyle, .streetwear)
        XCTAssertEqual(styleReport.styleBreakdown.count, 5)
        XCTAssertEqual(styleReport.ranking.overallAttractiveness, 73)
        XCTAssertEqual(styleReport.ranking.totalVotes, 156)
        XCTAssertEqual(styleReport.ranking.femaleAttractiveness, 89)
        XCTAssertEqual(styleReport.ranking.maleAttractiveness, 67)
        XCTAssertEqual(styleReport.recommendations.count, 5)
    }
}
