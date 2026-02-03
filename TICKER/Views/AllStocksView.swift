import SwiftUI

struct AllStocksView: View {
    @EnvironmentObject var appState: AppState
    @State private var selectedFriendID: UUID?
    @State private var searchCode = ""
    @State private var searchResult: Friend? = nil
    @State private var showSearchResult = false

    private var isPublic: Bool {
        appState.visibility == .publicVisible
    }

    private var selectedFriend: Friend? {
        guard let id = selectedFriendID else { return nil }
        return appState.friends.first(where: { $0.id == id })
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
                            Text("친구들의 주가를 확인하고 투자하세요")
                                .font(.subheadline)
                                .foregroundStyle(AppTheme.secondaryText)
                        }
                        Spacer()

                        // 장 상태
                        HStack(spacing: 4) {
                            Circle()
                                .fill(appState.isMarketOpen ? Color.green : Color.orange)
                                .frame(width: 8, height: 8)
                            Text(appState.marketStatusText)
                                .font(.caption.weight(.medium))
                                .foregroundStyle(appState.isMarketOpen ? AppTheme.gain : .orange)
                        }
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(AppTheme.cardBackgroundLight)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                    }

                    // Code Search Bar
                    codeSearchSection

                    // Pending Friend Requests
                    if !appState.friendRequests.isEmpty {
                        friendRequestsSection
                    }

                    // Friends Section
                    if !appState.friends.isEmpty {
                        friendsGridSection
                    }
                }
                .padding(24)
            }
            .background(AppTheme.background)
            .frame(minWidth: 500)

            // Right: Person Detail Inspector
            if let friend = selectedFriend {
                PersonDetailView(friend: friend, onClose: {
                    withAnimation { selectedFriendID = nil }
                })
                .frame(width: 340)
            }
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
        .overlay(EmptyView())
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

    // MARK: - Actions
    private func performCodeSearch() {
        guard !searchCode.trimmingCharacters(in: .whitespaces).isEmpty else { return }
        
        Task {
            do {
                let users: [User] = try await NetworkManager.shared.searchUsers(query: searchCode)
                if let user = users.first {
                    // Convert User to Friend for display
                    searchResult = Friend(
                        id: UUID(),
                        userId: user.id,
                        name: user.name,
                        ticker: user.friendCode ?? user.name.prefix(2).uppercased(),
                        currentPrice: Double(user.stockPrice),
                        change: 0.0,
                        bio: "",
                        avatarColor: .blue,
                        sparklineData: [],
                        priceHistory: [],
                        isStarred: false,
                        sharesOutstanding: 0,
                        tradingVolume: 0,
                        todayRecord: nil,
                        dailyRecords: []
                    )
                } else {
                    searchResult = nil
                }
                withAnimation(.easeInOut(duration: 0.2)) {
                    showSearchResult = true
                }
            } catch {
                print("Search failed: \(error)")
                searchResult = nil
                showSearchResult = true
            }
        }
    }

    private func addFriend(_ friend: Friend) {
        Task {
            do {
                try await NetworkManager.shared.addFriend(friendCode: searchCode)
                // Refresh watchlist to get updated friend requests
                await appState.fetchMyData()
                withAnimation {
                    showSearchResult = false
                    searchCode = ""
                }
            } catch {
                print("Add friend failed: \(error)")
            }
        }
    }

    private func acceptFriendRequest(_ request: FriendRequest) {
        guard let requesterId = request.requestId else { return }
        Task {
            await appState.acceptFriendRequest(requesterId: requesterId)
        }
    }

    private func declineFriendRequest(_ request: FriendRequest) {
        guard let requesterId = request.requestId else { return }
        Task {
            await appState.declineFriendRequest(requesterId: requesterId)
        }
    }
}

#Preview {
    AllStocksView()
        .environmentObject(AppState())
        .frame(width: 1100, height: 700)
        .preferredColorScheme(.dark)
}
