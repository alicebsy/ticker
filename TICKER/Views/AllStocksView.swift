import SwiftUI

struct AllStocksView: View {
    @EnvironmentObject var appState: AppState
    @State private var selectedFriendID: UUID?
    @State private var searchCode = ""
    @State private var searchResult: Friend? = nil
    @State private var showSearchResult = false
    @State private var showInsufficientFundsAlert = false
    @State private var showOverSellAlert = false
    @State private var alertMessage = ""

    // Mock data for Public View (Strangers)
    @State private var publicStocks: [Friend] = [
        Friend(id: UUID(), name: "익명1", ticker: "ANON1", currentPrice: 12000, change: 5.4, bio: "", avatarColor: .gray, sparklineData: [100, 102, 105, 103, 108, 110, 112], skills: [], trustScore: 50, listings: [
            FriendListing(id: UUID(), title: "알고리즘 공부", progress: 0.60),
            FriendListing(id: UUID(), title: "영어 회화", progress: 0.30),
        ]),
        Friend(id: UUID(), name: "익명2", ticker: "ANON2", currentPrice: 8500, change: -2.1, bio: "", avatarColor: .gray, sparklineData: [100, 98, 95, 97, 94, 92, 90], skills: [], trustScore: 50, listings: [
            FriendListing(id: UUID(), title: "다이어트 챌린지", progress: 0.45),
        ]),
        Friend(id: UUID(), name: "익명3", ticker: "ANON3", currentPrice: 34000, change: 12.5, bio: "", avatarColor: .gray, sparklineData: [100, 110, 120, 115, 125, 130, 140], skills: [], trustScore: 50, listings: [
            FriendListing(id: UUID(), title: "앱 개발", progress: 0.80),
            FriendListing(id: UUID(), title: "포트폴리오 완성", progress: 0.55),
        ]),
        Friend(id: UUID(), name: "익명4", ticker: "ANON4", currentPrice: 5600, change: 0.8, bio: "", avatarColor: .gray, sparklineData: [100, 101, 102, 101, 102, 103, 104], skills: [], trustScore: 50, listings: [
            FriendListing(id: UUID(), title: "독서 50권", progress: 0.20),
        ]),
        Friend(id: UUID(), name: "익명5", ticker: "ANON5", currentPrice: 19800, change: -5.6, bio: "", avatarColor: .gray, sparklineData: [100, 95, 90, 85, 90, 85, 80], skills: [], trustScore: 50, listings: [
            FriendListing(id: UUID(), title: "러닝 대회 준비", progress: 0.70),
        ])
    ]

    private var isPublic: Bool {
        appState.visibility == .publicVisible
    }

    private var selectedFriend: Friend? {
        guard let id = selectedFriendID else { return nil }
        // Search across friends + publicStocks
        if let f = appState.friends.first(where: { $0.id == id }) { return f }
        if let f = publicStocks.first(where: { $0.id == id }) { return f }
        return nil
    }

    var body: some View {
        HSplitView {
            // Left: Main Content
            ScrollView {
                VStack(spacing: 20) {
                    // Header
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("모든 종목")
                                .font(.title.weight(.bold))
                                .foregroundStyle(AppTheme.primaryText)
                            Text(isPublic ? "전체 사용자의 주가를 확인하세요" : "친구들의 주가를 확인하세요")
                                .font(.subheadline)
                                .foregroundStyle(AppTheme.secondaryText)
                        }
                        Spacer()
                    }

                    // Code Search Bar
                    codeSearchSection

                    // Pending Friend Requests
                    if !appState.friendRequests.isEmpty {
                        friendRequestsSection
                    }

                    // Friends Section (always visible)
                    if !appState.friends.isEmpty {
                        friendsGridSection
                    }

                    // Public anonymous stocks (only if public)
                    if isPublic {
                        anonymousStocksSection
                    }
                }
                .padding(24)
            }
            .background(AppTheme.background)
            .frame(minWidth: 500)

            // Right: Inspector Panel
            if let friend = selectedFriend {
                AllStocksInspector(friend: friend, onClose: {
                    withAnimation {
                        selectedFriendID = nil
                    }
                }, onInvest: { listingTitle, qty in
                    investInFriend(friend: friend, listingTitle: listingTitle, quantity: qty)
                }, onSell: { listingTitle, qty in
                    sellFromFriend(friendName: friend.name, listingTitle: listingTitle, quantity: qty)
                })
                .frame(width: 340)
            }
        }
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
    }

    // MARK: - Code Search Section
    private var codeSearchSection: some View {
        VStack(spacing: 12) {
            HStack(spacing: 10) {
                HStack(spacing: 8) {
                    Image(systemName: "person.badge.plus")
                        .foregroundStyle(AppTheme.secondaryText)
                    TextField("친구 코드를 입력하세요...", text: $searchCode)
                        .textFieldStyle(.plain)
                        .font(.subheadline)
                        .onSubmit {
                            performCodeSearch()
                        }
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 10)
                .background(AppTheme.cardBackground)
                .clipShape(RoundedRectangle(cornerRadius: 8))
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(AppTheme.border, lineWidth: 1)
                )

                Button {
                    performCodeSearch()
                } label: {
                    Text("검색")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 9)
                        .background(Color.green.gradient)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                }
                .buttonStyle(.plain)
            }

            // Search Result
            if showSearchResult {
                if let result = searchResult {
                    HStack(spacing: 12) {
                        AvatarView(name: result.name, color: result.avatarColor, size: 36)

                        VStack(alignment: .leading, spacing: 2) {
                            Text(result.name)
                                .font(.subheadline.weight(.medium))
                                .foregroundStyle(AppTheme.primaryText)
                            Text(result.ticker)
                                .font(.caption)
                                .foregroundStyle(AppTheme.secondaryText)
                        }

                        Spacer()

                        if appState.friends.contains(where: { $0.name == result.name }) {
                            Text("이미 친구")
                                .font(.caption.weight(.medium))
                                .foregroundStyle(AppTheme.secondaryText)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 5)
                                .background(AppTheme.cardBackgroundLight)
                                .clipShape(RoundedRectangle(cornerRadius: 6))
                        } else {
                            Button {
                                addFriend(result)
                            } label: {
                                HStack(spacing: 4) {
                                    Image(systemName: "person.badge.plus")
                                        .font(.caption)
                                    Text("친구 추가")
                                        .font(.caption.weight(.semibold))
                                }
                                .foregroundStyle(.white)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(Color.green.gradient)
                                .clipShape(RoundedRectangle(cornerRadius: 6))
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(14)
                    .background(AppTheme.cardBackground)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(Color.green.opacity(0.3), lineWidth: 1)
                    )
                } else {
                    HStack {
                        Image(systemName: "person.slash")
                            .foregroundStyle(AppTheme.tertiaryText)
                        Text("해당 코드의 사용자를 찾을 수 없습니다")
                            .font(.subheadline)
                            .foregroundStyle(AppTheme.secondaryText)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(AppTheme.cardBackground)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(AppTheme.border, lineWidth: 1)
                    )
                }
            }
        }
        .cardStyle()
        .padding(0)
        .background(Color.clear)
        .overlay(EmptyView()) // Reset card style, apply manually
    }

    // MARK: - Friend Requests Section
    private var friendRequestsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 6) {
                Image(systemName: "clock.fill")
                    .foregroundStyle(.green)
                Text("대기 중인 요청")
                    .font(.headline)
                    .foregroundStyle(AppTheme.primaryText)
            }
            .padding(.horizontal, 16)
            .padding(.top, 16)

            VStack(spacing: 4) {
                ForEach(appState.friendRequests) { request in
                    HStack(spacing: 12) {
                        Circle()
                            .fill(request.avatarColor.gradient)
                            .frame(width: 36, height: 36)
                            .overlay(
                                Text(String(request.name.prefix(1)))
                                    .font(.system(size: 14, weight: .bold))
                                    .foregroundStyle(.white)
                            )

                        Text(request.name)
                            .font(.subheadline.weight(.medium))
                            .foregroundStyle(AppTheme.primaryText)

                        Spacer()

                        if request.isSentByMe {
                            Text("요청 보냄")
                                .font(.caption)
                                .foregroundStyle(AppTheme.secondaryText)
                        } else {
                            HStack(spacing: 6) {
                                Button {
                                    acceptFriendRequest(request)
                                } label: {
                                    Image(systemName: "checkmark")
                                        .font(.caption.weight(.bold))
                                        .foregroundStyle(.white)
                                        .frame(width: 30, height: 30)
                                        .background(Color.green)
                                        .clipShape(RoundedRectangle(cornerRadius: 6))
                                }
                                .buttonStyle(.plain)

                                Button {
                                    declineFriendRequest(request)
                                } label: {
                                    Image(systemName: "xmark")
                                        .font(.caption.weight(.bold))
                                        .foregroundStyle(AppTheme.primaryText)
                                        .frame(width: 30, height: 30)
                                        .background(AppTheme.cardBackgroundLight)
                                        .clipShape(RoundedRectangle(cornerRadius: 6))
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(AppTheme.cardBackgroundLight)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                    .padding(.horizontal, 12)
                }
            }
            .padding(.bottom, 16)
        }
        .cardStyle()
    }

    // MARK: - Friends Grid Section
    private var friendsGridSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 6) {
                Image(systemName: "person.2.fill")
                    .foregroundStyle(.green)
                Text("친구")
                    .font(.headline)
                    .foregroundStyle(AppTheme.primaryText)

                Spacer()

                Text("\(appState.friends.count)명")
                    .font(.subheadline)
                    .foregroundStyle(AppTheme.secondaryText)
            }

            LazyVGrid(columns: [
                GridItem(.flexible(), spacing: 16),
                GridItem(.flexible(), spacing: 16)
            ], spacing: 16) {
                ForEach(appState.friends) { friend in
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
                        },
                        onClick: {
                            withAnimation(.easeInOut(duration: 0.2)) {
                                selectedFriendID = friend.id
                            }
                        }
                    )
                }
            }
        }
    }

    // MARK: - Anonymous Stocks Section (Public only)
    private var anonymousStocksSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 6) {
                Image(systemName: "globe")
                    .foregroundStyle(.cyan)
                Text("전체 공개 종목")
                    .font(.headline)
                    .foregroundStyle(AppTheme.primaryText)

                Spacer()

                Text("\(publicStocks.count)개")
                    .font(.subheadline)
                    .foregroundStyle(AppTheme.secondaryText)
            }

            LazyVGrid(columns: [
                GridItem(.flexible(), spacing: 16),
                GridItem(.flexible(), spacing: 16)
            ], spacing: 16) {
                ForEach(publicStocks) { friend in
                    StockCardView(
                        name: friend.name,
                        price: Int(friend.currentPrice),
                        change: friend.change,
                        sparklineData: friend.sparklineData,
                        onClick: {
                            withAnimation(.easeInOut(duration: 0.2)) {
                                selectedFriendID = friend.id
                            }
                        }
                    )
                }
            }
        }
    }

    // MARK: - Actions
    private func performCodeSearch() {
        guard !searchCode.trimmingCharacters(in: .whitespaces).isEmpty else { return }
        // Simulate search - for demo, match partial code to a random friend
        let mockResults: [Friend] = [
            Friend(id: UUID(), name: "한서연", ticker: "SEOYEON", currentPrice: 18500, change: 4.2, bio: "대학원생", avatarColor: .mint, sparklineData: [100, 103, 106, 108, 110, 112, 115], skills: ["Swift"], trustScore: 88, listings: [
                FriendListing(id: UUID(), title: "졸업 논문", progress: 0.50),
            ]),
        ]
        // Simple demo: always find a result for non-empty search
        if searchCode.count >= 4 {
            searchResult = mockResults.first
        } else {
            searchResult = nil
        }
        withAnimation(.easeInOut(duration: 0.2)) {
            showSearchResult = true
        }
    }

    private func addFriend(_ friend: Friend) {
        // Add to friend requests as "sent by me"
        let request = FriendRequest(id: UUID(), name: friend.name, avatarColor: friend.avatarColor, isSentByMe: true)
        appState.friendRequests.append(request)
        withAnimation {
            showSearchResult = false
            searchCode = ""
        }
    }

    private func acceptFriendRequest(_ request: FriendRequest) {
        // Remove from requests and add as friend
        appState.friendRequests.removeAll { $0.id == request.id }
        let newFriend = Friend(
            id: UUID(),
            name: request.name,
            ticker: String(request.name.prefix(2)).uppercased(),
            currentPrice: Double.random(in: 8000...25000),
            change: Double.random(in: -5...8),
            bio: "",
            avatarColor: request.avatarColor == .gray ? [Color.blue, .pink, .orange, .green, .purple, .mint].randomElement()! : request.avatarColor,
            sparklineData: (0..<10).map { _ in Double.random(in: 90...120) },
            skills: [],
            trustScore: Int.random(in: 70...95),
            listings: [
                FriendListing(id: UUID(), title: "목표 달성", progress: Double.random(in: 0.2...0.8)),
            ]
        )
        appState.friends.append(newFriend)
    }

    private func declineFriendRequest(_ request: FriendRequest) {
        appState.friendRequests.removeAll { $0.id == request.id }
    }

    private func sellFromFriend(friendName: String, listingTitle: String, quantity: Int) {
        // 보유량 확인
        guard let holding = appState.holdings.first(where: { $0.name == friendName }),
              let investment = holding.investments.first(where: { $0.listingTitle == listingTitle }) else {
            alertMessage = "해당 항목을 보유하고 있지 않습니다."
            showOverSellAlert = true
            return
        }

        if quantity > investment.quantity {
            alertMessage = "보유 수량(\(investment.quantity)주)보다 많이 매도할 수 없습니다."
            showOverSellAlert = true
            return
        }

        let price = appState.friends.first(where: { $0.name == friendName })?.currentPrice
            ?? publicStocks.first(where: { $0.name == friendName })?.currentPrice
            ?? holding.currentPrice

        let success = appState.sellStock(friendName: friendName, listingTitle: listingTitle, quantity: quantity, pricePerShare: price)
        if !success {
            alertMessage = "매도에 실패했습니다."
            showOverSellAlert = true
        }
    }

    private func investInFriend(friend: Friend, listingTitle: String, quantity: Int) {
        let totalCost = friend.currentPrice * Double(quantity)
        if appState.cash < totalCost {
            let formatter = NumberFormatter()
            formatter.numberStyle = .decimal
            let cashStr = formatter.string(from: NSNumber(value: Int(appState.cash))) ?? "0"
            let costStr = formatter.string(from: NSNumber(value: Int(totalCost))) ?? "0"
            alertMessage = "보유 현금(\(cashStr)P)이 부족합니다. 필요 금액: \(costStr)P"
            showInsufficientFundsAlert = true
            return
        }

        let success = appState.buyStock(friendName: friend.name, listingTitle: listingTitle, quantity: quantity, pricePerShare: friend.currentPrice)
        if !success {
            alertMessage = "매수에 실패했습니다. 잔고를 확인해주세요."
            showInsufficientFundsAlert = true
        }
    }
}

// MARK: - All Stocks Inspector (with listings + buy/sell)
struct AllStocksInspector: View {
    let friend: Friend
    var onClose: () -> Void
    var onInvest: ((String, Int) -> Void)?
    var onSell: ((String, Int) -> Void)?

    @EnvironmentObject var appState: AppState

    @State private var selectedListingID: UUID?
    @State private var investQuantity: Int = 1
    @State private var orderType: OrderType = .buy

    enum OrderType: String, CaseIterable {
        case buy = "매수"
        case sell = "매도"
    }

    // 이 사람에 대한 내 보유 정보
    private var myHolding: Holding? {
        appState.holdings.first(where: { $0.name == friend.name })
    }

    // 선택된 항목에 내가 보유한 수량
    private var myQuantityForSelectedListing: Int {
        guard let selID = selectedListingID,
              let listing = friend.listings.first(where: { $0.id == selID }),
              let holding = myHolding else { return 0 }
        return holding.investments.first(where: { $0.listingTitle == listing.title })?.quantity ?? 0
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                // Header with Close button
                HStack {
                    Text("주식 카드")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(AppTheme.primaryText)
                    Spacer()
                    Button(action: onClose) {
                        Image(systemName: "xmark")
                            .font(.caption.weight(.bold))
                            .foregroundStyle(AppTheme.secondaryText)
                            .frame(width: 24, height: 24)
                            .background(AppTheme.cardBackgroundLight)
                            .clipShape(Circle())
                    }
                    .buttonStyle(.plain)
                }
                .padding(16)

                // Avatar + Name + Price
                VStack(spacing: 10) {
                    AvatarView(name: friend.name, color: friend.avatarColor, size: 72)

                    Text(friend.name)
                        .font(.title3.weight(.semibold))
                        .foregroundStyle(AppTheme.primaryText)

                    Text(friend.ticker)
                        .font(.subheadline)
                        .foregroundStyle(AppTheme.secondaryText)

                    HStack(spacing: 8) {
                        Text(formatPrice(Int(friend.currentPrice)) + "P")
                            .font(.system(size: 22, weight: .bold).monospacedDigit())
                            .foregroundStyle(AppTheme.primaryText)
                    }

                    PriceChangeBadge(change: friend.change)
                }
                .frame(maxWidth: .infinity)
                .padding(.bottom, 20)

                Divider()
                    .background(AppTheme.border)

                // Chart
                VStack(alignment: .leading, spacing: 8) {
                    Text("7일 추이")
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(AppTheme.secondaryText)

                    SparklineView(data: friend.sparklineData, showGradient: true)
                        .frame(height: 80)
                }
                .padding(16)

                Divider()
                    .background(AppTheme.border)

                // Listings Section
                VStack(alignment: .leading, spacing: 12) {
                    HStack(spacing: 6) {
                        Image(systemName: "list.bullet.rectangle")
                            .foregroundStyle(.green)
                        Text("상장 항목")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(AppTheme.primaryText)
                    }

                    if friend.listings.isEmpty {
                        Text("상장 항목이 없습니다")
                            .font(.caption)
                            .foregroundStyle(AppTheme.tertiaryText)
                            .padding(.vertical, 8)
                    } else {
                        VStack(spacing: 6) {
                            ForEach(friend.listings) { listing in
                                let myQty = myHolding?.investments.first(where: { $0.listingTitle == listing.title })?.quantity ?? 0

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

                                            // Progress bar
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

                                            if myQty > 0 {
                                                Text("\(myQty)주 보유 중")
                                                    .font(.caption2)
                                                    .foregroundStyle(.blue)
                                            }
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
                }
                .padding(16)

                // Order Form (if listing selected)
                if let selectedID = selectedListingID,
                   let listing = friend.listings.first(where: { $0.id == selectedID }) {
                    Divider()
                        .background(AppTheme.border)

                    VStack(alignment: .leading, spacing: 14) {
                        Text("'\(listing.title)' 주문")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(AppTheme.primaryText)

                        // Buy/Sell Segmented Picker
                        HStack(spacing: 0) {
                            ForEach(OrderType.allCases, id: \.self) { type in
                                Button {
                                    withAnimation(.easeInOut(duration: 0.15)) {
                                        orderType = type
                                        investQuantity = 1
                                    }
                                } label: {
                                    Text(type.rawValue)
                                        .font(.subheadline.weight(.semibold))
                                        .foregroundStyle(
                                            orderType == type ? .white : AppTheme.secondaryText
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

                        if orderType == .sell {
                            HStack(spacing: 4) {
                                Image(systemName: "info.circle")
                                    .font(.caption2)
                                Text("보유: \(myQuantityForSelectedListing)주")
                                    .font(.caption)
                            }
                            .foregroundStyle(AppTheme.secondaryText)
                        }

                        // Quantity
                        HStack {
                            Text("수량")
                                .font(.subheadline)
                                .foregroundStyle(AppTheme.secondaryText)
                            Spacer()
                            HStack(spacing: 8) {
                                Button {
                                    if investQuantity > 1 { investQuantity -= 1 }
                                } label: {
                                    Image(systemName: "minus")
                                        .font(.caption.weight(.bold))
                                        .foregroundStyle(AppTheme.primaryText)
                                        .frame(width: 28, height: 28)
                                        .background(AppTheme.cardBackgroundLight)
                                        .clipShape(RoundedRectangle(cornerRadius: 6))
                                }
                                .buttonStyle(.plain)

                                Text("\(investQuantity)")
                                    .font(.system(.subheadline, weight: .medium).monospacedDigit())
                                    .frame(width: 40)
                                    .padding(.vertical, 4)
                                    .background(AppTheme.cardBackgroundLight)
                                    .clipShape(RoundedRectangle(cornerRadius: 6))
                                    .multilineTextAlignment(.center)

                                Button {
                                    if orderType == .sell {
                                        if investQuantity < myQuantityForSelectedListing {
                                            investQuantity += 1
                                        }
                                    } else {
                                        investQuantity += 1
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

                        // Estimated Amount
                        HStack {
                            Text("예상 금액")
                                .font(.subheadline)
                                .foregroundStyle(AppTheme.secondaryText)
                            Spacer()
                            Text(formatPrice(Int(friend.currentPrice) * investQuantity) + "P")
                                .font(.system(.subheadline, weight: .semibold).monospacedDigit())
                                .foregroundStyle(AppTheme.primaryText)
                        }

                        // Action Button
                        Button {
                            if orderType == .buy {
                                onInvest?(listing.title, investQuantity)
                            } else {
                                onSell?(listing.title, investQuantity)
                            }
                            investQuantity = 1
                            selectedListingID = nil
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
                        .disabled(orderType == .sell && myQuantityForSelectedListing == 0)
                        .opacity(orderType == .sell && myQuantityForSelectedListing == 0 ? 0.4 : 1)
                    }
                    .padding(16)
                }
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
    AllStocksView()
        .environmentObject(AppState())
        .frame(width: 1100, height: 700)
        .preferredColorScheme(.dark)
}
