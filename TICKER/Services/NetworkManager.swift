import SwiftUI
import Combine

class NetworkManager: ObservableObject {
    static let shared = NetworkManager()
    private let baseURL = "http://127.0.0.1:8080/api"
    
    private init() {}
    
    // MARK: - Generic Request
    func request<T: Codable>(_ endpoint: String, method: String = "GET", body: Codable? = nil) async throws -> T {
        guard let url = URL(string: baseURL + endpoint) else {
            throw NetworkError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = method
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        if let body = body {
            request.httpBody = try JSONEncoder().encode(body)
        }
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw NetworkError.invalidResponse
        }
        
        guard (200...299).contains(httpResponse.statusCode) else {
            if let errorResponse = try? JSONDecoder().decode(ErrorResponse.self, from: data) {
                 throw NetworkError.serverError(errorResponse.message)
            }
            throw NetworkError.serverError("Server error check: \(httpResponse.statusCode)")
        }
        
        return try JSONDecoder().decode(T.self, from: data)
    }
    
    // MARK: - Auth
    func signup(request: SignupRequest) async throws -> LoginResponse {
        return try await self.request("/auth/signup", method: "POST", body: request)
    }
    
    func login(request: LoginRequest) async throws -> LoginResponse {
        return try await self.request("/auth/login", method: "POST", body: request)
    }
}

// MARK: - Network Errors
enum NetworkError: Error, LocalizedError {
    case invalidURL
    case invalidResponse
    case serverError(String)
    case decodingError
    
    var errorDescription: String? {
        switch self {
        case .invalidURL: return "잘못된 URL입니다."
        case .invalidResponse: return "서버 응답이 올바르지 않습니다."
        case .serverError(let message): return message
        case .decodingError: return "데이터 처리 중 오류가 발생했습니다."
        }
    }
}

struct ErrorResponse: Codable {
    let error: String?
    let message: String
}
