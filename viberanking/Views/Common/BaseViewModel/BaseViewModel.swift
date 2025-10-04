//
//  BaseViewModel.swift
//  viberanking
//
//  Created by Kiro on 2025/07/23.
//

import Foundation
import Combine

// MARK: - Error Handler
@MainActor
class ErrorHandler: ObservableObject {
    @Published var currentError: AppError?
    
    func handle(_ error: Error) {
        if let appError = error as? AppError {
            currentError = appError
        } else {
            currentError = AppError.apiError(error)
        }
    }
    
    func clearError() {
        currentError = nil
    }
}

// MARK: - Base ViewModel Protocol
protocol BaseViewModelProtocol: ObservableObject {
    var isLoading: Bool { get set }
    var errorHandler: ErrorHandler { get }
    
    func handleError(_ error: Error)
    func setLoading(_ loading: Bool)
}

// MARK: - Base ViewModel Implementation
@MainActor
class BaseViewModel: BaseViewModelProtocol {
    @Published var isLoading = false
    @Published var error: AppError?
    let errorHandler = ErrorHandler()
    
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        setupErrorHandling()
    }
    
    private func setupErrorHandling() {
        errorHandler.$currentError
            .sink { [weak self] error in
                self?.error = error
                if error != nil {
                    self?.isLoading = false
                }
            }
            .store(in: &cancellables)
    }
    
    func handleError(_ error: Error) {
        errorHandler.handle(error)
    }
    
    func setLoading(_ loading: Bool) {
        isLoading = loading
    }
    
    // MARK: - Async Task Helper
    func performAsyncTask<T>(_ task: @escaping () async throws -> T) async -> T? {
        setLoading(true)
        defer { setLoading(false) }
        
        do {
            return try await task()
        } catch {
            handleError(error)
            return nil
        }
    }
    
    // MARK: - Non-blocking Async Task Helper (for API calls that shouldn't block UI)
    func performNonBlockingTask<T>(_ task: @escaping () async throws -> T) async -> T? {
        do {
            return try await task()
        } catch {
            handleError(error)
            return nil
        }
    }
    
    // MARK: - Retry Logic
    func retryTask<T>(
        maxAttempts: Int = AppConfiguration.Performance.maxRetryAttempts,
        delay: TimeInterval = 1.0,
        task: @escaping () async throws -> T
    ) async -> T? {
        var lastError: Error?
        
        for attempt in 1...maxAttempts {
            do {
                return try await task()
            } catch {
                lastError = error
                if attempt < maxAttempts {
                    try? await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
                }
            }
        }
        
        if let error = lastError {
            handleError(error)
        }
        return nil
    }
}

// MARK: - Loading State Management
extension BaseViewModel {
    func withLoading<T>(_ operation: () async throws -> T) async -> T? {
        setLoading(true)
        defer { setLoading(false) }
        
        do {
            return try await operation()
        } catch {
            handleError(error)
            return nil
        }
    }
}
