import SwiftUI

struct PortfolioView: View {
    @EnvironmentObject var appState: AppState
    @State private var balanceHidden = false

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Header
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("포트폴리오")
                            .font(.title.weight(.bold))
                        Text("내 계정 현황")
                            .font(.subheadline)
                            .foregroundStyle(AppTheme.secondaryText)
                    }

                    Spacer()

                    Menu {
                        Button { appState.visibility = .publicVisible } label: { Label("공개", systemImage: "globe") }
                        Button { appState.visibility = .privateOnly } label: { Label("비공개", systemImage: "lock") }
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: appState.visibility.icon)
                            Text(appState.visibility.label)
                        }
                        .font(.subheadline)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(AppTheme.cardBackground)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(AppTheme.border, lineWidth: 1)
                        )
                    }
                    .buttonStyle(.plain)
                }

                // Balance Card
                balanceCard

                // 2-column layout
                HStack(alignment: .top, spacing: 20) {
                    // Left Column
                    VStack(spacing: 24) {
                        investedStocksSection
                        activitySection
                    }
                    .frame(maxWidth: .infinity)

                    // Right Column
                    VStack(spacing: 20) {
                        rankingsSection
                        skillsSection
                        newsPreviewSection
                    }
                    .frame(width: 300)
                }
            }
            .padding(24)
        }
        .background(AppTheme.background)
    }

    // MARK: - Balance Card
    private var balanceCard: some View {
        HStack(alignment: .top) {
            // Left: total balance
            VStack(alignment: .leading, spacing: 10) {
                Text("총 자산")
                    .font(.subheadline)
                    .foregroundStyle(AppTheme.secondaryText)

                HStack(alignment: .center, spacing: 12) {
                    Text(balanceHidden ? "******" : formatPrice(Int(appState.totalAssets)) + "원")
                        .font(.system(size: 38, weight: .bold).monospacedDigit())
                        .foregroundStyle(AppTheme.primaryText)

                    Button {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            balanceHidden.toggle()
                        }
                    } label: {
                        Image(systemName: balanceHidden ? "eye.slash" : "eye")
                            .font(.title3)
                            .foregroundStyle(AppTheme.secondaryText)
                    }
                    .buttonStyle(.plain)
                }

                if appState.dailyChange != 0 {
                    HStack(spacing: 8) {
                        PriceChangeBadge(change: appState.dailyChange)
                        Text("오늘")
                            .font(.subheadline)
                            .foregroundStyle(AppTheme.secondaryText)
                    }
                }

                // 총 자산 구성 설명
                Text("보유 현금 + 내 가치(70주) + 투자 평가액")
                    .font(.caption)
                    .foregroundStyle(AppTheme.tertiaryText)
            }

            Spacer()

            // Right: breakdown
            VStack(alignment: .trailing, spacing: 16) {
                VStack(alignment: .trailing, spacing: 4) {
                    Text("내 가치 (시가총액)")
                        .font(.caption)
                        .foregroundStyle(AppTheme.secondaryText)
                    Text(formatPrice(Int(appState.myMarketCap)) + "원")
                        .font(.title3.weight(.semibold).monospacedDigit())
                        .foregroundStyle(AppTheme.neon)
                }

                VStack(alignment: .trailing, spacing: 4) {
                    Text("보유 현금")
                        .font(.caption)
                        .foregroundStyle(AppTheme.secondaryText)
                    Text(formatPrice(Int(appState.cash)) + "원")
                        .font(.title3.weight(.semibold).monospacedDigit())
                        .foregroundStyle(AppTheme.primaryText)
                }

                VStack(alignment: .trailing, spacing: 4) {
                    Text("투자 평가액")
                        .font(.caption)
                        .foregroundStyle(AppTheme.secondaryText)
                    Text(formatPrice(Int(appState.totalInvestedInOthers)) + "원")
                        .font(.title3.weight(.semibold).monospacedDigit())
                        .foregroundStyle(AppTheme.primaryText)
                }

                VStack(alignment: .trailing, spacing: 4) {
                    Text("내 코드")
                        .font(.caption)
                        .foregroundStyle(AppTheme.secondaryText)
                    HStack(spacing: 6) {
                        Text(appState.myFriendCode)
                            .font(.system(size: 13, weight: .semibold, design: .monospaced))
                            .foregroundStyle(AppTheme.neon)
                        Button {
                            NSPasteboard.general.clearContents()
                            NSPasteboard.general.setString(appState.myFriendCode, forType: .string)
                        } label: {
                            Image(systemName: "doc.on.doc")
                                .font(.caption)
                                .foregroundStyle(AppTheme.secondaryText)
                        }
                        .buttonStyle(.plain)
                        .help("코드 복사")
                    }
                }
            }
        }
        .padding(24)
        .cardStyle()
    }

    // MARK: - Invested Stocks Section
    private var investedStocksSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                HStack(spacing: 8) {
                    Image(systemName: "chart.line.uptrend.xyaxis")
                        .foregroundStyle(AppTheme.gain)
                    Text("투자 중인 종목")
                        .font(.headline)
                        .foregroundStyle(AppTheme.primaryText)
                }

                Spacer()

                Text("\(appState.holdings.count)개")
                    .font(.subheadline)
                    .foregroundStyle(AppTheme.secondaryText)
            }

            VStack(spacing: 10) {
                ForEach(appState.holdings) { holding in
                    StockCardView(
                        name: holding.name,
                        price: Int(holding.currentPrice),
                        change: holding.change,
                        sparklineData: holding.sparklineData
                    )
                }

                if appState.holdings.isEmpty {
                    VStack(spacing: 8) {
                        Image(systemName: "briefcase")
                            .font(.title2)
                            .foregroundStyle(AppTheme.tertiaryText)
                        Text("아직 투자한 종목이 없습니다")
                            .font(.subheadline)
                            .foregroundStyle(AppTheme.secondaryText)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 20)
                }
            }
        }
    }

    // MARK: - Activity Section
    private var activitySection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("최근 활동")
                .font(.headline)
                .foregroundStyle(AppTheme.primaryText)

            if recentActivities.isEmpty {
                VStack(spacing: 8) {
                    Image(systemName: "clock")
                        .font(.title2)
                        .foregroundStyle(AppTheme.tertiaryText)
                    Text("아직 활동 내역이 없습니다")
                        .font(.subheadline)
                        .foregroundStyle(AppTheme.secondaryText)
                    Text("주식을 매수/매도하거나 아이템을 구매하면 여기에 표시됩니다")
                        .font(.caption)
                        .foregroundStyle(AppTheme.tertiaryText)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 30)
                .cardStyle()
            } else {
                VStack(spacing: 0) {
                    ForEach(recentActivities) { activity in
                        ActivityRow(activity: activity)

                        if activity.id != recentActivities.last?.id {
                            Divider()
                                .background(AppTheme.border)
                                .padding(.leading, 44)
                        }
                    }
                }
                .cardStyle()
            }
        }
    }

    // MARK: - Rankings Section (상장폐지 대신)
    private var rankingsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 6) {
                Image(systemName: "trophy.fill")
                    .foregroundStyle(.yellow)
                Text("랭킹")
                    .font(.headline)
                    .foregroundStyle(AppTheme.primaryText)
            }
            .padding(.horizontal, 16)
            .padding(.top, 16)

            VStack(spacing: 4) {
                ForEach(appState.friendRankings) { entry in
                    HStack(spacing: 10) {
                        // 순위
                        Text("#\(entry.rank)")
                            .font(.system(.subheadline, weight: .bold).monospacedDigit())
                            .foregroundStyle(entry.rank <= 3 ? .yellow : AppTheme.secondaryText)
                            .frame(width: 30, alignment: .leading)

                        // 이름
                        Text(entry.name)
                            .font(.subheadline.weight(entry.isMe ? .bold : .medium))
                            .foregroundStyle(entry.isMe ? AppTheme.neon : AppTheme.primaryText)

                        if entry.isMe {
                            Text("나")
                                .font(.caption2.weight(.bold))
                                .foregroundStyle(.black)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(AppTheme.neon)
                                .clipShape(RoundedRectangle(cornerRadius: 4))
                        }

                        Spacer()

                        // 총 자산
                        VStack(alignment: .trailing, spacing: 2) {
                            Text(formatPrice(Int(entry.totalAssets)) + "원")
                                .font(.system(.caption, weight: .semibold).monospacedDigit())
                                .foregroundStyle(AppTheme.primaryText)

                            if entry.change != 0 {
                                Text(String(format: "%+.1f%%", entry.change))
                                    .font(.system(.caption2, weight: .medium).monospacedDigit())
                                    .foregroundStyle(entry.change >= 0 ? AppTheme.gain : AppTheme.loss)
                            }
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(entry.isMe ? AppTheme.neon.opacity(0.05) : Color.clear)
                    .clipShape(RoundedRectangle(cornerRadius: 6))
                    .padding(.horizontal, 12)
                }
            }
            .padding(.bottom, 16)
        }
        .cardStyle()
    }

    // MARK: - Skills Section
    private var skillsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 6) {
                Image(systemName: "sparkles")
                    .foregroundStyle(AppTheme.neon)
                Text("보유 스킬")
                    .font(.headline)
                    .foregroundStyle(AppTheme.primaryText)
            }
            .padding(.horizontal, 16)
            .padding(.top, 16)

            VStack(spacing: 4) {
                ForEach(appState.mySkills.sorted(by: { $0.key < $1.key }), id: \.key) { key, value in
                    HStack {
                        Text(key)
                            .font(.subheadline)
                            .foregroundStyle(AppTheme.primaryText)
                        Spacer()
                        Text("x\(value)")
                            .font(.system(.subheadline, weight: .semibold).monospacedDigit())
                            .foregroundStyle(AppTheme.gain)
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(AppTheme.cardBackgroundLight)
                    .clipShape(RoundedRectangle(cornerRadius: 6))
                    .padding(.horizontal, 12)
                }
            }

            Button {
                appState.selectedTab = .store
            } label: {
                Text("암시장에서 더 보기")
                    .font(.subheadline)
                    .foregroundStyle(AppTheme.primaryText)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                    .background(AppTheme.cardBackgroundLight)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
            }
            .buttonStyle(.plain)
            .padding(.horizontal, 12)
            .padding(.bottom, 16)
        }
        .cardStyle()
    }

    // MARK: - News Preview Section
    private var newsPreviewSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 6) {
                Image(systemName: "newspaper.fill")
                    .foregroundStyle(.cyan)
                Text("최신 뉴스")
                    .font(.headline)
                    .foregroundStyle(AppTheme.primaryText)
            }
            .padding(.horizontal, 16)
            .padding(.top, 16)

            VStack(spacing: 4) {
                ForEach(appState.newsPosts.prefix(3)) { post in
                    VStack(alignment: .leading, spacing: 6) {
                        HStack {
                            HStack(spacing: 3) {
                                Image(systemName: post.category.icon)
                                    .font(.system(size: 8))
                                Text(post.category.rawValue)
                                    .font(.system(size: 10, weight: .medium))
                            }
                            .foregroundStyle(post.category.color)

                            Spacer()

                            Text(post.timeAgo)
                                .font(.system(size: 10))
                                .foregroundStyle(AppTheme.tertiaryText)
                        }

                        Text(post.title)
                            .font(.subheadline.weight(.medium))
                            .foregroundStyle(AppTheme.primaryText)
                            .lineLimit(1)

                        HStack {
                            Text(post.displayAuthor)
                                .font(.caption)
                                .foregroundStyle(AppTheme.tertiaryText)
                            Spacer()
                            HStack(spacing: 8) {
                                HStack(spacing: 2) {
                                    Image(systemName: "heart.fill")
                                        .font(.system(size: 8))
                                        .foregroundStyle(.pink.opacity(0.7))
                                    Text("\(post.likes)")
                                        .font(.caption2)
                                        .foregroundStyle(AppTheme.tertiaryText)
                                }
                                HStack(spacing: 2) {
                                    Image(systemName: "bubble.right.fill")
                                        .font(.system(size: 8))
                                        .foregroundStyle(.cyan.opacity(0.7))
                                    Text("\(post.comments.count)")
                                        .font(.caption2)
                                        .foregroundStyle(AppTheme.tertiaryText)
                                }
                            }
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(AppTheme.cardBackgroundLight)
                    .clipShape(RoundedRectangle(cornerRadius: 6))
                    .padding(.horizontal, 12)
                }
            }

            Button {
                appState.selectedTab = .news
            } label: {
                Text("뉴스 더 보기")
                    .font(.subheadline)
                    .foregroundStyle(AppTheme.primaryText)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                    .background(AppTheme.cardBackgroundLight)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
            }
            .buttonStyle(.plain)
            .padding(.horizontal, 12)
            .padding(.bottom, 16)
        }
        .cardStyle()
    }

    // MARK: - Helpers
    private func formatPrice(_ value: Int) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        return formatter.string(from: NSNumber(value: value)) ?? "0"
    }

    private var recentActivities: [Activity] {
        Array(appState.activities.prefix(10))
    }
}

// MARK: - Activity
struct Activity: Identifiable {
    let id = UUID()
    let type: ActivityType
    let description: String
    let amount: Int
    let time: String
    let timestamp: Date

    init(type: ActivityType, description: String, amount: Int, time: String, timestamp: Date = Date()) {
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

enum ActivityType {
    case buy, sell, dividend, listing, purchase, bet

    var icon: String {
        switch self {
        case .buy: return "arrow.down.circle.fill"
        case .sell: return "arrow.up.circle.fill"
        case .dividend: return "gift.fill"
        case .listing: return "plus.circle.fill"
        case .purchase: return "bag.fill"
        case .bet: return "dice.fill"
        }
    }

    var color: Color {
        switch self {
        case .buy: return .blue
        case .sell: return .orange
        case .dividend: return .green
        case .listing: return .purple
        case .purchase: return .purple
        case .bet: return .pink
        }
    }
}

struct ActivityRow: View {
    let activity: Activity

    private var isIncome: Bool {
        activity.type == .sell || activity.type == .dividend
    }

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: activity.type.icon)
                .font(.title2)
                .foregroundStyle(activity.type.color)
                .frame(width: 32)

            VStack(alignment: .leading, spacing: 2) {
                Text(activity.description)
                    .font(.subheadline)
                    .foregroundStyle(AppTheme.primaryText)
                Text(activity.timeAgo)
                    .font(.caption)
                    .foregroundStyle(AppTheme.tertiaryText)
            }

            Spacer()

            if activity.amount > 0 {
                Text((isIncome ? "+" : "-") + formatActivityPrice(activity.amount) + "원")
                    .font(.system(.subheadline, weight: .medium).monospacedDigit())
                    .foregroundStyle(isIncome ? AppTheme.gain : AppTheme.primaryText)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }

    private func formatActivityPrice(_ value: Int) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        return formatter.string(from: NSNumber(value: value)) ?? "0"
    }
}

#Preview {
    PortfolioView()
        .environmentObject(AppState())
        .frame(width: 900, height: 800)
        .preferredColorScheme(.dark)
}
