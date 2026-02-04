import SwiftUI

struct ListingView: View {
    @EnvironmentObject var appState: AppState

    var body: some View {
        ScrollView {
            VStack(spacing: 32) {
                // Header
                headerSection

                // My Stock Chart
                myStockSection

                // Today's Listing
                todayListingSection

                // Price Change Rules
                priceChangeRulesCard

                // Recent History
                recentHistorySection
            }
            .padding(24)
        }
        .background(AppTheme.background)
    }

    // MARK: - Header
    private var headerSection: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("상장")
                    .font(.title.weight(.bold))
                    .foregroundStyle(AppTheme.primaryText)
                Text("오늘의 할 일을 등록하고 주가를 올리세요")
                    .font(.subheadline)
                    .foregroundStyle(AppTheme.secondaryText)
            }

            Spacer()

            HStack(spacing: 16) {
                VStack(alignment: .trailing, spacing: 2) {
                    Text("현재 내 주가")
                        .font(.caption)
                        .foregroundStyle(AppTheme.secondaryText)
                    Text(formatCurrency(Int(appState.userStockPrice)) + "원")
                        .font(.headline.monospacedDigit())
                        .foregroundStyle(AppTheme.gain)
                }

                VStack(alignment: .trailing, spacing: 2) {
                    Text("시가총액")
                        .font(.caption)
                        .foregroundStyle(AppTheme.secondaryText)
                    Text(formatCurrency(Int(appState.myMarketCap)) + "원")
                        .font(.headline.monospacedDigit())
                        .foregroundStyle(AppTheme.neon)
                }

                // 장 상태 배지
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
        }
    }

    // MARK: - My Stock Chart
    private var myStockSection: some View {
        VStack(alignment: .leading, spacing: 20) {
            Label("내 주가 차트", systemImage: "chart.bar.xaxis")
                .font(.headline)
                .foregroundStyle(AppTheme.primaryText)

            VStack(alignment: .leading, spacing: 8) {
                HStack(alignment: .firstTextBaseline, spacing: 12) {
                    Text(formatCurrency(Int(appState.userStockPrice)) + "원")
                        .font(.system(size: 36, weight: .bold, design: .rounded))
                        .foregroundStyle(AppTheme.primaryText)

                    if appState.dailyChange != 0 {
                        PriceChangeBadge(change: appState.dailyChange)
                    }
                }
            }

            // Chart with dates
            if appState.myPriceHistory.count > 1 {
                DateChartView(priceHistory: appState.myPriceHistory)
                    .frame(height: 250)
            } else {
                ZoomableChartView(
                    data: appState.userStockHistory,
                    minVisiblePoints: 5
                )
                .frame(height: 250)
            }
        }
        .padding(24)
        .cardStyle()
    }

    // MARK: - Today's Listing Section
    private var todayListingSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Label("오늘의 상장", systemImage: "chart.line.uptrend.xyaxis")
                    .font(.headline)
                    .foregroundStyle(AppTheme.gain)

                Spacer()

                let todayStr = todayDateString()
                Text(todayStr)
                    .font(.subheadline)
                    .foregroundStyle(AppTheme.secondaryText)
            }

            if let record = appState.myTodayRecord {
                // 상장 완료 상태 - 투두 목록 표시
                listedTodayView(record: record)
            } else {
                // 미상장 - 투두 입력 폼
                NewTodoListingForm()
            }
        }
        .padding(24)
        .cardStyle()
    }

    // MARK: - Listed Today View
    private func listedTodayView(record: DailyRecord) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            // 완성률 바
            VStack(spacing: 8) {
                HStack {
                    Text("완성률")
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(AppTheme.secondaryText)
                    Spacer()
                    Text("\(record.completedCount) / \(record.totalCount)")
                        .font(.system(.headline, weight: .bold).monospacedDigit())
                        .foregroundStyle(AppTheme.primaryText)
                    Text("(\(Int(record.completionRate * 100))%)")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(record.completionRate >= 0.75 ? AppTheme.gain : (record.completionRate >= 0.50 ? AppTheme.secondaryText : AppTheme.loss))
                }

                // Progress bar
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 4)
                            .fill(AppTheme.cardBackgroundLight)
                            .frame(height: 8)

                        RoundedRectangle(cornerRadius: 4)
                            .fill(progressColor(rate: record.completionRate))
                            .frame(width: max(4, geo.size.width * record.completionRate), height: 8)
                    }
                }
                .frame(height: 8)
            }

            // 예상 주가 변동폭
            HStack {
                HStack(spacing: 4) {
                    Image(systemName: "chart.line.uptrend.xyaxis")
                        .font(.caption)
                    Text("예상 주가 변동폭")
                        .font(.subheadline)
                }
                .foregroundStyle(AppTheme.secondaryText)

                Spacer()

                Text(record.projectedChangeText)
                    .font(.system(.headline, weight: .bold).monospacedDigit())
                    .foregroundStyle(record.projectedPriceChange >= 0 ? AppTheme.gain : AppTheme.loss)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background((record.projectedPriceChange >= 0 ? AppTheme.gain : AppTheme.loss).opacity(0.15))
                    .clipShape(RoundedRectangle(cornerRadius: 6))
            }

            Divider().background(AppTheme.border)

            // 투두 목록 + 완성 버튼
            VStack(spacing: 6) {
                ForEach(record.todoItems) { item in
                    TodoItemRow(item: item) {
                        Task {
                            if item.isCompleted {
                                await appState.uncompleteTodoItem(itemId: item.id)
                            } else {
                                await appState.completeTodoItem(itemId: item.id)
                            }
                        }
                    }
                }
            }
        }
    }

    // MARK: - Price Change Rules
    private var priceChangeRulesCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 6) {
                Image(systemName: "info.circle")
                    .foregroundStyle(.blue)
                Text("주가 변동 규칙")
                    .font(.headline)
                    .foregroundStyle(AppTheme.primaryText)
            }

            VStack(spacing: 4) {
                ruleRow(rate: "100%", change: "+10~15%", color: AppTheme.gain)
                ruleRow(rate: "75~99%", change: "+5%", color: AppTheme.gain)
                ruleRow(rate: "50~74%", change: "0%", color: AppTheme.secondaryText)
                ruleRow(rate: "25~49%", change: "-10%", color: AppTheme.loss)
                ruleRow(rate: "0~24%", change: "-20%", color: AppTheme.loss)
            }

            Text("* 밤 12시에 하루 완성률이 반영되어 다음 날 주가가 변동됩니다")
                .font(.caption)
                .foregroundStyle(AppTheme.tertiaryText)
        }
        .padding(24)
        .cardStyle()
    }

    private func ruleRow(rate: String, change: String, color: Color) -> some View {
        HStack {
            Text("완성률 \(rate)")
                .font(.subheadline)
                .foregroundStyle(AppTheme.primaryText)
            Spacer()
            Text(change)
                .font(.system(.subheadline, weight: .bold).monospacedDigit())
                .foregroundStyle(color)
        }
        .padding(.vertical, 6)
        .padding(.horizontal, 12)
        .background(AppTheme.cardBackgroundLight)
        .clipShape(RoundedRectangle(cornerRadius: 6))
    }

    // MARK: - Recent History
    private var recentHistorySection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("최근 기록")
                .font(.headline)
                .foregroundStyle(AppTheme.secondaryText)

            if appState.myDailyRecords.isEmpty {
                VStack(spacing: 8) {
                    Image(systemName: "clock")
                        .font(.title2)
                        .foregroundStyle(AppTheme.tertiaryText)
                    Text("아직 기록이 없습니다")
                        .font(.subheadline)
                        .foregroundStyle(AppTheme.secondaryText)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 20)
            } else {
                VStack(spacing: 8) {
                    ForEach(appState.myDailyRecords.suffix(7).reversed()) { record in
                        DailyRecordRow(record: record)
                    }
                }
            }
        }
    }

    // MARK: - Helpers
    private func progressColor(rate: Double) -> Color {
        if rate >= 0.75 { return AppTheme.gain }
        if rate >= 0.50 { return .yellow }
        return AppTheme.loss
    }

    private func todayDateString() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "M월 d일 (E)"
        formatter.locale = Locale(identifier: "ko_KR")
        return formatter.string(from: Date())
    }

    private func formatCurrency(_ value: Int) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        return formatter.string(from: NSNumber(value: value)) ?? "0"
    }
}

// MARK: - Todo Item Row
struct TodoItemRow: View {
    let item: TodoItem
    let onToggle: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            Button(action: onToggle) {
                Image(systemName: item.isCompleted ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 20))
                    .foregroundStyle(item.isCompleted ? AppTheme.gain : AppTheme.tertiaryText)
            }
            .buttonStyle(.plain)

            Text(item.title)
                .font(.subheadline.weight(.medium))
                .foregroundStyle(item.isCompleted ? AppTheme.secondaryText : AppTheme.primaryText)
                .strikethrough(item.isCompleted, color: AppTheme.tertiaryText)

            Spacer()

            if item.isCompleted {
                Text("완료")
                    .font(.caption.weight(.medium))
                    .foregroundStyle(AppTheme.gain)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(AppTheme.gain.opacity(0.1))
                    .clipShape(RoundedRectangle(cornerRadius: 4))
            }
        }
        .padding(.vertical, 10)
        .padding(.horizontal, 14)
        .background(item.isCompleted ? AppTheme.gain.opacity(0.05) : AppTheme.cardBackgroundLight)
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}

// MARK: - New Todo Listing Form
struct NewTodoListingForm: View {
    @EnvironmentObject var appState: AppState
    @State private var todoTexts: [String] = ["", "", "", ""]
    @State private var showMinimumAlert = false

    private var validTodos: [String] {
        todoTexts.filter { !$0.trimmingCharacters(in: .whitespaces).isEmpty }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("오늘의 할 일을 작성하세요")
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(AppTheme.primaryText)
                Spacer()
                Text("최소 4개")
                    .font(.caption)
                    .foregroundStyle(validTodos.count >= 4 ? AppTheme.gain : AppTheme.loss)
            }

            VStack(spacing: 8) {
                ForEach(todoTexts.indices, id: \.self) { index in
                    HStack(spacing: 8) {
                        Image(systemName: "circle")
                            .font(.system(size: 14))
                            .foregroundStyle(AppTheme.tertiaryText)

                        TextField("할 일 \(index + 1)", text: $todoTexts[index])
                            .textFieldStyle(.plain)
                            .font(.subheadline)
                            .foregroundStyle(AppTheme.primaryText)
                    }
                    .padding(.vertical, 10)
                    .padding(.horizontal, 12)
                    .background(AppTheme.cardBackgroundLight)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(AppTheme.border, lineWidth: 1)
                    )
                }
            }

            // 항목 추가 버튼
            Button {
                todoTexts.append("")
            } label: {
                HStack(spacing: 4) {
                    Image(systemName: "plus.circle")
                        .font(.caption)
                    Text("항목 추가")
                        .font(.caption)
                }
                .foregroundStyle(AppTheme.secondaryText)
            }
            .buttonStyle(.plain)

            // 상장하기 버튼
            Button {
                if validTodos.count >= 4 {
                    Task {
                        let items = validTodos.map { TodoItem(title: $0) }
                        await appState.listTodayTodos(items: items)
                    }
                } else {
                    showMinimumAlert = true
                }
            } label: {
                Text("상장하기")
                    .font(.headline)
                    .foregroundStyle(.black)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(validTodos.count >= 4 ? AppTheme.gain : Color.gray)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
            }
            .buttonStyle(.plain)
            .disabled(validTodos.count < 4)
            .alert("최소 4개 필요", isPresented: $showMinimumAlert) {
                Button("확인", role: .cancel) {}
            } message: {
                Text("최소 4개의 할 일을 작성해야 상장할 수 있습니다.")
            }

            Text("* 오전 10시 전에 상장하면 10시에 장이 열립니다")
                .font(.caption)
                .foregroundStyle(AppTheme.tertiaryText)
        }
    }
}

// MARK: - Daily Record Row
struct DailyRecordRow: View {
    let record: DailyRecord

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(formatDate(record.date))
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(AppTheme.primaryText)
                Text("\(record.completedCount)/\(record.totalCount) 완료")
                    .font(.caption)
                    .foregroundStyle(AppTheme.secondaryText)
            }

            Spacer()

            // 완성률
            Text("\(Int(record.completionRate * 100))%")
                .font(.system(.subheadline, weight: .semibold).monospacedDigit())
                .foregroundStyle(record.completionRate >= 0.75 ? AppTheme.gain : (record.completionRate >= 0.50 ? AppTheme.secondaryText : AppTheme.loss))
                .frame(width: 50, alignment: .trailing)

            // 주가 변동
            if let change = record.priceChangePercent {
                Text(String(format: "%+.0f%%", change * 100))
                    .font(.system(.subheadline, weight: .bold).monospacedDigit())
                    .foregroundStyle(change >= 0 ? AppTheme.gain : AppTheme.loss)
                    .frame(width: 60, alignment: .trailing)
            }
        }
        .padding()
        .cardStyle()
    }

    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "M/d (E)"
        formatter.locale = Locale(identifier: "ko_KR")
        return formatter.string(from: date)
    }
}

#Preview {
    ListingView()
        .environmentObject(AppState())
        .frame(width: 900, height: 800)
        .preferredColorScheme(.dark)
}
