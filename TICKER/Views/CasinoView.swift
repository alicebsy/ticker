import SwiftUI

struct CasinoView: View {
    @EnvironmentObject var appState: AppState
    @State private var betAmount = ""
    @State private var selectedFriendId: Int?
    @State private var selectedBetType: BetType = .success
    @State private var showInsufficientFundsAlert = false
    @State private var showBetSuccessAlert = false
    @State private var alertMessage = ""

    // 예언 등록
    @State private var newProphecyContent = ""
    @State private var isCreatingProphecy = false

    // 예언 배팅
    @State private var selectedProphecy: Prophecy?
    @State private var prophecyBetAmount = ""
    @State private var prophecyBetType: BetType = .success

    // 예언 종료 확인
    @State private var prophecyToClose: Prophecy?
    @State private var showCloseConfirm = false
    @State private var closeAsSuccess = true

    var selectedFriend: CasinoFriend? {
        appState.casinoFriends.first(where: { $0.id == selectedFriendId })
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Header
                headerSection

                // 나의 예언 등록
                myProphecySection

                // 친구 예언 배팅
                friendProphecyBetSection

                // 기존 예언 배팅 (친구 할 일)
                prophecyBetSection

                // 내 배팅 내역
                myBetsSection
            }
            .padding(24)
        }
        .onAppear {
            Task {
                await appState.fetchCasinoData()
                await appState.fetchProphecyData()
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
        .alert("예언 종료", isPresented: $showCloseConfirm) {
            Button("성공", role: .none) {
                if let p = prophecyToClose {
                    Task { await closeProphecyAction(prophecyId: p.id, success: true) }
                }
            }
            Button("실패", role: .destructive) {
                if let p = prophecyToClose {
                    Task { await closeProphecyAction(prophecyId: p.id, success: false) }
                }
            }
            Button("취소", role: .cancel) {}
        } message: {
            Text("예언 결과를 선택하세요. 정산이 진행됩니다.")
        }
    }

    // MARK: - Actions
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
                betAmount = ""
                selectedFriendId = nil
            } else {
                alertMessage = "베팅에 실패했습니다. 잔고를 확인해주세요."
                showInsufficientFundsAlert = true
            }
        }
    }

    private func createProphecyAction() async {
        guard !newProphecyContent.trimmingCharacters(in: .whitespaces).isEmpty else { return }
        isCreatingProphecy = true
        let success = await appState.createProphecy(content: newProphecyContent)
        if success {
            newProphecyContent = ""
            alertMessage = "예언이 등록되었습니다!"
            showBetSuccessAlert = true
        }
        isCreatingProphecy = false
    }

    private func placeProphecyBetAction() async {
        guard let prophecy = selectedProphecy else { return }
        guard let amount = Int(prophecyBetAmount), amount > 0 else { return }

        if amount > appState.cash {
            alertMessage = "보유 현금(\(formatCasinoPrice(appState.cash))P)이 부족합니다."
            showInsufficientFundsAlert = true
            return
        }

        let success = await appState.placeProphecyBet(
            prophecyId: prophecy.id,
            amount: amount,
            predictSuccess: prophecyBetType == .success
        )

        if success {
            alertMessage = "'\(prophecy.content)'에 '\(prophecyBetType.rawValue)' \(formatCasinoPrice(amount))P 베팅 완료!"
            showBetSuccessAlert = true
            prophecyBetAmount = ""
            selectedProphecy = nil
        } else {
            alertMessage = "베팅에 실패했습니다."
            showInsufficientFundsAlert = true
        }
    }

    private func closeProphecyAction(prophecyId: Int, success: Bool) async {
        let result = await appState.closeProphecy(prophecyId: prophecyId, success: success)
        if result {
            alertMessage = "예언이 종료되고 정산이 완료되었습니다!"
            showBetSuccessAlert = true
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

                Text("예언을 등록하고 친구들의 예언에 베팅하세요!")
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

    // MARK: - 나의 예언 등록 Section
    private var myProphecySection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "sparkles")
                    .foregroundStyle(.yellow)
                Text("나의 예언 등록")
                    .font(.headline)
            }

            Text("사소하고 재미있는 예언을 등록해보세요. 친구들이 배팅할 수 있습니다.")
                .font(.caption)
                .foregroundStyle(.secondary)

            HStack {
                TextField("예: 오늘 헬스장 간다, 커피 3잔 안 마시기", text: $newProphecyContent)
                    .textFieldStyle(.roundedBorder)

                Button {
                    Task { await createProphecyAction() }
                } label: {
                    if isCreatingProphecy {
                        ProgressView()
                            .controlSize(.small)
                    } else {
                        Text("등록")
                    }
                }
                .buttonStyle(.borderedProminent)
                .tint(.yellow)
                .disabled(newProphecyContent.trimmingCharacters(in: .whitespaces).isEmpty || isCreatingProphecy)
            }

            // 내 진행 중인 예언 목록
            if !appState.myProphecies.filter({ $0.isOpen }).isEmpty {
                Divider()
                Text("내 진행 중인 예언")
                    .font(.subheadline.weight(.semibold))

                ForEach(appState.myProphecies.filter { $0.isOpen }) { prophecy in
                    MyProphecyRow(prophecy: prophecy) {
                        prophecyToClose = prophecy
                        showCloseConfirm = true
                    }
                }
            }
        }
        .padding()
        .cardStyle()
    }

    // MARK: - 친구 예언 배팅 Section
    private var friendProphecyBetSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "person.2.fill")
                    .foregroundStyle(.cyan)
                Text("친구 예언 배팅")
                    .font(.headline)
            }

            Text("친구들의 예언에 성공/실패를 예측하고 베팅하세요.")
                .font(.caption)
                .foregroundStyle(.secondary)

            if appState.bettableProphecies.isEmpty {
                Text("배팅 가능한 예언이 없습니다.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .padding(.vertical, 12)
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(appState.bettableProphecies) { prophecy in
                            FriendProphecyCard(
                                prophecy: prophecy,
                                isSelected: selectedProphecy?.id == prophecy.id,
                                onSelect: { selectedProphecy = prophecy }
                            )
                        }
                    }
                }

                // 선택된 예언 배팅 UI
                if let prophecy = selectedProphecy {
                    VStack(spacing: 12) {
                        Divider()

                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(prophecy.ownerName)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                Text(prophecy.content)
                                    .font(.subheadline.weight(.medium))
                            }
                            Spacer()
                            Button {
                                selectedProphecy = nil
                            } label: {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundStyle(.secondary)
                            }
                            .buttonStyle(.plain)
                        }

                        // 배팅 유형 선택
                        HStack(spacing: 16) {
                            BetTypeButton(
                                type: .success,
                                isSelected: prophecyBetType == .success,
                                action: { prophecyBetType = .success }
                            )

                            BetTypeButton(
                                type: .failure,
                                isSelected: prophecyBetType == .failure,
                                action: { prophecyBetType = .failure }
                            )
                        }

                        // 배팅 금액
                        HStack {
                            TextField("금액 입력", text: $prophecyBetAmount)
                                .textFieldStyle(.roundedBorder)
                            Text("P")
                                .foregroundStyle(.secondary)
                        }

                        HStack(spacing: 8) {
                            ForEach(["1000", "5000", "10000", "50000"], id: \.self) { amount in
                                Button(amount) {
                                    prophecyBetAmount = amount
                                }
                                .buttonStyle(.bordered)
                                .controlSize(.small)
                            }
                        }

                        // 풀 정보
                        HStack {
                            VStack(alignment: .leading) {
                                Text("성공 풀")
                                    .font(.caption)
                                Text("\(formatCasinoPrice(prophecy.successPool))P")
                                    .font(.subheadline.weight(.semibold))
                                    .foregroundStyle(.green)
                            }
                            Spacer()
                            VStack(alignment: .trailing) {
                                Text("실패 풀")
                                    .font(.caption)
                                Text("\(formatCasinoPrice(prophecy.failurePool))P")
                                    .font(.subheadline.weight(.semibold))
                                    .foregroundStyle(.red)
                            }
                        }
                        .padding(.vertical, 8)

                        Button {
                            Task { await placeProphecyBetAction() }
                        } label: {
                            Text("베팅하기")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(AppTheme.casino)
                        .controlSize(.large)
                        .disabled(prophecyBetAmount.isEmpty || Int(prophecyBetAmount) == nil)
                    }
                }
            }
        }
        .padding()
        .cardStyle()
    }

    // MARK: - 기존 예언 배팅 Section (친구 할 일 성공/실패 예측)
    private var prophecyBetSection: some View {
        VStack(spacing: 20) {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Image(systemName: "checklist")
                        .foregroundStyle(.orange)
                    Text("할 일 배팅")
                        .font(.headline)
                }
                Text("친구를 선택하고, 오늘 할 일 성공/실패를 예언한 뒤 베팅하세요.")
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
                    Text("\(betAmount)P")
                        .font(.subheadline.weight(.semibold))
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 4) {
                    Text("예상 수익")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text("\((Int(betAmount) ?? 0) * 2)P")
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

    // MARK: - 내 배팅 내역 Section
    private var myBetsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("최근 배팅 내역")
                .font(.headline)

            // 예언 배팅 내역
            if !appState.myProphecyBets.isEmpty {
                Text("예언 배팅")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.secondary)

                ForEach(appState.myProphecyBets.prefix(5)) { bet in
                    ProphecyBetRow(bet: bet)
                }
            }

            // 할 일 배팅 내역
            if !appState.bettingHistory.isEmpty {
                Text("할 일 배팅")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.secondary)

                ForEach(appState.bettingHistory.prefix(5)) { bet in
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

            if appState.myProphecyBets.isEmpty && appState.bettingHistory.isEmpty {
                Text("최근 내역이 없습니다")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding()
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

// MARK: - My Prophecy Row
struct MyProphecyRow: View {
    let prophecy: Prophecy
    let onClose: () -> Void

    private func formatPrice(_ value: Int) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        return formatter.string(from: NSNumber(value: value)) ?? "0"
    }

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(prophecy.content)
                    .font(.subheadline.weight(.medium))
                HStack(spacing: 12) {
                    Text("성공 풀: \(formatPrice(prophecy.successPool))P")
                        .font(.caption)
                        .foregroundStyle(.green)
                    Text("실패 풀: \(formatPrice(prophecy.failurePool))P")
                        .font(.caption)
                        .foregroundStyle(.red)
                }
            }

            Spacer()

            Button("종료") {
                onClose()
            }
            .buttonStyle(.bordered)
            .controlSize(.small)
            .tint(.orange)
        }
        .padding(12)
        .background(Color(nsColor: .controlBackgroundColor).opacity(0.5))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}

// MARK: - Friend Prophecy Card
struct FriendProphecyCard: View {
    let prophecy: Prophecy
    let isSelected: Bool
    let onSelect: () -> Void

    private func formatPrice(_ value: Int) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        return formatter.string(from: NSNumber(value: value)) ?? "0"
    }

    var body: some View {
        Button(action: onSelect) {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    AvatarView(name: prophecy.ownerName, color: .cyan, size: 24)
                    Text(prophecy.ownerName)
                        .font(.caption.weight(.semibold))
                }

                Text(prophecy.content)
                    .font(.subheadline)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)

                HStack {
                    Text("총 \(formatPrice(prophecy.totalPool))P")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Spacer()
                    Text(prophecy.timeAgo)
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                }
            }
            .padding(12)
            .frame(width: 200)
            .background(isSelected ? Color.cyan.opacity(0.15) : Color(nsColor: .controlBackgroundColor))
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? Color.cyan : Color.clear, lineWidth: 2)
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Prophecy Bet Row
struct ProphecyBetRow: View {
    let bet: ProphecyBet

    private func formatPrice(_ value: Int) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        return formatter.string(from: NSNumber(value: value)) ?? "0"
    }

    var body: some View {
        HStack {
            Circle()
                .fill(bet.predictSuccess ? Color.green.opacity(0.3) : Color.red.opacity(0.3))
                .frame(width: 8, height: 8)

            VStack(alignment: .leading, spacing: 2) {
                Text(bet.ownerName)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text(bet.prophecyContent)
                    .font(.subheadline)
                    .lineLimit(1)
            }

            Spacer()

            Text("\(formatPrice(bet.amount))P")
                .font(.subheadline)

            switch bet.resultType {
            case .win:
                Text("+\(formatPrice(bet.profitLoss ?? 0))P")
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(AppTheme.gain)
            case .lose:
                Text("\(formatPrice(bet.profitLoss ?? 0))P")
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

                Text("TICKER")
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
