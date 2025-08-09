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
    private let baseURL: String
    private let accessToken = "vibe_api_2025_secure_token_8f9a2b3c4d5e6f7g8h9i0j1k2l3m4n5o"
    
    private init() {
        self.session = URLSession.shared
        self.baseURL = AppEnvironment.current.baseURL
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
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(accessToken, forHTTPHeaderField: "X-Access-Token")
        
        if let body = body {
            request.httpBody = try JSONSerialization.data(withJSONObject: body)
        }
        
        let (data, response) = try await session.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }
        
        print("📡 API 響應狀態碼: \(httpResponse.statusCode)")
        
        guard httpResponse.statusCode == 200 else {
            print("❌ API 錯誤狀態碼: \(httpResponse.statusCode)")
            if let responseString = String(data: data, encoding: .utf8) {
                print("❌ 錯誤響應內容: \(responseString)")
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
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(accessToken, forHTTPHeaderField: "X-Access-Token")
        
        if let body = body {
            request.httpBody = try JSONSerialization.data(withJSONObject: body)
        }
        
        let (_, response) = try await session.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }
        
        guard httpResponse.statusCode == 200 else {
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
            return "Server error with code: \(code)"
        case .decodingError(let error):
            return "Decoding error: \(error.localizedDescription)"
        }
    }
}