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
                    
                    // Watchlist Section (Starred)
                    watchlistSection
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
            
            VStack(spacing: 12) {
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
    @EnvironmentObject var appState: AppState
    @State private var orderType: OrderType = .buy
    @State private var quantity = "1"
    @State private var selectedListingID: UUID?
    @State private var showInsufficientFundsAlert = false
    @State private var showOverSellAlert = false
    @State private var showSuccessAlert = false
    @State private var alertMessage = ""

    enum OrderType: String, CaseIterable {
        case buy = "매수"
        case sell = "매도"
    }

    // 이 사람의 Friend 데이터에서 상장 항목 가져오기
    private var friendListings: [FriendListing] {
        appState.friends.first(where: { $0.name == holding.name })?.listings ?? []
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
                    StatRow(label: "총 보유 수량", value: "\(holding.quantity)주")
                    StatRow(label: "평균 단가", value: formatPrice(Int(holding.currentPrice * 0.9)) + "P")
                    StatRow(label: "평가 금액", value: formatPrice(Int(holding.totalValue)) + "P")

                    let profit = holding.totalValue - (holding.currentPrice * 0.9 * Double(holding.quantity))
                    StatRow(label: "평가 손익", value: (profit >= 0 ? "+" : "") + formatPrice(Int(profit)) + "P")
                }
                .padding(16)

                Divider()
                    .background(AppTheme.border)

                // My Investments in this person's listings
                VStack(alignment: .leading, spacing: 12) {
                    HStack(spacing: 6) {
                        Image(systemName: "chart.bar.doc.horizontal")
                            .foregroundStyle(.blue)
                        Text("투자 항목별 내역")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(AppTheme.primaryText)
                    }

                    if holding.investments.isEmpty {
                        Text("투자 내역이 없습니다")
                            .font(.caption)
                            .foregroundStyle(AppTheme.tertiaryText)
                            .padding(.vertical, 6)
                    } else {
                        VStack(spacing: 6) {
                            ForEach(holding.investments) { investment in
                                Button {
                                    // Find corresponding listing and select it
                                    if let match = friendListings.first(where: { $0.title == investment.listingTitle }) {
                                        withAnimation(.easeInOut(duration: 0.15)) {
                                            selectedListingID = match.id
                                            // Auto-set order type to Sell for convenience?
                                            orderType = .sell
                                        }
                                    }
                                } label: {
                                    HStack {
                                        VStack(alignment: .leading, spacing: 3) {
                                            Text(investment.listingTitle)
                                                .font(.subheadline.weight(.medium))
                                                .foregroundStyle(AppTheme.primaryText)
                                            Text("\(investment.quantity)주 보유")
                                                .font(.caption)
                                                .foregroundStyle(AppTheme.secondaryText)
                                        }
                                        Spacer()
                                        Text(formatPrice(Int(investment.totalValue)) + "P")
                                            .font(.system(.caption, weight: .semibold).monospacedDigit())
                                            .foregroundStyle(AppTheme.primaryText)
                                    }
                                    .padding(10)
                                    .background(
                                        // Highlight if selected
                                        (selectedListingID != nil && friendListings.first(where: { $0.id == selectedListingID })?.title == investment.listingTitle)
                                            ? Color.blue.opacity(0.1)
                                            : AppTheme.cardBackgroundLight
                                    )
                                    .clipShape(RoundedRectangle(cornerRadius: 8))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 8)
                                            .stroke(
                                                (selectedListingID != nil && friendListings.first(where: { $0.id == selectedListingID })?.title == investment.listingTitle)
                                                    ? Color.blue.opacity(0.5)
                                                    : Color.clear,
                                                lineWidth: 1
                                            )
                                    )
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                }
                .padding(16)

                Divider()
                    .background(AppTheme.border)

                // This person's listings (to buy/sell more)
                if !friendListings.isEmpty {
                    VStack(alignment: .leading, spacing: 12) {
                        HStack(spacing: 6) {
                            Image(systemName: "list.bullet.rectangle")
                                .foregroundStyle(.green)
                            Text("상장 항목")
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(AppTheme.primaryText)
                        }

                        VStack(spacing: 6) {
                            ForEach(friendListings) { listing in
                                Button {
                                    withAnimation(.easeInOut(duration: 0.15)) {
                                        selectedListingID = listing.id
                                    }
                                } label: {
                                    HStack {
                                        VStack(alignment: .leading, spacing: 4) {
                                            Text(listing.title)
                                                .font(.subheadline.weight(.medium))
                                                .foregroundStyle(AppTheme.primaryText)
                                            GeometryReader { geo in
                                                ZStack(alignment: .leading) {
                                                    RoundedRectangle(cornerRadius: 2)
                                                        .fill(AppTheme.cardBackgroundLight)
                                                        .frame(height: 4)
                                                    RoundedRectangle(cornerRadius: 2)
                                                        .fill(Color.green)
                                                        .frame(width: max(4, geo.size.width * listing.progress), height: 4)
                                                }
                                            }
                                            .frame(height: 4)
                                        }
                                        Spacer()
                                        Text("\(Int(listing.progress * 100))%")
                                            .font(.system(.caption, weight: .semibold).monospacedDigit())
                                            .foregroundStyle(AppTheme.secondaryText)
                                    }
                                    .padding(10)
                                    .background(
                                        selectedListingID == listing.id
                                            ? Color.green.opacity(0.1)
                                            : AppTheme.cardBackgroundLight
                                    )
                                    .clipShape(RoundedRectangle(cornerRadius: 8))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 8)
                                            .stroke(
                                                selectedListingID == listing.id ? Color.green.opacity(0.5) : Color.clear,
                                                lineWidth: 1
                                            )
                                    )
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                    .padding(16)
                }

                Divider()
                    .background(AppTheme.border)

                // Order Form
                VStack(alignment: .leading, spacing: 16) {
                    Text("주문")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(AppTheme.primaryText)

                    if let selID = selectedListingID, let listing = friendListings.first(where: { $0.id == selID }) {
                        HStack(spacing: 4) {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundStyle(.green)
                                .font(.caption)
                            Text("'\(listing.title)' 선택됨")
                                .font(.caption)
                                .foregroundStyle(.green)
                        }
                        .padding(.bottom, 4)
                    }

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

                    // 보유 현금 표시
                    HStack {
                        Text("보유 현금")
                            .font(.caption)
                            .foregroundStyle(AppTheme.secondaryText)
                        Spacer()
                        Text(formatPrice(Int(appState.cash)) + "P")
                            .font(.system(.caption, weight: .semibold).monospacedDigit())
                            .foregroundStyle(AppTheme.secondaryText)
                    }

                    Button {
                        executeOrder()
                    } label: {
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
        .alert("잔고 부족", isPresented: $showInsufficientFundsAlert) {
            Button("확인", role: .cancel) {}
        } message: {
            Text(alertMessage)
        }
        .alert("매도 불가", isPresented: $showOverSellAlert) {
            Button("확인", role: .cancel) {}
        } message: {
            Text(alertMessage)
        }
        .alert("주문 완료", isPresented: $showSuccessAlert) {
            Button("확인", role: .cancel) {}
        } message: {
            Text(alertMessage)
        }
    }

    private func executeOrder() {
        let qty = Int(quantity) ?? 1

        if orderType == .buy {
            // 매수
            guard let selID = selectedListingID,
                  let listing = friendListings.first(where: { $0.id == selID }) else {
                alertMessage = "상장 항목을 선택해주세요."
                showOverSellAlert = true
                return
            }

            let totalCost = holding.currentPrice * Double(qty)
            if appState.cash < totalCost {
                alertMessage = "보유 현금(\(formatPrice(Int(appState.cash)))P)이 부족합니다.\n필요 금액: \(formatPrice(Int(totalCost)))P"
                showInsufficientFundsAlert = true
                return
            }

            let success = appState.buyStock(
                friendName: holding.name,
                listingTitle: listing.title,
                quantity: qty,
                pricePerShare: holding.currentPrice
            )
            if success {
                alertMessage = "\(holding.name)의 '\(listing.title)' \(qty)주 매수 완료!"
                showSuccessAlert = true
                quantity = "1"
                selectedListingID = nil
            }
        } else {
            // 매도
            guard let selID = selectedListingID,
                  let listing = friendListings.first(where: { $0.id == selID }) else {
                alertMessage = "상장 항목을 선택해주세요."
                showOverSellAlert = true
                return
            }

            // 보유량 확인
            let myQty = holding.investments.first(where: { $0.listingTitle == listing.title })?.quantity ?? 0
            if qty > myQty {
                alertMessage = "보유 수량(\(myQty)주)보다 많이 매도할 수 없습니다."
                showOverSellAlert = true
                return
            }
            if myQty == 0 {
                alertMessage = "해당 항목을 보유하고 있지 않습니다."
                showOverSellAlert = true
                return
            }

            let success = appState.sellStock(
                friendName: holding.name,
                listingTitle: listing.title,
                quantity: qty,
                pricePerShare: holding.currentPrice
            )
            if success {
                alertMessage = "\(holding.name)의 '\(listing.title)' \(qty)주 매도 완료!"
                showSuccessAlert = true
                quantity = "1"
                selectedListingID = nil
            }
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
