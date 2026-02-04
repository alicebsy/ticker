import SwiftUI
import AppKit

/// StockCardView: 친구/종목 한 줄 카드 (macOS 리스트/사이드바/메인에서 재사용)
struct StockCardView: View {
    let name: String
    var avatar: NSImage? = nil
    let price: Int
    let change: Double
    let sparklineData: [Double]
    var isStarred: Bool = false
    var onStarClick: (() -> Void)? = nil

    var onClick: (() -> Void)? = nil

    @State private var isHovering = false

    private var initials: String {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        return String(trimmed.prefix(2)).uppercased()
    }

    private static var cardBackground: Color {
        Color(nsColor: NSColor.controlBackgroundColor)
    }

    private static var cardBackgroundLight: Color {
        Color(nsColor: NSColor.controlBackgroundColor).opacity(0.8)
    }

    private static var secondaryText: Color {
        Color.secondary
    }

    private static var border: Color {
        Color.primary.opacity(0.08)
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
                            .fill(Self.cardBackgroundLight)
                        Text(initials)
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundStyle(Self.secondaryText)
                    }
                }
                .frame(width: 42, height: 42)
                .clipShape(Circle())

                // Name + Price
                VStack(alignment: .leading, spacing: 4) {
                    Text(name)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(Color.primary)
                        .lineLimit(1)
                        .truncationMode(.tail)
                    Text("\(price.formatted(.number))P")
                        .font(.system(size: 18, weight: .bold).monospacedDigit())
                        .foregroundStyle(Color.primary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                // Right: sparkline + badge
                VStack(alignment: .trailing, spacing: 8) {
                    StockCardSparkline(data: sparklineData, showGradient: false)
                        .frame(width: 60, height: 20)
                    StockCardPriceBadge(change: change)
                }
                // Star Button
                Button(action: { onStarClick?() }) {
                    Image(systemName: isStarred ? "star.fill" : "star")
                        .foregroundStyle(isStarred ? .yellow : Self.secondaryText)
                        .font(.system(size: 16))
                }
                .buttonStyle(.plain)
            }
            .padding(14)
            .background(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(Self.cardBackground)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .stroke(
                        isHovering ? Color.accentColor.opacity(0.35) : Self.border,
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

// MARK: - Local helpers (Theme types may be in different compile order)
private struct StockCardSparkline: View {
    let data: [Double]
    var showGradient: Bool = true

    private var normalizedData: [Double] {
        guard let minVal = data.min(), let maxVal = data.max(), maxVal != minVal else {
            return data.map { _ in 0.5 }
        }
        return data.map { ($0 - minVal) / (maxVal - minVal) }
    }

    private var isPositive: Bool {
        guard let first = data.first, let last = data.last else { return true }
        return last >= first
    }

    private var lineColor: Color {
        isPositive ? .green : .red
    }

    var body: some View {
        GeometryReader { geometry in
            let width = geometry.size.width
            let height = geometry.size.height
            let stepX = width / CGFloat(max(normalizedData.count - 1, 1))

            ZStack {
                if showGradient {
                    Path { path in
                        path.move(to: CGPoint(x: 0, y: height))
                        for (index, value) in normalizedData.enumerated() {
                            let x = CGFloat(index) * stepX
                            let y = height - (CGFloat(value) * height)
                            path.addLine(to: CGPoint(x: x, y: y))
                        }
                        path.addLine(to: CGPoint(x: width, y: height))
                        path.closeSubpath()
                    }
                    .fill(
                        LinearGradient(
                            colors: [lineColor.opacity(0.3), lineColor.opacity(0.0)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                }
                Path { path in
                    for (index, value) in normalizedData.enumerated() {
                        let x = CGFloat(index) * stepX
                        let y = height - (CGFloat(value) * height)
                        if index == 0 {
                            path.move(to: CGPoint(x: x, y: y))
                        } else {
                            path.addLine(to: CGPoint(x: x, y: y))
                        }
                    }
                }
                .stroke(lineColor, lineWidth: 1)
            }
        }
    }
}

private struct StockCardPriceBadge: View {
    let change: Double
    private var isPositive: Bool { change >= 0 }

    var body: some View {
        HStack(spacing: 2) {
            Image(systemName: isPositive ? "arrowtriangle.up.fill" : "arrowtriangle.down.fill")
                .font(.system(size: 8))
            Text(String(format: "%+.1f%%", change))
                .font(.system(size: 12, weight: .semibold, design: .monospaced))
        }
        .foregroundStyle(isPositive ? Color.green : Color.red)
        .padding(.horizontal, 6)
        .padding(.vertical, 3)
        .background((isPositive ? Color.green : Color.red).opacity(0.15))
        .clipShape(RoundedRectangle(cornerRadius: 4))
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
    .background(Color(nsColor: .windowBackgroundColor))
    .preferredColorScheme(.dark)
}
