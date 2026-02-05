import SwiftUI

@main
struct HumanStockMarketApp: App {
    @StateObject private var appState = AppState()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(appState)
                .frame(minWidth: 1000, minHeight: 700)
                .onOpenURL { url in
                    print("🚀 앱이 URL을 받았습니다: \(url.absoluteString)")
                    handleOAuthCallback(url: url)
                }
        }
        .windowStyle(.hiddenTitleBar)
        .commands {
            SidebarCommands()
        }
        // WindowGroup 레벨에서 URL 처리 (더 안정적)
        .handlesExternalEvents(matching: Set(arrayLiteral: "ticker")) // macOS 전용 팁
    }

    private func handleOAuthCallback(url: URL) {
        // ticker://oauth?userId=33
        print("🔍 URL 스킴 확인: \(url.scheme ?? "nil"), 호스트: \(url.host ?? "nil")")
        
        guard url.scheme == "ticker",
              url.host == "oauth",
              let components = URLComponents(url: url, resolvingAgainstBaseURL: false) else {
            print("❌ 잘못된 URL 형식입니다.")
            return
        }
        
        if let userIdString = components.queryItems?.first(where: { $0.name == "userId" })?.value,
           let userId = Int(userIdString) {
            print("✅ 유저 ID 파싱 성공: \(userId). 로그인 처리를 시작합니다.")
            Task {
                await appState.handleKakaoOAuthCallback(userId: userId)
            }
        } else {
            print("❌ userId를 찾을 수 없거나 형식이 잘못되었습니다.")
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
        NetworkManager.shared.currentUserId = response.id
        
        self.currentUser = User(
            id: response.id,
            name: response.name,
            loginId: response.loginId,
            profileImage: response.profileImageUrl,
            loginMethod: .email,
            cashBalance: response.cashBalance,
            marketCap: response.marketCap,
            totalAssets: response.totalAssets,
            stockPrice: response.stockPrice,
            friendCode: response.friendCode
        )
        self.cash = response.cashBalance
        self.userStockPrice = Double(response.stockPrice)
        self.isLoggedIn = true
        
        setupWebSocket(userId: response.id)
        
        Task {
            await fetchMyData()
        }
    }

    /// 카카오 OAuth 콜백: userId로 유저 정보 조회 후 로그인 처리
    @MainActor
    func handleKakaoOAuthCallback(userId: Int) async {
        do {
            let userResponse = try await NetworkManager.shared.fetchUser(userId: userId)
            NetworkManager.shared.currentUserId = userResponse.id
            
            self.currentUser = User(
                id: userResponse.id,
                name: userResponse.name,
                loginId: userResponse.loginId,
                profileImage: userResponse.profileImageUrl,
                loginMethod: .kakao,
                cashBalance: userResponse.cashBalance,
                marketCap: userResponse.marketCap,
                totalAssets: userResponse.totalAssets,
                stockPrice: userResponse.stockPrice,
                friendCode: userResponse.friendCode
            )
            self.cash = userResponse.cashBalance
            self.userStockPrice = Double(userResponse.stockPrice)
            self.isLoggedIn = true
            
            setupWebSocket(userId: userResponse.id)
            
            await fetchMyData()
        } catch {
            print("카카오 로그인 콜백 에러: \(error.localizedDescription)")
        }
    }
    
    // MARK: - Real-time (WebSocket) Handlers
    private func setupWebSocket(userId: Int) {
        WebSocketManager.shared.onMessageReceived = { [weak self] notification in
            self?.handleRealTimeNotification(notification)
        }
        WebSocketManager.shared.onNewsCommentReceived = { [weak self] postId, commentDto in
            Task { @MainActor in
                self?.appendNewsCommentFromSocket(postId: postId, commentDto: commentDto)
            }
        }
        WebSocketManager.shared.connect(userId: userId)
    }

    /// 뉴스 글 상세 보는 중일 때 해당 글의 댓글 소켓 구독 (실시간 반영)
    func subscribeToNewsComments(postId: Int) {
        WebSocketManager.shared.subscribe(to: "/topic/news/\(postId)/comments")
    }

    @MainActor
    private func appendNewsCommentFromSocket(postId: Int, commentDto: NewsCommentDto) {
        let comment = commentDto.toNewsComment()
        if let idx = newsPosts.firstIndex(where: { $0.id == postId }) {
            if !newsPosts[idx].comments.contains(where: { $0.id == comment.id }) {
                newsPosts[idx].comments.append(comment)
            }
        }
        if var cached = newsPostDetailCache[postId], !cached.comments.contains(where: { $0.id == comment.id }) {
            cached.comments.append(comment)
            newsPostDetailCache[postId] = cached
        }
    }
    
    private func handleRealTimeNotification(_ notification: NotificationDto) {
        print("🔔 Real-time Notification: \(notification.type) - \(notification.message)")
        
        guard let type = NotificationType(rawValue: notification.type) else { return }
        
        switch type {
        case .stockPriceUpdated:
            handleStockPriceUpdate(notification)
        case .listingUpdated:
            // Refresh data to show new progress/completion
            Task { await fetchMyData() }
        case .investmentChanged:
            // Refresh data to show updated shares/holdings
            Task { await fetchMyData() }
        case .friendRequest, .friendAccepted, .friendRejected:
            // Refresh watchlist/request items
            Task { await fetchMyData() }
        case .betPlaced, .addedToWatchlist:
            // Could show a toast or local notification
            print("Toast: \(notification.message)")
        case .prophecyClosed, .prophecyBetResult:
            // 예언 관련 알림 - 데이터 새로고침 및 알림 표시
            Task {
                await fetchProphecyData()
                await fetchMyData()
            }
            // 알림 메시지 표시 (향후 토스트나 배너로 개선 가능)
            print("🎲 Prophecy Notification: \(notification.message)")
        }
    }
    
    private func handleStockPriceUpdate(_ notification: NotificationDto) {
        guard let userId = notification.userId, let newPrice = notification.stockPrice else { return }
        
        // 1. Update own price if it's mine
        if userId == currentUser?.id {
            DispatchQueue.main.async {
                self.userStockPrice = Double(newPrice)
                self.currentUser?.stockPrice = newPrice
                // Append to history for live chart
                self.userStockHistory.append(Double(newPrice))
                if self.userStockHistory.count > 20 { self.userStockHistory.removeFirst() }
            }
        }
        
        // 2. Update friend's price in watchlist
        if let index = self.friends.firstIndex(where: { $0.userId == userId }) {
            DispatchQueue.main.async {
                self.friends[index].currentPrice = Double(newPrice)
                if let totalAssets = notification.totalAssets {
                    self.friends[index].backendTotalAssets = Double(totalAssets)
                }
                self.friends[index].sparklineData.append(Double(newPrice))
                if self.friends[index].sparklineData.count > 20 { self.friends[index].sparklineData.removeFirst() }
            }
        }
    }
    
    @MainActor
    func fetchMyData() async {
        do {
            // 0. Update My Profile (to get latest friendCode, etc.)
            if let userId = currentUser?.id {
                let userResponse = try await NetworkManager.shared.fetchUser(userId: userId)
                self.currentUser?.friendCode = userResponse.friendCode
                self.currentUser?.cashBalance = userResponse.cashBalance
                self.currentUser?.stockPrice = userResponse.stockPrice
            }
            
            // 1. Portfolio
            let portfolio: PortfolioResponse = try await NetworkManager.shared.request("/portfolio")
            self.cash = portfolio.cashBalance
            self.myTradingVolume = 0 // Backend doesn't send this yet?
            // Update other assets if needed
            
            // 2. Holdings
            let heldResponse: HeldStocksResponse = try await NetworkManager.shared.request("/investments")
            
            self.holdings = heldResponse.stocks.map { dto in
                let totalVal = Double(dto.currentPrice * dto.quantity)
                let profit = Double(dto.profitLoss)
                let cost = totalVal - profit
                let avgPrice = dto.quantity > 0 ? cost / Double(dto.quantity) : 0

                let changePct = cost > 0 ? (profit / cost) * 100 : 0.0

                return Holding(
                    id: UUID(),
                    investmentId: dto.id, // Store backend investment ID
                    name: dto.ownerName,
                    ticker: String(dto.ownerName.prefix(2)),
                    currentPrice: Double(dto.currentPrice),
                    change: changePct,
                    quantity: dto.quantity,
                    avatarColor: .blue,
                    sparklineData: [],
                    averageBuyPrice: avgPrice
                )
            }
            // 3. Watchlist (Friends & Requests)
            let watchlistResponse: WatchlistResponse = try await NetworkManager.shared.request("/watchlist")
            
            self.friends = watchlistResponse.watchlistItems.map { dto in
                // Subscribe to each friend's stock updates
                WebSocketManager.shared.subscribe(to: "/topic/stock/\(dto.userId)")
                
                // Generate sparkline from dto.chartData
                let sparkline = dto.chartData.map { Double($0) }
                
                // sharesOutstanding = 30 - remainingShares
                let remaining = dto.remainingShares ?? 30
                let outstanding = 30 - remaining

                return Friend(
                    id: UUID(),
                    userId: dto.userId,
                    name: dto.name,
                    ticker: dto.name.prefix(2).uppercased(),
                    currentPrice: Double(dto.currentPrice),
                    change: parseChangePercent(dto.changePercent),
                    bio: "",
                    avatarColor: .gray,
                    sparklineData: sparkline,
                    priceHistory: [],
                    isStarred: true,
                    sharesOutstanding: outstanding,
                    tradingVolume: 0,
                    backendTotalAssets: dto.totalAssets.map { Double($0) },
                    todayRecord: nil,
                    dailyRecords: []
                )
            }
            
            // Sync Friend Requests
            var combinedRequests: [FriendRequest] = []
            
            // Received Requests (Need to Accept/Reject)
            for req in watchlistResponse.receivedRequests {
                combinedRequests.append(FriendRequest(
                    id: UUID(),
                    requestId: req.id,
                    userId: nil, // We don't have userId in FriendRequestDto, but we have req.id which is request id?
                    // Actually, looking at WatchlistResponse.java, it's a List of FriendRequestDto.
                    // FriendRequestDto inside WatchlistResponse has: Long id, String name, String imageUrl, String status.
                    // The 'id' here is likely the USER ID of the person who sent the request (requester).
                    // Wait, let's check WatchlistController again.
                    // acceptFriend(@PathVariable Long requesterId) - so 'id' should be the requester's user ID.
                    name: req.name,
                    avatarColor: .blue,
                    isSentByMe: false
                ))
            }
            
            // Sent Requests (Waiting for them)
            for req in watchlistResponse.sentRequests {
                combinedRequests.append(FriendRequest(
                    id: UUID(),
                    requestId: req.id,
                    userId: nil,
                    name: req.name,
                    avatarColor: .gray,
                    isSentByMe: true
                ))
            }
            
            self.friendRequests = combinedRequests
            // 뉴스는 뉴스 탭에서만 로드 (fetchMyData마다 덮어쓰면 댓글 등이 사라짐)
            // 4. Listing (My Stock & Todos)
            let listingResponse: ListingResponse = try await NetworkManager.shared.request("/listing")
            
            // Map listedTodos to DailyRecord (LISTED + COMPLETED 모두 포함)
            if !listingResponse.listedTodos.isEmpty {
                let items = listingResponse.listedTodos.map { dto in
                    let isCompleted = dto.completed ?? (dto.progress >= 100)
                    return TodoItem(
                        id: UUID(), // Local UI ID
                        backendId: dto.id,
                        title: dto.name,
                        isCompleted: isCompleted,
                        completedAt: isCompleted ? Date() : nil
                    )
                }

                self.myTodayRecord = DailyRecord(
                    date: Date(),
                    todoItems: items,
                    isListed: true,
                    priceChangePercent: nil // Calculated from server if needed, or fetched from chart
                )
            } else {
                self.myTodayRecord = nil
            }
            
            // Update My Stock Info
            // ListingResponse.myStockChart
            let chartDto = listingResponse.myStockChart
            self.userStockPrice = Double(chartDto.currentPrice)
            self.dailyChange = parseChangePercent(chartDto.changePercent)
            
            // Update Chart
            self.myPriceHistory = chartDto.chartData.map { point in
                // Parse date string
                let formatter = DateFormatter()
                formatter.dateFormat = "yyyy-MM-dd"
                let date = formatter.date(from: point.date) ?? Date()
                return PriceHistoryPoint(date: date, price: Double(point.price))
            }
            // Sparkline
            self.userStockHistory = self.myPriceHistory.map { $0.price }
            
        } catch {
            print("Failed to fetch data: \(error)")
        }
    }
    
    // Helper to parse "+3.50%" string to Double
    func parseChangePercent(_ str: String) -> Double {
        let clean = str.replacingOccurrences(of: "%", with: "")
        return Double(clean) ?? 0.0
    }

    // 내 주식 정보 (유저 = 기업)
    @Published var userStockPrice: Double = 1_000
    private var lastClosingPrice: Double = 1_000 // 어제 종가 (오늘 변동폭 기준)

    let myTotalShares: Int = 100
    let myFounderShares: Int = 70
    let myFloatShares: Int = 30
    @Published var mySharesOutstanding: Int = 0
    @Published var myTradingVolume: Double = 0

    // 내 투두 / 상장 기록
    @Published var myTodayRecord: DailyRecord? = nil
    @Published var myDailyRecords: [DailyRecord] = []
    
    // 차트 데이터 (2026년 2월 2일부터 시작)
    @Published var myPriceHistory: [PriceHistoryPoint] = [
        PriceHistoryPoint(
            date: Calendar.current.date(from: DateComponents(year: 2026, month: 2, day: 2))!,
            price: 1000
        )
    ]
    
    // 단순 Sparkline용 (호환성 유지)
    @Published var userStockHistory: [Double] = [1000]

    // 보유 종목 & 친구
    @Published var holdings: [Holding] = []
    @Published var friends: [Friend] = Friend.sampleData // Keep friends for now so the market isn't empty?
    // Wait, if friends are empty, the "All Stocks" view will be empty. The user might want to see stocks to buy.
    // The "Holdings" (Invested Stocks) should be empty. "Friends" (Market items) should probably stay as sample data for now if there is no backend for fetching logic friends list yet.
    // The user complained about "Invested Stocks" (holdings).
    // So I will only clear 'holdings'.

    @Published var friendRequests: [FriendRequest] = []
    
    // Casino & Dark Market
    @Published var casinoFriends: [CasinoFriend] = []
    @Published var bettingHistory: [BettingHistory] = []
    @Published var marketItems: [MarketItem] = []

    // Prophecy (사용자 정의 예언)
    @Published var myProphecies: [Prophecy] = []
    @Published var bettableProphecies: [Prophecy] = []
    @Published var myProphecyBets: [ProphecyBet] = []
    
    var myFriendCode: String {
        if let code = currentUser?.friendCode, !code.isEmpty {
            return code
        }
        return "코드 없음"
    }

    // 뉴스 / 커뮤니티 (서버에서 로드)
    @Published var newsPosts: [NewsPost] = []
    /// 글 상세(댓글 포함) 캐시. 탭/카테고리 전환해도 댓글이 유지되도록.
    @Published var newsPostDetailCache: [Int: NewsPost] = [:]
    /// 목록 + 캐시 병합: 캐시에 있으면 댓글 포함된 글 사용
    var mergedNewsPosts: [NewsPost] {
        newsPosts.map { newsPostDetailCache[$0.id] ?? $0 }
    }

    // 활동 내역
    @Published var activities: [TickerActivity] = []

    // 스토어
    // 스토어
    @Published var storeItems: [StoreItem] = StoreItem.sampleData
    @Published var mySkills: [String: Int] = ["시간 정지": 3, "도박 취소권": 1, "룰렛 추가 기회권": 2]

    init() {
        loadData()
        checkNewDay()
    }

    // MARK: - Persistence Logic
    private let defaults = UserDefaults.standard
    private let recordsKey = "myDailyRecords"
    private let priceHistoryKey = "myPriceHistory"
    private let userStockPriceKey = "userStockPrice"
    private let lastClosingPriceKey = "lastClosingPrice"
    private let cashKey = "userCash"
    private let todayRecordKey = "myTodayRecord"

    private func saveData() {
        if let encodedRecords = try? JSONEncoder().encode(myDailyRecords) {
            defaults.set(encodedRecords, forKey: recordsKey)
        }
        if let encodedHistory = try? JSONEncoder().encode(myPriceHistory) {
            defaults.set(encodedHistory, forKey: priceHistoryKey)
        }
        if let encodedToday = try? JSONEncoder().encode(myTodayRecord) {
            defaults.set(encodedToday, forKey: todayRecordKey)
        }
        defaults.set(userStockPrice, forKey: userStockPriceKey)
        defaults.set(lastClosingPrice, forKey: lastClosingPriceKey)
        defaults.set(cash, forKey: cashKey)
    }

    private func loadData() {
        if let data = defaults.data(forKey: recordsKey),
           let decoded = try? JSONDecoder().decode([DailyRecord].self, from: data) {
            myDailyRecords = decoded
        }
        if let data = defaults.data(forKey: priceHistoryKey),
           let decoded = try? JSONDecoder().decode([PriceHistoryPoint].self, from: data) {
            myPriceHistory = decoded
        }
        if let data = defaults.data(forKey: todayRecordKey),
           let decoded = try? JSONDecoder().decode(DailyRecord.self, from: data) {
            myTodayRecord = decoded
        }
        let savedPrice = defaults.double(forKey: userStockPriceKey)
        if savedPrice > 0 { userStockPrice = savedPrice }
        
        let savedClosing = defaults.double(forKey: lastClosingPriceKey)
        if savedClosing > 0 { lastClosingPrice = savedClosing }

        let savedCash = defaults.integer(forKey: cashKey)
        if savedCash > 0 { cash = savedCash }
    }

    private func checkNewDay() {
        guard let record = myTodayRecord else { return }
        
        let calendar = Calendar.current
        if !calendar.isDate(record.date, inSameDayAs: Date()) {
            print("📅 날짜 변경 감지: \(record.date) -> \(Date())")
            print("💾 어제 기록을 자동으로 정산하고 저장합니다.")
            
            // 어제 기록 정산 (저장소 이동)
            settleDailyPrices()
            
            // 정산 후에는 myTodayRecord가 nil이 되므로, 화면이 비워짐
            // 그리고 새로운 하루를 위해 lastClosingPrice가 확정됨.
        }
    }

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
    @MainActor
    func buyStock(friendName: String, quantity: Int, pricePerShare: Double) async -> (success: Bool, errorMessage: String?) {
        guard let friend = friends.first(where: { $0.name == friendName }) else {
            return (false, "친구를 찾을 수 없습니다.")
        }
        let subjectUserId = friend.userId

        let req = InvestRequest(subjectUserId: subjectUserId, quantity: quantity)

        do {
            try await NetworkManager.shared.requestVoid("/investments/buy", method: "POST", body: req)
            await fetchMyData()
            return (true, nil)
        } catch {
            print("Buy failed: \(error)")
            return (false, error.localizedDescription)
        }
    }

    // MARK: - 주식 매도 (사람 단위)
    @MainActor
    func sellStock(friendName: String, quantity: Int, pricePerShare: Double) async -> (success: Bool, errorMessage: String?) {
        guard let holding = holdings.first(where: { $0.name == friendName }),
              let invId = holding.investmentId else {
            return (false, "보유 종목을 찾을 수 없습니다.")
        }

        do {
            try await NetworkManager.shared.requestVoid("/investments/\(invId)/sell?quantity=\(quantity)", method: "POST")
            await fetchMyData()
            return (true, nil)
        } catch {
            print("Sell failed: \(error)")
            return (false, error.localizedDescription)
        }
    }

    // MARK: - 친구 상장 데이터 조회
    @MainActor
    func fetchFriendListing(friendUserId: Int) async {
        guard let index = friends.firstIndex(where: { $0.userId == friendUserId }) else { return }

        do {
            let listingResponse: ListingResponse = try await NetworkManager.shared.fetchFriendListing(userId: friendUserId)

            // 투두 데이터 매핑
            if !listingResponse.listedTodos.isEmpty {
                let items = listingResponse.listedTodos.map { dto in
                    let isCompleted = dto.completed ?? (dto.progress >= 100)
                    return TodoItem(
                        id: UUID(),
                        backendId: dto.id,
                        title: dto.name,
                        isCompleted: isCompleted,
                        completedAt: isCompleted ? Date() : nil
                    )
                }

                friends[index].todayRecord = DailyRecord(
                    date: Date(),
                    todoItems: items,
                    isListed: true,
                    priceChangePercent: nil
                )
            } else {
                friends[index].todayRecord = nil
            }

            // 주가 차트 데이터 매핑
            let chartDto = listingResponse.myStockChart
            friends[index].currentPrice = Double(chartDto.currentPrice)
            friends[index].change = parseChangePercent(chartDto.changePercent)

            friends[index].priceHistory = chartDto.chartData.map { point in
                let formatter = DateFormatter()
                formatter.dateFormat = "yyyy-MM-dd"
                let date = formatter.date(from: point.date) ?? Date()
                return PriceHistoryPoint(date: date, price: Double(point.price))
            }

            friends[index].sparklineData = friends[index].priceHistory.map { $0.price }
        } catch {
            print("Failed to fetch friend listing for userId \(friendUserId): \(error)")
        }
    }

    // MARK: - 투두 상장
    @MainActor
    func listTodayTodos(items: [TodoItem]) async -> Bool {
        guard items.count >= 4 else { return false }
        
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        let deadline = formatter.string(from: Date())
        
        var successCount = 0
        for item in items {
            let req = ListingRequest(
                name: item.title,
                deadline: deadline,
                rewardPoints: nil,
                difficulty: "NORMAL",
                visibility: "FRIENDS_ONLY"
            )
            do {
                let _: Todo? = try await NetworkManager.shared.request("/listing", method: "POST", body: req)
                // We should probably explicitly type the response as Todo but Todo maps to ListedTodoDto partially.
                // Or we can use ListedTodoDto.
                // But createTodo returns 'Todo' model from backend. I need a matching struct?
                // Actually 'Todo' in models.swift is not defined matching backend Todo completely.
                // Let's assume it works or use void and refresh.
                // Backend returns 'Todo' entity.
                successCount += 1
            } catch {
                print("Failed to list todo: \(error)")
            }
        }
        
        if successCount > 0 {
            await fetchMyData()
            addActivity(type: .listing, description: "오늘의 투두 \(items.count)개 상장", amount: 0)
            return true
        }
        return false
    }

    // MARK: - 투두 완성
    @MainActor
    func completeTodoItem(itemId: UUID) async {
        guard let record = myTodayRecord,
              let item = record.todoItems.first(where: { $0.id == itemId }),
              let backendId = item.backendId else { 
            print("Cannot complete todo: missing backend ID")
            return 
        }
        
        do {
            try await NetworkManager.shared.requestVoid("/listing/\(backendId)/complete", method: "POST")
            await fetchMyData()
            
            // 실시간 주가 반영 (fetchMyData calls it)
        } catch {
            print("Failed to complete todo: \(error)")
        }
    }
    
    // MARK: - 투두 완성 취소
    @MainActor
    func uncompleteTodoItem(itemId: UUID) async {
        guard let record = myTodayRecord,
              let item = record.todoItems.first(where: { $0.id == itemId }),
              let backendId = item.backendId else {
            print("Cannot uncomplete todo: missing backend ID")
            return
        }

        do {
            try await NetworkManager.shared.requestVoid("/listing/\(backendId)/uncomplete", method: "POST")
            await fetchMyData()
        } catch {
            print("Failed to uncomplete todo: \(error)")
        }
    }

    // MARK: - 자정 정산 (주가 확정)
    func settleDailyPrices() {
        // Backend schedules this? 
        // Or client triggers it?
        // Backend sets up a scheduler but also exposes /api/listing/daily-stock-update
        // Client can trigger it for testing or reliable execution?
        // For now, let's keep it local or call backend.
        Task {
            try? await NetworkManager.shared.requestVoid("/listing/daily-stock-update", method: "POST")
            await fetchMyData()
        }
    }

    // MARK: - 친구 요청 관리
    @MainActor
    func acceptFriendRequest(requesterId: Int) async {
        do {
            try await NetworkManager.shared.acceptFriend(requesterId: requesterId)
            await fetchMyData()
        } catch {
            print("Failed to accept friend: \(error)")
        }
    }
    
    @MainActor
    func declineFriendRequest(requesterId: Int) async {
        do {
            try await NetworkManager.shared.rejectFriend(requesterId: requesterId)
            await fetchMyData()
        } catch {
            print("Failed to reject friend: \(error)")
        }
    }
    
    // MARK: - Casino & Dark Market
    @MainActor
    func fetchCasinoData() async {
        do {
            let (casinoRes, friendsRes) = try await (NetworkManager.shared.getCasino(), NetworkManager.shared.getWatchlistFriends())
            self.cash = casinoRes.bettingBalance
            self.casinoFriends = friendsRes.map { f in
                CasinoFriend(id: f.id, name: f.name, imageUrl: f.profileImageUrl, currentPrice: f.stockPrice ?? 1000)
            }
            self.bettingHistory = casinoRes.betHistory.map { b in
                BettingHistory(id: b.id, targetName: b.target ?? "", betAmount: b.amount, betType: b.type ?? "", result: b.result, profitLoss: b.profit)
            }
        } catch {
            print("Failed to fetch casino data: \(error)")
        }
    }
    
    @MainActor
    func fetchDarkMarketData() async {
        do {
            let response = try await NetworkManager.shared.getDarkMarket()
            self.marketItems = response.items
            
            // Map MarketItem (Backend) to StoreItem (UI)
            self.storeItems = response.items.map { item in
                StoreItem(
                    id: UUID(), // Or store itemId separately
                    backendId: item.id,
                    name: item.name,
                    description: item.description,
                    price: item.price,
                    icon: getIconForItem(category: item.category),
                    rarity: getRarityForItem(category: item.category, price: item.price),
                    category: mapBackendCategory(item.category)
                )
            }
        } catch {
            print("Failed to fetch dark market data: \(error)")
        }
    }
    
    private func getIconForItem(category: String) -> String {
        switch category {
        case "SKILL": return "sparkles"
        case "ITEM": return "bag.fill"
        case "BOOST": return "bolt.fill"
        case "SECRET": return "person.fill.questionmark"
        default: return "cube.fill"
        }
    }
    
    private func getRarityForItem(category: String, price: Int) -> ItemRarity {
        if price > 40000 { return .legendary }
        if price > 20000 { return .epic }
        if price > 10000 { return .rare }
        return .common
    }
    
    private func mapBackendCategory(_ cat: String) -> StoreCategory {
        switch cat {
        case "SKILL": return .skill
        case "ITEM": return .item
        case "BOOST": return .boost
        case "SECRET": return .secret
        default: return .item
        }
    }
    
    // MARK: - Prophecy (사용자 정의 예언)

    @MainActor
    func fetchProphecyData() async {
        do {
            async let myPropheciesTask = NetworkManager.shared.getMyProphecies()
            async let bettableTask = NetworkManager.shared.getBettableProphecies()
            async let myBetsTask = NetworkManager.shared.getMyProphecyBets()

            let (myP, bettable, myBets) = try await (myPropheciesTask, bettableTask, myBetsTask)
            self.myProphecies = myP
            self.bettableProphecies = bettable
            self.myProphecyBets = myBets
        } catch {
            print("Failed to fetch prophecy data: \(error)")
        }
    }

    @MainActor
    func createProphecy(content: String) async -> Bool {
        do {
            let prophecy = try await NetworkManager.shared.createProphecy(content: content)
            self.myProphecies.insert(prophecy, at: 0)
            return true
        } catch {
            print("Failed to create prophecy: \(error)")
            return false
        }
    }

    @MainActor
    func closeProphecy(prophecyId: Int, success: Bool) async -> Bool {
        do {
            let updated = try await NetworkManager.shared.closeProphecy(prophecyId: prophecyId, success: success)
            if let idx = self.myProphecies.firstIndex(where: { $0.id == prophecyId }) {
                self.myProphecies[idx] = updated
            }
            // 배팅 내역도 새로고침 (정산됨)
            await fetchProphecyData()
            await fetchMyData()  // 잔액 업데이트
            return true
        } catch {
            print("Failed to close prophecy: \(error)")
            return false
        }
    }

    @MainActor
    func placeProphecyBet(prophecyId: Int, amount: Int, predictSuccess: Bool) async -> Bool {
        do {
            let bet = try await NetworkManager.shared.placeProphecyBet(prophecyId: prophecyId, amount: amount, predictSuccess: predictSuccess)
            self.myProphecyBets.insert(bet, at: 0)
            // 배팅 가능 목록 & 잔액 갱신
            await fetchProphecyData()
            await fetchMyData()
            return true
        } catch {
            print("Failed to place prophecy bet: \(error)")
            return false
        }
    }

    // MARK: - News
    @MainActor
    func fetchNews(category: NewsCategory?) async {
        do {
            let cat: String? = category == nil || category == .all ? nil : category!.backendValue
            let list: [NewsPostDto] = try await NetworkManager.shared.fetchNews(category: cat)
            var newPosts = list.map { $0.toNewsPost() }
            // 이미 불러온 댓글·API 개수 유지 (목록 API는 comments 미포함)
            for i in newPosts.indices {
                if let existing = newsPosts.first(where: { $0.id == newPosts[i].id }) {
                    if !existing.comments.isEmpty { newPosts[i].comments = existing.comments }
                    if existing.commentCountFromApi != nil { newPosts[i].commentCountFromApi = existing.commentCountFromApi }
                }
            }
            self.newsPosts = newPosts
        } catch {
            print("Failed to fetch news: \(error)")
        }
    }

    @MainActor
    func fetchNewsDetail(postId: Int) async -> NewsPost? {
        do {
            let dto = try await NetworkManager.shared.fetchNewsDetail(postId: postId)
            return dto.toNewsPost()
        } catch {
            print("Failed to fetch news detail: \(error)")
            return nil
        }
    }

    /// 글 상세(댓글 포함) 로드 후 newsPosts + 캐시에 반영. 탭/카테고리 전환해도 댓글 유지.
    @MainActor
    func loadNewsPostDetail(postId: Int) async -> NewsPost? {
        guard let full = await fetchNewsDetail(postId: postId) else { return nil }
        if let idx = newsPosts.firstIndex(where: { $0.id == postId }) {
            newsPosts[idx] = full
        }
        newsPostDetailCache[postId] = full
        return full
    }

    @MainActor
    func createNewsPost(title: String, content: String, category: NewsCategory, anonymous: Bool) async -> NewsPost? {
        do {
            let dto = try await NetworkManager.shared.createNewsPost(title: title, content: content, category: category.backendValue, anonymous: anonymous)
            let post = dto.toNewsPost()
            self.newsPosts.insert(post, at: 0)
            return post
        } catch {
            print("Failed to create news post: \(error)")
            return nil
        }
    }

    @MainActor
    func updateNewsPost(postId: Int, title: String, content: String, category: NewsCategory, anonymous: Bool) async -> NewsPost? {
        do {
            let dto = try await NetworkManager.shared.updateNewsPost(postId: postId, title: title, content: content, category: category.backendValue, anonymous: anonymous)
            let post = dto.toNewsPost()
            if let idx = self.newsPosts.firstIndex(where: { $0.id == postId }) {
                self.newsPosts[idx] = post
            }
            newsPostDetailCache[postId] = post
            return post
        } catch {
            print("Failed to update news post: \(error)")
            return nil
        }
    }

    @MainActor
    func deleteNewsPost(postId: Int) async -> Bool {
        do {
            try await NetworkManager.shared.deleteNewsPost(postId: postId)
            self.newsPosts.removeAll { $0.id == postId }
            newsPostDetailCache.removeValue(forKey: postId)
            return true
        } catch {
            print("Failed to delete news post: \(error)")
            return false
        }
    }

    @MainActor
    func addNewsComment(postId: Int, content: String) async -> NewsComment? {
        do {
            let dto = try await NetworkManager.shared.addNewsComment(postId: postId, content: content)
            let comment = dto.toNewsComment()
            if let idx = self.newsPosts.firstIndex(where: { $0.id == postId }) {
                self.newsPosts[idx].comments.append(comment)
            }
            if var cached = newsPostDetailCache[postId] {
                cached.comments.append(comment)
                newsPostDetailCache[postId] = cached
            }
            return comment
        } catch {
            print("Failed to add comment: \(error)")
            return nil
        }
    }

    @MainActor
    func likeNewsPost(postId: Int) async {
        do {
            try await NetworkManager.shared.likeNewsPost(postId: postId)
            if let idx = self.newsPosts.firstIndex(where: { $0.id == postId }) {
                self.newsPosts[idx].likes += 1
            }
            if var cached = newsPostDetailCache[postId] {
                cached.likes += 1
                newsPostDetailCache[postId] = cached
            }
        } catch {
            print("Failed to like post: \(error)")
        }
    }

    @MainActor
    func placeBet(targetUserId: Int, amount: Int, predictSuccess: Bool) async -> Bool {
        do {
            try await NetworkManager.shared.placeBet(friendUserId: targetUserId, amount: amount, predictSuccess: predictSuccess)
            await fetchCasinoData()
            await fetchMyData()
            return true
        } catch {
            print("Failed to place bet: \(error)")
            return false
        }
    }
    
    @MainActor
    func purchaseItem(itemId: Int, quantity: Int) async -> Bool {
        do {
            try await NetworkManager.shared.purchaseItem(itemId: itemId, quantity: quantity)
            await fetchDarkMarketData()
            await fetchMyData() // Refresh cash and skills
            return true
        } catch {
            print("Failed to purchase item: \(error)")
            return false
        }
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

        // 친구들 추가 (백엔드에서 받은 실제 총 자산 사용)
        for friend in friends {
            let friendTotal = friend.backendTotalAssets ?? (friend.marketCap + 100_000)
            entries.append(RankingEntry(
                rank: 0,
                name: friend.name,
                totalAssets: friendTotal,
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
    func addActivity(type: TickerActivityType, description: String, amount: Int) {
        let activity = TickerActivity(type: type, description: description, amount: amount, time: "방금 전", timestamp: Date())
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
