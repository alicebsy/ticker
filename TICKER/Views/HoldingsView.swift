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
                        // Search Field
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

                        // Sort Menu
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

                    // Holdings Table Card
                    holdingsTableCard
                }
                .padding(24)
            }
            .background(AppTheme.background)
            .frame(minWidth: 500)

            // Right: Inspector Panel
            if let holding = selectedHolding {
                HoldingInspector(holding: holding)
                    .frame(width: 320)
            }
        }
    }

    // MARK: - Summary Card
    private var summaryCard: some View {
        HStack(spacing: 0) {
            // 총 평가금액
            VStack(alignment: .leading, spacing: 6) {
                Text("총 평가금액")
                    .font(.caption)
                    .foregroundStyle(AppTheme.secondaryText)
                Text(formatPrice(Int(totalValue)) + "P")
                    .font(.system(size: 22, weight: .bold).monospacedDigit())
                    .foregroundStyle(AppTheme.primaryText)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            // 총 매입금액
            VStack(alignment: .leading, spacing: 6) {
                Text("총 매입금액")
                    .font(.caption)
                    .foregroundStyle(AppTheme.secondaryText)
                Text(formatPrice(Int(totalCost)) + "P")
                    .font(.system(size: 22, weight: .bold).monospacedDigit())
                    .foregroundStyle(AppTheme.primaryText)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            // 총 손익
            VStack(alignment: .leading, spacing: 6) {
                Text("총 손익")
                    .font(.caption)
                    .foregroundStyle(AppTheme.secondaryText)
                Text((totalProfit >= 0 ? "+" : "") + formatPrice(Int(totalProfit)) + "P")
                    .font(.system(size: 22, weight: .bold).monospacedDigit())
                    .foregroundStyle(totalProfit >= 0 ? AppTheme.gain : AppTheme.loss)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            // 총 수익률
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

    // MARK: - Holdings Table Card
    private var holdingsTableCard: some View {
        VStack(spacing: 0) {
            // Table Header
            HStack(spacing: 0) {
                Text("종목명")
                    .frame(maxWidth: .infinity, alignment: .leading)

                Text("현재가")
                    .frame(width: 130, alignment: .trailing)

                Text("손익")
                    .frame(width: 130, alignment: .trailing)

                Text("보유수량")
                    .frame(width: 80, alignment: .trailing)

                Text("보유 비중")
                    .frame(width: 140, alignment: .trailing)

                Text("주문")
                    .frame(width: 110, alignment: .center)
            }
            .font(.caption)
            .foregroundStyle(AppTheme.secondaryText)
            .padding(.horizontal, 16)
            .padding(.vertical, 12)

            Divider()
                .background(AppTheme.border)

            // Table Rows
            ForEach(filteredHoldings) { holding in
                HoldingRow(
                    holding: holding,
                    isSelected: holding.id == selectedHoldingID,
                    totalPortfolioValue: totalValue,
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
                    Image(systemName: "magnifyingglass")
                        .font(.title2)
                        .foregroundStyle(AppTheme.tertiaryText)
                    Text("검색 결과가 없습니다")
                        .font(.subheadline)
                        .foregroundStyle(AppTheme.secondaryText)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 40)
            }
        }
        .cardStyle()
    }

    // MARK: - Computed Properties
    private var totalValue: Double {
        appState.holdings.reduce(0) { $0 + $1.totalValue }
    }

    private var totalCost: Double {
        // 매입금액 = 현재가의 약 90% 기준 (임시)
        appState.holdings.reduce(0) { $0 + ($1.currentPrice * 0.9 * Double($1.quantity)) }
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
    let totalPortfolioValue: Double
    let onSelect: () -> Void

    @State private var isHovered = false

    private var profitLoss: Double {
        let cost = holding.currentPrice * 0.9 * Double(holding.quantity)
        return holding.totalValue - cost
    }

    private var profitPercent: Double {
        let cost = holding.currentPrice * 0.9
        guard cost > 0 else { return 0 }
        return ((holding.currentPrice - cost) / cost) * 100
    }

    private var portfolioWeight: Double {
        guard totalPortfolioValue > 0 else { return 0 }
        return (holding.totalValue / totalPortfolioValue) * 100
    }

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
                Text(formatPrice(Int(holding.currentPrice)) + "P")
                    .font(.system(.subheadline, weight: .medium).monospacedDigit())
                    .foregroundStyle(AppTheme.primaryText)
                PriceChangeBadge(change: holding.change)
            }
            .frame(width: 130, alignment: .trailing)

            // 손익
            VStack(alignment: .trailing, spacing: 2) {
                Text((profitLoss >= 0 ? "+" : "") + formatPrice(Int(profitLoss)) + "P")
                    .font(.system(.subheadline, weight: .medium).monospacedDigit())
                    .foregroundStyle(profitLoss >= 0 ? AppTheme.gain : AppTheme.loss)
                Text(String(format: "%+.1f%%", profitPercent))
                    .font(.system(.caption, weight: .medium).monospacedDigit())
                    .foregroundStyle(profitLoss >= 0 ? AppTheme.gain : AppTheme.loss)
            }
            .frame(width: 130, alignment: .trailing)

            // 보유수량
            Text("\(holding.quantity)주")
                .font(.system(.subheadline, weight: .medium).monospacedDigit())
                .foregroundStyle(AppTheme.primaryText)
                .frame(width: 80, alignment: .trailing)

            // 보유 비중 (progress bar)
            VStack(alignment: .trailing, spacing: 4) {
                Text(String(format: "%.1f%%", portfolioWeight))
                    .font(.system(.caption, weight: .medium).monospacedDigit())
                    .foregroundStyle(AppTheme.secondaryText)

                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 2)
                            .fill(AppTheme.cardBackgroundLight)
                            .frame(height: 4)

                        RoundedRectangle(cornerRadius: 2)
                            .fill(holding.avatarColor)
                            .frame(width: max(4, geo.size.width * CGFloat(portfolioWeight / 100)), height: 4)
                    }
                }
                .frame(height: 4)
            }
            .frame(width: 140, alignment: .trailing)

            // 주문 buttons
            HStack(spacing: 6) {
                Button {
                    onSelect()
                } label: {
                    Text("매수")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(Color.blue)
                        .clipShape(RoundedRectangle(cornerRadius: 6))
                }
                .buttonStyle(.plain)

                Button {
                    onSelect()
                } label: {
                    Text("매도")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(Color.orange)
                        .clipShape(RoundedRectangle(cornerRadius: 6))
                }
                .buttonStyle(.plain)
            }
            .frame(width: 110, alignment: .center)
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

// MARK: - Holding Inspector
struct HoldingInspector: View {
    let holding: Holding
    @State private var orderType: OrderType = .buy
    @State private var quantity = "1"

    enum OrderType: String, CaseIterable {
        case buy = "매수"
        case sell = "매도"
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                // Header
                VStack(alignment: .center, spacing: 12) {
                    AvatarView(name: holding.name, color: holding.avatarColor, size: 64)

                    Text(holding.name)
                        .font(.title3.weight(.semibold))
                        .foregroundStyle(AppTheme.primaryText)

                    Text(holding.ticker)
                        .font(.subheadline)
                        .foregroundStyle(AppTheme.secondaryText)

                    HStack(spacing: 8) {
                        Text(formatPrice(Int(holding.currentPrice)) + "P")
                            .font(.system(size: 24, weight: .bold).monospacedDigit())
                            .foregroundStyle(AppTheme.primaryText)

                        PriceChangeBadge(change: holding.change)
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(20)

                Divider()
                    .background(AppTheme.border)

                // Chart
                VStack(alignment: .leading, spacing: 8) {
                    Text("가격 추이")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(AppTheme.primaryText)

                    SparklineView(data: holding.sparklineData, showGradient: true)
                        .frame(height: 100)
                }
                .padding(16)

                Divider()
                    .background(AppTheme.border)

                // Stats
                VStack(spacing: 12) {
                    StatRow(label: "보유 수량", value: "\(holding.quantity)주")
                    StatRow(label: "평균 단가", value: formatPrice(Int(holding.currentPrice * 0.9)) + "P")
                    StatRow(label: "평가 금액", value: formatPrice(Int(holding.totalValue)) + "P")

                    let profit = holding.totalValue - (holding.currentPrice * 0.9 * Double(holding.quantity))
                    StatRow(label: "평가 손익", value: (profit >= 0 ? "+" : "") + formatPrice(Int(profit)) + "P")
                }
                .padding(16)

                Divider()
                    .background(AppTheme.border)

                // Order Form
                VStack(alignment: .leading, spacing: 16) {
                    Text("주문")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(AppTheme.primaryText)

                    // Custom Segmented Picker
                    HStack(spacing: 0) {
                        ForEach(OrderType.allCases, id: \.self) { type in
                            Button {
                                withAnimation(.easeInOut(duration: 0.15)) {
                                    orderType = type
                                }
                            } label: {
                                Text(type.rawValue)
                                    .font(.subheadline.weight(.semibold))
                                    .foregroundStyle(
                                        orderType == type
                                            ? .white
                                            : AppTheme.secondaryText
                                    )
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 8)
                                    .background(
                                        orderType == type
                                            ? (type == .buy ? Color.blue : Color.orange)
                                            : Color.clear
                                    )
                                    .clipShape(RoundedRectangle(cornerRadius: 6))
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(3)
                    .background(AppTheme.cardBackgroundLight)
                    .clipShape(RoundedRectangle(cornerRadius: 8))

                    HStack {
                        Text("수량")
                            .font(.subheadline)
                            .foregroundStyle(AppTheme.secondaryText)
                        Spacer()
                        HStack(spacing: 8) {
                            Button {
                                if let val = Int(quantity), val > 1 {
                                    quantity = "\(val - 1)"
                                }
                            } label: {
                                Image(systemName: "minus")
                                    .font(.caption.weight(.bold))
                                    .foregroundStyle(AppTheme.primaryText)
                                    .frame(width: 28, height: 28)
                                    .background(AppTheme.cardBackgroundLight)
                                    .clipShape(RoundedRectangle(cornerRadius: 6))
                            }
                            .buttonStyle(.plain)

                            TextField("", text: $quantity)
                                .textFieldStyle(.plain)
                                .font(.system(.subheadline, weight: .medium).monospacedDigit())
                                .multilineTextAlignment(.center)
                                .frame(width: 40)
                                .padding(.vertical, 4)
                                .background(AppTheme.cardBackgroundLight)
                                .clipShape(RoundedRectangle(cornerRadius: 6))

                            Button {
                                if let val = Int(quantity) {
                                    quantity = "\(val + 1)"
                                }
                            } label: {
                                Image(systemName: "plus")
                                    .font(.caption.weight(.bold))
                                    .foregroundStyle(AppTheme.primaryText)
                                    .frame(width: 28, height: 28)
                                    .background(AppTheme.cardBackgroundLight)
                                    .clipShape(RoundedRectangle(cornerRadius: 6))
                            }
                            .buttonStyle(.plain)

                            Text("주")
                                .font(.subheadline)
                                .foregroundStyle(AppTheme.secondaryText)
                        }
                    }

                    HStack {
                        Text("예상 금액")
                            .font(.subheadline)
                            .foregroundStyle(AppTheme.secondaryText)
                        Spacer()
                        Text(formatPrice(Int(holding.currentPrice) * (Int(quantity) ?? 1)) + "P")
                            .font(.system(.subheadline, weight: .semibold).monospacedDigit())
                            .foregroundStyle(AppTheme.primaryText)
                    }

                    Button(action: {}) {
                        Text(orderType == .buy ? "매수하기" : "매도하기")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 10)
                            .background(orderType == .buy ? Color.blue : Color.orange)
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                    }
                    .buttonStyle(.plain)
                }
                .padding(16)
            }
        }
        .background(AppTheme.cardBackground)
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
