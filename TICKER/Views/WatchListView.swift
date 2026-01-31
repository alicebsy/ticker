import SwiftUI

struct WatchlistView: View {
    @EnvironmentObject var appState: AppState
    @State private var selectedFriend: Friend?
    @State private var showAddFriendSheet = false
    @State private var searchText = ""
    
    private var filteredFriends: [Friend] {
        searchText.isEmpty ? appState.watchlist : appState.watchlist.filter {
            $0.name.contains(searchText) || $0.ticker.contains(searchText.uppercased())
        }
    }
    
    var body: some View {
        HSplitView {
            // Friends List
            VStack(spacing: 0) {
                // Header Stats
                headerStats
                
                Divider()
                
                // Friends Grid
                ScrollView {
                    LazyVGrid(columns: [
                        GridItem(.flexible(), spacing: 16),
                        GridItem(.flexible(), spacing: 16)
                    ], spacing: 16) {
                        ForEach(filteredFriends) { friend in
                            FriendCard(friend: friend, isSelected: selectedFriend?.id == friend.id)
                                .onTapGesture {
                                    withAnimation(.easeInOut(duration: 0.2)) {
                                        selectedFriend = friend
                                    }
                                }
                        }
                    }
                    .padding()
                }
            }
            .frame(minWidth: 500)
            
            // Friend Detail Panel
            if let friend = selectedFriend {
                FriendDetailPanel(friend: friend)
                    .frame(width: 320)
            }
        }
        .navigationTitle("관심 종목")
        .searchable(text: $searchText, prompt: "친구 검색")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button(action: { showAddFriendSheet = true }) {
                    Label("친구 추가", systemImage: "person.badge.plus")
                }
            }
        }
        .sheet(isPresented: $showAddFriendSheet) {
            AddFriendSheet()
        }
    }
    
    // MARK: - Header Stats
    private var headerStats: some View {
        HStack(spacing: 32) {
            VStack(alignment: .leading, spacing: 4) {
                Text("관심 종목")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text("\(appState.watchlist.count)명")
                    .font(.title2.weight(.bold))
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text("상승")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text("\(appState.watchlist.filter { $0.isPositive }.count)명")
                    .font(.title2.weight(.bold))
                    .foregroundStyle(AppTheme.gain)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text("하락")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text("\(appState.watchlist.filter { !$0.isPositive }.count)명")
                    .font(.title2.weight(.bold))
                    .foregroundStyle(AppTheme.loss)
            }
            
            Spacer()
        }
        .padding()
        .background(Color(nsColor: .controlBackgroundColor))
    }
}

// MARK: - Friend Card
struct FriendCard: View {
    let friend: Friend
    var isSelected: Bool = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                AvatarView(name: friend.name, color: friend.avatarColor, size: 44)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(friend.name)
                        .font(.subheadline.weight(.semibold))
                    Text(friend.ticker)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 2) {
                    Text("₩\(Int(friend.currentPrice))")
                        .font(.subheadline.weight(.semibold))
                    PriceChangeBadge(change: friend.change)
                }
            }
            
            Text(friend.bio)
                .font(.caption)
                .foregroundStyle(.secondary)
                .lineLimit(2)
            
            SparklineView(data: friend.sparklineData)
                .frame(height: 40)
            
            // Skills
            HStack(spacing: 6) {
                ForEach(friend.skills.prefix(3), id: \.self) { skill in
                    Text(skill)
                        .font(.caption2)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color.accentColor.opacity(0.1))
                        .clipShape(RoundedRectangle(cornerRadius: 4))
                }
            }
            
            // Trust Score
            HStack {
                Image(systemName: "shield.checkered")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                
                Text("신뢰도 \(friend.trustScore)점")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                
                Spacer()
                
                Button(action: {}) {
                    Text("투자하기")
                        .font(.caption)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.small)
            }
        }
        .padding()
        .background(isSelected ? Color.accentColor.opacity(0.1) : Color(nsColor: .controlBackgroundColor))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(isSelected ? Color.accentColor : Color.clear, lineWidth: 2)
        )
        .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
    }
}

// MARK: - Friend Detail Panel
struct FriendDetailPanel: View {
    let friend: Friend
    @State private var investAmount = "10000"
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                // Header
                VStack(spacing: 12) {
                    AvatarView(name: friend.name, color: friend.avatarColor, size: 80)
                    
                    Text(friend.name)
                        .font(.title3.weight(.semibold))
                    
                    Text(friend.ticker)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    
                    Text(friend.bio)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                    
                    HStack(spacing: 8) {
                        Text("₩\(Int(friend.currentPrice))")
                            .font(.title2.weight(.bold))
                        
                        PriceChangeBadge(change: friend.change)
                    }
                }
                .frame(maxWidth: .infinity)
                .padding()
                
                Divider()
                
                // Chart
                VStack(alignment: .leading, spacing: 8) {
                    Text("가격 추이")
                        .font(.subheadline.weight(.semibold))
                    
                    SparklineView(data: friend.sparklineData, showGradient: true)
                        .frame(height: 100)
                }
                .padding()
                
                Divider()
                
                // Skills
                VStack(alignment: .leading, spacing: 12) {
                    Text("보유 스킬")
                        .font(.subheadline.weight(.semibold))
                    
                    FlowLayout(spacing: 8) {
                        ForEach(friend.skills, id: \.self) { skill in
                            Text(skill)
                                .font(.caption)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 6)
                                .background(Color.accentColor.opacity(0.1))
                                .clipShape(RoundedRectangle(cornerRadius: 6))
                        }
                    }
                }
                .padding()
                
                Divider()
                
                // Stats
                VStack(spacing: 12) {
                    StatRow(label: "신뢰도", value: "\(friend.trustScore)점")
                    StatRow(label: "투자자 수", value: "24명")
                    StatRow(label: "시가총액", value: "₩4,500,000")
                    StatRow(label: "거래량(24h)", value: "156주")
                }
                .padding()
                
                Divider()
                
                // Invest Form
                VStack(alignment: .leading, spacing: 16) {
                    Text("투자하기")
                        .font(.subheadline.weight(.semibold))
                    
                    HStack {
                        Text("금액")
                            .font(.subheadline)
                        Spacer()
                        TextField("금액", text: $investAmount)
                            .textFieldStyle(.roundedBorder)
                            .frame(width: 100)
                        Text("원")
                            .font(.subheadline)
                    }
                    
                    HStack {
                        Text("예상 주식 수")
                            .font(.subheadline)
                        Spacer()
                        Text("\((Int(investAmount) ?? 0) / Int(friend.currentPrice))주")
                            .font(.subheadline.weight(.semibold))
                    }
                    
                    Button(action: {}) {
                        Text("투자하기")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)
                    
                    Button(action: {}) {
                        Label("관심 목록에서 제거", systemImage: "star.slash")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bordered)
                }
                .padding()
            }
        }
        .background(Color(nsColor: .controlBackgroundColor))
    }
}

// MARK: - Add Friend Sheet
struct AddFriendSheet: View {
    @Environment(\.dismiss) private var dismiss
    @State private var searchQuery = ""
    
    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Button("취소") { dismiss() }
                    .keyboardShortcut(.cancelAction)
                
                Spacer()
                
                Text("친구 추가")
                    .font(.headline)
                
                Spacer()
                
                Button("완료") { dismiss() }
                    .keyboardShortcut(.defaultAction)
            }
            .padding()
            
            Divider()
            
            TextField("이름 또는 티커로 검색", text: $searchQuery)
                .textFieldStyle(.roundedBorder)
                .padding()
            
            List {
                ForEach(1..<6) { i in
                    HStack(spacing: 12) {
                        Circle()
                            .fill(Color.blue.gradient)
                            .frame(width: 40, height: 40)
                            .overlay(Text("U\(i)").foregroundStyle(.white).font(.caption.weight(.bold)))
                        
                        VStack(alignment: .leading) {
                            Text("사용자 \(i)")
                                .font(.subheadline.weight(.medium))
                            Text("USER\(i)")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        
                        Spacer()
                        
                        Button("추가") {}
                            .buttonStyle(.bordered)
                            .controlSize(.small)
                    }
                    .padding(.vertical, 4)
                }
            }
        }
        .frame(width: 400, height: 450)
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
        .frame(width: 900, height: 700)
}
