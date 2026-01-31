import SwiftUI

// MARK: - Pending Request Model
struct FriendRequest: Identifiable {
    let id: UUID
    var name: String
    var avatarColor: Color
    var isSent: Bool // true = 내가 보낸 요청, false = 받은 요청
}

struct WatchlistView: View {
    @EnvironmentObject var appState: AppState
    @State private var selectedFriend: Friend?
    @State private var searchText = ""
    @State private var addFriendSearch = ""

    // Sample pending requests
    @State private var pendingRequests: [FriendRequest] = [
        FriendRequest(id: UUID(), name: "신유진", avatarColor: .gray, isSent: true),
        FriendRequest(id: UUID(), name: "임도현", avatarColor: .gray, isSent: false),
    ]

    private var filteredFriends: [Friend] {
        searchText.isEmpty ? appState.watchlist : appState.watchlist.filter {
            $0.name.contains(searchText) || $0.ticker.contains(searchText.uppercased())
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
                            Text("관심 종목")
                                .font(.title.weight(.bold))
                                .foregroundStyle(AppTheme.primaryText)
                            Text("친구들의 주가를 확인하세요")
                                .font(.subheadline)
                                .foregroundStyle(AppTheme.secondaryText)
                        }
                        Spacer()
                    }

                    // Add Friend Search Card
                    addFriendCard

                    // Pending Requests Card
                    if !pendingRequests.isEmpty {
                        pendingRequestsCard
                    }

                    // Watchlist Search
                    HStack(spacing: 8) {
                        Image(systemName: "magnifyingglass")
                            .foregroundStyle(AppTheme.secondaryText)
                        TextField("관심 종목 검색...", text: $searchText)
                            .textFieldStyle(.plain)
                            .font(.subheadline)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 10)
                    .background(AppTheme.cardBackground)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(AppTheme.border, lineWidth: 1)
                    )

                    // Friends Grid
                    LazyVGrid(columns: [
                        GridItem(.flexible(), spacing: 16),
                        GridItem(.flexible(), spacing: 16)
                    ], spacing: 16) {
                        ForEach(filteredFriends) { friend in
                            WatchlistFriendCard(
                                friend: friend,
                                isSelected: selectedFriend?.id == friend.id
                            )
                            .onTapGesture {
                                withAnimation(.easeInOut(duration: 0.2)) {
                                    selectedFriend = friend
                                }
                            }
                        }
                    }
                }
                .padding(24)
            }
            .background(AppTheme.background)
            .frame(minWidth: 500)

            // Right: Inspector Panel
            if let friend = selectedFriend {
                WatchlistInspector(friend: friend) {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        selectedFriend = nil
                    }
                }
                .frame(width: 320)
            }
        }
    }

    // MARK: - Add Friend Card
    private var addFriendCard: some View {
        HStack(spacing: 12) {
            Image(systemName: "person.2")
                .foregroundStyle(AppTheme.secondaryText)

            TextField("친구 이름 또는 ID로 검색...", text: $addFriendSearch)
                .textFieldStyle(.plain)
                .font(.subheadline)

            Spacer()

            Button(action: {}) {
                Text("친구 추가")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(Color.green)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
            }
            .buttonStyle(.plain)
        }
        .padding(16)
        .cardStyle()
    }

    // MARK: - Pending Requests Card
    private var pendingRequestsCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 8) {
                Image(systemName: "clock")
                    .foregroundStyle(AppTheme.secondaryText)
                Text("대기 중인 요청")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(AppTheme.primaryText)
            }

            VStack(spacing: 0) {
                ForEach(pendingRequests) { request in
                    HStack(spacing: 12) {
                        // Avatar
                        Circle()
                            .fill(request.avatarColor.gradient)
                            .frame(width: 36, height: 36)

                        Text(request.name)
                            .font(.subheadline.weight(.medium))
                            .foregroundStyle(AppTheme.primaryText)

                        Spacer()

                        if request.isSent {
                            Text("요청 보냄")
                                .font(.caption)
                                .foregroundStyle(AppTheme.secondaryText)
                        } else {
                            HStack(spacing: 8) {
                                Button(action: {
                                    withAnimation {
                                        pendingRequests.removeAll { $0.id == request.id }
                                    }
                                }) {
                                    Image(systemName: "checkmark")
                                        .font(.caption.weight(.bold))
                                        .foregroundStyle(.white)
                                        .frame(width: 30, height: 30)
                                        .background(Color.green)
                                        .clipShape(RoundedRectangle(cornerRadius: 6))
                                }
                                .buttonStyle(.plain)

                                Button(action: {
                                    withAnimation {
                                        pendingRequests.removeAll { $0.id == request.id }
                                    }
                                }) {
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
                    .padding(.vertical, 10)

                    if request.id != pendingRequests.last?.id {
                        Divider()
                            .background(AppTheme.border)
                    }
                }
            }
        }
        .padding(16)
        .cardStyle()
    }
}

// MARK: - Watchlist Friend Card
struct WatchlistFriendCard: View {
    let friend: Friend
    var isSelected: Bool = false
    @State private var isHovered = false

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Top: Avatar + Name + Price
            HStack {
                AvatarView(name: friend.name, color: friend.avatarColor, size: 40)

                VStack(alignment: .leading, spacing: 2) {
                    Text(friend.name)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(AppTheme.primaryText)
                }

                Spacer()

                // Star icon
                Image(systemName: "star.fill")
                    .foregroundStyle(Color.green)
                    .font(.caption)
            }

            // Price + Badge
            HStack(spacing: 8) {
                Text(formatPrice(Int(friend.currentPrice)) + "P")
                    .font(.system(size: 18, weight: .bold).monospacedDigit())
                    .foregroundStyle(AppTheme.primaryText)

                PriceChangeBadge(change: friend.change)
            }

            // Sparkline
            SparklineView(data: friend.sparklineData, showGradient: true)
                .frame(height: 50)
        }
        .padding(16)
        .background(
            isSelected
                ? AppTheme.cardBackgroundLight
                : AppTheme.cardBackground
        )
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(isSelected ? Color.green : AppTheme.border, lineWidth: isSelected ? 2 : 1)
        )
        .scaleEffect(isHovered ? 1.02 : 1.0)
        .animation(.easeInOut(duration: 0.15), value: isHovered)
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

// MARK: - Watchlist Inspector
struct WatchlistInspector: View {
    let friend: Friend
    var onClose: () -> Void

    @State private var selectedListingID: FriendListing.ID?
    @State private var investQuantity = "1"
    @State private var showInvestForm = false

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

                // Active Listings (상장 중인 종목)
                VStack(alignment: .leading, spacing: 12) {
                    HStack(spacing: 6) {
                        Image(systemName: "chart.line.uptrend.xyaxis")
                            .font(.caption)
                            .foregroundStyle(AppTheme.gain)
                        Text("상장 중인 종목")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(AppTheme.primaryText)
                    }

                    if friend.listings.isEmpty {
                        Text("상장 중인 종목이 없습니다")
                            .font(.caption)
                            .foregroundStyle(AppTheme.tertiaryText)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                    } else {
                        VStack(spacing: 8) {
                            ForEach(friend.listings) { listing in
                                ListingSelectRow(
                                    listing: listing,
                                    isSelected: selectedListingID == listing.id
                                )
                                .onTapGesture {
                                    withAnimation(.easeInOut(duration: 0.15)) {
                                        if selectedListingID == listing.id {
                                            selectedListingID = nil
                                            showInvestForm = false
                                        } else {
                                            selectedListingID = listing.id
                                            showInvestForm = true
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
                .padding(16)

                // Invest Form (appears when a listing is selected)
                if showInvestForm, let listingID = selectedListingID,
                   let listing = friend.listings.first(where: { $0.id == listingID }) {
                    Divider()
                        .background(AppTheme.border)

                    VStack(alignment: .leading, spacing: 16) {
                        HStack {
                            Text("투자하기")
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(AppTheme.primaryText)
                            Spacer()
                            Text(listing.title)
                                .font(.caption)
                                .foregroundStyle(AppTheme.gain)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 3)
                                .background(AppTheme.gain.opacity(0.15))
                                .clipShape(RoundedRectangle(cornerRadius: 4))
                        }

                        // Quantity
                        HStack {
                            Text("수량")
                                .font(.subheadline)
                                .foregroundStyle(AppTheme.secondaryText)
                            Spacer()
                            HStack(spacing: 8) {
                                Button {
                                    if let val = Int(investQuantity), val > 1 {
                                        investQuantity = "\(val - 1)"
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

                                TextField("", text: $investQuantity)
                                    .textFieldStyle(.plain)
                                    .font(.system(.subheadline, weight: .medium).monospacedDigit())
                                    .multilineTextAlignment(.center)
                                    .frame(width: 40)
                                    .padding(.vertical, 4)
                                    .background(AppTheme.cardBackgroundLight)
                                    .clipShape(RoundedRectangle(cornerRadius: 6))

                                Button {
                                    if let val = Int(investQuantity) {
                                        investQuantity = "\(val + 1)"
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

                        // Total
                        HStack {
                            Text("예상 금액")
                                .font(.subheadline)
                                .foregroundStyle(AppTheme.secondaryText)
                            Spacer()
                            Text(formatPrice(Int(friend.currentPrice) * (Int(investQuantity) ?? 1)) + "P")
                                .font(.system(.subheadline, weight: .semibold).monospacedDigit())
                                .foregroundStyle(AppTheme.primaryText)
                        }

                        // Buy button
                        Button(action: {}) {
                            Text("매수")
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 10)
                                .background(Color.green)
                                .clipShape(RoundedRectangle(cornerRadius: 8))
                        }
                        .buttonStyle(.plain)

                        // Bet button
                        Button(action: {}) {
                            Text("베팅하기")
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(AppTheme.primaryText)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 10)
                                .background(AppTheme.cardBackgroundLight)
                                .clipShape(RoundedRectangle(cornerRadius: 8))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 8)
                                        .stroke(AppTheme.border, lineWidth: 1)
                                )
                        }
                        .buttonStyle(.plain)
                    }
                    .padding(16)
                    .transition(.opacity.combined(with: .move(edge: .bottom)))
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

// MARK: - Listing Select Row (in inspector)
struct ListingSelectRow: View {
    let listing: FriendListing
    var isSelected: Bool = false

    var body: some View {
        VStack(spacing: 8) {
            HStack {
                Text(listing.title)
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(AppTheme.primaryText)
                Spacer()
                Text("\(Int(listing.progress * 100))%")
                    .font(.system(.caption, weight: .semibold).monospacedDigit())
                    .foregroundStyle(AppTheme.secondaryText)
            }

            // Progress bar
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 3)
                        .fill(AppTheme.cardBackgroundLight)
                        .frame(height: 6)

                    RoundedRectangle(cornerRadius: 3)
                        .fill(Color.green)
                        .frame(width: max(6, geo.size.width * CGFloat(listing.progress)), height: 6)
                }
            }
            .frame(height: 6)
        }
        .padding(12)
        .background(isSelected ? AppTheme.gain.opacity(0.08) : Color.clear)
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(isSelected ? AppTheme.gain.opacity(0.3) : AppTheme.border, lineWidth: 1)
        )
        .contentShape(Rectangle())
    }
}

// MARK: - Flow Layout
struct FlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = layout(proposal: proposal, subviews: subviews)
        return result.size
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = layout(proposal: proposal, subviews: subviews)
        for (index, frame) in result.frames.enumerated() {
            subviews[index].place(at: CGPoint(x: bounds.minX + frame.minX, y: bounds.minY + frame.minY), proposal: .unspecified)
        }
    }

    private func layout(proposal: ProposedViewSize, subviews: Subviews) -> (size: CGSize, frames: [CGRect]) {
        let maxWidth = proposal.width ?? .infinity
        var frames: [CGRect] = []
        var x: CGFloat = 0
        var y: CGFloat = 0
        var rowHeight: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)

            if x + size.width > maxWidth && x > 0 {
                x = 0
                y += rowHeight + spacing
                rowHeight = 0
            }

            frames.append(CGRect(origin: CGPoint(x: x, y: y), size: size))
            rowHeight = max(rowHeight, size.height)
            x += size.width + spacing
        }

        return (CGSize(width: maxWidth, height: y + rowHeight), frames)
    }
}

#Preview {
    WatchlistView()
        .environmentObject(AppState())
        .frame(width: 1000, height: 700)
        .preferredColorScheme(.dark)
}
