import SwiftUI

struct ContentView: View {
    @EnvironmentObject var appState: AppState
    @State private var columnVisibility: NavigationSplitViewVisibility = .all
    
    // 테마 설정을 저장 (기본값 다크모드)
    @AppStorage("isDarkMode") private var isDarkMode = true

    var body: some View {
        Group {
            if appState.isLoggedIn {
                NavigationSplitView(columnVisibility: $columnVisibility) {
                    // SidebarView에 테마 상태를 바인딩으로 전달
                    SidebarView(isDarkMode: $isDarkMode)
                        .navigationSplitViewColumnWidth(min: 200, ideal: 220, max: 280)
                } detail: {
                    DetailView()
                }
                .navigationSplitViewStyle(.balanced)
            } else {
                LoginView()
            }
        }
        .animation(.easeInOut(duration: 0.3), value: appState.isLoggedIn)
        // 사용자의 선택에 따라 다크/라이트 모드 적용
        .preferredColorScheme(isDarkMode ? .dark : .light)
    }
}

// MARK: - Sidebar View
struct SidebarView: View {
    @EnvironmentObject var appState: AppState
    @Binding var isDarkMode: Bool // ContentView와 동기화되는 변수

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
                        Text("TICKER")
                            .font(.headline)
                    }
                    .padding(.bottom, 8)
                }

                Section {
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("내 자산")
                                .font(.caption)
                                .foregroundStyle(AppTheme.secondaryText)
                            Text(formatCurrency(appState.totalAssets))
                                .font(.system(.body, weight: .semibold).monospacedDigit())
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

            // 하단 영역: 유저 정보 + 모드 전환 버튼
            VStack(spacing: 12) {
                if let user = appState.currentUser {
                    HStack(spacing: 10) {
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
                                .foregroundStyle(AppTheme.secondaryText)
                        }

                        Spacer()

                        Button(action: {
                            appState.logout()
                        }) {
                            Image(systemName: "rectangle.portrait.and.arrow.right")
                                .font(.system(size: 12))
                                .foregroundStyle(AppTheme.secondaryText)
                        }
                        .buttonStyle(.plain)
                        .help("로그아웃")
                    }

                    Divider()
                }

                // 모드 전환 버튼 영역
                Button(action: {
                    withAnimation {
                        isDarkMode.toggle()
                    }
                }) {
                    HStack {
                        Image(systemName: isDarkMode ? "moon.fill" : "sun.max.fill")
                            .foregroundStyle(isDarkMode ? .yellow : .orange)
                            .font(.system(size: 14))

                        Text(isDarkMode ? "라이트 모드" : "다크 모드")
                            .font(.caption)
                            .foregroundStyle(AppTheme.secondaryText)

                        Spacer()

                        Text(isDarkMode ? "Dark" : "Light")
                            .font(.system(size: 10, weight: .bold))
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.gray.opacity(0.2))
                            .cornerRadius(4)
                    }
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(AppTheme.sidebarBackground)
        }
        .frame(minWidth: 200)
    }

    private func formatCurrency(_ value: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 0
        return "₩" + (formatter.string(from: NSNumber(value: value)) ?? "0")
    }
}

// MARK: - Sidebar Item (기존 코드와 동일)
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

// MARK: - Detail View (기존 코드와 동일)
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
        .background(AppTheme.background)
    }
}

// MARK: - Settings View (기존 코드와 동일)
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

    var body: some View {
        Form {
            Toggle("애니메이션 효과", isOn: $showAnimations)
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
