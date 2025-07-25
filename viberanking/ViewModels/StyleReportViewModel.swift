import Foundation
import Combine
import viberanking

class StyleReportViewModel: ObservableObject {
    @Published var styleReport: StyleReport?
    @Published var isLoading = false
    @Published var errorMessage: String?

    private let styleAnalysisService: StyleAnalysisServiceProtocol
    private var cancellables = Set<AnyCancellable>()

    init(styleAnalysisService: StyleAnalysisServiceProtocol) {
        self.styleAnalysisService = styleAnalysisService
    }

    func fetchStyleReport(for userId: String) {
        isLoading = true
        errorMessage = nil

        Task {
            do {
                let report = try await styleAnalysisService.generateStyleReport(for: userId)
                DispatchQueue.main.async {
                    self.styleReport = report
                    self.isLoading = false
                }
            } catch {
                DispatchQueue.main.async {
                    self.errorMessage = error.localizedDescription
                    self.isLoading = false
                }
            }
        }
    }
}
