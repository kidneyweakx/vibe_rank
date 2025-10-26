//
//  APIClient.swift
//  viberanking
//
//  Created by Kiro on 2025/08/04.
//

import Foundation

/// Base API client for handling HTTP requests
class APIClient {
    
    static let shared = APIClient()
    
    private let session: URLSession
    let baseURL: String

    private init() {
        self.session = URLSession.shared
        self.baseURL = AppEnvironment.current.baseURL
    }

    /// Get JWT token from keychain
    private func getJWTToken() -> String? {
        return try? KeychainItem.readJWTToken()
    }
    
    /// Decode JWT token to see its payload
    private func decodeJWTToken(_ token: String) -> [String: Any]? {
        let parts = token.components(separatedBy: ".")
        guard parts.count == 3 else { return nil }
        
        // JWT payload is base64url encoded (second part)
        var base64 = parts[1]
            .replacingOccurrences(of: "-", with: "+")
            .replacingOccurrences(of: "_", with: "/")
        
        // Add padding if needed
        let paddingLength = (4 - base64.count % 4) % 4
        base64 = base64.padding(toLength: base64.count + paddingLength, withPad: "=", startingAt: 0)
        
        guard let data = Data(base64Encoded: base64),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            return nil
        }
        
        return json
    }
    
    /// Perform a generic API request
    func performRequest<T: Decodable>(
        endpoint: String,
        method: HTTPMethod = .GET,
        body: [String: Any]? = nil,
        responseType: T.Type
    ) async throws -> T {

        guard let url = URL(string: "\(baseURL)\(endpoint)") else {
            throw APIError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = method.rawValue

        // Add JWT token if available
        if let jwtToken = getJWTToken() {
            request.setValue("Bearer \(jwtToken)", forHTTPHeaderField: "Authorization")
            // Debug: Print JWT token details (first 50 chars for security)
            print("🔑 JWT Token (partial): \(String(jwtToken.prefix(50)))...")
            
            // Debug: Decode JWT payload to see what's inside
            if let jwtPayload = decodeJWTToken(jwtToken) {
                print("🔍 JWT Payload: \(jwtPayload)")
            }
        } else {
            print("⚠️ No JWT token found in keychain")
        }
        
        if let body = body {
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.httpBody = try JSONSerialization.data(withJSONObject: body)
        }
        
        // Request log
        print("➡️ API 請求: \(method.rawValue) \(endpoint)")
        if let body = body, !body.isEmpty,
           let bodyData = try? JSONSerialization.data(withJSONObject: body, options: []),
           bodyData.count <= 64 * 1024, // 避免打印過大的請求
           let bodyString = String(data: bodyData, encoding: .utf8) {
            print("📝 請求內容(<=64KB): \n\(bodyString)")
        } else if let body = body, !body.isEmpty {
            print("📝 請求內容過大(>64KB)，略過打印")
        }

        let (data, response) = try await session.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }
        
        print("📡 API 響應狀態碼: \(httpResponse.statusCode) ← \(method.rawValue) \(endpoint)")

        guard httpResponse.statusCode == 200 else {
            let responseText = String(data: data, encoding: .utf8)
            if let responseText = responseText {
                // Try to extract common error fields for readability
                if let json = try? JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] {
                    let message = (json["message"] as? String)
                        ?? (json["error"] as? String)
                        ?? (json["detail"] as? String)
                        ?? responseText
                    print("❌ API 錯誤 [\(httpResponse.statusCode)] — \(method.rawValue) \(endpoint)\n↪︎ 訊息: \(message)")
                } else {
                    print("❌ API 錯誤 [\(httpResponse.statusCode)] — \(method.rawValue) \(endpoint)\n↪︎ 內容: \(responseText)")
                }
            } else {
                print("❌ API 錯誤 [\(httpResponse.statusCode)] — \(method.rawValue) \(endpoint) (無響應內容)")
            }

            // Handle 401 Unauthorized - JWT token expired or invalid
            if httpResponse.statusCode == 401 {
                print("🔒 JWT token expired or invalid, clearing token and notifying app")
                try? KeychainItem.deleteJWTToken()
                NotificationCenter.default.post(name: .userSessionExpired, object: nil)
            }

            throw APIError.serverError(httpResponse.statusCode)
        }
        
        // 打印實際的響應內容
        if let responseString = String(data: data, encoding: .utf8) {
            print("📄 API 響應內容: \(responseString)")
        }
        
        do {
            let decoder = JSONDecoder()
            // 設置日期解碼格式
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSS'Z'"
            dateFormatter.timeZone = TimeZone(abbreviation: "UTC")
            decoder.dateDecodingStrategy = .formatted(dateFormatter)
            
            let decodedResponse = try decoder.decode(responseType, from: data)
            print("✅ JSON 解碼成功")
            return decodedResponse
        } catch {
            print("❌ JSON 解碼失敗: \(error)")
            if let responseString = String(data: data, encoding: .utf8) {
                print("❌ 無法解碼的響應: \(responseString)")
            }
            throw APIError.decodingError(error)
        }
    }
    
    /// Perform a request without expecting a response body
    func performRequest(
        endpoint: String,
        method: HTTPMethod = .POST,
        body: [String: Any]? = nil
    ) async throws {
        
        guard let url = URL(string: "\(baseURL)\(endpoint)") else {
            throw APIError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = method.rawValue

        // Add JWT token if available
        if let jwtToken = getJWTToken() {
            request.setValue("Bearer \(jwtToken)", forHTTPHeaderField: "Authorization")
        }

        if let body = body {
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.httpBody = try JSONSerialization.data(withJSONObject: body)
        }

        // Request log (no-body response)
        print("➡️ API 請求: \(method.rawValue) \(endpoint)")
        if let body = body, !body.isEmpty,
           let bodyData = try? JSONSerialization.data(withJSONObject: body, options: []),
           bodyData.count <= 64 * 1024,
           let bodyString = String(data: bodyData, encoding: .utf8) {
            print("📝 請求內容(<=64KB): \n\(bodyString)")
        } else if let body = body, !body.isEmpty {
            print("📝 請求內容過大(>64KB)，略過打印")
        }

        let (data, response) = try await session.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }
        
        print("📡 API 響應狀態碼: \(httpResponse.statusCode) ← \(method.rawValue) \(endpoint)")
        guard httpResponse.statusCode == 200 else {
            let responseText = String(data: data, encoding: .utf8)
            if let responseText = responseText {
                if let json = try? JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] {
                    let message = (json["message"] as? String)
                        ?? (json["error"] as? String)
                        ?? (json["detail"] as? String)
                        ?? responseText
                    print("❌ API 錯誤 [\(httpResponse.statusCode)] — \(method.rawValue) \(endpoint)\n↪︎ 訊息: \(message)")
                } else {
                    print("❌ API 錯誤 [\(httpResponse.statusCode)] — \(method.rawValue) \(endpoint)\n↪︎ 內容: \(responseText)")
                }
            } else {
                print("❌ API 錯誤 [\(httpResponse.statusCode)] — \(method.rawValue) \(endpoint) (無響應內容)")
            }

            // Handle 401 Unauthorized - JWT token expired or invalid
            if httpResponse.statusCode == 401 {
                print("🔒 JWT token expired or invalid, clearing token and notifying app")
                try? KeychainItem.deleteJWTToken()
                NotificationCenter.default.post(name: .userSessionExpired, object: nil)
            }

            throw APIError.serverError(httpResponse.statusCode)
        }
    }
}

// MARK: - HTTP Method

enum HTTPMethod: String {
    case GET = "GET"
    case POST = "POST"
    case PUT = "PUT"
    case DELETE = "DELETE"
}

// MARK: - API Error

enum APIError: Error, LocalizedError {
    case invalidURL
    case invalidResponse
    case serverError(Int)
    case decodingError(Error)
    
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid URL"
        case .invalidResponse:
            return "Invalid response"
        case .serverError(let code):
            switch code {
            case 400: return "Bad Request (400) – 參數錯誤或缺失"
            case 401: return "Unauthorized (401) – 未授權或登入已過期"
            case 403: return "Forbidden (403) – 無權限存取此資源"
            case 404: return "Not Found (404) – 找不到資源或用戶資料"
            case 409: return "Conflict (409) – 資源衝突，請稍後重試"
            case 422: return "Unprocessable Entity (422) – 驗證失敗，請檢查輸入"
            case 429: return "Too Many Requests (429) – 請稍後再試"
            case 500...599: return "Server Error (\(code)) – 伺服器發生內部錯誤"
            default: return "Server error with code: \(code)"
            }
        case .decodingError(let error):
            return "Decoding error: \(error.localizedDescription)"
        }
    }
}