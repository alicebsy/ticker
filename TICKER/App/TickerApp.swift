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
    @Published var isLoggedIn: Bool = false
    @Published var currentUser: User? = nil
    @Published var selectedTab: SidebarTab = .portfolio
    @Published var visibility: PortfolioVisibility = .publicVisible // Default to Public as per new logic possibility, or .friends. User said "If public... If private...". Let's default to .publicVisible for now.
    @Published var cash: Double = 80000  // 보유 현금 (초기 총자산 ~100만P 중 투자 후 남은 현금)
    @Published var dailyChange: Double = 2.4
    @Published var holdings: [Holding] = Holding.sampleData
    @Published var watchlist: [Friend] = Friend.sampleData
    @Published var myListings: [Listing] = Listing.sampleData
    @Published var storeItems: [StoreItem] = StoreItem.sampleData
    
    // Friends & Social
    @Published var myFriendCode: String = {
        let code = Int.random(in: 1000...9999)
        return "TICKER-\(String(format: "%04d", code))"
    }()
    @Published var friends: [Friend] = Friend.sampleData
    @Published var friendRequests: [FriendRequest] = [
        FriendRequest(id: UUID(), name: "신유진", avatarColor: .gray, isSentByMe: true),
        FriendRequest(id: UUID(), name: "임도현", avatarColor: .gray, isSentByMe: false),
    ]

    // News / Community
    @Published var newsPosts: [NewsPost] = NewsPost.sampleData

    // Activity Log (동적 활동 내역)
    @Published var activities: [Activity] = []

    // User Gamification Stats
    @Published var userStockPrice: Double = 10000.0 // Adjusted for 1M economy
    @Published var streak: Int = 0
    @Published var mySkills: [String: Int] = ["시간 정지": 3, "도박 취소권": 1, "룰렛 추가 기회권": 2]
    @Published var userStockHistory: [Double] = [
        8000, 8200, 8500, 8300, 8800, 9200, 9000, 9500, 9800, 10000
    ] // Initial history ending at current price

    // MARK: - 총 자산 = 보유 현금 + 투자 평가액
    var totalInvested: Double {
        holdings.reduce(0) { $0 + $1.currentPrice * Double($1.quantity) }
    }

    var totalAssets: Double {
        cash + totalInvested
    }

    // MARK: - Transaction Functions

    /// 주식 매수 - 잔고 부족 시 false 반환
    @discardableResult
    func buyStock(friendName: String, listingTitle: String, quantity: Int, pricePerShare: Double) -> Bool {
        let totalCost = pricePerShare * Double(quantity)
        guard cash >= totalCost else { return false }

        // 현금에서 차감 (holdings에 추가되면 totalInvested로 이동)
        cash -= totalCost

        if let holdingIndex = holdings.firstIndex(where: { $0.name == friendName }) {
            if let investIndex = holdings[holdingIndex].investments.firstIndex(where: { $0.listingTitle == listingTitle }) {
                holdings[holdingIndex].investments[investIndex].quantity += quantity
            } else {
                holdings[holdingIndex].investments.append(
                    HoldingInvestment(id: UUID(), listingTitle: listingTitle, quantity: quantity, pricePerShare: pricePerShare)
                )
            }
            holdings[holdingIndex].quantity += quantity
        } else {
            // 새로운 보유 종목 생성 — Friend 데이터에서 정보 가져오기
            let friend = friends.first(where: { $0.name == friendName })
            let newHolding = Holding(
                id: UUID(),
                name: friendName,
                ticker: friend?.ticker ?? String(friendName.prefix(2)).uppercased(),
                currentPrice: pricePerShare,
                change: friend?.change ?? 0,
                quantity: quantity,
                avatarColor: friend?.avatarColor ?? .gray,
                sparklineData: friend?.sparklineData ?? [100, 100],
                investments: [
                    HoldingInvestment(id: UUID(), listingTitle: listingTitle, quantity: quantity, pricePerShare: pricePerShare)
                ]
            )
            holdings.append(newHolding)
        }

        // 활동 기록
        addActivity(type: .buy, description: "\(friendName) '\(listingTitle)' \(quantity)주 매수", amount: Int(totalCost))
        return true
    }

    /// 주식 매도 - 보유량 초과 시 false 반환
    @discardableResult
    func sellStock(friendName: String, listingTitle: String, quantity: Int, pricePerShare: Double) -> Bool {
        guard let holdingIndex = holdings.firstIndex(where: { $0.name == friendName }) else { return false }
        guard let investIndex = holdings[holdingIndex].investments.firstIndex(where: { $0.listingTitle == listingTitle }) else { return false }

        let currentQty = holdings[holdingIndex].investments[investIndex].quantity
        guard currentQty >= quantity else { return false }

        let totalRevenue = pricePerShare * Double(quantity)

        holdings[holdingIndex].investments[investIndex].quantity -= quantity
        holdings[holdingIndex].quantity -= quantity

        // 해당 항목의 수량이 0이면 투자 내역에서 삭제
        if holdings[holdingIndex].investments[investIndex].quantity <= 0 {
            holdings[holdingIndex].investments.remove(at: investIndex)
        }

        // 전체 수량이 0 이하면 보유 종목에서 삭제
        if holdings[holdingIndex].quantity <= 0 {
            holdings.remove(at: holdingIndex)
        }

        // 매도 수익을 현금에 추가
        cash += totalRevenue

        // 활동 기록
        addActivity(type: .sell, description: "\(friendName) '\(listingTitle)' \(quantity)주 매도", amount: Int(totalRevenue))
        return true
    }

    /// 스토어 아이템 구매 - 잔고 부족 시 false 반환
    @discardableResult
    func purchaseStoreItem(item: StoreItem) -> Bool {
        let price = Double(item.price)
        guard cash >= price else { return false }

        cash -= price

        // 스킬/아이템 인벤토리에 추가
        if let existing = mySkills[item.name] {
            mySkills[item.name] = existing + 1
        } else {
            mySkills[item.name] = 1
        }

        // 활동 기록
        addActivity(type: .purchase, description: "'\(item.name)' 구매", amount: item.price)
        return true
    }

    /// 카지노 베팅 - 잔고 부족 시 false 반환
    @discardableResult
    func placeBet(amount: Int, target: String, betType: BetType) -> Bool {
        let betAmount = Double(amount)
        guard cash >= betAmount else { return false }

        cash -= betAmount

        // 활동 기록
        addActivity(type: .bet, description: "\(target)에게 '\(betType.rawValue)' 베팅", amount: amount)
        return true
    }

    /// 활동 내역 추가
    func addActivity(type: ActivityType, description: String, amount: Int) {
        let activity = Activity(type: type, description: description, amount: amount, time: "방금 전", timestamp: Date())
        activities.insert(activity, at: 0)

        // 최대 50개까지만 유지
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
    
    func checkDeadlines() {
        let now = Date()
        var hasChanges = false
        
        for index in myListings.indices {
            // Check if active and deadline passed
            if myListings[index].isActive && myListings[index].deadline < now {
                // Auto-Failure Logic
                myListings[index].isActive = false
                
                // Penalty: -20% Price, Reset Streak
                let penalty = userStockPrice * 0.20
                userStockPrice -= penalty
                myListings[index].change = -penalty // Record loss
                
                streak = 0
                hasChanges = true
            }
        }
        
        if hasChanges {
            userStockHistory.append(userStockPrice)
        }
    }
}

// MARK: - User Model
struct User: Identifiable {
    let id: UUID
    var name: String
    var profileImage: String?
    var loginMethod: LoginMethod
}

enum LoginMethod {
    case kakao
    case apple
    case guest
    
    var displayName: String {
        switch self {
        case .kakao: return "카카오"
        case .apple: return "Apple"
        case .guest: return "게스트"
        }
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
        case .allStocks: return "person.3.fill" // Changed icon to represent 'All People'
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
