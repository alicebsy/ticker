import SwiftUI

@main
struct HumanStockMarketApp: App {
    @StateObject private var appState = AppState()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(appState)
                .frame(minWidth: 1000, minHeight: 700)
        }
        .windowStyle(.hiddenTitleBar)
        .commands {
            SidebarCommands()
        }

        Settings {
            SettingsView()
        }
    }
}

// MARK: - App State
class AppState: ObservableObject {
    // Auth
    @Published var isLoggedIn: Bool = false
    @Published var currentUser: User? = nil
    @Published var selectedTab: SidebarTab = .portfolio
    @Published var visibility: PortfolioVisibility = .publicVisible

    // 경제 시스템
    @Published var cash: Int = 100_000 // Changed to Int to match User model
    @Published var dailyChange: Double = 0.0

    // MARK: - Auth Actions
    @MainActor
    func signup(request: SignupRequest) async throws {
        let response = try await NetworkManager.shared.signup(request: request)
        self.handleAuthResponse(response)
    }

    @MainActor
    func login(request: LoginRequest) async throws {
        let response = try await NetworkManager.shared.login(request: request)
        self.handleAuthResponse(response)
    }

    private func handleAuthResponse(_ response: LoginResponse) {
        self.currentUser = User(
            id: response.id,
            name: response.name,
            loginId: response.loginId,
            profileImage: response.profileImageUrl,
            loginMethod: .guest, // Defaulting for now
            cashBalance: response.cashBalance,
            marketCap: response.marketCap,
            totalAssets: response.totalAssets,
            stockPrice: 1000 // Default or derived
        )
        self.cash = response.cashBalance
        self.isLoggedIn = true
    }

    // 내 주식 정보 (유저 = 기업)
    @Published var userStockPrice: Double = 1_000
    let myTotalShares: Int = 100
    let myFounderShares: Int = 70
    let myFloatShares: Int = 30
    @Published var mySharesOutstanding: Int = 0
    @Published var myTradingVolume: Double = 0

    // 내 투두 / 상장 기록
    @Published var myTodayRecord: DailyRecord? = nil
    @Published var myDailyRecords: [DailyRecord] = []
    @Published var myPriceHistory: [PriceHistoryPoint] = Friend.generateSamplePriceHistory(basePrice: 1000)
    @Published var userStockHistory: [Double] = [
        700, 750, 800, 830, 870, 900, 920, 950, 980, 1000
    ]

    // 보유 종목 & 친구
    @Published var holdings: [Holding] = []
    @Published var friends: [Friend] = Friend.sampleData // Keep friends for now so the market isn't empty?
    // Wait, if friends are empty, the "All Stocks" view will be empty. The user might want to see stocks to buy.
    // The "Holdings" (Invested Stocks) should be empty. "Friends" (Market items) should probably stay as sample data for now if there is no backend for fetching logic friends list yet.
    // The user complained about "Invested Stocks" (holdings).
    // So I will only clear 'holdings'.

    @Published var friendRequests: [FriendRequest] = []
    @Published var myFriendCode: String = {
        let code = Int.random(in: 1000...9999)
        return "TICKER-\(String(format: "%04d", code))"
    }()

    // 뉴스 / 커뮤니티
    @Published var newsPosts: [NewsPost] = NewsPost.sampleData

    // 활동 내역
    @Published var activities: [Activity] = []

    // 스토어
    @Published var storeItems: [StoreItem] = StoreItem.sampleData
    @Published var mySkills: [String: Int] = ["시간 정지": 3, "도박 취소권": 1, "룰렛 추가 기회권": 2]

    // MARK: - 시가총액 (내 가치)
    var myMarketCap: Double {
        userStockPrice * Double(myTotalShares)
    }

    var myAvailableShares: Int {
        myFloatShares - mySharesOutstanding
    }

    // MARK: - 총 자산 = 보유 현금 + (내 주가 × 70주) + 타인 투자 평가액
    var totalInvestedInOthers: Double {
        holdings.reduce(0) { $0 + $1.currentPrice * Double($1.quantity) }
    }

    var totalAssets: Double {
        Double(cash) + (userStockPrice * Double(myFounderShares)) + totalInvestedInOthers
    }

    // MARK: - 장 운영 시간 (10시 ~ 24시)
    var isMarketOpen: Bool {
        let calendar = Calendar.current
        let hour = calendar.component(.hour, from: Date())
        return hour >= 10  // 10시부터 24시(0시)까지 거래 가능
    }

    var marketStatusText: String {
        isMarketOpen ? "장 운영 중" : "준비 중 (10시 개장)"
    }

    // MARK: - 주식 매수 (사람 단위)
    @discardableResult
    func buyStock(friendName: String, quantity: Int, pricePerShare: Double) -> Bool {
        let totalCost = pricePerShare * Double(quantity)
        guard cash >= Int(totalCost) else { return false }
        // 가용 주식 수 확인
        guard let friendIndex = friends.firstIndex(where: { $0.name == friendName }) else { return false }
        guard friends[friendIndex].availableShares >= quantity else { return false }

        // 현금 차감
        cash -= Int(totalCost)

        // 친구의 outstanding 증가 + 거래대금 추가
        friends[friendIndex].sharesOutstanding += quantity
        friends[friendIndex].tradingVolume += totalCost

        // 홀딩 업데이트 또는 생성
        if let holdingIndex = holdings.firstIndex(where: { $0.name == friendName }) {
            let existingValue = holdings[holdingIndex].averageBuyPrice * Double(holdings[holdingIndex].quantity)
            let newValue = pricePerShare * Double(quantity)
            let totalQty = holdings[holdingIndex].quantity + quantity
            holdings[holdingIndex].averageBuyPrice = (existingValue + newValue) / Double(totalQty)
            holdings[holdingIndex].quantity += quantity
            holdings[holdingIndex].currentPrice = pricePerShare
        } else {
            let friend = friends[friendIndex]
            let newHolding = Holding(
                id: UUID(),
                name: friendName,
                ticker: friend.ticker,
                currentPrice: pricePerShare,
                change: friend.change,
                quantity: quantity,
                avatarColor: friend.avatarColor,
                sparklineData: friend.sparklineData,
                averageBuyPrice: pricePerShare
            )
            holdings.append(newHolding)
        }

        addActivity(type: .buy, description: "\(friendName) \(quantity)주 매수", amount: Int(totalCost))
        return true
    }

    // MARK: - 주식 매도 (사람 단위)
    @discardableResult
    func sellStock(friendName: String, quantity: Int, pricePerShare: Double) -> Bool {
        guard let holdingIndex = holdings.firstIndex(where: { $0.name == friendName }) else { return false }
        let currentQty = holdings[holdingIndex].quantity
        guard currentQty >= quantity else { return false }

        let totalRevenue = pricePerShare * Double(quantity)

        // 홀딩 수량 차감
        holdings[holdingIndex].quantity -= quantity
        if holdings[holdingIndex].quantity <= 0 {
            holdings.remove(at: holdingIndex)
        }

        // 현금 추가
        cash += Int(totalRevenue)

        // 친구의 outstanding 감소 + 거래대금 추가
        if let friendIndex = friends.firstIndex(where: { $0.name == friendName }) {
            friends[friendIndex].sharesOutstanding -= quantity
            friends[friendIndex].tradingVolume += totalRevenue
        }

        addActivity(type: .sell, description: "\(friendName) \(quantity)주 매도", amount: Int(totalRevenue))
        return true
    }

    // MARK: - 투두 상장
    @discardableResult
    func listTodayTodos(items: [TodoItem]) -> Bool {
        guard items.count >= 4 else { return false }
        let record = DailyRecord(
            date: Date(),
            todoItems: items,
            isListed: true,
            priceChangePercent: nil
        )
        myTodayRecord = record
        addActivity(type: .listing, description: "오늘의 투두 \(items.count)개 상장", amount: 0)
        return true
    }

    // MARK: - 투두 완성
    func completeTodoItem(itemId: UUID) {
        guard var record = myTodayRecord,
              let index = record.todoItems.firstIndex(where: { $0.id == itemId }) else { return }
        record.todoItems[index].isCompleted = true
        record.todoItems[index].completedAt = Date()
        myTodayRecord = record
    }

    // MARK: - 투두 완성 취소
    func uncompleteTodoItem(itemId: UUID) {
        guard var record = myTodayRecord,
              let index = record.todoItems.firstIndex(where: { $0.id == itemId }) else { return }
        record.todoItems[index].isCompleted = false
        record.todoItems[index].completedAt = nil
        myTodayRecord = record
    }

    // MARK: - 자정 정산 (주가 변동)
    func settleDailyPrices() {
        guard var record = myTodayRecord else { return }

        let changePercent = record.projectedPriceChange
        userStockPrice *= (1.0 + changePercent)
        userStockPrice = max(100, userStockPrice) // 최소 100원

        record.priceChangePercent = changePercent
        myDailyRecords.append(record)
        myTodayRecord = nil
        userStockHistory.append(userStockPrice)
        myPriceHistory.append(PriceHistoryPoint(date: Date(), price: userStockPrice))
        dailyChange = changePercent * 100
    }

    // MARK: - 랭킹 (총 자산 기준)
    struct RankingEntry: Identifiable {
        let id = UUID()
        var rank: Int
        var name: String
        var totalAssets: Double
        var change: Double
        var isMe: Bool
    }

    var friendRankings: [RankingEntry] {
        var entries: [RankingEntry] = []

        // 나 추가
        entries.append(RankingEntry(
            rank: 0,
            name: currentUser?.name ?? "나",
            totalAssets: totalAssets,
            change: dailyChange,
            isMe: true
        ))

        // 친구들 추가 (시가총액 기준 - 클라이언트에서는 정확한 총 자산을 알 수 없으므로)
        for friend in friends {
            entries.append(RankingEntry(
                rank: 0,
                name: friend.name,
                totalAssets: friend.marketCap + 100_000, // 시가총액 + 초기 현금 추정
                change: friend.change,
                isMe: false
            ))
        }

        // 정렬 및 순위 부여
        entries.sort { $0.totalAssets > $1.totalAssets }
        for i in entries.indices {
            entries[i].rank = i + 1
        }

        return entries
    }

    // MARK: - 스토어 구매
    @discardableResult
    func purchaseStoreItem(item: StoreItem) -> Bool {
        guard cash >= item.price else { return false }

        cash -= item.price

        if let existing = mySkills[item.name] {
            mySkills[item.name] = existing + 1
        } else {
            mySkills[item.name] = 1
        }

        addActivity(type: .purchase, description: "'\(item.name)' 구매", amount: item.price)
        return true
    }

    // MARK: - 카지노 베팅
    @discardableResult
    func placeBet(amount: Int, target: String, betType: BetType) -> Bool {
        guard cash >= amount else { return false }

        cash -= amount

        addActivity(type: .bet, description: "\(target)에게 '\(betType.rawValue)' 베팅", amount: amount)
        return true
    }

    // MARK: - 활동 내역
    func addActivity(type: ActivityType, description: String, amount: Int) {
        let activity = Activity(type: type, description: description, amount: amount, time: "방금 전", timestamp: Date())
        activities.insert(activity, at: 0)

        if activities.count > 50 {
            activities = Array(activities.prefix(50))
        }
    }

    func logout() {
        withAnimation(.easeInOut(duration: 0.3)) {
            isLoggedIn = false
            currentUser = nil
        }
    }
}

// MARK: - Sample Data Extensions
extension DailyRecord {
    static func sampleRecords() -> [DailyRecord] {
        let sampleTodos = [
            ["알고리즘 3문제 풀기", "운동 30분", "독서 1시간", "코딩 프로젝트"],
            ["영어 공부", "블로그 글쓰기", "운동", "요리하기"],
            ["미팅 준비", "보고서 작성", "운동", "독서", "일기 쓰기"],
            ["코딩 연습", "운동", "공부", "정리정돈"],
            ["프로젝트 개발", "러닝 5km", "독서", "영어 회화"],
            ["데이터 분석", "운동", "블로그", "코드 리뷰"],
            ["알고리즘 풀기", "운동 1시간", "독서", "스터디 참여"],
        ]

        return (0..<7).map { i in
            let date = Calendar.current.date(byAdding: .day, value: -(7 - i), to: Date()) ?? Date()
            let todos = sampleTodos[i % sampleTodos.count]
            let completedCount = Int.random(in: 1...todos.count)
            let items = todos.enumerated().map { index, title in
                TodoItem(title: title, isCompleted: index < completedCount)
            }
            let rate = Double(completedCount) / Double(todos.count)
            let change: Double
            if rate >= 1.0 { change = Double.random(in: 0.10...0.15) }
            else if rate >= 0.75 { change = 0.05 }
            else if rate >= 0.50 { change = 0.0 }
            else if rate >= 0.25 { change = -0.10 }
            else { change = -0.20 }

            return DailyRecord(
                date: date,
                todoItems: items,
                isListed: true,
                priceChangePercent: change
            )
        }
    }
}

extension PriceHistoryPoint {
    static func sampleHistory(currentPrice: Double) -> [PriceHistoryPoint] {
        var history: [PriceHistoryPoint] = []
        var price = currentPrice * 0.7
        for i in 0..<10 {
            let date = Calendar.current.date(byAdding: .day, value: -(10 - 1 - i), to: Date()) ?? Date()
            price *= Double.random(in: 0.93...1.10)
            price = max(100, price)
            history.append(PriceHistoryPoint(date: date, price: price))
        }
        if !history.isEmpty {
            history[history.count - 1] = PriceHistoryPoint(date: Date(), price: currentPrice)
        }
        return history
    }
}



// MARK: - Sidebar Tab Enum
enum SidebarTab: String, CaseIterable, Identifiable {
    case portfolio = "포트폴리오"
    case listing = "상장"
    case holdings = "보유 종목"
    case allStocks = "모든 종목"
    case store = "암시장"
    case casino = "카지노"
    case news = "뉴스"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .portfolio: return "chart.pie.fill"
        case .listing: return "plus.circle.fill"
        case .holdings: return "briefcase.fill"
        case .allStocks: return "person.3.fill"
        case .store: return "bag.fill"
        case .casino: return "dice.fill"
        case .news: return "newspaper.fill"
        }
    }

    var color: Color {
        switch self {
        case .portfolio: return .blue
        case .listing: return .green
        case .holdings: return .orange
        case .allStocks: return .yellow
        case .store: return .purple
        case .casino: return .pink
        case .news: return .cyan
        }
    }
}

// MARK: - Portfolio Visibility
enum PortfolioVisibility {
    case publicVisible, privateOnly

    var label: String {
        switch self {
        case .publicVisible: return "공개"
        case .privateOnly: return "비공개"
        }
    }

    var icon: String {
        switch self {
        case .publicVisible: return "globe"
        case .privateOnly: return "lock"
        }
    }
}
