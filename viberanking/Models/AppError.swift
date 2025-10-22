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
    case apiError(Error)
    case imageUploadFailed
    case insufficientRatings
    case reportGenerationFailed
    case invalidImageFormat
    case photoTooOld
    case invalidEXIFData
    case userNotFound
    case photoNotFound
    case invalidURL
    case ratingSubmissionFailed
    case serverError(Int)
    case needsOnboarding
    case validationError(String)
    
    var errorDescription: String? {
        switch self {
        case .authenticationFailed:
            return "登入失敗，請重試"
        case .networkError(let error):
            return "網路連接問題，請檢查網路設定: \(error.localizedDescription)"
        case .apiError(let error):
            return "API 錯誤: \(error.localizedDescription)"
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
        case .serverError(let statusCode):
            switch statusCode {
            case 400: return "請求格式錯誤 (400) — 參數錯誤或缺失"
            case 401: return "未授權 (401) — 登入狀態失效或權杖無效"
            case 403: return "拒絕存取 (403) — 權限不足"
            case 404: return "找不到資源 (404) — 可能尚未完成註冊或資料不存在"
            case 409: return "資料衝突 (409) — 請稍後重試"
            case 422: return "驗證失敗 (422) — 請檢查輸入資料"
            case 429: return "請求過於頻繁 (429) — 請稍後再試"
            case 500...599: return "伺服器錯誤 (\(statusCode)) — 請稍後重試"
            default: return "伺服器錯誤 (\(statusCode))"
            }
        case .invalidURL:
            return "無效的網址"
        case .needsOnboarding:
            return "需要完成初次引導流程"
        case .validationError(let message):
            return message
        }
    }
    
    var recoverySuggestion: String? {
        switch self {
        case .authenticationFailed:
            return "請檢查網路連接並重新登入"
        case .networkError, .apiError:
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
        case .serverError(let statusCode):
            switch statusCode {
            case 400, 422:
                return "請檢查輸入資料並重試"
            case 401:
                return "請重新登入"
            case 403:
                return "請聯繫客服開通權限或切換帳號"
            case 404:
                return "若首次登入請完成註冊；否則請重新登入或聯繫客服"
            case 409:
                return "資料狀態衝突，請稍後再試"
            case 429:
                return "操作過於頻繁，請稍後再試"
            case 500...599:
                return "伺服器異常，請稍後再試或聯繫客服"
            default:
                return "請稍後重試或聯繫客服"
            }
        case .needsOnboarding:
            return "請完成新手引導步驟以繼續使用"
        case .invalidURL:
            return "請檢查輸入資料並重試"
        case .validationError:
            return "請檢查輸入資料並重試"
        }
    }
}

