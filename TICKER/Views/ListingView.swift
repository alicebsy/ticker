import SwiftUI

struct ListingView: View {
    @EnvironmentObject var appState: AppState
    @State private var selectedListing: Listing?
    @State private var chartTimeRange: ChartTimeRange = .week

    enum ChartTimeRange: String, CaseIterable, Identifiable {
        case day = "1D"
        case week = "7D"
        case month = "1M"
        
        var id: String { rawValue }
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 32) {
                // Header (Like PortfolioView)
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("상장")
                            .font(.title.weight(.bold))
                            .foregroundStyle(AppTheme.primaryText)
                        Text("새로운 목표를 상장하고 내 주가를 확인하세요")
                            .font(.subheadline)
                            .foregroundStyle(AppTheme.secondaryText)
                    }
                    Spacer()
                    
                    // User Stats Badge
                    HStack(spacing: 12) {
                        VStack(alignment: .trailing, spacing: 2) {
                            Text("현재 내 주가")
                                .font(.caption)
                                .foregroundStyle(AppTheme.secondaryText)
                            Text("₩\(Int(appState.userStockPrice))")
                                .font(.headline.monospacedDigit())
                                .foregroundStyle(AppTheme.gain)
                        }
                        
                        VStack(alignment: .trailing, spacing: 2) {
                            Text("연승")
                                .font(.caption)
                                .foregroundStyle(AppTheme.secondaryText)
                            Text("\(appState.streak)회")
                                .font(.headline.monospacedDigit())
                                .foregroundStyle(AppTheme.neon)
                        }
                    }
                    .padding(12)
                    .background(AppTheme.cardBackgroundLight)
                    .cornerRadius(8)
                }
                
                // New Listing Card (Embedded)
                NewListingCard()
                
                // My Stock Chart Section
                myStockSection
                
                // Active Listings Section
                activeListingsSection
                
                // Completed Listings Section
                completedListingsSection
            }
            .padding(24)
        }
        .background(AppTheme.background)
        .navigationTitle("") // Hide default navigation title since we have custom header
    }
    
    // MARK: - My Stock Section
    private var myStockSection: some View {
        VStack(alignment: .leading, spacing: 20) {
            // Header for Chart Section
            HStack {
                Label("내 주가 차트", systemImage: "chart.bar.xaxis")
                    .font(.headline)
                    .foregroundStyle(AppTheme.primaryText)
                
                Spacer()
                
                HStack(spacing: 0) {
                    ForEach(ChartTimeRange.allCases) { range in
                        Button(action: { chartTimeRange = range }) {
                            Text(range.rawValue)
                                .font(.caption.weight(.medium))
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(chartTimeRange == range ? AppTheme.gain : Color.clear)
                                .foregroundStyle(chartTimeRange == range ? .black : AppTheme.secondaryText)
                                .cornerRadius(4)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(4)
                .background(Color.black.opacity(0.3))
                .cornerRadius(6)
            }
            
            VStack(alignment: .leading, spacing: 8) {
                HStack(alignment: .firstTextBaseline, spacing: 12) {
                    Text("\(Int(appState.userStockPrice))P")
                        .font(.system(size: 36, weight: .bold, design: .rounded))
                        .foregroundStyle(AppTheme.primaryText)
                    
                    HStack(spacing: 4) {
                        Image(systemName: "arrow.up.right")
                        Text("+3.85%")
                    }
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(AppTheme.gain)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(AppTheme.gain.opacity(0.1))
                    .cornerRadius(4)
                    
                    Text("연속 \(appState.streak)일 상승")
                        .font(.caption)
                        .foregroundStyle(AppTheme.secondaryText)
                }
            }
            
            // Zoomable Chart
            ZoomableChartView(
                data: appState.userStockHistory,
                minVisiblePoints: 5
            )
            .frame(height: 250)
            .background(Color.black.opacity(0.2))
            .cornerRadius(12)
        }
        .padding(24)
        .cardStyle()
        .onAppear {
            appState.checkDeadlines()
        }
    }
    
    // MARK: - Active Listings Section
    private var activeListingsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Label("상장 중인 종목", systemImage: "chart.line.uptrend.xyaxis")
                    .font(.headline)
                    .foregroundStyle(AppTheme.gain)
                
                Spacer()
            }
            
            VStack(spacing: 0) {
                // Table Header
                HStack {
                    Text("종목명")
                        .frame(maxWidth: .infinity, alignment: .leading)
                    Text("마감일")
                        .frame(width: 100, alignment: .leading)
                    Text("보상")
                        .frame(width: 80, alignment: .leading)
                    Text("진행률")
                        .frame(width: 60, alignment: .leading)
                    Text("액션")
                        .frame(width: 180, alignment: .trailing)
                }
                .font(.caption)
                .foregroundStyle(AppTheme.secondaryText)
                .padding(.horizontal)
                .padding(.bottom, 12)
                
                Divider()
                    .background(AppTheme.border)
                
                ForEach(appState.myListings.filter { $0.isActive }) { listing in
                    ListingTableRow(listing: listing)
                    Divider()
                        .background(AppTheme.border)
                }
            }
        }
        .padding(24)
        .cardStyle()
    }
    
    // MARK: - Completed Listings Section
    private var completedListingsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("완료된 상장")
                .font(.headline)
                .foregroundStyle(AppTheme.secondaryText)
            
            VStack(spacing: 8) {
                // Filter actual completed listings
                ForEach(appState.myListings.filter { !$0.isActive }) { listing in
                     CompletedListingRow(
                        title: listing.title,
                        result: listing.change >= 0 ? .success : .failure,
                        reward: Int(listing.initialPrice),
                        penalty: Int(abs(listing.change)) // Dynamic penalty display
                    )
                }
            }
        }
    }
}

// MARK: - Listing Table Row
struct ListingTableRow: View {
    let listing: Listing
    @EnvironmentObject var appState: AppState
    @State private var showTimeStopAlert = false
    
    // Computed binding to update the specific listing in AppState
    private var listingBinding: Binding<Listing>? {
        guard let index = appState.myListings.firstIndex(where: { $0.id == listing.id }) else { return nil }
        return $appState.myListings[index]
    }

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(listing.title)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(AppTheme.primaryText)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            
            HStack(spacing: 4) {
                Image(systemName: "clock")
                Text(formatDate(listing.deadline))
            }
            .font(.caption)
            .foregroundStyle(AppTheme.secondaryText)
            .frame(width: 100, alignment: .leading)
            
            Text("₩\(Int(listing.currentPrice))")
                .font(.system(size: 13, weight: .bold))
                .foregroundStyle(AppTheme.gain)
                .frame(width: 80, alignment: .leading)
            
            // Progress Section with Slider
            if let binding = listingBinding {
                VStack(spacing: 2) {
                    HStack {
                        Text("\(Int(binding.progress.wrappedValue * 100))%")
                            .font(.caption2.weight(.bold))
                            .foregroundStyle(AppTheme.gain)
                        Spacer()
                    }
                    
                    Slider(value: binding.progress, in: 0...1)
                        .tint(AppTheme.gain)
                        .scaleEffect(0.8) // Make it a bit smaller to fit
                        .frame(height: 10)
                }
                .frame(width: 60)
            } else {
                Text("\(Int(listing.progress * 100))%")
                    .font(.caption)
                    .foregroundStyle(AppTheme.secondaryText)
                    .frame(width: 60, alignment: .leading)
            }
            
            HStack(spacing: 8) {
                // Sell Button
                Button(action: { completeListing(success: true) }) {
                    HStack(spacing: 4) {
                        Image(systemName: "checkmark")
                        Text("매도")
                    }
                    .font(.caption.weight(.medium))
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(AppTheme.gain)
                    .foregroundStyle(.black)
                    .cornerRadius(4)
                }
                .buttonStyle(PlainButtonStyle())
                
                // Time Stop Button
                let ticketCount = appState.mySkills["시간 정지"] ?? 0
                Button(action: {
                    if ticketCount > 0 {
                        showTimeStopAlert = true
                    }
                }) {
                    HStack(spacing: 4) {
                        Image(systemName: "clock")
                        Text("존버 (\(ticketCount))")
                    }
                    .font(.caption.weight(.medium))
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(ticketCount > 0 ? Color.white.opacity(0.1) : Color.black.opacity(0.3))
                    .foregroundStyle(ticketCount > 0 ? AppTheme.primaryText : AppTheme.secondaryText)
                    .cornerRadius(4)
                }
                .disabled(ticketCount <= 0)
                .buttonStyle(PlainButtonStyle())
                .alert("시간 정지 사용", isPresented: $showTimeStopAlert) {
                    Button("사용", role: .none) {
                        useTimeStop()
                    }
                    Button("취소", role: .cancel) {}
                } message: {
                    Text("마감일을 하루 연장하시겠습니까?\n남은 '시간 정지' 스킬: \(ticketCount)개")
                }
            }
            .frame(width: 180, alignment: .trailing)
        }
        .padding(.vertical, 16)
        .padding(.horizontal, 8)
    }
    
    // MARK: - Gamification Logic
    private func completeListing(success: Bool) {
        if let index = appState.myListings.firstIndex(where: { $0.id == listing.id }) {
            withAnimation {
                var updatedListing = appState.myListings[index]
                updatedListing.isActive = false
                
                if success {
                    // Success Logic
                    // 1. Base 10% increase
                    let baseIncrease = appState.userStockPrice * 0.10
                    
                    // 2. Streak Bonus (1% per streak)
                    let streakBonus = appState.userStockPrice * (0.01 * Double(appState.streak))
                    
                    // Update User Price
                    appState.userStockPrice += (baseIncrease + streakBonus)
                    
                    // Update Listing status (Storing reward as positive change)
                    updatedListing.change = baseIncrease + streakBonus
                    
                    // Increase Streak
                    appState.streak += 1
                }
                // Failure is handled by checkDeadlines automatically now
                
                appState.myListings[index] = updatedListing
                
                // Update History
                appState.userStockHistory.append(appState.userStockPrice)
            }
        }
    }
    
    private func useTimeStop() {
        guard let count = appState.mySkills["시간 정지"], count > 0 else { return }
        
        if let index = appState.myListings.firstIndex(where: { $0.id == listing.id }) {
            withAnimation {
                // Consume 1 Ticket
                appState.mySkills["시간 정지"] = count - 1
                
                // Extend deadline by 1 day
                let newDate = Calendar.current.date(byAdding: .day, value: 1, to: appState.myListings[index].deadline) ?? Date()
                appState.myListings[index].deadline = newDate
            }
        }
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: date)
    }
}

// MARK: - New Listing Card (Embedded Form)
struct NewListingCard: View {
    @EnvironmentObject var appState: AppState
    
    @State private var title = ""
    @State private var date = Date()
    @State private var difficulty = 1 // Default to Normal (1)
    @State private var visibility = 0 // 0: Friends Only
    
    // Validated Pricing based on Formula
    var calculatedPrice: Int {
        let basePrice: Double
        switch difficulty {
        case 0: basePrice = 5000  // Easy
        case 1: basePrice = 10000 // Normal
        case 2: basePrice = 20000 // Hard
        default: basePrice = 10000
        }
        
        let multiplier = appState.userStockPrice / 10000.0 // Adjusted base multiplier
        return Int(basePrice * multiplier)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            HStack {
                Image(systemName: "plus")
                    .foregroundStyle(AppTheme.gain)
                Text("신규 상장")
                    .font(.title2.weight(.bold))
                    .foregroundStyle(AppTheme.primaryText)
                
                Spacer()
                
                // Difficulty Info
                Text("예상 공모가: ₩\(calculatedPrice)")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(AppTheme.gain)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(AppTheme.gain.opacity(0.1))
                    .cornerRadius(6)
            }
            .padding(.bottom, 8)
            
            // Form Fields
            VStack(spacing: 20) {
                inputGroup(title: "종목명 (할 일)", placeholder: "예: 헬스장 주 3회 가기", text: $title)
                
                HStack(spacing: 16) {
                    // Date Picker
                    VStack(alignment: .leading, spacing: 8) {
                        Text("마감일")
                            .font(.caption)
                            .foregroundStyle(AppTheme.secondaryText)
                        
                        HStack {
                            Image(systemName: "calendar")
                                .foregroundStyle(AppTheme.secondaryText)
                            DatePicker("", selection: $date, displayedComponents: [.date, .hourAndMinute])
                                .labelsHidden()
                                .colorScheme(.dark)
                        }
                        .padding(12)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(AppTheme.cardBackgroundLight)
                        .cornerRadius(8)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(AppTheme.border, lineWidth: 1)
                        )
                    }
                    
                    // Difficulty
                    VStack(alignment: .leading, spacing: 8) {
                        Text("난이도")
                            .font(.caption)
                            .foregroundStyle(AppTheme.secondaryText)
                        
                        Menu {
                            Button("🟢 쉬움 (5,000P)", action: { difficulty = 0 })
                            Button("🟡 보통 (10,000P)", action: { difficulty = 1 })
                            Button("🔴 어려움 (20,000P)", action: { difficulty = 2 })
                        } label: {
                            HStack {
                                Text(difficultyLabel)
                                    .foregroundStyle(difficultyColor)
                                Spacer()
                                Image(systemName: "chevron.down")
                                    .font(.caption)
                                    .foregroundStyle(AppTheme.secondaryText)
                            }
                            .padding(12)
                            .background(AppTheme.cardBackgroundLight)
                            .cornerRadius(8)
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(AppTheme.border, lineWidth: 1)
                            )
                        }
                        .menuStyle(.borderlessButton)
                    }
                }
                
                // Visibility
                 VStack(alignment: .leading, spacing: 8) {
                     Text("공개 범위")
                         .font(.caption)
                         .foregroundStyle(AppTheme.secondaryText)
                     
                     Menu {
                         Button("친구만", action: { visibility = 0 })
                         Button("전체 공개", action: { visibility = 1 })
                         Button("비공개", action: { visibility = 2 })
                     } label: {
                         HStack {
                             Text(visibilityLabel)
                                 .foregroundStyle(AppTheme.primaryText)
                             Spacer()
                             Image(systemName: "chevron.down")
                                 .font(.caption)
                                 .foregroundStyle(AppTheme.secondaryText)
                         }
                         .padding(12)
                         .background(AppTheme.cardBackgroundLight)
                         .cornerRadius(8)
                         .overlay(
                             RoundedRectangle(cornerRadius: 8)
                                 .stroke(AppTheme.border, lineWidth: 1)
                         )
                     }
                     .menuStyle(.borderlessButton)
                 }
            }
            
            Button(action: {
                approveListing()
            }) {
                Text("상장 승인")
                    .font(.headline)
                    .foregroundStyle(.black)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(title.isEmpty ? Color.gray : AppTheme.gain)
                    .cornerRadius(8)
            }
            .disabled(title.isEmpty)
            .buttonStyle(PlainButtonStyle())
        }
        .padding(24)
        .cardStyle()
    }
    
    private func approveListing() {
        let newListing = Listing(
            id: UUID(),
            title: title,
            category: .project, // Default for now
            initialPrice: Double(calculatedPrice),
            currentPrice: Double(calculatedPrice),
            change: 0,
            progress: 0.0,
            deadline: date,
            isActive: true
        )
        
        withAnimation {
            appState.myListings.insert(newListing, at: 0)
            // Reset fields
            title = ""
            date = Date()
            difficulty = 1
        }
    }
    
    private var difficultyLabel: String {
        switch difficulty {
        case 0: return "쉬움"
        case 1: return "보통"
        case 2: return "어려움"
        default: return "보통"
        }
    }
    
    private var difficultyColor: Color {
        switch difficulty {
        case 0: return .green
        case 1: return .yellow
        case 2: return .red
        default: return .white
        }
    }
    
    private var visibilityLabel: String {
        switch visibility {
        case 0: return "친구만"
        case 1: return "전체 공개"
        case 2: return "비공개"
        default: return "친구만"
        }
    }
    
    private func inputGroup(title: String, placeholder: String, text: Binding<String>, icon: String? = nil) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.caption)
                .foregroundStyle(AppTheme.secondaryText)
            
            HStack {
                if let icon = icon {
                    Image(systemName: icon)
                        .foregroundStyle(AppTheme.secondaryText)
                }
                
                TextField(placeholder, text: text)
                    .textFieldStyle(.plain)
                    .foregroundStyle(AppTheme.primaryText)
            }
            .padding(12)
            .background(AppTheme.cardBackgroundLight)
            .cornerRadius(8)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(AppTheme.border, lineWidth: 1)
            )
        }
    }
}

// MARK: - Completed Listing Row
struct CompletedListingRow: View {
    let title: String
    let result: ListingResult
    var reward: Int = 0
    var penalty: Int = 0
    
    enum ListingResult {
        case success, failure
    }
    
    var body: some View {
        HStack {
            Image(systemName: result == .success ? "checkmark.circle.fill" : "xmark.circle.fill")
                .foregroundStyle(result == .success ? AppTheme.gain : AppTheme.loss)
            
            Text(title)
                .font(.subheadline)
                .foregroundStyle(AppTheme.primaryText)
                .strikethrough(result == .failure, color: .secondary)
            
            Spacer()
            
            Text(result == .success ? "+₩\(reward)" : "-₩\(penalty)")
                .font(.subheadline.weight(.medium))
                .foregroundStyle(result == .success ? AppTheme.gain : AppTheme.loss)
        }
        .padding()
        .cardStyle()
    }
}

#Preview {
    ListingView()
        .environmentObject(AppState())
        .frame(width: 900, height: 800)
}
