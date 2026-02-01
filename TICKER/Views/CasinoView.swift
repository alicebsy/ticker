import SwiftUI

struct CasinoView: View {
    @EnvironmentObject var appState: AppState
    @State private var selectedGame: CasinoGame = .friendBet
    @State private var betAmount = ""
    @State private var selectedFriend: Friend?
    @State private var selectedBetType: BetType = .success
    @State private var showInsufficientFundsAlert = false
    @State private var showBetSuccessAlert = false
    @State private var alertMessage = ""
    
    enum CasinoGame: String, CaseIterable {
        case friendBet = "친구 베팅"
        case prophecy = "예언"
        case roulette = "룰렛"
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Header
                headerSection
                
                // Game Selector
                gameSelector
                
                // Game Content
                switch selectedGame {
                case .friendBet:
                    friendBetSection
                case .prophecy:
                    prophecySection
                case .roulette:
                    rouletteSection
                }
                
                // Recent Bets
                recentBetsSection
            }
            .padding(24)
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
        guard let friend = selectedFriend else { return }
        guard let amount = Int(betAmount), amount > 0 else { return }

        if Double(amount) > appState.cash {
            alertMessage = "보유 현금(\(formatCasinoPrice(Int(appState.cash)))P)이 부족합니다.\n베팅 금액: \(formatCasinoPrice(amount))P"
            showInsufficientFundsAlert = true
            return
        }

        let success = appState.placeBet(amount: amount, target: friend.name, betType: selectedBetType)
        if success {
            alertMessage = "\(friend.name)에게 '\(selectedBetType.rawValue)' \(formatCasinoPrice(amount))P 베팅 완료!"
            showBetSuccessAlert = true
            // 초기화
            betAmount = ""
            selectedFriend = nil
        } else {
            alertMessage = "베팅에 실패했습니다. 잔고를 확인해주세요."
            showInsufficientFundsAlert = true
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
                
                Text("친구의 성공/실패에 베팅하고 보상을 받으세요")
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
    
    // MARK: - Game Selector
    private var gameSelector: some View {
        Picker("게임", selection: $selectedGame) {
            ForEach(CasinoGame.allCases, id: \.self) { game in
                Text(game.rawValue).tag(game)
            }
        }
        .pickerStyle(.segmented)
    }
    
    // MARK: - Friend Bet Section
    private var friendBetSection: some View {
        VStack(spacing: 20) {
            // Friend Selection
            VStack(alignment: .leading, spacing: 12) {
                Text("베팅 대상 선택")
                    .font(.headline)
                
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(appState.friends) { friend in
                            FriendBetCard(
                                friend: friend,
                                isSelected: selectedFriend?.id == friend.id,
                                action: { selectedFriend = friend }
                            )
                        }
                    }
                }
            }
            
            // Bet Type Selection
            if selectedFriend != nil {
                VStack(alignment: .leading, spacing: 12) {
                    Text("베팅 유형")
                        .font(.headline)
                    
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
                    Text("베팅 금액")
                        .font(.headline)
                    
                    HStack {
                        TextField("금액 입력", text: $betAmount)
                            .textFieldStyle(.roundedBorder)
                        
                        Text("원")
                            .foregroundStyle(.secondary)
                    }
                    
                    // Quick Amount Buttons
                    HStack(spacing: 8) {
                        ForEach(["1,000", "5,000", "10,000", "50,000"], id: \.self) { amount in
                            Button(amount) {
                                betAmount = amount.replacingOccurrences(of: ",", with: "")
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
    
    // MARK: - Prophecy Section
    private var prophecySection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("진행 중인 예언")
                .font(.headline)
            
            VStack(spacing: 12) {
                ProphecyCard(
                    title: "김철수가 이번 달 안에 프로젝트를 완료할 것이다",
                    yesOdds: 1.8,
                    noOdds: 2.2,
                    deadline: "3일 남음",
                    totalPool: 125000
                )
                
                ProphecyCard(
                    title: "이영희의 주가가 다음 주에 10% 상승할 것이다",
                    yesOdds: 2.5,
                    noOdds: 1.5,
                    deadline: "7일 남음",
                    totalPool: 89000
                )
                
                ProphecyCard(
                    title: "박지민이 운동 30일 챌린지를 성공할 것이다",
                    yesOdds: 1.4,
                    noOdds: 3.0,
                    deadline: "15일 남음",
                    totalPool: 234000
                )
            }
        }
        .padding()
        .cardStyle()
    }
    
    // MARK: - Roulette Section
    private var rouletteSection: some View {
        VStack(spacing: 24) {
            Text("준비 중")
                .font(.title2.weight(.semibold))
                .foregroundStyle(.secondary)
            
            Image(systemName: "hourglass")
                .font(.system(size: 60))
                .foregroundStyle(.secondary)
            
            Text("룰렛 게임은 곧 출시됩니다")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(60)
        .cardStyle()
    }
    
    // MARK: - Recent Bets Section
    private var recentBetsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("최근 베팅 내역")
                .font(.headline)
            
            VStack(spacing: 8) {
                RecentBetRow(target: "김철수", type: .success, amount: 10000, result: .win, profit: 8000)
                RecentBetRow(target: "이영희", type: .failure, amount: 5000, result: .lose, profit: -5000)
                RecentBetRow(target: "박지민", type: .success, amount: 20000, result: .pending, profit: 0)
            }
        }
    }
}

// MARK: - Friend Bet Card
struct FriendBetCard: View {
    let friend: Friend
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                AvatarView(name: friend.name, color: friend.avatarColor, size: 50)
                
                Text(friend.name)
                    .font(.caption.weight(.medium))
                
                Text(friend.ticker)
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
            
            Text("₩\(amount)")
                .font(.subheadline)
            
            switch result {
            case .win:
                Text("+₩\(profit)")
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(AppTheme.gain)
            case .lose:
                Text("₩\(profit)")
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


