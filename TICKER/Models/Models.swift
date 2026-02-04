import SwiftUI

// MARK: - TodoItem (하루의 할 일 항목)
struct TodoItem: Identifiable, Hashable, Codable {
    let id: UUID
    var backendId: Int? // Backend ID
    var title: String
    var isCompleted: Bool
    var completedAt: Date?

    init(id: UUID = UUID(), backendId: Int? = nil, title: String, isCompleted: Bool = false, completedAt: Date? = nil) {
        self.id = id
        self.backendId = backendId
        self.title = title
        self.isCompleted = isCompleted
        self.completedAt = completedAt
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }

    static func == (lhs: TodoItem, rhs: TodoItem) -> Bool {
        lhs.id == rhs.id
    }
}

// MARK: - DailyRecord (하루의 투두 기록)
struct DailyRecord: Identifiable, Hashable, Codable {
    let id: UUID
    var date: Date
    var todoItems: [TodoItem]
    var isListed: Bool  // 상장 여부
    var priceChangePercent: Double?  // nil = 아직 정산 전, 정산 후 값 설정

    init(id: UUID = UUID(), date: Date = Date(), todoItems: [TodoItem] = [], isListed: Bool = false, priceChangePercent: Double? = nil) {
        self.id = id
        self.date = date
        self.todoItems = todoItems
        self.isListed = isListed
        self.priceChangePercent = priceChangePercent
    }

    var completionRate: Double {
        guard !todoItems.isEmpty else { return 0 }
        return Double(todoItems.filter { $0.isCompleted }.count) / Double(todoItems.count)
    }

    var completedCount: Int {
        todoItems.filter { $0.isCompleted }.count
    }

    var totalCount: Int {
        todoItems.count
    }

    /// 완성률 기반 예상 주가 변동폭
    var projectedPriceChange: Double {
        let rate = completionRate
        if rate >= 1.0 { return Double.random(in: 0.10...0.15) }  // 100%: +10~15%
        if rate >= 0.75 { return 0.05 }                            // 75~99%: +5%
        if rate >= 0.50 { return 0.0 }                              // 50~74%: 0%
        if rate >= 0.25 { return -0.10 }                            // 25~49%: -10%
        return -0.20                                                 // 0~24%: -20%
    }

    /// 예상 변동폭 텍스트
    var projectedChangeText: String {
        let rate = completionRate
        if rate >= 1.0 { return "+10~15%" }
        if rate >= 0.75 { return "+5%" }
        if rate >= 0.50 { return "0%" }
        if rate >= 0.25 { return "-10%" }
        return "-20%"
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }

    static func == (lhs: DailyRecord, rhs: DailyRecord) -> Bool {
        lhs.id == rhs.id
    }
}

// MARK: - PriceHistoryPoint (차트용 가격 이력)
struct PriceHistoryPoint: Identifiable, Hashable, Codable {
    let id: UUID
    var date: Date
    var price: Double

    init(id: UUID = UUID(), date: Date = Date(), price: Double) {
        self.id = id
        self.date = date
        self.price = price
    }
}

// MARK: - Holding (내가 보유한 타인 주식)
struct Holding: Identifiable, Hashable {
    let id: UUID
    var investmentId: Int? // Backend Investment ID
    var name: String
    var ticker: String
    var currentPrice: Double
    var change: Double
    var quantity: Int
    var avatarColor: Color
    var sparklineData: [Double]
    var averageBuyPrice: Double  // 평균 매수가

    var totalValue: Double {
        currentPrice * Double(quantity)
    }

    var profitLoss: Double {
        (currentPrice - averageBuyPrice) * Double(quantity)
    }

    var profitPercent: Double {
        guard averageBuyPrice > 0 else { return 0 }
        return ((currentPrice - averageBuyPrice) / averageBuyPrice) * 100
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }

    static func == (lhs: Holding, rhs: Holding) -> Bool {
        lhs.id == rhs.id
    }

    static let sampleData: [Holding] = [
        Holding(
            id: UUID(),
            name: "김철수",
            ticker: "CHUL",
            currentPrice: 1200,
            change: 3.5,
            quantity: 5,
            avatarColor: .blue,
            sparklineData: [1000, 1050, 1030, 1080, 1120, 1100, 1150, 1180, 1200],
            averageBuyPrice: 1050
        ),
        Holding(
            id: UUID(),
            name: "이영희",
            ticker: "YOUNG",
            currentPrice: 890,
            change: -1.2,
            quantity: 10,
            avatarColor: .pink,
            sparklineData: [1000, 980, 960, 940, 920, 910, 900, 890],
            averageBuyPrice: 1000
        ),
        Holding(
            id: UUID(),
            name: "박지민",
            ticker: "JIMIN",
            currentPrice: 1500,
            change: 7.8,
            quantity: 3,
            avatarColor: .orange,
            sparklineData: [1000, 1100, 1200, 1150, 1300, 1400, 1500],
            averageBuyPrice: 1100
        ),
    ]
}

// MARK: - LoginMethod
enum LoginMethod: String, Codable {
    case kakao
    case email
    case guest

    var displayName: String {
        switch self {
        case .kakao: return "카카오"
        case .email: return "이메일"
        case .guest: return "게스트"
        }
    }
}

// MARK: - User
struct User: Identifiable, Codable {
    let id: Int
    var name: String
    var loginId: String
    var profileImage: String?
    var loginMethod: LoginMethod?
    
    // Financials
    var cashBalance: Int
    var marketCap: Int
    var totalAssets: Int
    var stockPrice: Int
    var friendCode: String?
    
    enum CodingKeys: String, CodingKey {
        case id, name, loginId, cashBalance, marketCap, totalAssets, stockPrice, friendCode
        case profileImage = "profileImageUrl"
        case loginMethod
    }
    
    // Sample Data Factory
    static let sampleUser = User(
        id: 1,
        name: "김주식",
        loginId: "user1",
        profileImage: nil,
        loginMethod: .kakao,
        cashBalance: 100_000,
        marketCap: 100_000,
        totalAssets: 200_000,
        stockPrice: 1000,
        friendCode: "TICKER-1234"
    )
}
// MARK: - Todo (Backend Entity)
struct Todo: Codable, Identifiable {
    let id: Int
    let name: String
    let deadline: String
    let rewardPoints: Int
    let progress: Int
    let status: String
}

enum Difficulty: String, Codable {
    case easy = "EASY"
    case normal = "NORMAL"
    case hard = "HARD"
}

// MARK: - API Requests & Responses
struct SignupRequest: Codable {
    let loginId: String
    let password: String
    let name: String
}

struct LoginRequest: Codable {
    let loginId: String
    let password: String
}

struct InvestRequest: Codable {
    let subjectUserId: Int
    let quantity: Int
}

struct HeldStockDto: Codable, Identifiable {
    let id: Int // Investment ID
    let ownerName: String
    let ownerImageUrl: String?
    let currentPrice: Int
    let priceChangePercent: String
    let profitLoss: Int
    let profitLossPercent: String
    let quantity: Int
    let holdingRatio: Int
}

struct HeldStocksResponse: Codable {
    let totalValuation: Int
    let totalPurchaseAmount: Int
    let totalProfitLoss: Int
    let totalReturnRate: String
    let stocks: [HeldStockDto]
}

struct InvestmentSummaryDto: Codable, Identifiable {
    let id: Int
    let ownerName: String
    let ownerImageUrl: String?
    let currentValue: Int
    let changePercent: String
}

struct SkillSummaryDto: Codable {
    let name: String
    let quantity: Int
}

struct DelistedSummaryDto: Codable, Identifiable {
    var id: String { date + todoName }
    let todoName: String
    let date: String
    let profitLoss: Int
    let status: String
}

struct PortfolioResponse: Codable {
    let totalAssets: Int
    let cashBalance: Int
    let marketCap: Int
    let dailyChangePercent: String
    let investingAmount: Int
    let investments: [InvestmentSummaryDto]
    let skills: [SkillSummaryDto]
    let delistedHistory: [DelistedSummaryDto]
}



struct FriendRequestDto: Codable, Identifiable {
    let id: Int // Request ID? Or User ID? Check Java. It says sending request ID.
    // Wait, Java says FriendRequestDto has id. is it request ID or user id?
    // "private Long id;" usually ID of the request entity.
    let name: String
    let imageUrl: String?
    let status: String
}

struct WatchlistItemDto: Codable, Identifiable {
    var id: Int { userId }
    let userId: Int
    let name: String
    let imageUrl: String?
    let currentPrice: Int
    let changePercent: String
    let chartData: [Int]
    let remainingShares: Int?

    enum CodingKeys: String, CodingKey {
        case userId, name, imageUrl, currentPrice, changePercent, chartData, remainingShares
    }
}

struct ListingRequest: Codable {
    let name: String
    let deadline: String // YYYY-MM-DD
    let rewardPoints: Int?
    let difficulty: String
    let visibility: String
}

struct ListingResponse: Codable {
    let myStockChart: StockChartDto
    let listedTodos: [ListedTodoDto]
}

struct StockChartDto: Codable {
    let currentPrice: Int
    let changePercent: String
    let status: String
    let chartData: [ChartPointDto]
}

struct ChartPointDto: Codable {
    let date: String
    let price: Int
}

struct ListedTodoDto: Codable, Identifiable {
    let id: Int
    let name: String
    let deadline: String
    let reward: Int
    let progress: Int
    let completed: Bool?
}

struct WatchlistResponse: Codable {
    let sentRequests: [FriendRequestDto]
    let receivedRequests: [FriendRequestDto]
    let watchlistItems: [WatchlistItemDto]
}

struct LoginResponse: Codable {
    let id: Int
    let loginId: String
    let name: String
    let profileImageUrl: String?
    let cashBalance: Int
    let marketCap: Int
    let totalAssets: Int
    let stockPrice: Int
    let friendCode: String?
    let message: String
}

// MARK: - Casino
struct CasinoGameResponse: Codable {
    let availableFriends: [CasinoFriend]
    let myBettingHistory: [BettingHistory]
}

struct CasinoFriend: Codable, Identifiable {
    let id: Int
    let name: String
    let imageUrl: String?
    let currentPrice: Int
    let todayTodoCount: Int
    let todayCompletedCount: Int
}

struct BettingHistory: Codable, Identifiable {
    let id: Int
    let targetName: String
    let betAmount: Int
    let betType: String
    let result: String?
    let profitLoss: Int?
}

struct PlaceBetData: Codable {
    let targetUserId: Int
    let betAmount: Int
    let betType: String // "SUCCESS" or "FAIL"
}

// MARK: - Dark Market
struct MarketResponse: Codable {
    let items: [MarketItem]
}

struct MarketItem: Codable, Identifiable {
    let id: Int
    let name: String
    let description: String
    let price: Int
    let stock: Int
    let category: String
}

struct PurchaseData: Codable {
    let itemId: Int
    let quantity: Int
}

// MARK: - Notifications (Real-time)
struct NotificationDto: Codable {
    let type: String
    let message: String
    let fromUserId: Int?
    let fromUserName: String?
    let fromUserImageUrl: String?
    let timestamp: String?
    
    // Stock update fields
    let userId: Int?
    let stockPrice: Int?
    let marketCap: Int?
    let totalAssets: Int?
    
    // Listing update fields
    let todoId: Int?
    let progress: Int?
    let completed: Bool?
    
    // Investment fields
    let remainingShares: Int?
}

enum NotificationType: String {
    case friendRequest = "FRIEND_REQUEST"
    case friendAccepted = "FRIEND_ACCEPTED"
    case friendRejected = "FRIEND_REJECTED"
    case stockPriceUpdated = "STOCK_PRICE_UPDATED"
    case listingUpdated = "LISTING_UPDATED"
    case investmentChanged = "INVESTMENT_CHANGED"
    case betPlaced = "BET_PLACED"
    case addedToWatchlist = "ADDED_TO_WATCHLIST"
}

/// 백엔드 GET /api/users/{id} 응답 (User 엔티티 직렬화)
struct UserResponse: Codable {
    let id: Int
    let name: String
    let loginId: String
    let profileImageUrl: String?
    let cashBalance: Int
    let marketCap: Int
    let totalAssets: Int
    let stockPrice: Int
    let friendCode: String?
    let oauthProvider: String?
}

// MARK: - FriendRequest
struct FriendRequest: Identifiable, Hashable {
    let id: UUID
    var requestId: Int? // Backend Request ID
    var userId: Int?    // Backend User ID (requester)
    var name: String
    var avatarColor: Color
    var isSentByMe: Bool

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }

    static func == (lhs: FriendRequest, rhs: FriendRequest) -> Bool {
        lhs.id == rhs.id
    }
}

// MARK: - Friend (유저 = 기업)
struct Friend: Identifiable, Hashable {
    let id: UUID
    var userId: Int = 0 // Backend User ID
    var name: String
    var ticker: String
    var currentPrice: Double       // 주당 가격
    var change: Double             // 일일 변동률 (%)
    var bio: String
    var avatarColor: Color
    var sparklineData: [Double]
    var priceHistory: [PriceHistoryPoint]
    var isStarred: Bool = false

    // 주식 구조
    var totalShares: Int { 100 }
    var founderShares: Int { 70 }
    var floatShares: Int { 30 }
    var sharesOutstanding: Int     // 30주 중 이미 매수된 주식 수

    var availableShares: Int { floatShares - sharesOutstanding }
    var marketCap: Double { currentPrice * Double(totalShares) }  // 시가총액 = 내 가치
    var tradingVolume: Double      // 오늘 거래대금

    // 투두 기록
    var todayRecord: DailyRecord?
    var dailyRecords: [DailyRecord]

    var isPositive: Bool { change >= 0 }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }

    static func == (lhs: Friend, rhs: Friend) -> Bool {
        lhs.id == rhs.id
    }

    static func generateSamplePriceHistory(basePrice: Double, days: Int = 14) -> [PriceHistoryPoint] {
        var history: [PriceHistoryPoint] = []
        var price = basePrice * 0.7
        for i in 0..<days {
            let date = Calendar.current.date(byAdding: .day, value: -(days - 1 - i), to: Date()) ?? Date()
            price *= Double.random(in: 0.92...1.12)
            price = max(100, price)
            history.append(PriceHistoryPoint(date: date, price: price))
        }
        // 마지막 날 가격을 현재가에 맞추기
        if var last = history.last {
            last = PriceHistoryPoint(id: last.id, date: last.date, price: basePrice)
            history[history.count - 1] = last
        }
        return history
    }

    static func generateSampleDailyRecords(days: Int = 7) -> [DailyRecord] {
        var records: [DailyRecord] = []
        let sampleTodos = [
            ["알고리즘 3문제 풀기", "운동 30분", "독서 1시간", "코딩 프로젝트"],
            ["영어 공부", "블로그 글쓰기", "운동", "요리하기"],
            ["미팅 준비", "보고서 작성", "운동", "독서", "일기 쓰기"],
            ["코딩 연습", "운동", "공부", "정리정돈"],
        ]

        for i in 0..<days {
            let date = Calendar.current.date(byAdding: .day, value: -(days - i), to: Date()) ?? Date()
            let todos = sampleTodos[i % sampleTodos.count]
            let completedCount = Int.random(in: 1...todos.count)
            let items = todos.enumerated().map { index, title in
                TodoItem(title: title, isCompleted: index < completedCount)
            }
            let rate = Double(completedCount) / Double(todos.count)
            let changePercent: Double
            if rate >= 1.0 { changePercent = Double.random(in: 0.10...0.15) }
            else if rate >= 0.75 { changePercent = 0.05 }
            else if rate >= 0.50 { changePercent = 0.0 }
            else if rate >= 0.25 { changePercent = -0.10 }
            else { changePercent = -0.20 }

            records.append(DailyRecord(
                date: date,
                todoItems: items,
                isListed: true,
                priceChangePercent: changePercent
            ))
        }
        return records
    }

    static let sampleData: [Friend] = [
        Friend(
            id: UUID(),
            name: "김철수",
            ticker: "CHUL",
            currentPrice: 1200,
            change: 3.5,
            bio: "풀스택 개발자, 매일 코딩에 열정을 쏟는 중",
            avatarColor: .blue,
            sparklineData: [1000, 1050, 1030, 1080, 1120, 1100, 1150, 1180, 1200],
            priceHistory: generateSamplePriceHistory(basePrice: 1200),
            sharesOutstanding: 8,
            tradingVolume: 15600,
            todayRecord: DailyRecord(
                date: Date(),
                todoItems: [
                    TodoItem(title: "알고리즘 3문제 풀기", isCompleted: true),
                    TodoItem(title: "운동 30분", isCompleted: true),
                    TodoItem(title: "독서 1시간", isCompleted: false),
                    TodoItem(title: "코딩 프로젝트 진행", isCompleted: false),
                ],
                isListed: true
            ),
            dailyRecords: generateSampleDailyRecords()
        ),
        Friend(
            id: UUID(),
            name: "이영희",
            ticker: "YOUNG",
            currentPrice: 890,
            change: -1.2,
            bio: "디자이너 겸 프론트엔드 개발자",
            avatarColor: .pink,
            sparklineData: [1000, 980, 960, 940, 920, 910, 900, 890],
            priceHistory: generateSamplePriceHistory(basePrice: 890),
            sharesOutstanding: 12,
            tradingVolume: 8900,
            todayRecord: DailyRecord(
                date: Date(),
                todoItems: [
                    TodoItem(title: "포트폴리오 리뉴얼", isCompleted: false),
                    TodoItem(title: "UI/UX 스터디", isCompleted: true),
                    TodoItem(title: "피그마 작업", isCompleted: false),
                    TodoItem(title: "운동하기", isCompleted: false),
                ],
                isListed: true
            ),
            dailyRecords: generateSampleDailyRecords()
        ),
        Friend(
            id: UUID(),
            name: "박지민",
            ticker: "JIMIN",
            currentPrice: 1500,
            change: 7.8,
            bio: "AI 연구원, 논문 마스터",
            avatarColor: .orange,
            sparklineData: [1000, 1100, 1200, 1150, 1300, 1400, 1500],
            priceHistory: generateSamplePriceHistory(basePrice: 1500),
            sharesOutstanding: 18,
            tradingVolume: 42000,
            todayRecord: DailyRecord(
                date: Date(),
                todoItems: [
                    TodoItem(title: "논문 리뷰", isCompleted: true),
                    TodoItem(title: "실험 코드 작성", isCompleted: true),
                    TodoItem(title: "세미나 발표 준비", isCompleted: true),
                    TodoItem(title: "운동 1시간", isCompleted: false),
                    TodoItem(title: "영어 공부", isCompleted: true),
                ],
                isListed: true
            ),
            dailyRecords: generateSampleDailyRecords()
        ),
        Friend(
            id: UUID(),
            name: "최수진",
            ticker: "SUJIN",
            currentPrice: 1100,
            change: 0.5,
            bio: "백엔드 엔지니어, 클라우드 전문가",
            avatarColor: .green,
            sparklineData: [1000, 1010, 990, 1020, 1000, 1030, 1010, 1040, 1100],
            priceHistory: generateSamplePriceHistory(basePrice: 1100),
            sharesOutstanding: 5,
            tradingVolume: 5500,
            todayRecord: DailyRecord(
                date: Date(),
                todoItems: [
                    TodoItem(title: "AWS 자격증 공부", isCompleted: true),
                    TodoItem(title: "Docker 실습", isCompleted: true),
                    TodoItem(title: "Go 언어 학습", isCompleted: true),
                    TodoItem(title: "러닝 5km", isCompleted: true),
                ],
                isListed: true
            ),
            dailyRecords: generateSampleDailyRecords()
        ),
        Friend(
            id: UUID(),
            name: "정민호",
            ticker: "MINHO",
            currentPrice: 750,
            change: -5.3,
            bio: "창업가, 스타트업 대표",
            avatarColor: .purple,
            sparklineData: [1000, 950, 900, 870, 830, 800, 780, 750],
            priceHistory: generateSamplePriceHistory(basePrice: 750),
            sharesOutstanding: 20,
            tradingVolume: 22500,
            todayRecord: DailyRecord(
                date: Date(),
                todoItems: [
                    TodoItem(title: "투자 미팅", isCompleted: false),
                    TodoItem(title: "팀 회의", isCompleted: true),
                    TodoItem(title: "사업계획서 수정", isCompleted: false),
                    TodoItem(title: "운동", isCompleted: false),
                ],
                isListed: true
            ),
            dailyRecords: generateSampleDailyRecords()
        ),
    ]
}

// MARK: - StoreCategory
enum StoreCategory: String, CaseIterable, Codable {
    case skill = "스킬"
    case item = "아이템"
    case boost = "부스트"
    case secret = "비밀"
}

// MARK: - ItemRarity
enum ItemRarity: String, Codable {
    case common = "일반"
    case rare = "레어"
    case epic = "에픽"
    case legendary = "전설"

    var color: Color {
        switch self {
        case .common: return .gray
        case .rare: return .blue
        case .epic: return .purple
        case .legendary: return .orange
        }
    }
}

// MARK: - StoreItem
struct StoreItem: Identifiable, Codable {
    let id: UUID
    var backendId: Int? // Backend ID
    var name: String
    var description: String
    var price: Int
    var icon: String
    var rarity: ItemRarity
    var category: StoreCategory

    init(id: UUID = UUID(), backendId: Int? = nil, name: String, description: String, price: Int, icon: String, rarity: ItemRarity, category: StoreCategory) {
        self.id = id
        self.backendId = backendId
        self.name = name
        self.description = description
        self.price = price
        self.icon = icon
        self.rarity = rarity
        self.category = category
    }

    static let sampleData: [StoreItem] = [
        StoreItem(id: UUID(), name: "주가 조작기", description: "24시간 동안 특정 친구의 주가를 5% 올릴 수 있습니다", price: 25000, icon: "chart.line.uptrend.xyaxis", rarity: .epic, category: .item),
        StoreItem(id: UUID(), name: "스파이 스킬", description: "다른 사람의 포트폴리오를 24시간 동안 열람할 수 있습니다", price: 15000, icon: "eye.fill", rarity: .rare, category: .skill),
        StoreItem(id: UUID(), name: "더블 부스트", description: "다음 거래의 수익을 2배로 증가시킵니다", price: 10000, icon: "bolt.fill", rarity: .rare, category: .boost),
        StoreItem(id: UUID(), name: "익명 거래", description: "거래 내역을 다른 사용자에게 숨길 수 있습니다", price: 30000, icon: "person.fill.questionmark", rarity: .epic, category: .secret),
        StoreItem(id: UUID(), name: "시간 정지", description: "마감일을 하루 연장할 수 있습니다", price: 50000, icon: "clock.arrow.circlepath", rarity: .legendary, category: .item),
        StoreItem(id: UUID(), name: "힐링 포션", description: "하락한 신뢰도를 10점 회복합니다", price: 8000, icon: "heart.fill", rarity: .common, category: .item),
    ]
}

// MARK: - TickerActivity (활동 내역)
struct TickerActivity: Identifiable, Codable {
    let id: UUID
    let type: TickerActivityType
    let description: String
    let amount: Int
    let time: String
    let timestamp: Date

    init(id: UUID = UUID(), type: TickerActivityType, description: String, amount: Int, time: String, timestamp: Date = Date()) {
        self.id = id
        self.type = type
        self.description = description
        self.amount = amount
        self.time = time
        self.timestamp = timestamp
    }

    var timeAgo: String {
        let interval = Date().timeIntervalSince(timestamp)
        if interval < 60 { return "방금 전" }
        if interval < 3600 { return "\(Int(interval / 60))분 전" }
        if interval < 86400 { return "\(Int(interval / 3600))시간 전" }
        return "\(Int(interval / 86400))일 전"
    }
}

enum TickerActivityType: String, Codable {
    case buy = "매수"
    case sell = "매도"
    case dividend = "배당"
    case listing = "상장"
    case deposit = "입금"
    case purchase = "구매"
    case bet = "베팅"

    var icon: String {
        switch self {
        case .buy: return "arrow.down.circle.fill"
        case .sell: return "arrow.up.circle.fill"
        case .dividend: return "gift.fill"
        case .listing: return "paperplane.fill"
        case .deposit: return "plus.circle.fill"
        case .purchase: return "bag.fill"
        case .bet: return "dice.fill"
        }
    }

    var color: Color {
        switch self {
        case .buy: return .blue
        case .sell: return .orange
        case .dividend: return .green
        case .listing: return .green
        case .purchase: return .purple
        case .bet: return .pink
        case .deposit: return .orange
        }
    }
}

// MARK: - NewsPost
struct NewsPost: Identifiable, Hashable {
    let id: UUID
    var author: String
    var authorTicker: String
    var avatarColor: Color
    var title: String
    var content: String
    var category: NewsCategory
    var likes: Int
    var comments: [NewsComment]
    var timestamp: Date
    var isAnonymous: Bool

    var displayAuthor: String {
        isAnonymous ? "익명" : author
    }

    var timeAgo: String {
        let interval = Date().timeIntervalSince(timestamp)
        if interval < 60 { return "방금 전" }
        if interval < 3600 { return "\(Int(interval / 60))분 전" }
        if interval < 86400 { return "\(Int(interval / 3600))시간 전" }
        return "\(Int(interval / 86400))일 전"
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }

    static func == (lhs: NewsPost, rhs: NewsPost) -> Bool {
        lhs.id == rhs.id
    }

    static let sampleData: [NewsPost] = [
        NewsPost(
            id: UUID(),
            author: "박지민",
            authorTicker: "JIMIN",
            avatarColor: .orange,
            title: "요즘 AI 관련 투두 많이 하시나요?",
            content: "AI 프로젝트 관련 투두 작성이 요즘 대세인 것 같은데, 다들 어떤 식으로 하고 계신가요?",
            category: .discussion,
            likes: 12,
            comments: [
                NewsComment(id: UUID(), author: "김철수", content: "저도 AI 쪽 투두 위주로 해요!", timestamp: Date().addingTimeInterval(-1800)),
                NewsComment(id: UUID(), author: "최수진", content: "꾸준히 하면 주가 잘 오르더라구요", timestamp: Date().addingTimeInterval(-900)),
            ],
            timestamp: Date().addingTimeInterval(-600),
            isAnonymous: false
        ),
        NewsPost(
            id: UUID(),
            author: "김철수",
            authorTicker: "CHUL",
            avatarColor: .blue,
            title: "정민호 주가 왜 이렇게 떨어지나요?",
            content: "정민호 주식 보유하고 있는데 계속 하락 중이네요. 투두 완성률이 낮은 건지...",
            category: .analysis,
            likes: 8,
            comments: [
                NewsComment(id: UUID(), author: "익명", content: "투두 완성률 25% 미만이래요", timestamp: Date().addingTimeInterval(-3000)),
            ],
            timestamp: Date().addingTimeInterval(-3600),
            isAnonymous: false
        ),
        NewsPost(
            id: UUID(),
            author: "최수진",
            authorTicker: "SUJIN",
            avatarColor: .green,
            title: "투두 100% 달성 꿀팁 공유",
            content: "매일 달성 가능한 작은 목표 4개로 시작하세요. 무리하지 않는 게 핵심입니다!",
            category: .tip,
            likes: 15,
            comments: [
                NewsComment(id: UUID(), author: "박지민", content: "좋은 팁이네요!", timestamp: Date().addingTimeInterval(-5400)),
                NewsComment(id: UUID(), author: "정민호", content: "저도 따라해볼게요", timestamp: Date().addingTimeInterval(-4800)),
            ],
            timestamp: Date().addingTimeInterval(-7200),
            isAnonymous: false
        ),
        NewsPost(
            id: UUID(),
            author: "이영희",
            authorTicker: "YOUNG",
            avatarColor: .pink,
            title: "카지노에서 30만P 날렸습니다...",
            content: "룰렛에서 연속으로 잃었네요... 카지노 하지 마세요 진심으로...",
            category: .free,
            likes: 23,
            comments: [
                NewsComment(id: UUID(), author: "김철수", content: "ㅋㅋㅋㅋ 저도요...", timestamp: Date().addingTimeInterval(-10800)),
            ],
            timestamp: Date().addingTimeInterval(-14400),
            isAnonymous: false
        ),
        NewsPost(
            id: UUID(),
            author: "정민호",
            authorTicker: "MINHO",
            avatarColor: .purple,
            title: "이번 주 수익률 TOP 3 예측",
            content: "박지민: 투두 완성률 높아서 급등 예상\n김철수: 꾸준한 상승세\n최수진: 100% 달성 자주 함",
            category: .analysis,
            likes: 18,
            comments: [],
            timestamp: Date().addingTimeInterval(-28800),
            isAnonymous: false
        ),
    ]
}

// MARK: - NewsComment
struct NewsComment: Identifiable, Hashable {
    let id: UUID
    var author: String
    var content: String
    var timestamp: Date

    var timeAgo: String {
        let interval = Date().timeIntervalSince(timestamp)
        if interval < 60 { return "방금 전" }
        if interval < 3600 { return "\(Int(interval / 60))분 전" }
        if interval < 86400 { return "\(Int(interval / 3600))시간 전" }
        return "\(Int(interval / 86400))일 전"
    }
}

// MARK: - NewsCategory
enum NewsCategory: String, CaseIterable, Codable {
    case all = "전체"
    case free = "자유"
    case analysis = "분석"
    case tip = "꿀팁"
    case discussion = "토론"

    var icon: String {
        switch self {
        case .all: return "square.grid.2x2"
        case .free: return "bubble.left.fill"
        case .analysis: return "chart.bar.fill"
        case .tip: return "lightbulb.fill"
        case .discussion: return "text.bubble.fill"
        }
    }

    var color: Color {
        switch self {
        case .all: return .gray
        case .free: return .cyan
        case .analysis: return .blue
        case .tip: return .yellow
        case .discussion: return .green
        }
    }
}

// MARK: - BetType
enum BetType: String {
    case success = "성공"
    case failure = "실패"

    var color: Color {
        switch self {
        case .success: return .green
        case .failure: return .red
        }
    }
}


