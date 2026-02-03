import SwiftUI

struct StoreView: View {
    @EnvironmentObject var appState: AppState
    @State private var selectedCategory: StoreCategory? = nil
    @State private var selectedItem: StoreItem?
    @State private var showInsufficientFundsAlert = false
    @State private var showPurchaseSuccessAlert = false
    @State private var alertMessage = ""
    
    private var filteredItems: [StoreItem] {
        guard let category = selectedCategory else {
            return appState.storeItems
        }
        return appState.storeItems.filter { $0.category == category }
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Header
                headerSection
                
                // Category Filter
                categoryFilter
                
                // Items Grid
                itemsGrid
                
                // Warning Banner
                warningBanner
            }
            .padding(24)
        }
        .onAppear {
            Task {
                await appState.fetchDarkMarketData()
            }
        }
        .navigationTitle("암시장")
        .sheet(item: $selectedItem) { item in
            ItemDetailSheet(item: item, onPurchase: {
                purchaseItem(item)
            }, cash: appState.cash)
        }
        .alert("잔고 부족", isPresented: $showInsufficientFundsAlert) {
            Button("확인", role: .cancel) {}
        } message: {
            Text(alertMessage)
        }
        .alert("구매 완료", isPresented: $showPurchaseSuccessAlert) {
            Button("확인", role: .cancel) {}
        } message: {
            Text(alertMessage)
        }
    }
    
    // MARK: - Header Section
    private var headerSection: some View {
        HStack {
            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 8) {
                    Image(systemName: "bag.fill")
                        .font(.title)
                        .foregroundStyle(AppTheme.neon)
                    
                    Text("암시장")
                        .font(.largeTitle.weight(.bold))
                }
                
                Text("금지된 아이템과 특수 스킬을 거래하세요")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 4) {
                Text("보유 현금")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text(formatCashDisplay(Int(appState.cash)) + "P")
                    .font(.title2.weight(.bold))
                    .foregroundStyle(AppTheme.neon)
            }
        }
        .padding()
        .background(
            LinearGradient(
                colors: [Color.black.opacity(0.8), Color.purple.opacity(0.3)],
                startPoint: .leading,
                endPoint: .trailing
            )
        )
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
    
    // MARK: - Category Filter
    private var categoryFilter: some View {
        HStack(spacing: 12) {
            CategoryButton(
                title: "전체",
                isSelected: selectedCategory == nil,
                action: { selectedCategory = nil }
            )
            
            ForEach(StoreCategory.allCases, id: \.self) { category in
                CategoryButton(
                    title: category.rawValue,
                    isSelected: selectedCategory == category,
                    action: { selectedCategory = category }
                )
            }
            
            Spacer()
        }
    }
    
    // MARK: - Items Grid
    private var itemsGrid: some View {
        LazyVGrid(columns: [
            GridItem(.flexible(), spacing: 16),
            GridItem(.flexible(), spacing: 16),
            GridItem(.flexible(), spacing: 16)
        ], spacing: 16) {
            ForEach(filteredItems) { item in
                StoreItemCard(item: item)
                    .onTapGesture {
                        selectedItem = item
                    }
            }
        }
    }
    
    // MARK: - Purchase Logic
    private func purchaseItem(_ item: StoreItem) {
        guard let backendId = item.backendId else { return }
        
        Task {
            let success = await appState.purchaseItem(itemId: backendId, quantity: 1)
            if success {
                alertMessage = "'\(item.name)' 구매 완료! (\(item.price)P 차감)"
                selectedItem = nil
                showPurchaseSuccessAlert = true
            } else {
                let formatter = NumberFormatter()
                formatter.numberStyle = .decimal
                let cashStr = formatter.string(from: NSNumber(value: Int(appState.cash))) ?? "0"
                alertMessage = "구매에 실패했습니다. 잔고를 확인해주세요.\n현재 잔액: \(cashStr)P\n필요 금액: \(item.price)P"
                selectedItem = nil
                showInsufficientFundsAlert = true
            }
        }
    }

    private func formatCashDisplay(_ value: Int) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        return formatter.string(from: NSNumber(value: value)) ?? "0"
    }

    // MARK: - Warning Banner
    private var warningBanner: some View {
        HStack(spacing: 12) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.title2)
                .foregroundStyle(.orange)
            
            VStack(alignment: .leading, spacing: 4) {
                Text("경고")
                    .font(.subheadline.weight(.semibold))
                Text("암시장 아이템 사용시 신뢰도가 하락할 수 있습니다. 신중하게 구매하세요.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            
            Spacer()
        }
        .padding()
        .background(Color.orange.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

// MARK: - Category Button
struct CategoryButton: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.subheadline.weight(isSelected ? .semibold : .regular))
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(isSelected ? Color.accentColor : Color(nsColor: .controlBackgroundColor))
                .foregroundStyle(isSelected ? .white : .primary)
                .clipShape(RoundedRectangle(cornerRadius: 8))
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Store Item Card
struct StoreItemCard: View {
    let item: StoreItem
    @EnvironmentObject var appState: AppState
    @State private var isHovered = false

    private var canAfford: Bool {
        appState.cash >= item.price
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Icon & Rarity
            HStack {
                ZStack {
                    Circle()
                        .fill(item.rarity.color.opacity(0.2))
                        .frame(width: 50, height: 50)

                    Image(systemName: item.icon)
                        .font(.title2)
                        .foregroundStyle(item.rarity.color)
                }

                Spacer()

                Text(item.rarity.rawValue)
                    .font(.caption.weight(.semibold))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(item.rarity.color.opacity(0.2))
                    .foregroundStyle(item.rarity.color)
                    .clipShape(RoundedRectangle(cornerRadius: 4))
            }

            // Info
            VStack(alignment: .leading, spacing: 4) {
                Text(item.name)
                    .font(.subheadline.weight(.semibold))

                Text(item.description)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            }

            Spacer()

            // Price & Buy
            HStack {
                Text("\(formatStorePrice(item.price))P")
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(canAfford ? AppTheme.neon : AppTheme.loss)

                Spacer()

                if !canAfford {
                    Text("잔고 부족")
                        .font(.caption2)
                        .foregroundStyle(AppTheme.loss)
                }
            }
        }
        .padding()
        .frame(height: 180)
        .background(Color(nsColor: .controlBackgroundColor))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(item.rarity.color.opacity(isHovered ? 0.5 : 0), lineWidth: 2)
        )
        .scaleEffect(isHovered ? 1.02 : 1.0)
        .animation(.easeInOut(duration: 0.2), value: isHovered)
        .onHover { hovering in
            isHovered = hovering
        }
    }

    private func formatStorePrice(_ value: Int) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        return formatter.string(from: NSNumber(value: value)) ?? "0"
    }
}

// MARK: - Item Detail Sheet
struct ItemDetailSheet: View {
    let item: StoreItem
    var onPurchase: () -> Void
    var cash: Int
    @Environment(\.dismiss) private var dismiss

    private var canAfford: Bool {
        cash >= item.price
    }

    private func formatDetailPrice(_ value: Int) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        return formatter.string(from: NSNumber(value: value)) ?? "0"
    }

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Spacer()
                Button(action: { dismiss() }) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.title2)
                        .foregroundStyle(.secondary)
                }
            }
            .padding()

            // Content
            VStack(spacing: 24) {
                // Icon
                ZStack {
                    Circle()
                        .fill(item.rarity.color.opacity(0.2))
                        .frame(width: 100, height: 100)

                    Image(systemName: item.icon)
                        .font(.system(size: 44))
                        .foregroundStyle(item.rarity.color)
                }

                // Info
                VStack(spacing: 8) {
                    Text(item.name)
                        .font(.title2.weight(.bold))

                    Text(item.rarity.rawValue)
                        .font(.caption.weight(.semibold))
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(item.rarity.color.opacity(0.2))
                        .foregroundStyle(item.rarity.color)
                        .clipShape(RoundedRectangle(cornerRadius: 6))
                }

                Text(item.description)
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)

                Divider()

                // Effects
                VStack(alignment: .leading, spacing: 12) {
                    Text("효과")
                        .font(.subheadline.weight(.semibold))

                    HStack {
                        Image(systemName: "sparkles")
                            .foregroundStyle(item.rarity.color)
                        Text("24시간 동안 효과 지속")
                            .font(.subheadline)
                    }

                    HStack {
                        Image(systemName: "exclamationmark.triangle")
                            .foregroundStyle(.orange)
                        Text("신뢰도 -5 패널티")
                            .font(.subheadline)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                Spacer()

                // Purchase
                VStack(spacing: 12) {
                    HStack {
                        Text("가격")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                        Spacer()
                        Text("\(formatDetailPrice(item.price))P")
                            .font(.title3.weight(.bold))
                            .foregroundStyle(canAfford ? AppTheme.neon : AppTheme.loss)
                    }

                    HStack {
                        Text("보유 현금")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Spacer()
                        Text("\(formatDetailPrice(Int(cash)))P")
                            .font(.caption.weight(.medium))
                            .foregroundStyle(.secondary)
                    }

                    Button(action: { onPurchase() }) {
                        Text(canAfford ? "구매하기" : "잔고 부족")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)
                    .disabled(!canAfford)
                }
            }
            .padding(24)
        }
        .frame(width: 350, height: 550)
    }
}

#Preview {
    StoreView()
        .environmentObject(AppState())
        .frame(width: 900, height: 700)
}
