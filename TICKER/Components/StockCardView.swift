import SwiftUI

/// StockCardView: 친구/종목 한 줄 카드 (macOS 리스트/사이드바/메인에서 재사용)
struct StockCardView: View {
    let name: String
    var avatar: NSImage? = nil
    let price: Int
    let change: Double
    let sparklineData: [Double]

    var onClick: (() -> Void)? = nil

    @State private var isHovering = false

    private var initials: String {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        return String(trimmed.prefix(2)).uppercased()
    }

    var body: some View {
        Button(action: { onClick?() }) {
            HStack(spacing: 14) {
                // Avatar
                ZStack {
                    if let img = avatar {
                        Image(nsImage: img)
                            .resizable()
                            .scaledToFill()
                    } else {
                        Circle()
                            .fill(AppTheme.cardBackgroundLight)
                        Text(initials)
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundStyle(AppTheme.secondaryText)
                    }
                }
                .frame(width: 42, height: 42)
                .clipShape(Circle())

                // Name + Price
                VStack(alignment: .leading, spacing: 4) {
                    Text(name)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(AppTheme.primaryText)
                        .lineLimit(1)
                        .truncationMode(.tail)
                    Text("\(price.formatted(.number))P")
                        .font(.system(size: 18, weight: .bold).monospacedDigit())
                        .foregroundStyle(AppTheme.primaryText)
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                // Right: sparkline + badge
                VStack(alignment: .trailing, spacing: 8) {
                    SparklineView(data: sparklineData, showGradient: false)
                        .frame(width: 60, height: 20)
                    PriceChangeBadge(change: change)
                }
            }
            .padding(14)
            .background(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(AppTheme.cardBackground)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .stroke(
                        isHovering ? Color.accentColor.opacity(0.35) : AppTheme.border,
                        lineWidth: 1
                    )
            )
            .contentShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        }
        .buttonStyle(.plain)
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.15)) {
                isHovering = hovering
            }
        }
    }
}

#Preview {
    VStack(spacing: 12) {
        StockCardView(
            name: "SK하이닉스",
            price: 912_000,
            change: 5.92,
            sparklineData: [1, 1.2, 1.1, 1.3, 1.8, 1.7, 2.0]
        )
        StockCardView(
            name: "휴림로봇",
            price: 14_810,
            change: -2.44,
            sparklineData: [2.0, 1.9, 1.7, 1.6, 1.55, 1.45, 1.4]
        )
    }
    .padding()
    .frame(width: 420)
    .background(AppTheme.background)
    .preferredColorScheme(.dark)
}
