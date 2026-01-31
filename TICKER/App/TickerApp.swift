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
    @Published var totalAssets: Double = 1250000
    @Published var dailyChange: Double = 2.4
    @Published var holdings: [Holding] = Holding.sampleData
    @Published var watchlist: [Friend] = Friend.sampleData
    @Published var myListings: [Listing] = Listing.sampleData
    @Published var storeItems: [StoreItem] = StoreItem.sampleData
    
    func logout() {
        withAnimation(.easeInOut(duration: 0.3)) {
            isLoggedIn = false
            currentUser = nil
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
    case watchlist = "관심 종목"
    case store = "암시장"
    case casino = "카지노"
    
    var id: String { rawValue }
    
    var icon: String {
        switch self {
        case .portfolio: return "chart.pie.fill"
        case .listing: return "plus.circle.fill"
        case .holdings: return "briefcase.fill"
        case .watchlist: return "star.fill"
        case .store: return "bag.fill"
        case .casino: return "dice.fill"
        }
    }
    
    var color: Color {
        switch self {
        case .portfolio: return .blue
        case .listing: return .green
        case .holdings: return .orange
        case .watchlist: return .yellow
        case .store: return .purple
        case .casino: return .pink
        }
    }
}
