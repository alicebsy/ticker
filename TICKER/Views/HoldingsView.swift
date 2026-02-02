import SwiftUI

struct HoldingsView: View {
    @EnvironmentObject var appState: AppState
    @State private var selectedHoldingID: Holding.ID?
    @State private var sortOrder: SortOrder = .value
    @State private var searchText = ""

    private var selectedHolding: Holding? {
        guard let id = selectedHoldingID else { return nil }
        return appState.holdings.first { $0.id == id }
    }

    // 선택된 Holding에 대응하는 Friend 정보
    private var selectedFriend: Friend? {
        guard let holding = selectedHolding else { return nil }
        return appState.friends.first { $0.name == holding.name }
    }

    enum SortOrder: String, CaseIterable {
        case name = "이름순"
        case value = "평가액순"
        case change = "수익률순"
    }

    private var filteredHoldings: [Holding] {
        let filtered = searchText.isEmpty ? appState.holdings : appState.holdings.filter {
            $0.name.contains(searchText) || $0.ticker.contains(searchText.uppercased())
        }

        return filtered.sorted { a, b in
            switch sortOrder {
            case .name: return a.name < b.name
            case .value: return a.totalValue > b.totalValue
            case .change: return a.change > b.change
            }
        }
    }

    var body: some View {
        HSplitView {
            // Left: Main Content
            ScrollView {
                VStack(spacing: 20) {
                    // Header
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("보유 종목")
                                .font(.title.weight(.bold))
                                .foregroundStyle(AppTheme.primaryText)
                            Text("투자 포트폴리오를 관리하세요")
                                .font(.subheadline)
                                .foregroundStyle(AppTheme.secondaryText)
                        }
                        Spacer()
                    }

                    // Summary Stats Card
                    summaryCard

                    // Search + Sort
                    HStack(spacing: 12) {
                        HStack(spacing: 8) {
                            Image(systemName: "magnifyingglass")
                                .foregroundStyle(AppTheme.secondaryText)
                            TextField("종목명 또는 티커 검색", text: $searchText)
                                .textFieldStyle(.plain)
                                .font(.subheadline)
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(AppTheme.cardBackground)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(AppTheme.border, lineWidth: 1)
                        )

                        Menu {
                            ForEach(SortOrder.allCases, id: \.self) { order in
                                Button {
                                    sortOrder = order
                                } label: {
                                    HStack {
                                        Text(order.rawValue)
                                        if sortOrder == order {
                                            Image(systemName: "checkmark")
                                        }
                                    }
                                }
                            }
                        } label: {
                            HStack(spacing: 4) {
                                Image(systemName: "arrow.up.arrow.down")
                                Text("정렬")
                            }
                            .font(.subheadline)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(AppTheme.cardBackground)
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(AppTheme.border, lineWidth: 1)
                            )
                        }
                        .buttonStyle(.plain)
                    }

                    // Holdings Table
                    holdingsTableCard

                    // Watchlist
                    watchlistSection
                }
                .padding(24)
            }
            .background(AppTheme.background)
            .frame(minWidth: 500)

            // Right: Person Detail Inspector
            if let friend = selectedFriend {
                PersonDetailView(friend: friend, onClose: {
                    withAnimation { selectedHoldingID = nil }
                })
                .frame(width: 340)
            }
        }
    }

    // MARK: - Summary Card
    private var summaryCard: some View {
        HStack(spacing: 0) {
            VStack(alignment: .leading, spacing: 6) {
                Text("총 평가금액")
                    .font(.caption)
                    .foregroundStyle(AppTheme.secondaryText)
                Text(formatPrice(Int(totalValue)) + "원")
                    .font(.system(size: 22, weight: .bold).monospacedDigit())
                    .foregroundStyle(AppTheme.primaryText)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            VStack(alignment: .leading, spacing: 6) {
                Text("총 매입금액")
                    .font(.caption)
                    .foregroundStyle(AppTheme.secondaryText)
                Text(formatPrice(Int(totalCost)) + "원")
                    .font(.system(size: 22, weight: .bold).monospacedDigit())
                    .foregroundStyle(AppTheme.primaryText)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            VStack(alignment: .leading, spacing: 6) {
                Text("총 손익")
                    .font(.caption)
                    .foregroundStyle(AppTheme.secondaryText)
                Text((totalProfit >= 0 ? "+" : "") + formatPrice(Int(totalProfit)) + "원")
                    .font(.system(size: 22, weight: .bold).monospacedDigit())
                    .foregroundStyle(totalProfit >= 0 ? AppTheme.gain : AppTheme.loss)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            VStack(alignment: .leading, spacing: 6) {
                Text("총 수익률")
                    .font(.caption)
                    .foregroundStyle(AppTheme.secondaryText)
                PriceChangeBadge(change: totalProfitPercent)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(20)
        .cardStyle()
    }

    // MARK: - Holdings Table
    private var holdingsTableCard: some View {
        VStack(spacing: 0) {
            // Table Header
            HStack(spacing: 0) {
                Text("종목명")
                    .frame(maxWidth: .infinity, alignment: .leading)
                Text("현재가")
                    .frame(width: 120, alignment: .trailing)
                Text("손익")
                    .frame(width: 120, alignment: .trailing)
                Text("보유수량")
                    .frame(width: 80, alignment: .trailing)
                Text("평가금액")
                    .frame(width: 120, alignment: .trailing)
            }
            .font(.caption)
            .foregroundStyle(AppTheme.secondaryText)
            .padding(.horizontal, 16)
            .padding(.vertical, 12)

            Divider().background(AppTheme.border)

            ForEach(filteredHoldings) { holding in
                HoldingRow(
                    holding: holding,
                    isSelected: holding.id == selectedHoldingID,
                    onSelect: {
                        withAnimation(.easeInOut(duration: 0.15)) {
                            selectedHoldingID = holding.id
                        }
                    }
                )

                if holding.id != filteredHoldings.last?.id {
                    Divider()
                        .background(AppTheme.border)
                        .padding(.leading, 16)
                }
            }

            if filteredHoldings.isEmpty {
                VStack(spacing: 8) {
                    Image(systemName: "briefcase")
                        .font(.title2)
                        .foregroundStyle(AppTheme.tertiaryText)
                    Text("보유 종목이 없습니다")
                        .font(.subheadline)
                        .foregroundStyle(AppTheme.secondaryText)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 40)
            }
        }
        .cardStyle()
    }

    // MARK: - Watchlist Section
    private var watchlistSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 6) {
                Image(systemName: "star.fill")
                    .foregroundStyle(.yellow)
                Text("관심 종목")
                    .font(.headline)
                    .foregroundStyle(AppTheme.primaryText)
            }

            let starredFriends = appState.friends.filter { $0.isStarred }

            if starredFriends.isEmpty {
                Text("관심 종목이 없습니다")
                    .font(.subheadline)
                    .foregroundStyle(AppTheme.secondaryText)
                    .padding(.vertical, 20)
                    .frame(maxWidth: .infinity)
                    .background(AppTheme.cardBackground)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            } else {
                LazyVGrid(columns: [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)], spacing: 12) {
                    ForEach(starredFriends) { friend in
                        StockCardView(
                            name: friend.name,
                            price: Int(friend.currentPrice),
                            change: friend.change,
                            sparklineData: friend.sparklineData,
                            isStarred: friend.isStarred,
                            onStarClick: {
                                if let index = appState.friends.firstIndex(where: { $0.id == friend.id }) {
                                    appState.friends[index].isStarred.toggle()
                                }
                            }
                        )
                    }
                }
            }
        }
    }

    // MARK: - Computed Properties
    private var totalValue: Double {
        appState.holdings.reduce(0) { $0 + $1.totalValue }
    }

    private var totalCost: Double {
        appState.holdings.reduce(0) { $0 + ($1.averageBuyPrice * Double($1.quantity)) }
    }

    private var totalProfit: Double {
        totalValue - totalCost
    }

    private var totalProfitPercent: Double {
        guard totalCost > 0 else { return 0 }
        return ((totalValue - totalCost) / totalCost) * 100
    }

    private func formatPrice(_ value: Int) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        return formatter.string(from: NSNumber(value: value)) ?? "0"
    }
}

// MARK: - Holding Row
struct HoldingRow: View {
    let holding: Holding
    let isSelected: Bool
    let onSelect: () -> Void

    @State private var isHovered = false

    var body: some View {
        HStack(spacing: 0) {
            // 종목명
            HStack(spacing: 10) {
                AvatarView(name: holding.name, color: holding.avatarColor, size: 34)

                VStack(alignment: .leading, spacing: 2) {
                    Text(holding.name)
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(AppTheme.primaryText)
                    Text(holding.ticker)
                        .font(.caption)
                        .foregroundStyle(AppTheme.secondaryText)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            // 현재가
            VStack(alignment: .trailing, spacing: 2) {
                Text(formatPrice(Int(holding.currentPrice)) + "원")
                    .font(.system(.subheadline, weight: .medium).monospacedDigit())
                    .foregroundStyle(AppTheme.primaryText)
                PriceChangeBadge(change: holding.change)
            }
            .frame(width: 120, alignment: .trailing)

            // 손익
            VStack(alignment: .trailing, spacing: 2) {
                Text((holding.profitLoss >= 0 ? "+" : "") + formatPrice(Int(holding.profitLoss)) + "원")
                    .font(.system(.subheadline, weight: .medium).monospacedDigit())
                    .foregroundStyle(holding.profitLoss >= 0 ? AppTheme.gain : AppTheme.loss)
                Text(String(format: "%+.1f%%", holding.profitPercent))
                    .font(.system(.caption, weight: .medium).monospacedDigit())
                    .foregroundStyle(holding.profitLoss >= 0 ? AppTheme.gain : AppTheme.loss)
            }
            .frame(width: 120, alignment: .trailing)

            // 보유수량
            Text("\(holding.quantity)주")
                .font(.system(.subheadline, weight: .medium).monospacedDigit())
                .foregroundStyle(AppTheme.primaryText)
                .frame(width: 80, alignment: .trailing)

            // 평가금액
            Text(formatPrice(Int(holding.totalValue)) + "원")
                .font(.system(.subheadline, weight: .medium).monospacedDigit())
                .foregroundStyle(AppTheme.primaryText)
                .frame(width: 120, alignment: .trailing)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(
            isSelected
                ? AppTheme.cardBackgroundLight
                : (isHovered ? AppTheme.cardBackgroundLight.opacity(0.5) : Color.clear)
        )
        .contentShape(Rectangle())
        .onTapGesture { onSelect() }
        .onHover { hovering in
            isHovered = hovering
        }
    }

    private func formatPrice(_ value: Int) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        return formatter.string(from: NSNumber(value: value)) ?? "0"
    }
}

#Preview {
    HoldingsView()
        .environmentObject(AppState())
        .frame(width: 1100, height: 700)
        .preferredColorScheme(.dark)
}
