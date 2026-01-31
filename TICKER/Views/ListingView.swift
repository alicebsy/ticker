import SwiftUI

struct ListingView: View {
    @EnvironmentObject var appState: AppState
    @State private var showNewListingSheet = false
    @State private var selectedListing: Listing?
    
    var body: some View {
        HSplitView {
            // Main Content
            ScrollView {
                VStack(spacing: 24) {
                    // Header with "New Listing" button
                    headerSection
                    
                    // My Stock Price Chart
                    myStockSection
                    
                    // Active Listings
                    activeListingsSection
                    
                    // Completed Listings
                    completedListingsSection
                }
                .padding(24)
            }
            .frame(minWidth: 500)
            
            // Inspector Panel
            if let listing = selectedListing {
                ListingInspector(listing: listing)
                    .frame(width: 300)
            }
        }
        .navigationTitle("상장")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button(action: { showNewListingSheet = true }) {
                    Label("새 상장", systemImage: "plus")
                }
            }
        }
        .sheet(isPresented: $showNewListingSheet) {
            NewListingSheet()
        }
    }
    
    // MARK: - Header Section
    private var headerSection: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("내 주가")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                
                HStack(alignment: .firstTextBaseline, spacing: 8) {
                    Text("₩18,500")
                        .font(.system(size: 32, weight: .bold, design: .rounded))
                    
                    PriceChangeBadge(change: 4.2)
                }
            }
            
            Spacer()
            
            Button(action: { showNewListingSheet = true }) {
                Label("새 할일 상장", systemImage: "plus.circle.fill")
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
        }
    }
    
    // MARK: - My Stock Section
    private var myStockSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("내 주가 차트")
                .font(.headline)
            
            VStack(spacing: 16) {
                SparklineView(
                    data: [100, 105, 108, 103, 110, 115, 112, 118, 125, 130, 128, 135],
                    showGradient: true
                )
                .frame(height: 150)
                
                // Stats Row
                HStack(spacing: 24) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("시가총액")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Text("₩1,850,000")
                            .font(.subheadline.weight(.semibold))
                    }
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("거래량")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Text("324주")
                            .font(.subheadline.weight(.semibold))
                    }
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("투자자")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Text("12명")
                            .font(.subheadline.weight(.semibold))
                    }
                    
                    Spacer()
                }
            }
            .padding()
            .cardStyle()
        }
    }
    
    // MARK: - Active Listings Section
    private var activeListingsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("상장 중인 종목")
                    .font(.headline)
                
                Spacer()
                
                Text("\(appState.myListings.filter { $0.isActive }.count)개")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            
            VStack(spacing: 12) {
                ForEach(appState.myListings.filter { $0.isActive }) { listing in
                    ListingRow(listing: listing, isSelected: selectedListing?.id == listing.id)
                        .onTapGesture {
                            withAnimation(.easeInOut(duration: 0.2)) {
                                selectedListing = listing
                            }
                        }
                }
            }
        }
    }
    
    // MARK: - Completed Listings Section
    private var completedListingsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("완료된 상장")
                .font(.headline)
            
            VStack(spacing: 8) {
                CompletedListingRow(title: "Swift 공부하기", result: .success, reward: 15000)
                CompletedListingRow(title: "매일 운동", result: .failure, penalty: -5000)
                CompletedListingRow(title: "독서 모임 참석", result: .success, reward: 8000)
            }
        }
    }
}

// MARK: - Listing Row
struct ListingRow: View {
    let listing: Listing
    var isSelected: Bool = false
    
    var body: some View {
        HStack(spacing: 16) {
            // Category Icon
            ZStack {
                Circle()
                    .fill(listing.category.color.opacity(0.15))
                    .frame(width: 44, height: 44)
                
                Image(systemName: listing.category.icon)
                    .foregroundStyle(listing.category.color)
            }
            
            // Info
            VStack(alignment: .leading, spacing: 4) {
                Text(listing.title)
                    .font(.subheadline.weight(.semibold))
                
                HStack(spacing: 8) {
                    Text(listing.category.rawValue)
                        .font(.caption)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(listing.category.color.opacity(0.15))
                        .clipShape(RoundedRectangle(cornerRadius: 4))
                    
                    Text("D-\(daysRemaining)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            
            Spacer()
            
            // Progress
            VStack(alignment: .trailing, spacing: 4) {
                Text("\(Int(listing.progress * 100))%")
                    .font(.subheadline.weight(.semibold))
                
                ProgressView(value: listing.progress)
                    .frame(width: 80)
                    .tint(listing.category.color)
            }
            
            // Price Change
            VStack(alignment: .trailing, spacing: 4) {
                Text("₩\(Int(listing.currentPrice))")
                    .font(.subheadline.weight(.semibold))
                
                PriceChangeBadge(change: listing.change)
            }
        }
        .padding()
        .background(isSelected ? Color.accentColor.opacity(0.1) : Color(nsColor: .controlBackgroundColor))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(isSelected ? Color.accentColor : Color.clear, lineWidth: 2)
        )
    }
    
    private var daysRemaining: Int {
        Calendar.current.dateComponents([.day], from: Date(), to: listing.deadline).day ?? 0
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
                .strikethrough(result == .failure, color: .secondary)
            
            Spacer()
            
            Text(result == .success ? "+₩\(reward)" : "₩\(penalty)")
                .font(.subheadline.weight(.medium))
                .foregroundStyle(result == .success ? AppTheme.gain : AppTheme.loss)
        }
        .padding()
        .cardStyle()
    }
}

// MARK: - Listing Inspector
struct ListingInspector: View {
    let listing: Listing
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header
            VStack(alignment: .leading, spacing: 8) {
                Text(listing.title)
                    .font(.title3.weight(.semibold))
                
                HStack {
                    Text(listing.category.rawValue)
                        .font(.caption)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(listing.category.color.opacity(0.15))
                        .clipShape(RoundedRectangle(cornerRadius: 6))
                    
                    Spacer()
                    
                    PriceChangeBadge(change: listing.change)
                }
            }
            .padding()
            
            Divider()
            
            // Stats
            VStack(spacing: 16) {
                StatRow(label: "시작가", value: "₩\(Int(listing.initialPrice))")
                StatRow(label: "현재가", value: "₩\(Int(listing.currentPrice))")
                StatRow(label: "진행률", value: "\(Int(listing.progress * 100))%")
                StatRow(label: "마감일", value: formatDate(listing.deadline))
            }
            .padding()
            
            Divider()
            
            // Progress Section
            VStack(alignment: .leading, spacing: 12) {
                Text("진행 상황")
                    .font(.subheadline.weight(.semibold))
                
                ProgressView(value: listing.progress)
                    .tint(listing.category.color)
                
                Text("목표까지 \(Int((1 - listing.progress) * 100))% 남음")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .padding()
            
            Spacer()
            
            // Actions
            VStack(spacing: 8) {
                Button(action: {}) {
                    Label("진행 상황 업데이트", systemImage: "arrow.clockwise")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                
                Button(action: {}) {
                    Label("상장 폐지", systemImage: "xmark.circle")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
                .tint(.red)
            }
            .padding()
        }
        .background(Color(nsColor: .controlBackgroundColor))
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy.MM.dd"
        return formatter.string(from: date)
    }
}

struct StatRow: View {
    let label: String
    let value: String
    
    var body: some View {
        HStack {
            Text(label)
                .font(.subheadline)
                .foregroundStyle(.secondary)
            Spacer()
            Text(value)
                .font(.subheadline.weight(.medium))
        }
    }
}

// MARK: - New Listing Sheet
struct NewListingSheet: View {
    @Environment(\.dismiss) private var dismiss
    @State private var title = ""
    @State private var category: ListingCategory = .project
    @State private var initialPrice = "10000"
    @State private var deadline = Date().addingTimeInterval(86400 * 30)
    @State private var description = ""
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Button("취소") { dismiss() }
                    .keyboardShortcut(.cancelAction)
                
                Spacer()
                
                Text("새 할일 상장")
                    .font(.headline)
                
                Spacer()
                
                Button("상장하기") {
                    // Create listing
                    dismiss()
                }
                .keyboardShortcut(.defaultAction)
                .disabled(title.isEmpty)
            }
            .padding()
            
            Divider()
            
            Form {
                Section("기본 정보") {
                    TextField("할일 제목", text: $title)
                    
                    Picker("카테고리", selection: $category) {
                        ForEach(ListingCategory.allCases, id: \.self) { cat in
                            Label(cat.rawValue, systemImage: cat.icon)
                                .tag(cat)
                        }
                    }
                    
                    TextField("공모가 (₩)", text: $initialPrice)
                    
                    DatePicker("마감일", selection: $deadline, displayedComponents: .date)
                }
                
                Section("설명") {
                    TextEditor(text: $description)
                        .frame(height: 100)
                }
                
                Section {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("상장 규칙")
                            .font(.subheadline.weight(.semibold))
                        
                        Text("• 할일을 완료하면 주가가 상승합니다\n• 마감일까지 미완료시 주가가 하락합니다\n• 투자자들에게 배당금이 지급됩니다")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .formStyle(.grouped)
        }
        .frame(width: 450, height: 500)
    }
}

#Preview {
    ListingView()
        .environmentObject(AppState())
        .frame(width: 900, height: 700)
}
