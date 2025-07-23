//
//  AppError.swift
//  viberanking
//
//  Created by Kiro on 2025/07/23.
//

import Foundation

// MARK: - Application Error Types
enum AppError: Error, LocalizedError {
    case authenticationFailed
    case networkError(Error)
    case imageUploadFailed
    case insufficientRatings
    case reportGenerationFailed
    case invalidImageFormat
    case photoTooOld
    case invalidEXIFData
    case userNotFound
    case photoNotFound
    case ratingSubmissionFailed
    case validationError(String)
    case firebaseError(FirebaseError)
    
    var errorDescription: String? {
        switch self {
        case .authenticationFailed:
            return "登入失敗，請重試"
        case .networkError(let error):
            return "網路連接問題，請檢查網路設定: \(error.localizedDescription)"
        case .imageUploadFailed:
            return "照片上傳失敗，請重試"
        case .insufficientRatings:
            return "評分數量不足，無法生成報告"
        case .reportGenerationFailed:
            return "報告生成失敗，請稍後重試"
        case .invalidImageFormat:
            return "不支援的圖片格式"
        case .photoTooOld:
            return "請上傳24小時內拍攝的照片"
        case .invalidEXIFData:
            return "照片缺少必要資訊，請使用相機拍攝"
        case .userNotFound:
            return "找不到用戶資料"
        case .photoNotFound:
            return "找不到照片資料"
        case .ratingSubmissionFailed:
            return "評分提交失敗，請重試"
        case .validationError(let message):
            return message
        case .firebaseError(let firebaseError):
            return firebaseError.errorDescription
        }
    }
    
    var recoverySuggestion: String? {
        switch self {
        case .authenticationFailed:
            return "請檢查網路連接並重新登入"
        case .networkError:
            return "請檢查網路連接並重試"
        case .imageUploadFailed:
            return "請檢查網路連接並重新上傳"
        case .insufficientRatings:
            return "請繼續評分其他照片"
        case .reportGenerationFailed:
            return "請稍後再試或聯繫客服"
        case .invalidImageFormat:
            return "請選擇 JPG 或 PNG 格式的照片"
        case .photoTooOld:
            return "請使用相機拍攝新照片"
        case .invalidEXIFData:
            return "請避免使用螢幕截圖，改用相機拍攝"
        case .userNotFound, .photoNotFound:
            return "請重新登入或聯繫客服"
        case .ratingSubmissionFailed:
            return "請檢查網路連接並重試"
        case .validationError:
            return "請檢查輸入資料並重試"
        case .firebaseError:
            return "請檢查網路連接並重試"
        }
    }
}

// MARK: - Error Handler Utility
class ErrorHandler: ObservableObject {
    @Published var currentError: AppError?
    @Published var showingError = false
    
    func handle(_ error: Error) {
        DispatchQueue.main.async {
            if let appError = error as? AppError {
                self.currentError = appError
            } else if let firebaseError = error as? FirebaseError {
                self.currentError = .firebaseError(firebaseError)
            } else {
                self.currentError = .networkError(error)
            }
            self.showingError = true
        }
    }
    
    func clearError() {
        currentError = nil
        showingError = false
    }
}