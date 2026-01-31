import SwiftUI

/// StockCardView: 친구/종목 한 줄 카드 (macOS 리스트/사이드바/메인에서 재사용)
struct StockCardView: View {
    let name: String
    var avatar: NSImage? = nil          // macOS라 NSImage 추천 (나중에 URL로 바꿔도 됨)
    let price: Int                      // e.g. 912000
    let change: Double                  // e.g. +5.92 (%)
    let sparklineData: [Double]

    var onClick: (() -> Void)? = nil

    @State private var isHovering = false

    private var initials: String {
        // TS: name.slice(0,2).toUpperCase()
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        let prefix2 = String(trimmed.prefix(2))
        return prefix2.uppercased()
    }

    var body: some View {
        Button(action: { onClick?() }) {
            HStack(spacing: 14) {
                // Avatar
                StockCardAvatarView(image: avatar, fallbackText: initials)
                    .frame(width: 40, height: 40)

                // Name + Price
                VStack(alignment: .leading, spacing: 4) {
                    Text(name)
                        .font(.system(size: 14, weight: .semibold))
                        .lineLimit(1)
                        .truncationMode(.tail)

                    Text("\(price.formatted(.number))P")
                        .font(.system(size: 18, weight: .bold))
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                // Right: sparkline + badge
                VStack(alignment: .trailing, spacing: 8) {
                    SparklineView(data: sparklineData)
                        .frame(width: 60, height: 20)

                    PriceBadgeView(value: change, percentage: true, showIcon: true, size: .sm)
                }
            }
            .padding(14)
            .background(cardBackground)
            .overlay(cardBorder)
            .contentShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        }
        .buttonStyle(.plain) // macOS: 버튼 기본 스타일 제거
        .onHover { hovering in
            isHovering = hovering
        }
    }

    // MARK: - Styles

    private var cardBackground: some View {
        RoundedRectangle(cornerRadius: 12, style: .continuous)
            .fill(Color(NSColor.windowBackgroundColor).opacity(0.6))
    }

    private var cardBorder: some View {
        RoundedRectangle(cornerRadius: 12, style: .continuous)
            .stroke(borderColor, lineWidth: 1)
    }

    private var borderColor: Color {
        // TS: hover:border-primary/30 느낌
        if isHovering {
            return Color.accentColor.opacity(0.35)
        } else {
            return Color(NSColor.separatorColor).opacity(0.8)
        }
    }
}

// MARK: - StockCardAvatarView (간단 버전)
private struct StockCardAvatarView: View {
    let image: NSImage?
    let fallbackText: String

    var body: some View {
        ZStack {
            if let image {
                Image(nsImage: image)
                    .resizable()
                    .scaledToFill()
            } else {
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(Color(NSColor.controlBackgroundColor).opacity(0.8))

                Text(fallbackText)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(.secondary)
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
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
}
