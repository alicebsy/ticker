import SwiftUI

struct PortfolioView: View {
    @EnvironmentObject var appState: AppState
    @State private var balanceHidden = false
    // @State private var visibility: PortfolioVisibility = .publicVisible // Removed local state

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
                        skillsSection
                        delistedSection
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
                    Text(balanceHidden ? "******" : formatPrice(Int(appState.totalAssets)) + "P")
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

                HStack(spacing: 8) {
                    PriceChangeBadge(change: appState.dailyChange)
                    Text("오늘")
                        .font(.subheadline)
                        .foregroundStyle(AppTheme.secondaryText)
                }
            }

            Spacer()

            // Right: invested + cash
            VStack(alignment: .trailing, spacing: 16) {
                VStack(alignment: .trailing, spacing: 4) {
                    Text("투자 중")
                        .font(.caption)
                        .foregroundStyle(AppTheme.secondaryText)
                    Text(formatPrice(totalInvested) + "P")
                        .font(.title3.weight(.semibold).monospacedDigit())
                        .foregroundStyle(AppTheme.primaryText)
                }

                VStack(alignment: .trailing, spacing: 4) {
                    Text("보유 현금")
                        .font(.caption)
                        .foregroundStyle(AppTheme.secondaryText)
                    Text(formatPrice(Int(appState.totalAssets) - totalInvested) + "P")
                        .font(.title3.weight(.semibold).monospacedDigit())
                        .foregroundStyle(AppTheme.primaryText)
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
            }
        }
    }

    // MARK: - Activity Section
    private var activitySection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("최근 활동")
                .font(.headline)
                .foregroundStyle(AppTheme.primaryText)

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

    // MARK: - Delisted Section
    private var delistedSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 6) {
                Image(systemName: "exclamationmark.triangle")
                    .foregroundStyle(AppTheme.loss)
                Text("상장 폐지 내역")
                    .font(.headline)
                    .foregroundStyle(AppTheme.primaryText)
            }
            .padding(.horizontal, 16)
            .padding(.top, 16)

            VStack(spacing: 8) {
                // Filter for failed listings (isActive is false AND change is negative)
                ForEach(appState.myListings.filter { !$0.isActive && $0.change < 0 }, id: \.id) { item in
                    VStack(spacing: 6) {
                        HStack {
                            Text(item.title)
                                .font(.subheadline.weight(.medium))
                                .foregroundStyle(AppTheme.primaryText)
                            Spacer()
                            Text(formatPrice(Int(item.change)) + "P")
                                .font(.system(.subheadline, weight: .medium).monospacedDigit())
                                .foregroundStyle(AppTheme.loss)
                        }
                        HStack {
                            Text(formatDate(item.deadline))
                                .font(.caption)
                                .foregroundStyle(AppTheme.tertiaryText)
                            Spacer()
                            Text("상장 폐지")
                                .font(.caption)
                                .foregroundStyle(AppTheme.tertiaryText)
                        }
                    }
                    .padding(12)
                    .background(AppTheme.cardBackgroundLight)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                    .padding(.horizontal, 12)
                }
            }
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
    private var totalInvested: Int {
        appState.holdings.reduce(0) { $0 + Int($1.currentPrice) * $1.quantity }
    }

    private func formatPrice(_ value: Int) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        return formatter.string(from: NSNumber(value: value)) ?? "0"
    }

    private var recentActivities: [Activity] {
        [
            Activity(type: .buy, description: "김철수(CHUL) 5주 매수", amount: 76000, time: "10분 전"),
            Activity(type: .sell, description: "이영희(YOUNG) 3주 매도", amount: 26700, time: "1시간 전"),
            Activity(type: .dividend, description: "박지민(JIMIN) 배당금 수령", amount: 5000, time: "3시간 전"),
            Activity(type: .listing, description: "'iOS 앱 출시' 상장 완료", amount: 10000, time: "어제"),
        ]
    }
    
    // Using appState.mySkills instead of mockSkills


    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: date)
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
                    .foregroundStyle(AppTheme.primaryText)
                Text(activity.time)
                    .font(.caption)
                    .foregroundStyle(AppTheme.tertiaryText)
            }

            Spacer()

            Text((activity.type == .sell || activity.type == .dividend ? "+" : "-") + "₩\(activity.amount)")
                .font(.system(.subheadline, weight: .medium).monospacedDigit())
                .foregroundStyle(
                    activity.type == .sell || activity.type == .dividend
                        ? AppTheme.gain
                        : AppTheme.primaryText
                )
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }
}

#Preview {
    PortfolioView()
        .environmentObject(AppState())
        .frame(width: 900, height: 800)
        .preferredColorScheme(.dark)
}
