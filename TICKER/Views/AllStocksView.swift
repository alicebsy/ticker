import SwiftUI

struct AllStocksView: View {
    @EnvironmentObject var appState: AppState
    @State private var selectedFriendID: UUID?
    @State private var searchText = ""
    
    // Mock data for Public View (Strangers)
    @State private var publicStocks: [Friend] = [
        Friend(id: UUID(), name: "익명1", ticker: "ANON1", currentPrice: 12000, change: 5.4, bio: "", avatarColor: .gray, sparklineData: [100, 102, 105, 103, 108, 110, 112], skills: [], trustScore: 50, listings: []),
        Friend(id: UUID(), name: "익명2", ticker: "ANON2", currentPrice: 8500, change: -2.1, bio: "", avatarColor: .gray, sparklineData: [100, 98, 95, 97, 94, 92, 90], skills: [], trustScore: 50, listings: []),
        Friend(id: UUID(), name: "익명3", ticker: "ANON3", currentPrice: 34000, change: 12.5, bio: "", avatarColor: .gray, sparklineData: [100, 110, 120, 115, 125, 130, 140], skills: [], trustScore: 50, listings: []),
        Friend(id: UUID(), name: "익명4", ticker: "ANON4", currentPrice: 5600, change: 0.8, bio: "", avatarColor: .gray, sparklineData: [100, 101, 102, 101, 102, 103, 104], skills: [], trustScore: 50, listings: []),
        Friend(id: UUID(), name: "익명5", ticker: "ANON5", currentPrice: 19800, change: -5.6, bio: "", avatarColor: .gray, sparklineData: [100, 95, 90, 85, 90, 85, 80], skills: [], trustScore: 50, listings: [])
    ]
    
    private var isPublic: Bool {
        appState.visibility == .publicVisible
    }
    
    private var sourceList: [Friend] {
        isPublic ? publicStocks : appState.watchlist
    }
    
    private var filteredList: [Friend] {
        if searchText.isEmpty {
            return sourceList
        } else {
            return sourceList.filter {
                $0.name.contains(searchText) || $0.ticker.contains(searchText.uppercased())
            }
        }
    }
    
    private var selectedFriend: Friend? {
        guard let id = selectedFriendID else { return nil }
        return sourceList.first { $0.id == id }
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

                    // Search
                    HStack(spacing: 8) {
                        Image(systemName: "magnifyingglass")
                            .foregroundStyle(AppTheme.secondaryText)
                        TextField("종목 검색...", text: $searchText)
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

                    // Grid
                    LazyVGrid(columns: [
                        GridItem(.flexible(), spacing: 16),
                        GridItem(.flexible(), spacing: 16)
                    ], spacing: 16) {
                        ForEach(filteredList) { friend in
                            StockCardView(
                                name: friend.name,
                                price: Int(friend.currentPrice),
                                change: friend.change,
                                sparklineData: friend.sparklineData,
                                isStarred: friend.isStarred,
                                onStarClick: {
                                    toggleStar(for: friend)
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
                .padding(24)
            }
            .background(AppTheme.background)
            .frame(minWidth: 500)

            // Right: Inspector Panel
            if let friend = selectedFriend {
                // Reusing WatchlistInspector or creating a similar one. 
                // Since WatchlistInspector is in WatchlistView.swift which I might delete, I should incorporate it here or verify its availability.
                // Assuming I will replace WatchListView content with this, I need to define the Inspector here or use a shared one.
                // I will define a local inspector for now or assume WatchlistInspector is available if I keep the file?
                // Plan: I'll copy the inspector code here to be safe and independent.
                AllStocksInspector(friend: friend, onClose: {
                    withAnimation {
                        selectedFriendID = nil
                    }
                })
                .frame(width: 320)
            }
        }
    }
    
    private func toggleStar(for friend: Friend) {
        if isPublic {
            // Can't star public unknown people in this iteration (or maybe add to friends?)
            // For now, no action or disabled
        } else {
            if let index = appState.watchlist.firstIndex(where: { $0.id == friend.id }) {
                appState.watchlist[index].isStarred.toggle()
            }
        }
    }
}

// MARK: - Inspector
struct AllStocksInspector: View {
    let friend: Friend
    var onClose: () -> Void

    @State private var selectedListingID: UUID?
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
                
                // ... (Additional details can be added here)
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
