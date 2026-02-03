import SwiftUI

struct PersonDetailView: View {
    let friend: Friend
    var onClose: (() -> Void)? = nil
    @EnvironmentObject var appState: AppState

    @State private var orderType: OrderType = .buy
    @State private var quantity: Int = 1
    @State private var selectedDateOffset: Int = 0  // 0 = 오늘, -1 = 어제, ...
    @State private var showAlert = false
    @State private var alertTitle = ""
    @State private var alertMessage = ""

    enum OrderType: String, CaseIterable {
        case buy = "매수"
        case sell = "매도"
    }

    // 내가 이 사람의 주식을 보유하고 있는지
    private var myHolding: Holding? {
        appState.holdings.first(where: { $0.name == friend.name })
    }

    private var myHoldingQuantity: Int {
        myHolding?.quantity ?? 0
    }

    // 선택된 날짜의 기록
    private var selectedRecord: DailyRecord? {
        if selectedDateOffset == 0 {
            return friend.todayRecord
        } else {
            let targetDate = Calendar.current.date(byAdding: .day, value: selectedDateOffset, to: Date()) ?? Date()
            return friend.dailyRecords.first { record in
                Calendar.current.isDate(record.date, inSameDayAs: targetDate)
            }
        }
    }

    private var selectedDateString: String {
        let date = Calendar.current.date(byAdding: .day, value: selectedDateOffset, to: Date()) ?? Date()
        let formatter = DateFormatter()
        formatter.dateFormat = "M월 d일 (E)"
        formatter.locale = Locale(identifier: "ko_KR")
        return formatter.string(from: date)
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                // Close button
                if let onClose = onClose {
                    HStack {
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
                    .padding(.horizontal, 16)
                    .padding(.top, 12)
                }

                // 1. Header: Avatar + Name + Price
                headerSection

                Divider().background(AppTheme.border)

                // 2. Stock Chart
                chartSection

                Divider().background(AppTheme.border)

                // 3. Today's Todo / Date Navigation
                todoSection

                Divider().background(AppTheme.border)

                // 4. Buy/Sell Section
                tradingSection
            }
        }
        .background(AppTheme.cardBackground)
        .alert(alertTitle, isPresented: $showAlert) {
            Button("확인", role: .cancel) {}
        } message: {
            Text(alertMessage)
        }
    }

    // MARK: - Header Section
    private var headerSection: some View {
        VStack(spacing: 12) {
            AvatarView(name: friend.name, color: friend.avatarColor, size: 64)

            Text(friend.name)
                .font(.title3.weight(.semibold))
                .foregroundStyle(AppTheme.primaryText)

            Text(friend.ticker)
                .font(.subheadline)
                .foregroundStyle(AppTheme.secondaryText)

            // 현재 주가 (크게)
            HStack(spacing: 8) {
                Text(formatCurrency(Int(friend.currentPrice)) + "원")
                    .font(.system(size: 28, weight: .bold).monospacedDigit())
                    .foregroundStyle(AppTheme.primaryText)

                PriceChangeBadge(change: friend.change)
            }

            // 시가총액 (가치)
            VStack(spacing: 4) {
                Text("시가총액 (가치)")
                    .font(.caption)
                    .foregroundStyle(AppTheme.secondaryText)
                Text(formatCurrency(Int(friend.marketCap)) + "원")
                    .font(.system(.headline, weight: .semibold).monospacedDigit())
                    .foregroundStyle(AppTheme.primaryText)
            }

            // 거래대금
            if friend.tradingVolume > 0 {
                Text("오늘 \(formatCurrency(Int(friend.tradingVolume)))원 거래됨")
                    .font(.caption)
                    .foregroundStyle(AppTheme.tertiaryText)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(20)
    }

    // MARK: - Chart Section
    private var chartSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("주가 차트")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(AppTheme.primaryText)

            if friend.priceHistory.count > 1 {
                // 날짜 표시가 있는 차트
                DateChartView(priceHistory: friend.priceHistory)
                    .frame(height: 120)
            } else {
                SparklineView(data: friend.sparklineData, showGradient: true)
                    .frame(height: 100)
            }
        }
        .padding(16)
    }

    // MARK: - Todo Section with Date Navigation
    private var todoSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Date Navigation
            HStack {
                Button {
                    selectedDateOffset -= 1
                } label: {
                    Image(systemName: "chevron.left")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(AppTheme.primaryText)
                        .frame(width: 28, height: 28)
                        .background(AppTheme.cardBackgroundLight)
                        .clipShape(RoundedRectangle(cornerRadius: 6))
                }
                .buttonStyle(.plain)

                Spacer()

                Text(selectedDateString)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(AppTheme.primaryText)

                Spacer()

                Button {
                    if selectedDateOffset < 0 {
                        selectedDateOffset += 1
                    }
                } label: {
                    Image(systemName: "chevron.right")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(selectedDateOffset < 0 ? AppTheme.primaryText : AppTheme.tertiaryText)
                        .frame(width: 28, height: 28)
                        .background(AppTheme.cardBackgroundLight)
                        .clipShape(RoundedRectangle(cornerRadius: 6))
                }
                .buttonStyle(.plain)
                .disabled(selectedDateOffset >= 0)
            }

            if let record = selectedRecord {
                // 완성률
                HStack {
                    Text("완성률")
                        .font(.caption)
                        .foregroundStyle(AppTheme.secondaryText)

                    Spacer()

                    Text("\(record.completedCount) / \(record.totalCount)")
                        .font(.system(.subheadline, weight: .semibold).monospacedDigit())
                        .foregroundStyle(AppTheme.primaryText)

                    Text("(\(Int(record.completionRate * 100))%)")
                        .font(.caption.weight(.medium))
                        .foregroundStyle(record.completionRate >= 0.75 ? AppTheme.gain : (record.completionRate >= 0.50 ? AppTheme.secondaryText : AppTheme.loss))
                }

                // 주가 변동 (정산된 경우) 또는 예상 변동폭
                HStack {
                    if let settled = record.priceChangePercent {
                        Text("주가 변동")
                            .font(.caption)
                            .foregroundStyle(AppTheme.secondaryText)
                        Spacer()
                        Text(String(format: "%+.0f%%", settled * 100))
                            .font(.system(.subheadline, weight: .bold).monospacedDigit())
                            .foregroundStyle(settled >= 0 ? AppTheme.gain : AppTheme.loss)
                    } else {
                        Text("예상 주가 변동폭")
                            .font(.caption)
                            .foregroundStyle(AppTheme.secondaryText)
                        Spacer()
                        Text(record.projectedChangeText)
                            .font(.system(.subheadline, weight: .bold).monospacedDigit())
                            .foregroundStyle(record.projectedPriceChange >= 0 ? AppTheme.gain : AppTheme.loss)
                    }
                }

                // 투두 목록
                VStack(spacing: 4) {
                    ForEach(record.todoItems) { item in
                        HStack(spacing: 8) {
                            Image(systemName: item.isCompleted ? "checkmark.circle.fill" : "circle")
                                .font(.system(size: 14))
                                .foregroundStyle(item.isCompleted ? AppTheme.gain : AppTheme.tertiaryText)

                            Text(item.title)
                                .font(.subheadline)
                                .foregroundStyle(item.isCompleted ? AppTheme.primaryText : AppTheme.secondaryText)
                                .strikethrough(item.isCompleted, color: AppTheme.tertiaryText)

                            Spacer()
                        }
                        .padding(.vertical, 6)
                        .padding(.horizontal, 10)
                        .background(AppTheme.cardBackgroundLight)
                        .clipShape(RoundedRectangle(cornerRadius: 6))
                    }
                }
            } else {
                VStack(spacing: 8) {
                    Image(systemName: "doc.text")
                        .font(.title2)
                        .foregroundStyle(AppTheme.tertiaryText)
                    Text("이 날의 투두 기록이 없습니다")
                        .font(.subheadline)
                        .foregroundStyle(AppTheme.secondaryText)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 20)
            }
        }
        .padding(16)
    }

    // MARK: - Trading Section
    private var tradingSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("주문")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(AppTheme.primaryText)

            // 장 상태 표시
            if !appState.isMarketOpen {
                HStack(spacing: 6) {
                    Image(systemName: "clock.fill")
                        .font(.caption)
                    Text("장 마감 - 거래 불가 (10시 개장)")
                        .font(.caption)
                }
                .foregroundStyle(.orange)
                .padding(8)
                .frame(maxWidth: .infinity)
                .background(Color.orange.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: 6))
            }

            // Buy/Sell Segmented
            HStack(spacing: 0) {
                ForEach(OrderType.allCases, id: \.self) { type in
                    Button {
                        withAnimation(.easeInOut(duration: 0.15)) {
                            orderType = type
                            quantity = 1
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

            // 매수 가능 수량 / 보유 수량
            if orderType == .buy {
                HStack {
                    Text("매수 가능 수량")
                        .font(.caption)
                        .foregroundStyle(AppTheme.secondaryText)
                    Spacer()
                    Text("\(friend.availableShares) / \(friend.floatShares) 주")
                        .font(.system(.caption, weight: .semibold).monospacedDigit())
                        .foregroundStyle(friend.availableShares > 0 ? AppTheme.gain : AppTheme.loss)
                }
            } else {
                HStack {
                    Text("보유 수량")
                        .font(.caption)
                        .foregroundStyle(AppTheme.secondaryText)
                    Spacer()
                    Text("\(myHoldingQuantity) 주")
                        .font(.system(.caption, weight: .semibold).monospacedDigit())
                        .foregroundStyle(AppTheme.primaryText)
                }
            }

            // Quantity
            HStack {
                Text("수량")
                    .font(.subheadline)
                    .foregroundStyle(AppTheme.secondaryText)
                Spacer()
                HStack(spacing: 8) {
                    Button {
                        if quantity > 1 { quantity -= 1 }
                    } label: {
                        Image(systemName: "minus")
                            .font(.caption.weight(.bold))
                            .foregroundStyle(AppTheme.primaryText)
                            .frame(width: 28, height: 28)
                            .background(AppTheme.cardBackgroundLight)
                            .clipShape(RoundedRectangle(cornerRadius: 6))
                    }
                    .buttonStyle(.plain)

                    Text("\(quantity)")
                        .font(.system(.subheadline, weight: .medium).monospacedDigit())
                        .frame(width: 40)
                        .padding(.vertical, 4)
                        .background(AppTheme.cardBackgroundLight)
                        .clipShape(RoundedRectangle(cornerRadius: 6))
                        .multilineTextAlignment(.center)

                    Button {
                        let maxQty = orderType == .buy ? friend.availableShares : myHoldingQuantity
                        if quantity < maxQty {
                            quantity += 1
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

            // 예상 금액
            HStack {
                Text("예상 금액")
                    .font(.subheadline)
                    .foregroundStyle(AppTheme.secondaryText)
                Spacer()
                Text(formatCurrency(Int(friend.currentPrice) * quantity) + "원")
                    .font(.system(.subheadline, weight: .semibold).monospacedDigit())
                    .foregroundStyle(AppTheme.primaryText)
            }

            // 보유 현금
            HStack {
                Text("보유 현금")
                    .font(.caption)
                    .foregroundStyle(AppTheme.secondaryText)
                Spacer()
                Text(formatCurrency(Int(appState.cash)) + "원")
                    .font(.system(.caption, weight: .semibold).monospacedDigit())
                    .foregroundStyle(AppTheme.secondaryText)
            }

            // 실행 버튼
            Button {
                executeOrder()
            } label: {
                Text(orderType == .buy ? "매수하기" : "매도하기")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background(
                        (orderType == .buy ? Color.blue : Color.orange)
                            .opacity(canExecuteOrder ? 1.0 : 0.4)
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 8))
            }
            .buttonStyle(.plain)
            .disabled(!canExecuteOrder)
        }
        .padding(16)
    }

    // MARK: - Order Execution
    private var canExecuteOrder: Bool {
        guard appState.isMarketOpen else { return false }
        if orderType == .buy {
            return friend.availableShares >= quantity && appState.cash >= Int(friend.currentPrice * Double(quantity))
        } else {
            return myHoldingQuantity >= quantity
        }
    }

    private func executeOrder() {
        Task {
            if orderType == .buy {
                let success = await appState.buyStock(
                    friendName: friend.name,
                    quantity: quantity,
                    pricePerShare: friend.currentPrice
                )
                if success {
                    alertTitle = "매수 완료"
                    alertMessage = "\(friend.name) \(quantity)주 매수 완료!"
                    showAlert = true
                    quantity = 1
                } else {
                    alertTitle = "매수 실패"
                    alertMessage = "잔고 부족 또는 매수 가능 수량 초과입니다."
                    showAlert = true
                }
            } else {
                let success = await appState.sellStock(
                    friendName: friend.name,
                    quantity: quantity,
                    pricePerShare: friend.currentPrice
                )
                if success {
                    alertTitle = "매도 완료"
                    alertMessage = "\(friend.name) \(quantity)주 매도 완료!"
                    showAlert = true
                    quantity = 1
                } else {
                    alertTitle = "매도 실패"
                    alertMessage = "보유 수량이 부족합니다."
                    showAlert = true
                }
            }
        }
    }

    private func formatCurrency(_ value: Int) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        return formatter.string(from: NSNumber(value: value)) ?? "0"
    }
}

// MARK: - Date Chart View (날짜 x축이 있는 차트)
struct DateChartView: View {
    let priceHistory: [PriceHistoryPoint]

    private var sortedHistory: [PriceHistoryPoint] {
        priceHistory.sorted { $0.date < $1.date }
    }

    private var prices: [Double] {
        sortedHistory.map { $0.price }
    }

    private var isPositive: Bool {
        guard let first = prices.first, let last = prices.last else { return true }
        return last >= first
    }

    private var lineColor: Color {
        isPositive ? AppTheme.gain : AppTheme.loss
    }

    var body: some View {
        VStack(spacing: 4) {
            GeometryReader { geometry in
                let width = geometry.size.width
                let height = geometry.size.height - 20  // 날짜 라벨 공간

                let minPrice = prices.min() ?? 0
                let maxPrice = prices.max() ?? 1
                let range = maxPrice - minPrice
                let effectiveRange = range == 0 ? 1.0 : range

                let stepX = width / CGFloat(max(prices.count - 1, 1))

                ZStack(alignment: .topLeading) {
                    // Gradient fill
                    Path { path in
                        path.move(to: CGPoint(x: 0, y: height))
                        for (index, price) in prices.enumerated() {
                            let x = CGFloat(index) * stepX
                            let y = height - CGFloat((price - minPrice) / effectiveRange) * height
                            path.addLine(to: CGPoint(x: x, y: y))
                        }
                        path.addLine(to: CGPoint(x: CGFloat(prices.count - 1) * stepX, y: height))
                        path.closeSubpath()
                    }
                    .fill(
                        LinearGradient(
                            colors: [lineColor.opacity(0.3), lineColor.opacity(0.0)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )

                    // Line
                    Path { path in
                        for (index, price) in prices.enumerated() {
                            let x = CGFloat(index) * stepX
                            let y = height - CGFloat((price - minPrice) / effectiveRange) * height
                            if index == 0 {
                                path.move(to: CGPoint(x: x, y: y))
                            } else {
                                path.addLine(to: CGPoint(x: x, y: y))
                            }
                        }
                    }
                    .stroke(lineColor, style: StrokeStyle(lineWidth: 2, lineCap: .round, lineJoin: .round))

                    // Date labels
                    let labelIndices = calculateLabelIndices(total: sortedHistory.count, maxLabels: 5)
                    ForEach(labelIndices, id: \.self) { index in
                        let x = CGFloat(index) * stepX
                        let formatter = DateFormatter()
                        let _ = formatter.dateFormat = "M/d"

                        Text(formatter.string(from: sortedHistory[index].date))
                            .font(.system(size: 9))
                            .foregroundStyle(AppTheme.tertiaryText)
                            .position(x: x, y: height + 12)
                    }
                }
            }
        }
    }

    private func calculateLabelIndices(total: Int, maxLabels: Int) -> [Int] {
        guard total > 1 else { return [0] }
        if total <= maxLabels { return Array(0..<total) }
        let step = Double(total - 1) / Double(maxLabels - 1)
        return (0..<maxLabels).map { Int(Double($0) * step) }
    }
}

#Preview {
    PersonDetailView(friend: Friend.sampleData[0])
        .environmentObject(AppState())
        .frame(width: 340, height: 800)
        .preferredColorScheme(.dark)
}
