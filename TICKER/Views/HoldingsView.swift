import SwiftUI

struct HoldingsView: View {
    @EnvironmentObject var appState: AppState
<<<<<<< HEAD
    @State private var selectedHoldingID: Holding.ID?
    @State private var sortOrder: SortOrder = .value
    @State private var searchText = ""

    private var selectedHolding: Holding? {
        guard let id = selectedHoldingID else { return nil }
        return appState.holdings.first { $0.id == id }
    }
=======
    @State private var selectedHolding: Holding?
    @State private var sortOrder: SortOrder = .value
    @State private var searchText = ""
>>>>>>> main
    
    enum SortOrder: String, CaseIterable {
        case name = "이름순"
        case value = "평가액순"
        case change = "수익률순"
    }
    
    private var filteredHoldings: [Holding] {
        let filtered = searchText.isEmpty ? appState.holdings : appState.holdings.filter {
            $0.name.contains(searchText) || $0.ticker.contains(searchText.uppercased())
        }
        
        return filtered.sorted { a, b in
            switch sortOrder {
            case .name: return a.name < b.name
            case .value: return a.totalValue > b.totalValue
            case .change: return a.change > b.change
            }
        }
    }
    
    var body: some View {
        HSplitView {
            // Holdings Table
            VStack(spacing: 0) {
                // Summary Header
                summaryHeader
                
                Divider()
                
                // Table
                holdingsTable
            }
            .frame(minWidth: 500)
            
            // Inspector Panel
            if let holding = selectedHolding {
                HoldingInspector(holding: holding)
                    .frame(width: 320)
            }
        }
        .navigationTitle("보유 종목")
        .searchable(text: $searchText, prompt: "종목명 또는 티커 검색")
        .toolbar {
            ToolbarItem(placement: .automatic) {
                Picker("정렬", selection: $sortOrder) {
                    ForEach(SortOrder.allCases, id: \.self) { order in
                        Text(order.rawValue).tag(order)
                    }
                }
            }
        }
    }
    
    // MARK: - Summary Header
    private var summaryHeader: some View {
        HStack(spacing: 32) {
            VStack(alignment: .leading, spacing: 4) {
                Text("총 평가액")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text(formatCurrency(totalValue))
                    .font(.title2.weight(.bold))
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text("총 수익")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                HStack(spacing: 4) {
                    Text(formatCurrency(totalProfit))
                        .font(.title2.weight(.bold))
                        .foregroundStyle(totalProfit >= 0 ? AppTheme.gain : AppTheme.loss)
                    
                    PriceChangeBadge(change: totalProfitPercent)
                }
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 4) {
                Text("보유 종목")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text("\(appState.holdings.count)개")
                    .font(.title2.weight(.bold))
            }
        }
        .padding()
        .background(Color(nsColor: .controlBackgroundColor))
    }
    
    // MARK: - Holdings Table
    private var holdingsTable: some View {
<<<<<<< HEAD
        Table(of: Holding.self, selection: $selectedHoldingID) {
=======
        Table(of: Holding.self, selection: $selectedHolding) {
>>>>>>> main
            TableColumn("종목") { holding in
                HStack(spacing: 12) {
                    AvatarView(name: holding.name, color: holding.avatarColor, size: 32)
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text(holding.name)
                            .font(.subheadline.weight(.medium))
                        Text(holding.ticker)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .width(min: 150, ideal: 180)
            
            TableColumn("현재가") { holding in
                Text("₩\(Int(holding.currentPrice))")
                    .font(.subheadline.monospacedDigit())
            }
            .width(min: 80, ideal: 100)
            
            TableColumn("등락") { holding in
                PriceChangeBadge(change: holding.change)
            }
            .width(min: 70, ideal: 80)
            
            TableColumn("보유수량") { holding in
                Text("\(holding.quantity)주")
                    .font(.subheadline.monospacedDigit())
            }
            .width(min: 60, ideal: 80)
            
            TableColumn("평가액") { holding in
                Text("₩\(Int(holding.totalValue))")
                    .font(.subheadline.weight(.medium).monospacedDigit())
            }
            .width(min: 100, ideal: 120)
            
            TableColumn("차트") { holding in
                SparklineView(data: holding.sparklineData)
                    .frame(width: 80, height: 24)
            }
            .width(min: 80, ideal: 100)
        } rows: {
            ForEach(filteredHoldings) { holding in
                TableRow(holding)
            }
        }
    }
    
    // MARK: - Computed Properties
    private var totalValue: Double {
        appState.holdings.reduce(0) { $0 + $1.totalValue }
    }
    
    private var totalProfit: Double {
        totalValue * 0.124 // 임시 계산
    }
    
    private var totalProfitPercent: Double {
        12.4
    }
    
    private func formatCurrency(_ value: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 0
        return "₩" + (formatter.string(from: NSNumber(value: value)) ?? "0")
    }
}

// MARK: - Holding Inspector
struct HoldingInspector: View {
    let holding: Holding
    @State private var orderType: OrderType = .buy
    @State private var quantity = "1"
    
    enum OrderType: String, CaseIterable {
        case buy = "매수"
        case sell = "매도"
    }
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                // Header
                VStack(alignment: .center, spacing: 12) {
                    AvatarView(name: holding.name, color: holding.avatarColor, size: 64)
                    
                    Text(holding.name)
                        .font(.title3.weight(.semibold))
                    
                    Text(holding.ticker)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    
                    HStack(spacing: 8) {
                        Text("₩\(Int(holding.currentPrice))")
                            .font(.title2.weight(.bold))
                        
                        PriceChangeBadge(change: holding.change)
                    }
                }
                .frame(maxWidth: .infinity)
                .padding()
                
                Divider()
                
                // Chart
                VStack(alignment: .leading, spacing: 8) {
                    Text("가격 추이")
                        .font(.subheadline.weight(.semibold))
                    
                    SparklineView(data: holding.sparklineData, showGradient: true)
                        .frame(height: 100)
                }
                .padding()
                
                Divider()
                
                // Stats
                VStack(spacing: 12) {
                    StatRow(label: "보유 수량", value: "\(holding.quantity)주")
                    StatRow(label: "평균 단가", value: "₩\(Int(holding.currentPrice * 0.9))")
                    StatRow(label: "평가 금액", value: "₩\(Int(holding.totalValue))")
                    StatRow(label: "평가 손익", value: "+₩\(Int(holding.totalValue * 0.1))")
                }
                .padding()
                
                Divider()
                
                // Order Form
                VStack(alignment: .leading, spacing: 16) {
                    Text("주문")
                        .font(.subheadline.weight(.semibold))
                    
                    Picker("주문 유형", selection: $orderType) {
                        ForEach(OrderType.allCases, id: \.self) { type in
                            Text(type.rawValue).tag(type)
                        }
                    }
                    .pickerStyle(.segmented)
                    
                    HStack {
                        Text("수량")
                            .font(.subheadline)
                        Spacer()
                        TextField("수량", text: $quantity)
                            .textFieldStyle(.roundedBorder)
                            .frame(width: 80)
                        Text("주")
                            .font(.subheadline)
                    }
                    
                    HStack {
                        Text("예상 금액")
                            .font(.subheadline)
                        Spacer()
                        Text("₩\(Int(holding.currentPrice) * (Int(quantity) ?? 1))")
                            .font(.subheadline.weight(.semibold))
                    }
                    
                    Button(action: {}) {
                        Text(orderType == .buy ? "매수하기" : "매도하기")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(orderType == .buy ? .blue : .orange)
                    .controlSize(.large)
                }
                .padding()
            }
        }
        .background(Color(nsColor: .controlBackgroundColor))
    }
}

#Preview {
    HoldingsView()
        .environmentObject(AppState())
        .frame(width: 1000, height: 600)
}
