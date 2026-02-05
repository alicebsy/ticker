import SwiftUI
import Combine

class NetworkManager: ObservableObject {
    static let shared = NetworkManager()
    private let baseURL = "http://10.249.19.34:8080/api"
    
    private init() {}
    
    var currentUserId: Int?

    // MARK: - Generic Request
    func request<T: Codable>(_ endpoint: String, method: String = "GET", body: Codable? = nil) async throws -> T {
        guard let url = URL(string: baseURL + endpoint) else {
            throw NetworkError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = method
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        // Add User ID Header if exists
        if let userId = currentUserId {
            request.setValue("\(userId)", forHTTPHeaderField: "X-User-Id")
        }
        
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
        
        // Handle Void response
        if T.self == Void.self {
             return () as! T // Swift 5.7+ might handle this better, but JSONDecoder won't decode Void
             // Wait, JSONDecoder().decode(Void.self, from: data) fails. 
             // We need to check if T is Void. But T is Codable. Void is not Codable usually?
             // Actually, usually we return an Empty struct or handle Void specifically.
             // Let's rely on the caller to expect a struct or string. 
             // If T is Void, we should return before decoding.
        }
        
        return try JSONDecoder().decode(T.self, from: data)
    }

    // Helper for Void requests
    func requestVoid(_ endpoint: String, method: String = "GET", body: Codable? = nil) async throws {
        guard let url = URL(string: baseURL + endpoint) else { throw NetworkError.invalidURL }
        var request = URLRequest(url: url)
        request.httpMethod = method
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        if let userId = currentUserId { request.setValue("\(userId)", forHTTPHeaderField: "X-User-Id") }
        if let body = body { request.httpBody = try JSONEncoder().encode(body) }
        
        let (data, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse else { throw NetworkError.invalidResponse }
        guard (200...299).contains(httpResponse.statusCode) else {
             if let errorResponse = try? JSONDecoder().decode(ErrorResponse.self, from: data) {
                 throw NetworkError.serverError(errorResponse.message)
            }
            throw NetworkError.serverError("Server error check: \(httpResponse.statusCode)")
        }
    }
    
    // MARK: - Auth
    func signup(request: SignupRequest) async throws -> LoginResponse {
        return try await self.request("/auth/signup", method: "POST", body: request)
    }
    
    func login(request: LoginRequest) async throws -> LoginResponse {
        return try await self.request("/auth/login", method: "POST", body: request)
    }

    // MARK: - Kakao OAuth
    /// 카카오 로그인 URL 가져오기 (백엔드에서 OAuth2 시작점)
    var kakaoLoginURL: URL? {
        // 백엔드의 Spring Security OAuth2 시작 엔드포인트로 직접 이동
        URL(string: "http://10.249.19.34:8080/oauth2/authorization/kakao")
    }

    /// userId로 유저 정보 조회 (카카오 로그인 콜백 후 사용)
    func fetchUser(userId: Int) async throws -> UserResponse {
        return try await self.request("/users/\(userId)")
    }
    
    // MARK: - User Search
    func searchUsers(query: String) async throws -> [User] {
        return try await request("/users/search?q=\(query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")")
    }
    
    // MARK: - Watchlist / Friends
    struct AddFriendRequest: Codable {
        let friendCode: String?
        let friendUserId: Int?
    }
    
    func addFriend(friendCode: String) async throws {
        let req = AddFriendRequest(friendCode: friendCode, friendUserId: nil)
        try await requestVoid("/watchlist/friends", method: "POST", body: req)
    }
    
    func acceptFriend(requesterId: Int) async throws {
        try await requestVoid("/watchlist/friends/\(requesterId)/accept", method: "POST")
    }
    
    func rejectFriend(requesterId: Int) async throws {
        try await requestVoid("/watchlist/friends/\(requesterId)/reject", method: "POST")
    }
    
    // MARK: - Friend Listing
    func fetchFriendListing(userId: Int, period: String = "7D") async throws -> ListingResponse {
        return try await request("/listing/user/\(userId)?period=\(period)")
    }

    // MARK: - News
    func fetchNews(category: String?) async throws -> [NewsPostDto] {
        var path = "/news"
        if let cat = category, cat != "ALL", !cat.isEmpty {
            path += "?category=\(cat)"
        }
        return try await request(path)
    }

    func fetchNewsDetail(postId: Int) async throws -> NewsPostDto {
        return try await request("/news/\(postId)")
    }

    struct CreateNewsPostBody: Codable {
        let title: String
        let content: String
        let category: String
        let anonymous: Bool
    }
    func createNewsPost(title: String, content: String, category: String, anonymous: Bool) async throws -> NewsPostDto {
        let body = CreateNewsPostBody(title: title, content: content, category: category, anonymous: anonymous)
        return try await request("/news", method: "POST", body: body)
    }

    struct UpdateNewsPostBody: Codable {
        let title: String
        let content: String
        let category: String
        let anonymous: Bool
    }
    func updateNewsPost(postId: Int, title: String, content: String, category: String, anonymous: Bool) async throws -> NewsPostDto {
        let body = UpdateNewsPostBody(title: title, content: content, category: category, anonymous: anonymous)
        return try await request("/news/\(postId)", method: "PUT", body: body)
    }

    func deleteNewsPost(postId: Int) async throws {
        let _: EmptyJson = try await request("/news/\(postId)", method: "DELETE")
    }
    private struct EmptyJson: Codable {}

    struct CreateNewsCommentBody: Codable {
        let content: String
    }
    func addNewsComment(postId: Int, content: String) async throws -> NewsCommentDto {
        return try await request("/news/\(postId)/comments", method: "POST", body: CreateNewsCommentBody(content: content))
    }

    func likeNewsPost(postId: Int) async throws {
        try await requestVoid("/news/\(postId)/like", method: "POST")
    }

    // MARK: - Casino (백엔드: bettingBalance, betHistory / 친구 목록은 watchlist/friends)
    struct CasinoResponse: Codable {
        let bettingBalance: Int
        let betHistory: [CasinoBetHistoryItem]
    }
    struct CasinoBetHistoryItem: Codable {
        let id: Int
        let target: String?
        let type: String?
        let amount: Int
        let result: String?
        let profit: Int?
    }
    func getCasino() async throws -> CasinoResponse {
        return try await request("/casino")
    }

    struct PlaceBetBody: Codable {
        let friendUserId: Int?
        let todoId: Int?
        let amount: Int
        let predictSuccess: Bool
    }
    func placeBet(friendUserId: Int, amount: Int, predictSuccess: Bool) async throws {
        let body = PlaceBetBody(friendUserId: friendUserId, todoId: nil, amount: amount, predictSuccess: predictSuccess)
        try await requestVoid("/casino/bets", method: "POST", body: body)
    }

    /// GET /api/watchlist/friends → 친구 목록 (예언 배팅 대상)
    func getWatchlistFriends() async throws -> [WatchlistFriend] {
        return try await request("/watchlist/friends")
    }
    struct WatchlistFriend: Codable, Identifiable {
        let id: Int
        let name: String
        let loginId: String?
        let profileImageUrl: String?
        let cashBalance: Int?
        let marketCap: Int?
        let totalAssets: Int?
        let stockPrice: Int?
    }
    
    // MARK: - Dark Market
    func getDarkMarket() async throws -> MarketResponse {
        return try await request("/dark-market")
    }

    func purchaseItem(itemId: Int, quantity: Int) async throws {
        let req = PurchaseData(itemId: itemId, quantity: quantity)
        try await requestVoid("/dark-market/purchase", method: "POST", body: req)
    }

    // MARK: - Prophecy (사용자 정의 예언)

    /// 나의 예언 등록
    func createProphecy(content: String) async throws -> Prophecy {
        let body = CreateProphecyRequest(content: content)
        return try await request("/prophecies", method: "POST", body: body)
    }

    /// 나의 예언 목록
    func getMyProphecies() async throws -> [Prophecy] {
        return try await request("/prophecies/my")
    }

    /// 배팅 가능한 예언 목록 (친구들의 OPEN 예언)
    func getBettableProphecies() async throws -> [Prophecy] {
        return try await request("/prophecies/bettable")
    }

    /// 예언 상세 조회
    func getProphecy(prophecyId: Int) async throws -> Prophecy {
        return try await request("/prophecies/\(prophecyId)")
    }

    /// 예언 종료 (결과 입력)
    func closeProphecy(prophecyId: Int, success: Bool) async throws -> Prophecy {
        let body = CloseProphecyRequest(success: success)
        return try await request("/prophecies/\(prophecyId)/close", method: "POST", body: body)
    }

    /// 예언에 배팅하기
    func placeProphecyBet(prophecyId: Int, amount: Int, predictSuccess: Bool) async throws -> ProphecyBet {
        let body = ProphecyBetRequest(prophecyId: prophecyId, amount: amount, predictSuccess: predictSuccess)
        return try await request("/prophecies/bets", method: "POST", body: body)
    }

    /// 나의 예언 배팅 내역
    func getMyProphecyBets() async throws -> [ProphecyBet] {
        return try await request("/prophecies/bets/my")
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
