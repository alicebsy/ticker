import SwiftUI

struct ContentView: View {
    @EnvironmentObject var appState: AppState
    @State private var columnVisibility: NavigationSplitViewVisibility = .all
    
    var body: some View {
        Group {
            if appState.isLoggedIn {
                // 로그인 후 메인 앱
                NavigationSplitView(columnVisibility: $columnVisibility) {
                    SidebarView()
                        .navigationSplitViewColumnWidth(min: 200, ideal: 220, max: 280)
                } detail: {
                    DetailView()
                }
                .navigationSplitViewStyle(.balanced)
            } else {
                // 로그인 화면
                LoginView()
            }
        }
        .animation(.easeInOut(duration: 0.3), value: appState.isLoggedIn)
    }
}

// MARK: - Sidebar View
struct SidebarView: View {
    @EnvironmentObject var appState: AppState
    @AppStorage("darkMode") private var darkMode = false
    
    var body: some View {
        VStack(spacing: 0) {
            List(selection: $appState.selectedTab) {
                Section {
                    ForEach(SidebarTab.allCases) { tab in
                        SidebarItem(tab: tab)
                            .tag(tab)
                    }
                } header: {
                    HStack {
                        Image(systemName: "chart.line.uptrend.xyaxis")
                            .foregroundStyle(.green)
                        Text("인간 주식 시장")
                            .font(.headline)
                    }
                    .padding(.bottom, 8)
                }
                
                Section {
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("내 자산")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            Text(formatCurrency(appState.totalAssets))
                                .font(.system(.body, design: .rounded, weight: .semibold))
                        }
                        
                        Spacer()
                        
                        PriceChangeBadge(change: appState.dailyChange)
                    }
                    .padding(.vertical, 4)
                } header: {
                    Text("요약")
                }
            }
            .listStyle(.sidebar)
            
            Divider()
            
            // 하단 영역: 유저 정보 + 다크 모드 토글
            VStack(spacing: 12) {
                // 유저 정보
                if let user = appState.currentUser {
                    HStack(spacing: 10) {
                        // 프로필 이미지
                        ZStack {
                            Circle()
                                .fill(Color.green.opacity(0.2))
                                .frame(width: 32, height: 32)
                            
                            Text(String(user.name.prefix(1)))
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundStyle(.green)
                        }
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text(user.name)
                                .font(.system(size: 13, weight: .medium))
                            
                            Text(user.loginMethod.displayName + " 로그인")
                                .font(.system(size: 10))
                                .foregroundStyle(.secondary)
                        }
                        
                        Spacer()
                        
                        // 로그아웃 버튼
                        Button(action: {
                            appState.logout()
                        }) {
                            Image(systemName: "rectangle.portrait.and.arrow.right")
                                .font(.system(size: 12))
                                .foregroundStyle(.secondary)
                        }
                        .buttonStyle(.plain)
                        .help("로그아웃")
                    }
                    
                    Divider()
                }
                
                // 다크 모드 토글
                HStack {
                    Image(systemName: darkMode ? "moon.fill" : "sun.max.fill")
                        .foregroundStyle(darkMode ? .yellow : .orange)
                        .font(.system(size: 14))
                    
                    Text(darkMode ? "다크 모드" : "라이트 모드")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    
                    Spacer()
                    
                    Toggle("", isOn: $darkMode)
                        .toggleStyle(.switch)
                        .labelsHidden()
                        .scaleEffect(0.8)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(Color(nsColor: .windowBackgroundColor).opacity(0.5))
        }
        .frame(minWidth: 200)
        .preferredColorScheme(darkMode ? .dark : .light)
    }
    
    private func formatCurrency(_ value: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 0
        return "₩" + (formatter.string(from: NSNumber(value: value)) ?? "0")
    }
}

// MARK: - Sidebar Item
struct SidebarItem: View {
    let tab: SidebarTab
    
    var body: some View {
        Label {
            Text(tab.rawValue)
        } icon: {
            Image(systemName: tab.icon)
                .foregroundStyle(tab.color)
        }
    }
}

// MARK: - Detail View (Tab Router)
struct DetailView: View {
    @EnvironmentObject var appState: AppState
    
    var body: some View {
        Group {
            switch appState.selectedTab {
            case .portfolio:
                PortfolioView()
            case .listing:
                ListingView()
            case .holdings:
                HoldingsView()
            case .watchlist:
                WatchlistView()
            case .store:
                StoreView()
            case .casino:
                CasinoView()
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(nsColor: .windowBackgroundColor))
    }
}

// MARK: - Settings View
struct SettingsView: View {
    var body: some View {
        TabView {
            GeneralSettingsView()
                .tabItem {
                    Label("일반", systemImage: "gear")
                }
            
            NotificationSettingsView()
                .tabItem {
                    Label("알림", systemImage: "bell")
                }
        }
        .frame(width: 450, height: 300)
    }
}

struct GeneralSettingsView: View {
    @AppStorage("showAnimations") private var showAnimations = true
    @AppStorage("darkMode") private var darkMode = false
    
    var body: some View {
        Form {
            Toggle("애니메이션 효과", isOn: $showAnimations)
            Toggle("다크 모드", isOn: $darkMode)
        }
        .padding()
    }
}

struct NotificationSettingsView: View {
    @AppStorage("priceAlerts") private var priceAlerts = true
    @AppStorage("friendActivity") private var friendActivity = true
    
    var body: some View {
        Form {
            Toggle("가격 변동 알림", isOn: $priceAlerts)
            Toggle("친구 활동 알림", isOn: $friendActivity)
        }
        .padding()
    }
}

#Preview {
    ContentView()
        .environmentObject(AppState())
        .frame(width: 1000, height: 700)
}
