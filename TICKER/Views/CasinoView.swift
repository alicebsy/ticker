import SwiftUI

struct CasinoView: View {
    @EnvironmentObject var appState: AppState
    @State private var betAmount = ""
    @State private var selectedFriendId: Int?
    @State private var selectedBetType: BetType = .success
    @State private var showInsufficientFundsAlert = false
    @State private var showBetSuccessAlert = false
    @State private var alertMessage = ""
    
    var selectedFriend: CasinoFriend? {
        appState.casinoFriends.first(where: { $0.id == selectedFriendId })
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Header
                headerSection
                
                // 예언 배팅 (친구 성공/실패 예측)
                prophecyBetSection
                
                // Recent Bets
                recentBetsSection
            }
            .padding(24)
        }
        .onAppear {
            Task {
                await appState.fetchCasinoData()
            }
        }
        .navigationTitle("카지노")
        .alert("잔고 부족", isPresented: $showInsufficientFundsAlert) {
            Button("확인", role: .cancel) {}
        } message: {
            Text(alertMessage)
        }
        .alert("베팅 완료", isPresented: $showBetSuccessAlert) {
            Button("확인", role: .cancel) {}
        } message: {
            Text(alertMessage)
        }
    }

    // MARK: - Bet Action
    private func placeBetAction() {
        guard let friendId = selectedFriendId else { return }
        guard let amount = Int(betAmount), amount > 0 else { return }

        if amount > appState.cash {
            alertMessage = "보유 현금(\(formatCasinoPrice(appState.cash))P)이 부족합니다.\n베팅 금액: \(formatCasinoPrice(amount))P"
            showInsufficientFundsAlert = true
            return
        }

        Task {
            let success = await appState.placeBet(targetUserId: friendId, amount: amount, predictSuccess: selectedBetType == .success)
            if success {
                alertMessage = "\(selectedFriend?.name ?? "친구")에게 '\(selectedBetType.rawValue)' \(formatCasinoPrice(amount))P 베팅 완료!"
                showBetSuccessAlert = true
                // 초기화
                betAmount = ""
                selectedFriendId = nil
            } else {
                alertMessage = "베팅에 실패했습니다. 잔고를 확인해주세요."
                showInsufficientFundsAlert = true
            }
        }
    }

    private func formatCasinoPrice(_ value: Int) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        return formatter.string(from: NSNumber(value: value)) ?? "0"
    }
    
    // MARK: - Header Section
    private var headerSection: some View {
        HStack {
            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 8) {
                    Image(systemName: "dice.fill")
                        .font(.title)
                        .foregroundStyle(AppTheme.casino)
                    
                    Text("카지노")
                        .font(.largeTitle.weight(.bold))
                }
                
                Text("친구의 할 일 성공/실패를 예언하고 베팅하세요")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 4) {
                Text("베팅 가능 금액")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text(formatCasinoPrice(Int(appState.cash)) + "P")
                    .font(.title2.weight(.bold))
                    .foregroundStyle(AppTheme.casino)
            }
        }
        .padding()
        .background(
            LinearGradient(
                colors: [Color.black.opacity(0.8), Color.pink.opacity(0.3)],
                startPoint: .leading,
                endPoint: .trailing
            )
        )
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
    
    // MARK: - 예언 배팅 Section (친구 성공/실패 예측)
    private var prophecyBetSection: some View {
        VStack(spacing: 20) {
            VStack(alignment: .leading, spacing: 12) {
                Text("예언 배팅")
                    .font(.headline)
                Text("친구를 선택하고, 할 일 성공/실패를 예언한 뒤 베팅하세요.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            // Friend Selection
            VStack(alignment: .leading, spacing: 12) {
                Text("베팅 대상 선택")
                    .font(.subheadline.weight(.semibold))
                
                if appState.casinoFriends.isEmpty {
                    Text("친구가 없습니다. 워치리스트에 친구를 추가하면 베팅할 수 있습니다.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .padding(.vertical, 8)
                } else {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 12) {
                            ForEach(appState.casinoFriends) { friend in
                                FriendBetCard(
                                    name: friend.name,
                                    isSelected: selectedFriendId == friend.id,
                                    action: { selectedFriendId = friend.id }
                                )
                            }
                        }
                    }
                }
            }
            
            // Bet Type Selection
            if selectedFriend != nil {
                VStack(alignment: .leading, spacing: 12) {
                    Text("베팅 유형")
                        .font(.subheadline.weight(.semibold))
                    
                    HStack(spacing: 16) {
                        BetTypeButton(
                            type: .success,
                            isSelected: selectedBetType == .success,
                            action: { selectedBetType = .success }
                        )
                        
                        BetTypeButton(
                            type: .failure,
                            isSelected: selectedBetType == .failure,
                            action: { selectedBetType = .failure }
                        )
                    }
                }
            }
            
            // Bet Amount
            if selectedFriend != nil {
                VStack(alignment: .leading, spacing: 12) {
                    Text("베팅 금액 (P)")
                        .font(.subheadline.weight(.semibold))
                    
                    HStack {
                        TextField("금액 입력", text: $betAmount)
                            .textFieldStyle(.roundedBorder)
                        
                        Text("P")
                            .foregroundStyle(.secondary)
                    }
                    
                    // Quick Amount Buttons
                    HStack(spacing: 8) {
                        ForEach(["1000", "5000", "10000", "50000"], id: \.self) { amount in
                            Button(amount) {
                                betAmount = amount
                            }
                            .buttonStyle(.bordered)
                            .controlSize(.small)
                        }
                    }
                }
            }
            
            // Bet Summary
            if selectedFriend != nil && !betAmount.isEmpty {
                betSummary
            }
        }
        .padding()
        .cardStyle()
    }
    
    // MARK: - Bet Summary
    private var betSummary: some View {
        VStack(spacing: 16) {
            Divider()
            
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("베팅 대상")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text(selectedFriend?.name ?? "-")
                        .font(.subheadline.weight(.semibold))
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    Text("베팅 유형")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text(selectedBetType.rawValue)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(selectedBetType.color)
                }
            }
            
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("베팅 금액")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text("₩\(betAmount)")
                        .font(.subheadline.weight(.semibold))
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    Text("예상 수익")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text("₩\((Int(betAmount) ?? 0) * 2)")
                        .font(.subheadline.weight(.bold))
                        .foregroundStyle(AppTheme.gain)
                }
            }
            
            Button {
                placeBetAction()
            } label: {
                Text("베팅하기")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .tint(AppTheme.casino)
            .controlSize(.large)
        }
    }
    
    // MARK: - Recent Bets Section
    private var recentBetsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("최근 베팅 내역")
                .font(.headline)
            
            if appState.bettingHistory.isEmpty {
                Text("최근 내역이 없습니다")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding()
            } else {
                VStack(spacing: 8) {
                    ForEach(appState.bettingHistory) { bet in
                        RecentBetRow(
                            target: bet.targetName,
                            type: bet.betType == "SUCCESS" ? .success : .failure,
                            amount: bet.betAmount,
                            result: parseBetResult(bet.result),
                            profit: bet.profitLoss ?? 0,
                            unit: "P"
                        )
                    }
                }
            }
        }
    }
    
    private func parseBetResult(_ result: String?) -> RecentBetRow.BetResult {
        guard let result = result?.lowercased() else { return .pending }
        switch result {
        case "win": return .win
        case "lose": return .lose
        default: return .pending
        }
    }
}

// MARK: - Friend Bet Card
struct FriendBetCard: View {
    let name: String
    var color: Color = .blue
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                AvatarView(name: name, color: color, size: 50)
                
                Text(name)
                    .font(.caption.weight(.medium))
                
                Text("TICKER") // Mock
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
            .padding()
            .background(isSelected ? Color.accentColor.opacity(0.1) : Color(nsColor: .controlBackgroundColor))
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? Color.accentColor : Color.clear, lineWidth: 2)
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Bet Type Button
struct BetTypeButton: View {
    let type: BetType
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: type == .success ? "checkmark.circle.fill" : "xmark.circle.fill")
                    .font(.title)
                
                Text(type.rawValue)
                    .font(.subheadline.weight(.semibold))
                
                Text(type == .success ? "성공에 베팅" : "실패에 베팅")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(isSelected ? type.color.opacity(0.15) : Color(nsColor: .controlBackgroundColor))
            .foregroundStyle(isSelected ? type.color : .primary)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? type.color : Color.clear, lineWidth: 2)
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Prophecy Card
struct ProphecyCard: View {
    let title: String
    let yesOdds: Double
    let noOdds: Double
    let deadline: String
    let totalPool: Int
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.subheadline.weight(.medium))
            
            HStack {
                Text(deadline)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                
                Spacer()
                
                Text("총 베팅: ₩\(totalPool)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            
            HStack(spacing: 12) {
                Button(action: {}) {
                    VStack(spacing: 4) {
                        Text("YES")
                            .font(.caption.weight(.semibold))
                        Text("x\(String(format: "%.1f", yesOdds))")
                            .font(.caption2)
                    }
                    .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
                .tint(.green)
                
                Button(action: {}) {
                    VStack(spacing: 4) {
                        Text("NO")
                            .font(.caption.weight(.semibold))
                        Text("x\(String(format: "%.1f", noOdds))")
                            .font(.caption2)
                    }
                    .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
                .tint(.red)
            }
        }
        .padding()
        .background(Color(nsColor: .controlBackgroundColor).opacity(0.5))
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }
}

// MARK: - Recent Bet Row
struct RecentBetRow: View {
    let target: String
    let type: BetType
    let amount: Int
    let result: BetResult
    let profit: Int
    var unit: String = "P"
    
    enum BetResult {
        case win, lose, pending
    }
    
    var body: some View {
        HStack {
            Circle()
                .fill(type.color.opacity(0.2))
                .frame(width: 8, height: 8)
            
            Text(target)
                .font(.subheadline)
            
            Text("(\(type.rawValue))")
                .font(.caption)
                .foregroundStyle(.secondary)
            
            Spacer()
            
            Text("\(amount)\(unit)")
                .font(.subheadline)
            
            switch result {
            case .win:
                Text("+\(profit)\(unit)")
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(AppTheme.gain)
            case .lose:
                Text("\(profit)\(unit)")
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(AppTheme.loss)
            case .pending:
                Text("진행 중")
                    .font(.caption)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 2)
                    .background(Color.orange.opacity(0.2))
                    .clipShape(RoundedRectangle(cornerRadius: 4))
            }
        }
        .padding()
        .cardStyle()
    }
}

#Preview {
    CasinoView()
        .environmentObject(AppState())
        .frame(width: 800, height: 900)
}


