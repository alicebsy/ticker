import SwiftUI

struct PortfolioView: View {
    @EnvironmentObject var appState: AppState
    @State private var selectedTimeRange: TimeRange = .week
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Header
                headerSection
                
                // Stats Grid
                statsGrid
                
                // Main Chart
                mainChartSection
                
                // Holdings Overview
                holdingsSection
                
                // Recent Activity
                activitySection
            }
            .padding(24)
        }
        .navigationTitle("포트폴리오")
        .toolbar {
            ToolbarItem(placement: .automatic) {
                Button(action: {}) {
                    Image(systemName: "arrow.clockwise")
                }
                .help("새로고침")
            }
            
            ToolbarItem(placement: .automatic) {
                Button(action: {}) {
                    Image(systemName: "square.and.arrow.up")
                }
                .help("공유")
            }
        }
    }
    
    // MARK: - Header Section
    private var headerSection: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 8) {
                Text("총 자산")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                
                HStack(alignment: .firstTextBaseline, spacing: 12) {
                    Text(formatCurrency(appState.totalAssets))
                        .font(.system(size: 36, weight: .bold, design: .rounded))
                    
                    PriceChangeBadge(change: appState.dailyChange)
                }
                
                Text("어제 대비 \(appState.dailyChange >= 0 ? "+" : "")\(formatCurrency(appState.totalAssets * appState.dailyChange / 100))")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            
            Spacer()
            
            // Time Range Picker
            Picker("기간", selection: $selectedTimeRange) {
                ForEach(TimeRange.allCases) { range in
                    Text(range.rawValue).tag(range)
                }
            }
            .pickerStyle(.segmented)
            .frame(width: 250)
        }
    }
    
    // MARK: - Stats Grid
    private var statsGrid: some View {
        LazyVGrid(columns: [
            GridItem(.flexible()),
            GridItem(.flexible()),
            GridItem(.flexible()),
            GridItem(.flexible())
        ], spacing: 16) {
            StatCard(
                title: "투자 중인 친구",
                value: "\(appState.holdings.count)명",
                subtitle: "전체 수익률 +12.4%",
                icon: "person.2.fill",
                iconColor: .blue
            )
            
            StatCard(
                title: "내 상장 종목",
                value: "\(appState.myListings.count)개",
                subtitle: "진행 중",
                icon: "list.bullet.clipboard.fill",
                iconColor: .green
            )
            
            StatCard(
                title: "보유 스킬",
                value: "7개",
                subtitle: "레어 2개 보유",
                icon: "star.fill",
                iconColor: .orange
            )
            
            StatCard(
                title: "신뢰도",
                value: "92점",
                subtitle: "상위 8%",
                icon: "shield.checkered",
                iconColor: .purple
            )
        }
    }
    
    // MARK: - Main Chart Section
    private var mainChartSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("자산 추이")
                    .font(.headline)
                
                Spacer()
                
                Menu {
                    Button("전체 자산") {}
                    Button("투자 수익") {}
                    Button("내 주가") {}
                } label: {
                    HStack(spacing: 4) {
                        Text("전체 자산")
                            .font(.subheadline)
                        Image(systemName: "chevron.down")
                            .font(.caption)
                    }
                    .foregroundStyle(.secondary)
                }
                .menuStyle(.borderlessButton)
            }
            
            // Chart Area
            SparklineView(
                data: generateChartData(),
                showGradient: true
            )
            .frame(height: 200)
            .padding()
            .cardStyle()
        }
    }
    
    // MARK: - Holdings Section
    private var holdingsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("투자 중인 친구")
                    .font(.headline)
                
                Spacer()
                
                Button("전체 보기") {
                    appState.selectedTab = .holdings
                }
                .buttonStyle(.link)
            }
            
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 12) {
                ForEach(appState.holdings.prefix(3)) { holding in
                    HoldingCard(holding: holding)
                }
            }
        }
    }
    
    // MARK: - Activity Section
    private var activitySection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("최근 활동")
                .font(.headline)
            
            VStack(spacing: 0) {
                ForEach(recentActivities) { activity in
                    ActivityRow(activity: activity)
                    
                    if activity.id != recentActivities.last?.id {
                        Divider()
                            .padding(.leading, 44)
                    }
                }
            }
            .cardStyle()
        }
    }
    
    // MARK: - Helpers
    private func formatCurrency(_ value: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 0
        return "₩" + (formatter.string(from: NSNumber(value: value)) ?? "0")
    }
    
    private func generateChartData() -> [Double] {
        var data: [Double] = [100]
        for _ in 1..<30 {
            let change = Double.random(in: -3...4)
            data.append(data.last! + change)
        }
        return data
    }
    
    private var recentActivities: [Activity] {
        [
            Activity(type: .buy, description: "김철수(CHUL) 5주 매수", amount: 76000, time: "10분 전"),
            Activity(type: .sell, description: "이영희(YOUNG) 3주 매도", amount: 26700, time: "1시간 전"),
            Activity(type: .dividend, description: "박지민(JIMIN) 배당금 수령", amount: 5000, time: "3시간 전"),
            Activity(type: .listing, description: "'iOS 앱 출시' 상장 완료", amount: 10000, time: "어제"),
        ]
    }
}

// MARK: - Time Range
enum TimeRange: String, CaseIterable, Identifiable {
    case day = "1일"
    case week = "1주"
    case month = "1개월"
    case quarter = "3개월"
    case year = "1년"
    
    var id: String { rawValue }
}

// MARK: - Holding Card
struct HoldingCard: View {
    let holding: Holding
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                AvatarView(name: holding.name, color: holding.avatarColor, size: 36)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(holding.name)
                        .font(.subheadline.weight(.semibold))
                    Text(holding.ticker)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                
                Spacer()
                
                PriceChangeBadge(change: holding.change)
            }
            
            SparklineView(data: holding.sparklineData)
                .frame(height: 40)
            
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("현재가")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                    Text("₩\(Int(holding.currentPrice))")
                        .font(.subheadline.weight(.semibold))
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 2) {
                    Text("보유")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                    Text("\(holding.quantity)주")
                        .font(.subheadline.weight(.semibold))
                }
            }
        }
        .padding()
        .cardStyle()
    }
}

// MARK: - Activity
struct Activity: Identifiable {
    let id = UUID()
    let type: ActivityType
    let description: String
    let amount: Int
    let time: String
}

enum ActivityType {
    case buy, sell, dividend, listing
    
    var icon: String {
        switch self {
        case .buy: return "arrow.down.circle.fill"
        case .sell: return "arrow.up.circle.fill"
        case .dividend: return "gift.fill"
        case .listing: return "plus.circle.fill"
        }
    }
    
    var color: Color {
        switch self {
        case .buy: return .blue
        case .sell: return .orange
        case .dividend: return .green
        case .listing: return .purple
        }
    }
}

struct ActivityRow: View {
    let activity: Activity
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: activity.type.icon)
                .font(.title2)
                .foregroundStyle(activity.type.color)
                .frame(width: 32)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(activity.description)
                    .font(.subheadline)
                Text(activity.time)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            
            Spacer()
            
            Text((activity.type == .sell ? "+" : "-") + "₩\(activity.amount)")
                .font(.subheadline.weight(.medium))
                .foregroundStyle(activity.type == .sell || activity.type == .dividend ? AppTheme.gain : AppTheme.primaryText)
        }
        .padding()
    }
}

#Preview {
    PortfolioView()
        .environmentObject(AppState())
        .frame(width: 800, height: 900)
}
